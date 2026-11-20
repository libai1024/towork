import 'package:towork/l10n/strings.dart';

import 'dart:async';

import '../local_chat_runtime.dart';
import '../local_workspace_session.dart';
import '../../domain/ai/agent_run.dart';
import '../../domain/ai/model_gateway.dart';
import '../../domain/ai/model_router.dart';
import '../../domain/chat/local_chat.dart';
import '../../domain/repositories/chat_gateway.dart';
import '../../domain/models/chat_reply.dart';
import '../../domain/settings/model_settings.dart';
import '../../domain/workspace/workspace_commands.dart';
import 'chat_view_model.dart';

class LiveChatViewModel extends ChatViewModel {
  LiveChatViewModel({
    required this.runtime,
    this.localWorkspace,
    this.autoRoute,
    required super.todos,
    required super.currentSession,
    required void Function(String?) super.selectSession,
  }) : _current = currentSession,
       _select = selectSession,
       super(chats: runtime.projection, gateway: _UnusedGateway()) {
    _configuration = runtime.configurations.listen((config) {
      if (_activeVersion != null && config.version != _activeVersion) cancel();
    }, onError: (Object _) => cancel());
  }
  final LocalChatRuntime runtime;
  final LocalWorkspaceSession? localWorkspace;

  /// 用户是否选了「自动」模型。为空或返回 false 时绝不自动换账户。
  final bool Function()? autoRoute;
  bool get _auto => autoRoute?.call() ?? false;

  /// 自动模式下按优先级选一个可用账户；没有候选时退回当前配置，
  /// 让真实的失败原因照常暴露。
  Future<ModelRuntimeCredential> _acquire({required bool needsVision}) async {
    if (_auto) {
      final routed = await runtime.accounts.route(needsVision: needsVision);
      if (routed != null) return routed.credential;
    }
    return runtime.settings.runtimeCredential();
  }

  Future<T> _foreground<T>(Future<T> Function() action) =>
      localWorkspace?.foreground(action) ?? action();
  final String? Function() _current;
  final void Function(String?) _select;
  StreamSubscription<ModelConfiguration>? _configuration;
  ModelCancellation? _signal;
  Future<void>? _operation;
  int? _activeVersion;
  String? _activeRun;
  bool _selecting = false;
  String? _pendingInput, _pendingText, _pendingSession;

  @override
  bool send(String input, {required String model, bool agentEnabled = true}) =>
      throw StateError('Use sendPersisted for asynchronous chat');

  @override
  Future<bool> sendPersisted(
    String input, {
    required String model,
    bool agentEnabled = true,
    String? inputId,
    String? attachmentId,
    String? replyToInputId,
    bool fromVoice = false,
  }) async {
    final text = input.trim();
    if (!mounted || state.isGenerating || text.isEmpty) return false;
    final originalSession = _current();
    final signal = ModelCancellation();
    _signal = signal;
    state = ChatGenerationState(
      isGenerating: true,
      sessionId: originalSession,
      isSavingInput: true,
    );
    var accepted = false;
    try {
      final credential = await _acquire(needsVision: attachmentId != null);
      _activeVersion = credential.configuration.version;
      if (signal.isCancelled) {
        throw const ModelFailure(ModelFailureCode.cancelled);
      }
      if (_pendingInput == null ||
          (inputId != null && _pendingInput != inputId) ||
          _pendingText != text ||
          _pendingSession != originalSession) {
        _pendingInput = inputId ?? newWorkspaceId('message');
        _pendingText = text;
        _pendingSession = originalSession;
      }
      final turn = await runtime.persistence.prepare(
        inputId: _pendingInput!,
        content: text,
        profile: credential.configuration.profile,
        agentEnabled: agentEnabled,
        sessionId: originalSession,
        attachmentId: attachmentId,
        replyToInputId: replyToInputId,
        voice: fromVoice,
      );
      accepted = true;
      _pendingInput = null;
      await runtime.refresh();
      if (mounted && !signal.isCancelled && _current() == originalSession) {
        _selecting = true;
        try {
          _select(turn.sessionId);
        } finally {
          _selecting = false;
        }
      }
      if (!mounted) {
        signal.cancel();
      }
      _launch(turn, credential, signal);
      return true;
    } catch (error) {
      _signal = null;
      _activeVersion = null;
      if (mounted) {
        state = ChatGenerationState(error: error, sessionId: originalSession);
      }
      // An acknowledged commit may clear the draft even if its projection failed.
      // Before acknowledgement the cached input ID remains available for retry.
      return accepted;
    }
  }

  void _launch(
    LocalChatTurn turn,
    ModelRuntimeCredential credential,
    ModelCancellation signal, {
    AgentApproval? approval,
    bool retry = false,
  }) {
    _activeRun = turn.run.id;
    _operation = _foreground(
      () => _drive(turn, credential, signal, approval: approval, retry: retry),
    );
  }

  Future<void> _drive(
    LocalChatTurn turn,
    ModelRuntimeCredential credential,
    ModelCancellation signal, {
    AgentApproval? approval,
    bool retry = false,
  }) async {
    var streaming = '';
    String? notice;
    void publish() {
      if (mounted && identical(_signal, signal)) {
        state = ChatGenerationState(
          isGenerating: true,
          sessionId: turn.sessionId,
          runId: turn.run.id,
          messageId: 'stream_${turn.run.id}',
          streamingText: streaming,
          notice: notice,
        );
      }
    }

    final runner = runtime.runner(
      turn.agentEnabled,
      onRoundStart: (_) {
        streaming = '';
        publish();
      },
    );
    void onText(String delta) {
      streaming += delta;
      publish();
    }

    Object? error;
    try {
      publish();
      var key = credential.secret;
      var revision = turn.run.revision;
      var retrying = retry;
      final tried = <String>{};
      while (true) {
        final AgentRun ended;
        if (retrying) {
          ended = await runner.retry(
            turn.run.id,
            expectedRevision: revision,
            apiKey: key,
            cancellation: signal,
            onText: onText,
          );
        } else {
          ended = await runner.resume(
            turn.run.id,
            apiKey: key,
            approval: approval,
            cancellation: signal,
            onText: onText,
          );
        }
        // 自动模式下，额度用尽、限流、Key 失效这类失败换下一个账户重试。
        // 每个账户本轮最多试一次；没有候选就把真实失败留给用户。
        final next = await _failover(ended, signal, tried);
        if (next == null) break;
        notice = next.notice;
        key = next.credential.secret;
        revision = next.run.revision;
        retrying = true;
        streaming = '';
        publish();
      }
    } catch (failure) {
      error = failure;
    } finally {
      try {
        await runtime.refresh();
      } catch (failure) {
        error ??= failure;
      }
      if (identical(_signal, signal)) {
        _signal = null;
        _activeVersion = null;
        _activeRun = null;
        if (mounted) {
          state = ChatGenerationState(
            error: error,
            sessionId: turn.sessionId,
            notice: notice,
          );
        }
      }
    }
  }

  /// 判断一次失败是否该换账户；该换则冷却失败账户、切到下一个并改绑运行。
  Future<_Failover?> _failover(
    AgentRun ended,
    ModelCancellation signal,
    Set<String> tried,
  ) async {
    if (!_auto || signal.isCancelled || ended.status != AgentRunStatus.failed) {
      return null;
    }
    final advice = ModelRouter.adviceForRunFailure(ended.failureCode);
    if (advice == null) return null;
    final before = await runtime.accounts.load();
    final failed = before.active;
    if (failed != null) {
      tried.add(failed.id);
      await runtime.accounts.penalize(failed.id, advice);
    }
    // 接下来的切换是自己发起的，不应被「配置变化即取消」误伤。
    _activeVersion = null;
    final routed = await runtime.accounts.route(
      needsVision: ended.history.any(
        (message) => message['_towork_attachment_id'] != null,
      ),
      exclude: tried,
    );
    if (routed == null || signal.isCancelled) return null;
    final rebound = await runtime.rebind(
      ended,
      routed.credential.configuration.profile,
    );
    _activeVersion = routed.credential.configuration.version;
    final from = failed == null
        ? strings.currentModel
        : ProviderCatalog.modelLabel(
            failed.profile.model,
            kind: failed.profile.product,
          );
    final to = ProviderCatalog.modelLabel(
      routed.account.profile.model,
      kind: routed.account.profile.product,
    );
    return _Failover(
      rebound,
      routed.credential,
      strings.switchedTo(from, advice.reason, to),
    );
  }

  @override
  Future<void> resumeRun(
    String id, {
    AgentApproval? approval,
    bool retry = false,
  }) async {
    if (!mounted || state.isGenerating) return;
    final signal = ModelCancellation();
    _signal = signal;
    state = ChatGenerationState(
      isGenerating: true,
      sessionId: _current(),
      runId: id,
    );
    try {
      await runtime.refresh();
      var turn = runtime.projection.turn(id);
      if (turn == null ||
          runtime.projection.sessionById(turn.sessionId) == null) {
        throw const AgentFailure(AgentFailureCode.conflict);
      }
      if (retry && turn.undoneAt != null) {
        throw const AgentFailure(AgentFailureCode.conflict);
      }
      final ModelRuntimeCredential credential;
      if (retry && turn.run.status == AgentRunStatus.failed) {
        // 重试用的是「现在选中的模型」：失败后换了模型或账户，把这次运行
        // 改绑过去再继续，不必重新输入。
        credential = await _acquire(
          needsVision: turn.run.history.any(
            (message) => message['_towork_attachment_id'] != null,
          ),
        );
        if (credential.configuration.version != turn.run.profile.revision) {
          await runtime.rebind(turn.run, credential.configuration.profile);
          await runtime.refresh();
          turn = runtime.projection.turn(id)!;
        }
      } else {
        credential = await runtime.settings.runtimeCredential(
          expectedVersion: turn.run.profile.revision,
        );
      }
      _activeVersion = credential.configuration.version;
      _launch(turn, credential, signal, approval: approval, retry: retry);
      await _operation;
    } catch (error) {
      _signal = null;
      _activeVersion = null;
      if (mounted) {
        state = ChatGenerationState(
          error: error,
          sessionId: _current(),
          runId: id,
        );
      }
    }
  }

  @override
  void cancel() {
    if (_selecting) return;
    _signal?.cancel();
  }

  @override
  Future<void> cancelRun(String id) async {
    if (_activeRun == id) {
      cancel();
      await _operation;
    }
    final run = await runtime.runs.read(id);
    if (!run.isTerminal) await runtime.runner(true).cancelWaiting(id);
    await runtime.refresh();
  }

  @override
  bool retry() {
    if (state.isGenerating) return false;
    final turns =
        runtime.projection.data.turns
            .where((t) => t.sessionId == _current())
            .toList()
          ..sort((a, b) => a.position.compareTo(b.position));
    final last = turns.lastOrNull;
    if (last?.run.status != AgentRunStatus.failed) return false;
    unawaited(resumeRun(last!.run.id, retry: true));
    return true;
  }

  @override
  Future<void> renameSessionPersisted(String id, String title) async {
    final conversation = runtime.projection.conversation(id);
    if (conversation == null) {
      throw const AgentFailure(AgentFailureCode.conflict);
    }
    await runtime.persistence.rename(
      id,
      title,
      expectedRevision: conversation.revision,
    );
    await runtime.refresh();
  }

  @override
  Future<void> deleteSessionPersisted(String id) async {
    if (_activeRun != null && state.sessionId == id) {
      cancel();
      await _operation;
    }
    await runtime.refresh();
    for (final turn in runtime.projection.data.turns.where(
      (t) => t.sessionId == id && !t.run.isTerminal,
    )) {
      await runtime.runner(true).cancelWaiting(turn.run.id);
    }
    final conversation = runtime.projection.conversation(id);
    if (conversation == null) {
      throw const AgentFailure(AgentFailureCode.conflict);
    }
    await runtime.persistence.delete(
      id,
      expectedRevision: conversation.revision,
    );
    await runtime.refresh();
    if (mounted && _current() == id) _select(null);
  }

  @override
  Future<void> undoRun(String id) async {
    await _foreground(() async {
      await runtime.persistence.undo(id);
      await runtime.refresh();
    });
  }

  @override
  Future<void> refreshRunProposal(String id) async {
    if (state.isGenerating) throw const AgentFailure(AgentFailureCode.conflict);
    final turn = runtime.projection.turn(id);
    if (turn == null || turn.undoneAt != null) {
      throw const AgentFailure(AgentFailureCode.conflict);
    }
    await _foreground(() async {
      await runtime.refreshProposal(id, expectedRevision: turn.run.revision);
      await runtime.refresh();
    });
  }

  @override
  void dispose() {
    _signal?.cancel();
    unawaited(_configuration?.cancel());
    super.dispose();
  }
}

class _Failover {
  const _Failover(this.run, this.credential, this.notice);
  final AgentRun run;
  final ModelRuntimeCredential credential;
  final String notice;
}

class _UnusedGateway implements ChatGateway {
  @override
  Future<ChatReply> respond(String input) =>
      throw StateError('Production uses AgentRunner');
}
