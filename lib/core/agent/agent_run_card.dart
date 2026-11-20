import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/local_chat_runtime.dart';
import '../../agent/agent_tool_changes.dart';
import '../../app/providers.dart';
import '../widgets/app_toast.dart';
import '../widgets/ai_component_card.dart';
import 'agent_change_preview.dart';
import 'agent_run_summary.dart';
import '../widgets/reply_copy_button.dart';

export 'agent_change_preview.dart' show reminderRulesLabel;
import '../../domain/ai/agent_run.dart';
import '../../domain/ai/model_gateway.dart';
import '../../domain/settings/model_settings.dart';
import '../../domain/workspace/workspace_commands.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../app/chat/chat_view_model.dart';

String chatFailureMessage(Object? error) => switch (error) {
  SettingsFailure(code: SettingsFailureCode.missingKey) =>
    strings.saveAKimiApiKeyInModel,
  SettingsFailure(code: SettingsFailureCode.conflict) =>
    strings.modelSettingsChangedSendANewRequest,
  ModelFailure(code: ModelFailureCode.contextBudget) =>
    strings.inputIsTooLongShortenItOr,
  ModelFailure(code: ModelFailureCode.cancelled) => strings.requestStopped,
  AgentFailure(code: AgentFailureCode.budget) =>
    strings.theContextOrActionLimitHasBeen,
  AgentFailure(code: AgentFailureCode.conflict) =>
    strings.theChatOrRecordHasChangedFinish,
  WorkspaceFailure(code: WorkspaceFailureCode.versionConflict) =>
    strings.theRecordOrTableStructureHasSince,
  // 未知错误一律走稳定本地文案：原始异常可能携带 API Key、
  // 绝对路径或上游 JSON，不允许进入 UI（诊断仍走日志链路）。
  _ => strings.couldntCompleteTheActionYourDataIs,
};
String runFailureMessage(String? code) => switch (code) {
  'model_authentication' ||
  'model_forbidden' => strings.checkYourModelCredentialsAndAccessIn,
  'model_rateLimited' => strings.modelRateLimitReachedTryAgainLater,
  'model_quota' => strings.thisAccountIsOutOfQuotaSelect,
  'attachment_missing' => strings.theSourceImageIsUnavailableSelectIt,
  'attachment_storage' => strings.couldntReadTheSourceImageTryAgain,
  'model_configuration' => strings.modelSettingsChangedDuringTheRequestRetry,
  'model_contextBudget' => strings.inputOrToolResultsAreTooLong,
  'model_budget' ||
  'agent_budget' => strings.actionLimitReachedSendAnotherRequestOr,
  'workspace_versionConflict' ||
  'workspace_notFound' => strings.theTargetHasChangedYouCanReplan,
  'model_network' ||
  'model_timeout' => strings.connectionInterruptedOrModelTimedOutTry,
  'model_protocol' ||
  'model_truncated' ||
  'agent_invalid' => strings.theModelResponseFailedValidationThisBatch,
  // 同上：未知失败码不透传，避免内部码/上游报文片段上屏。
  _ => strings.requestIncompleteYouCanRetryCompletedActions,
};

class AgentRunCard extends ConsumerStatefulWidget {
  const AgentRunCard({
    super.key,
    required this.runId,
    this.replyText,
    this.hasResultCards = false,
  });
  final String runId;

  /// Non-null in a chat reply, whose text and result cards share this footer.
  final String? replyText;
  final bool hasResultCards;
  @override
  ConsumerState<AgentRunCard> createState() => _AgentRunCardState();
}

class _AgentRunCardState extends ConsumerState<AgentRunCard> {
  bool _busy = false;
  String? _selectionProposal;
  Set<String> _selected = {};
  Future<void> _perform(Future<void> Function(ChatViewModel) work) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await work(ref.read(chatViewModelProvider.notifier));
    } catch (error) {
      if (mounted) AppToast.show(context, message: chatFailureMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(sessionListProvider);
    final turn = ref
        .watch(localChatRuntimeProvider)
        ?.projection
        .turn(widget.runId);
    if (turn == null) return const SizedBox.shrink();
    final run = turn.run;
    final generation = ref.watch(chatViewModelProvider);
    final blocked = _busy || generation.isGenerating;
    final active = generation.isGenerating && generation.runId == run.id;
    final canCopy =
        !active &&
        run.status != AgentRunStatus.generating &&
        (widget.replyText?.isNotEmpty ?? false);
    final c = AppColors.of(context);
    final waiting = run.status == AgentRunStatus.awaitingConfirmation;
    final resumable = {
      AgentRunStatus.ready,
      AgentRunStatus.interrupted,
      AgentRunStatus.queued,
    }.contains(run.status);
    final failed = run.status == AgentRunStatus.failed;
    final calls = ((run.proposal?['calls'] as List?) ?? []).cast<JsonObject>();
    final changes = calls.where(AgentToolChanges.isWrite).toList();
    final selectionProposal =
        '${run.id}/${run.revision}/${run.proposal?['digest']}';
    if (_selectionProposal != selectionProposal) {
      _selectionProposal = selectionProposal;
      _selected = changes.map((c) => c['tool_call_id']! as String).toSet();
    }
    final label = turn.undoneAt != null
        ? context.strings.changesUndone
        : switch (run.status) {
            AgentRunStatus.awaitingConfirmation =>
              context.strings.awaitingConfirmation(changes.length),
            AgentRunStatus.ready ||
            AgentRunStatus.queued ||
            AgentRunStatus.interrupted =>
              context.strings.requestSavedReadyToContinue,
            AgentRunStatus.generating => context.strings.working,
            AgentRunStatus.succeeded =>
              run.receipts.isEmpty
                  ? context.strings.replySaved
                  : context.strings.actionBatchesSubmitted(run.receipts.length),
            AgentRunStatus.failed => runFailureMessage(run.failureCode),
            AgentRunStatus.cancelled => context.strings.requestStoppedBuild,
          };
    if (widget.replyText != null && active) {
      return const SizedBox.shrink();
    }
    if (!canCopy &&
        run.status == AgentRunStatus.succeeded &&
        run.receipts.isEmpty &&
        run.contextOmittedTurns == 0 &&
        turn.undoneAt == null) {
      return const SizedBox.shrink();
    }
    // 无需交互的终态（成功/已停止/已撤销）退化为紧凑状态行：
    // 内容卡由待办/数据消息承担，这里只标记任务过程状态。
    if (!waiting && !resumable && !failed) {
      return AgentRunSummary(
        key: ValueKey('quiet-run-${run.id}'),
        label:
            widget.replyText != null &&
                turn.undoneAt == null &&
                run.status == AgentRunStatus.succeeded &&
                (widget.hasResultCards || run.receipts.isEmpty)
            ? ''
            : label,
        replyText: canCopy ? widget.replyText : null,
        compactActions: widget.replyText != null,
        undoEnabled: !blocked,
        processing: run.status == AgentRunStatus.generating,
        icon: turn.undoneAt != null
            ? LucideIcons.undo2
            : run.status == AgentRunStatus.cancelled
            ? LucideIcons.square
            : LucideIcons.check,
        note: run.status == AgentRunStatus.cancelled && run.receipts.isNotEmpty
            ? context.strings.completedActionBatchesRetained(
                run.receipts.length,
              )
            : run.contextOmittedTurns > 0
            ? context.strings.earlierTurnsOutsideThisRequestFullHistory(
                run.contextOmittedTurns,
              )
            : null,
        onUndo:
            turn.undoneAt == null && run.isTerminal && run.receipts.isNotEmpty
            ? () => _perform((vm) => vm.undoRun(run.id))
            : null,
      );
    }
    return AiComponentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: c.labelPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (run.contextOmittedTurns > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                context.strings
                    .earlierTurnsOutsideThisRequestFullHistoryIsAvailable(
                      run.contextOmittedTurns,
                    ),
                style: AppTextStyles.footnote.copyWith(color: c.labelSecondary),
              ),
            ),
          if ((failed || waiting || run.status == AgentRunStatus.cancelled) &&
              run.receipts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                context.strings.completedActionBatchesRetained(
                  run.receipts.length,
                ),
                style: AppTextStyles.footnote.copyWith(color: c.labelSecondary),
              ),
            ),
          if (waiting || resumable && changes.isNotEmpty) ...[
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final change in changes)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (waiting)
                            Checkbox(
                              key: ValueKey(
                                'agent-select-${change['tool_call_id']}',
                              ),
                              semanticLabel: context.strings.selectLabel(
                                '${(change['business_table'] as Map?)?['name'] ?? (change['after'] as Map?)?['name'] ?? (change['after'] as Map?)?['title'] ?? (change['before'] as Map?)?['data']?['title'] ?? context.strings.actions}',
                              ),
                              value: _selected.contains(change['tool_call_id']),
                              onChanged: blocked
                                  ? null
                                  : (checked) => setState(() {
                                      final id =
                                          change['tool_call_id']! as String;
                                      checked == true
                                          ? _selected.add(id)
                                          : _selected.remove(id);
                                    }),
                            ),
                          Expanded(child: AgentChangePreview(change: change)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
          if (canCopy ||
              waiting ||
              resumable ||
              failed && turn.undoneAt == null ||
              run.receipts.isNotEmpty &&
                  run.isTerminal &&
                  turn.undoneAt == null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (canCopy) ReplyCopyButton(text: widget.replyText!),
                  if (waiting)
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        textStyle: AppTextStyles.footnote,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: blocked || _selected.isEmpty
                          ? null
                          : () => _perform(
                              (vm) => vm.resumeRun(
                                run.id,
                                approval: AgentApproval(
                                  runRevision: run.revision,
                                  proposalId: run.proposal!['id']! as String,
                                  digest: run.proposal!['digest']! as String,
                                  selectedToolCallIds: _selected.toList(),
                                ),
                              ),
                            ),
                      child: Text(
                        _selected.length == changes.length
                            ? context.strings.acceptAll
                            : context.strings.acceptSelected(_selected.length),
                      ),
                    ),
                  if (waiting)
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: AppTextStyles.footnote,
                      ),
                      onPressed: blocked || _selected.isEmpty
                          ? null
                          : () => _perform(
                              (vm) => vm.resumeRun(
                                run.id,
                                approval: AgentApproval(
                                  runRevision: run.revision,
                                  proposalId: run.proposal!['id']! as String,
                                  digest: run.proposal!['digest']! as String,
                                  selectedToolCallIds: _selected.toList(),
                                  reject: true,
                                ),
                              ),
                            ),
                      child: Text(
                        context.strings.rejectSelected(_selected.length),
                      ),
                    ),
                  if ((waiting ||
                          failed &&
                              {
                                'workspace_versionConflict',
                                'workspace_notFound',
                              }.contains(run.failureCode)) &&
                      changes.isNotEmpty &&
                      calls.every(
                        (call) =>
                            call['business_intent'] != null ||
                            call['table_intent'] != null ||
                            call['intent_patch'] != null ||
                            call['recurrence_intent'] != null,
                      ))
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: AppTextStyles.footnote,
                      ),
                      onPressed: blocked
                          ? null
                          : () =>
                                _perform((vm) => vm.refreshRunProposal(run.id)),
                      child: Text(context.strings.refreshChanges),
                    ),
                  if (resumable)
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        textStyle: AppTextStyles.footnote,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: blocked
                          ? null
                          : () => _perform((vm) => vm.resumeRun(run.id)),
                      child: Text(context.strings.continueLabel),
                    ),
                  if (waiting || resumable)
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: AppTextStyles.footnote,
                      ),
                      onPressed: blocked
                          ? null
                          : () => _perform((vm) => vm.cancelRun(run.id)),
                      child: Text(context.strings.cancelRequest),
                    ),
                  if (failed &&
                      turn.undoneAt == null &&
                      !{
                        'model_contextBudget',
                        'model_budget',
                        'agent_budget',
                      }.contains(run.failureCode))
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: AppTextStyles.footnote,
                      ),
                      onPressed: blocked
                          ? null
                          : () => _perform(
                              (vm) => vm.resumeRun(run.id, retry: true),
                            ),
                      child: Text(context.strings.retry),
                    ),
                  if (run.receipts.isNotEmpty &&
                      run.isTerminal &&
                      turn.undoneAt == null)
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: AppTextStyles.footnote,
                      ),
                      onPressed: blocked
                          ? null
                          : () => _perform((vm) => vm.undoRun(run.id)),
                      child: Text(
                        run.receipts.length == 1
                            ? context.strings.undoThisBatch
                            : context.strings.undoAllChangesInThisRequest,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
