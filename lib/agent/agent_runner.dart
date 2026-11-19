import '../domain/attachments/local_image.dart';

import 'dart:async';
import 'dart:convert';

import '../domain/ai/agent_run.dart';
import '../domain/ai/context_window.dart';
import '../domain/ai/model_gateway.dart';
import '../domain/chat/chat_question.dart';
import '../domain/settings/app_preferences.dart';
import '../domain/workspace/workspace_commands.dart';

/// A finite, interactive model/tool loop. Returns at confirmation boundaries.
/// Protocol messages are durable; text deltas are provisional and never receipts.
class AgentRunner {
  AgentRunner({
    required this.gateway,
    required this.store,
    required this.tools,
    this.maxRounds = 8,
    this.maxTokens = 4096,
    this.maxContextBytes = 1024 * 1024,
    this.contextWindow = const ContextWindow(),
    this.activeTimeout = const Duration(minutes: 2),
    this.maxCorrections = 0,
    this.onRoundStart,
  }) {
    if (maxRounds < 1 ||
        maxRounds > 32 ||
        maxCorrections < 0 ||
        maxCorrections > 4 ||
        maxTokens < 1 ||
        maxTokens > 32768 ||
        maxContextBytes < 1 ||
        activeTimeout <= Duration.zero) {
      throw const AgentFailure(AgentFailureCode.invalid);
    }
  }
  final ModelGateway gateway;
  final AgentRunStore store;
  final AgentToolExecutor tools;
  final int maxRounds;
  final int maxTokens;
  final int maxContextBytes;
  final ContextWindow contextWindow;
  final Duration activeTimeout;

  /// 一次运行里允许模型自行修正被拒绝的工具调用几次。
  ///
  /// 参数写错、版本过期这类问题，把原因作为工具结果还给模型，它通常下一轮
  /// 就能改对；直接判失败则要用户重说一遍。0 表示保持「一错即止」。
  final int maxCorrections;
  final void Function(int round)? onRoundStart;

  /// Explicit retry keeps the input and committed receipts. Failed proposals
  /// become tool errors so the model must plan again against current versions.
  Future<AgentRun> retry(
    String id, {
    required int expectedRevision,
    required String apiKey,
    ModelCancellation? cancellation,
    void Function(String)? onText,
  }) async {
    final run = await store.read(id);
    if (run.status != AgentRunStatus.failed ||
        run.revision != expectedRevision) {
      throw const AgentFailure(AgentFailureCode.conflict);
    }
    if (run.round >= maxRounds ||
        (run.failureCode?.endsWith('budget') == true ||
            run.failureCode == 'model_contextBudget')) {
      throw const AgentFailure(AgentFailureCode.budget);
    }
    final history = <JsonObject>[...run.history];
    if (run.proposal case final proposal?) {
      for (final call in (proposal['calls']! as List).cast<JsonObject>()) {
        history.add({
          'role': 'tool',
          'tool_call_id': call['tool_call_id'],
          'content': jsonEncode({
            'status': 'not_executed',
            'reason': run.failureCode,
          }),
        });
      }
    }
    final reopened = await store.save(
      run.next(
        AgentRunStatus.interrupted,
        history: history,
        clearProposal: true,
      ),
      expectedRevision: expectedRevision,
    );
    return _advance(
      reopened,
      apiKey: apiKey,
      cancellation: cancellation,
      onText: onText,
    );
  }

  Future<AgentRun> start(
    AgentRun initial, {
    required String apiKey,
    ModelCancellation? cancellation,
    void Function(String)? onText,
  }) async {
    final run = await store.create(initial);
    // Duplicate input never repeats a prior model request or business effect.
    if (run.status != AgentRunStatus.queued) return run;
    return _advance(
      run,
      apiKey: apiKey,
      cancellation: cancellation,
      onText: onText,
    );
  }

  /// Only explicit user interaction should invoke resume. Code profiles are not
  /// scheduled in the background. A live generating run cannot be stolen.
  Future<AgentRun> resume(
    String id, {
    required String apiKey,
    AgentApproval? approval,
    ModelCancellation? cancellation,
    void Function(String)? onText,
  }) async {
    final run = await store.read(id);
    if (run.isTerminal || run.status == AgentRunStatus.generating) return run;
    if (run.status == AgentRunStatus.awaitingConfirmation && approval == null) {
      return run;
    }
    return _advance(
      run,
      apiKey: apiKey,
      approval: approval,
      cancellation: cancellation,
      onText: onText,
    );
  }

  /// Cancels a persisted waiting run. Active calls use their cancellation signal.
  Future<AgentRun> cancelWaiting(String id) async {
    final run = await store.read(id);
    if (run.isTerminal) return run;
    if (run.status == AgentRunStatus.generating) {
      throw const AgentFailure(AgentFailureCode.conflict);
    }
    return store.save(
      run.next(AgentRunStatus.cancelled),
      expectedRevision: run.revision,
    );
  }

  Future<AgentRun> _advance(
    AgentRun initial, {
    required String apiKey,
    AgentApproval? approval,
    ModelCancellation? cancellation,
    void Function(String)? onText,
  }) async {
    var run = initial;
    JsonObject? observedUsage;
    var corrections = 0;
    final signal = cancellation ?? ModelCancellation();
    final watch = Stopwatch()..start();
    void checkBudget() {
      if (signal.isCancelled) {
        throw const ModelFailure(ModelFailureCode.cancelled);
      }
      if (watch.elapsed >= activeTimeout) {
        throw const ModelFailure(ModelFailureCode.timeout);
      }
    }

    try {
      while (true) {
        checkBudget();
        if (run.proposal != null) {
          final expectedRevision = run.revision + 1;
          run = await tools.execute(
            run,
            approval: approval,
            cancellation: signal,
          );
          approval = null;
          // An already acknowledged batch may belong to another live caller.
          // Return its snapshot instead of taking over its next model round.
          if (run.revision != expectedRevision) return run;
          if (run.status == AgentRunStatus.awaitingConfirmation ||
              run.isTerminal) {
            return run;
          }
          checkBudget();
        } else if (approval != null) {
          throw const AgentFailure(AgentFailureCode.conflict);
        }
        final lastUser = run.history.lastIndexWhere((m) => m['role'] == 'user');
        if (questionsFromHistory(run.history, lastUser).isNotEmpty) {
          if (run.status != AgentRunStatus.generating) {
            run = await store.save(
              run.next(AgentRunStatus.generating),
              expectedRevision: run.revision,
            );
          }
          return await store.save(
            run.next(AgentRunStatus.succeeded),
            expectedRevision: run.revision,
          );
        }
        if (run.round >= maxRounds ||
            utf8.encode(jsonEncode(run.history)).length > maxContextBytes) {
          throw const ModelFailure(ModelFailureCode.budget);
        }
        final selected = contextWindow.select(
          run.history,
          tools: tools.schemas,
          outputReserve: maxTokens,
          previouslyOmittedTurns: run.historyOmittedTurns,
        );
        run = await store.save(
          run.next(
            AgentRunStatus.generating,
            round: run.round + 1,
            requestOmittedTurns: selected.omittedTurns,
            estimatedInputTokens: selected.estimatedInputTokens,
          ),
          expectedRevision: run.revision,
        );
        checkBudget();
        onRoundStart?.call(run.round);
        final completion = await _collect(
          ModelRequest(
            profile: run.profile,
            messages: selected.messages,
            tools: tools.schemas,
            maxTokens: maxTokens,
          ),
          apiKey,
          signal,
          activeTimeout - watch.elapsed,
          onText,
        );
        observedUsage = {'round': run.round, 'usage': completion.usage};
        checkBudget();
        if (completion.finishReason == 'tool_calls') {
          try {
            run = await tools.propose(run, completion);
          } catch (error) {
            final feedback = corrections < maxCorrections
                ? await _correction(run, completion, error)
                : null;
            if (feedback == null) rethrow;
            corrections++;
            // 整批都没有执行。把拒绝原因记成工具结果，下一轮由模型改正。
            run = await store.save(
              run.next(
                AgentRunStatus.generating,
                history: [
                  ...run.history,
                  completion.assistantMessage,
                  ...feedback,
                ],
                usage: [
                  ...run.usage,
                  {'round': run.round, 'usage': completion.usage},
                ],
              ),
              expectedRevision: run.revision,
            );
          }
          observedUsage = null;
        } else {
          final returnedTools = completion.assistantMessage['tool_calls'];
          if (completion.finishReason != 'stop' ||
              completion.assistantMessage['role'] != 'assistant' ||
              (returnedTools != null &&
                  (returnedTools is! List || returnedTools.isNotEmpty)) ||
              completion.text.trim().isEmpty) {
            throw const ModelFailure(ModelFailureCode.protocol);
          }
          return await store.save(
            run.next(
              AgentRunStatus.succeeded,
              history: [...run.history, completion.assistantMessage],
              usage: [
                ...run.usage,
                {'round': run.round, 'usage': completion.usage},
              ],
            ),
            expectedRevision: run.revision,
          );
        }
      }
    } catch (error) {
      // CAS conflict belongs to another caller. Never turn its live run into a
      // failure, and never automatically repeat a commit after uncertain IO.
      if (error is AgentFailure &&
          (error.code == AgentFailureCode.conflict ||
              error.code == AgentFailureCode.storage)) {
        rethrow;
      }
      final code = switch (error) {
        ModelFailure failure => 'model_${failure.code.name}',
        AgentFailure failure => 'agent_${failure.code.name}',
        WorkspaceFailure failure => 'workspace_${failure.code.name}',
        PreferenceFailure _ => 'preferences_unavailable',
        AttachmentFailure failure => 'attachment_${failure.code.name}',
        _ => 'internal',
      };
      final cancelled =
          signal.isCancelled ||
          (error is ModelFailure && error.code == ModelFailureCode.cancelled) ||
          (error is AgentFailure && error.code == AgentFailureCode.cancelled);
      return store.save(
        run.next(
          cancelled ? AgentRunStatus.cancelled : AgentRunStatus.failed,
          failureCode: code,
          usage: observedUsage == null
              ? run.usage
              : [...run.usage, observedUsage],
        ),
        expectedRevision: run.revision,
      );
    } finally {
      watch.stop();
    }
  }

  /// 可由模型自行改正的拒绝才返回工具结果；其余情况返回 null，照旧判失败。
  ///
  /// 结果只含稳定错误码和固定提示，不回传参数原文或内部异常。带图片的
  /// 运行不走这条路：图片导入的范围限制必须一次到位，不给第二次机会。
  Future<List<JsonObject>?> _correction(
    AgentRun run,
    ModelCompleted completion,
    Object error,
  ) async {
    final code = switch (error) {
      AgentFailure(code: AgentFailureCode.invalid) => 'invalid_arguments',
      WorkspaceFailure(code: WorkspaceFailureCode.validation) =>
        'invalid_arguments',
      WorkspaceFailure(code: WorkspaceFailureCode.versionConflict) =>
        'version_conflict',
      WorkspaceFailure(code: WorkspaceFailureCode.notFound) => 'not_found',
      _ => null,
    };
    final message = completion.assistantMessage;
    final calls = message['tool_calls'];
    if (code == null ||
        message['role'] != 'assistant' ||
        calls is! List ||
        calls.isEmpty ||
        run.history.any((m) => m['_towork_attachment_id'] != null)) {
      return null;
    }
    final ids = <String>{};
    for (final call in calls) {
      final id = call is Map ? call['id'] : null;
      if (id is! String || id.isEmpty || !ids.add(id)) return null;
    }
    var problems = const <String, String>{};
    if (tools case final AgentToolDiagnostics diagnostics) {
      try {
        problems = await diagnostics.diagnose(run, completion);
      } catch (_) {
        // 诊断只是锦上添花；失败时退回批次级错误码。
      }
    }
    const hints = {
      'invalid_arguments':
          'Arguments do not match the tool schema or a business rule. Re-read '
          'the schema, fix this call and resend the whole batch.',
      'unknown_tool': 'No such tool. Use only the listed tools.',
      'version_conflict':
          'The record changed, was deleted, or the id/version is wrong. Query '
          'it again, then retry with the current id and version.',
      'not_found':
          'The record does not exist. Query before selecting a target.',
      'batch_conflict':
          'Each call is valid alone but the batch is not: one record is '
          'changed twice, or the combined result breaks a reference. Merge '
          'the changes into one call per record.',
      'batch_too_large':
          'Too many tool calls in one reply. Send at most 20 per batch and '
          'continue with the rest after the receipts arrive.',
      'batch_rejected':
          'Nothing in this batch ran because another call was rejected. Fix '
          'that call and resend this one unchanged.',
    };
    return [
      for (final id in ids)
        () {
          final problem =
              problems[id] ??
              (problems.isEmpty
                  ? (ids.length == 1 ? code : 'batch_conflict')
                  : 'batch_rejected');
          return <String, Object?>{
            'role': 'tool',
            'tool_call_id': id,
            'content': jsonEncode({
              'status': 'not_executed',
              'error': problem,
              'hint': hints[problem],
            }),
          };
        }(),
    ];
  }

  Future<ModelCompleted> _collect(
    ModelRequest request,
    String key,
    ModelCancellation signal,
    Duration remaining,
    void Function(String)? onText,
  ) async {
    if (key.trim().isEmpty) {
      throw const ModelFailure(ModelFailureCode.configuration);
    }
    final transportCancellation = ModelCancellation();
    final iterator = StreamIterator(
      gateway.stream(request, apiKey: key, cancellation: transportCancellation),
    );
    final cancelled = Completer<bool>();
    final detach = signal.onCancel(() {
      transportCancellation.cancel();
      if (!cancelled.isCompleted) {
        cancelled.completeError(const ModelFailure(ModelFailureCode.cancelled));
      }
    });
    final watch = Stopwatch()..start();
    ModelCompleted? completed;
    var bytes = 0;
    try {
      while (await Future.any([iterator.moveNext(), cancelled.future]).timeout(
        remaining - watch.elapsed,
        onTimeout: () => throw const ModelFailure(ModelFailureCode.timeout),
      )) {
        if (signal.isCancelled) {
          throw const ModelFailure(ModelFailureCode.cancelled);
        }
        if (completed != null) {
          throw const ModelFailure(ModelFailureCode.protocol);
        }
        switch (iterator.current) {
          case ModelTextDelta(:final text):
            bytes += utf8.encode(text).length;
            if (bytes > maxContextBytes) {
              throw const ModelFailure(ModelFailureCode.budget);
            }
            onText?.call(text);
          case final ModelCompleted event:
            if (utf8.encode(jsonEncode(event.assistantMessage)).length >
                maxContextBytes) {
              throw const ModelFailure(ModelFailureCode.budget);
            }
            completed = event;
        }
      }
      if (completed == null) {
        throw const ModelFailure(ModelFailureCode.truncated);
      }
      return completed;
    } finally {
      detach();
      transportCancellation.cancel();
      watch.stop();
      // The gateway owns its transport; cancellation closes a pending request.
      await iterator.cancel();
    }
  }
}
