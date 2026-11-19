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
    '请先在模型连接中保存 Kimi API Key，再发送。',
  SettingsFailure(code: SettingsFailureCode.conflict) =>
    '模型配置已改变，请发送新请求；已完成的操作会保留。',
  ModelFailure(code: ModelFailureCode.contextBudget) =>
    '这次内容过长，请缩短输入或拆分请求；原有历史已保留。',
  ModelFailure(code: ModelFailureCode.cancelled) => '已停止本次请求。',
  AgentFailure(code: AgentFailureCode.budget) => '本次上下文或执行轮数已达上限，请新建会话。',
  AgentFailure(code: AgentFailureCode.conflict) =>
    '会话或记录已变化，请先处理未完成的请求或重新打开会话。',
  WorkspaceFailure(code: WorkspaceFailureCode.versionConflict) =>
    '记录或表结构已有后续修改，不能覆盖。',
  // 未知错误一律走稳定本地文案：原始异常可能携带 API Key、
  // 绝对路径或上游 JSON，不允许进入 UI（诊断仍走日志链路）。
  _ => '暂时无法完成操作，原有数据已保留，请重试。',
};
String runFailureMessage(String? code) => switch (code) {
  'model_authentication' || 'model_forbidden' => '模型凭据或访问权限不可用，请检查模型连接。',
  'model_rateLimited' => '模型请求受限，请稍后重试。',
  'model_quota' => '这个账户的额度已用尽，可以换一个模型后重试。',
  'attachment_missing' => '来源图片已不可用，请返回截图导入重新选择图片。',
  'attachment_storage' => '暂时无法读取来源图片，请稍后重试。',
  'model_configuration' => '模型配置在处理过程中发生了变化，可以用当前模型重试。',
  'model_contextBudget' => '本次内容或工具结果过长，请拆分请求；已完成操作仍保留。',
  'model_budget' || 'agent_budget' => '本次执行已达上限，请发送新请求或新建会话。',
  'workspace_versionConflict' || 'workspace_notFound' => '目标已经变化，可重新规划。',
  'model_network' || 'model_timeout' => '网络中断或模型响应超时，可以重试。',
  'model_protocol' ||
  'model_truncated' ||
  'agent_invalid' => '模型返回未通过校验，未执行该批修改。',
  // 同上：未知失败码不透传，避免内部码/上游报文片段上屏。
  _ => '请求未完成，可以重试；已完成的操作会保留。',
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
        ? '已撤销本次修改'
        : switch (run.status) {
            AgentRunStatus.awaitingConfirmation => '待确认 ${changes.length} 项',
            AgentRunStatus.ready ||
            AgentRunStatus.queued ||
            AgentRunStatus.interrupted => '请求已保存，等待继续',
            AgentRunStatus.generating => '正在处理',
            AgentRunStatus.succeeded =>
              run.receipts.isEmpty ? '回复已保存' : '已提交 ${run.receipts.length} 批操作',
            AgentRunStatus.failed => runFailureMessage(run.failureCode),
            AgentRunStatus.cancelled => '已停止本次请求',
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
            ? '已完成的 ${run.receipts.length} 批操作仍保留。'
            : run.contextOmittedTurns > 0
            ? '本次未带入较早的 ${run.contextOmittedTurns} 轮对话，完整历史仍可查看。'
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
                '本次未带入较早的 ${run.contextOmittedTurns} 轮对话，完整历史仍可查看。涉及旧内容时请补充说明。',
                style: AppTextStyles.footnote.copyWith(color: c.labelSecondary),
              ),
            ),
          if ((failed || waiting || run.status == AgentRunStatus.cancelled) &&
              run.receipts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '已完成的 ${run.receipts.length} 批操作仍保留。',
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
                              semanticLabel:
                                  '选择${(change['business_table'] as Map?)?['name'] ?? (change['after'] as Map?)?['name'] ?? (change['after'] as Map?)?['title'] ?? (change['before'] as Map?)?['data']?['title'] ?? '操作'}',
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
                            ? '全部接受'
                            : '接受选中（${_selected.length}）',
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
                      child: Text('拒绝选中（${_selected.length}）'),
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
                      child: const Text('刷新差异'),
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
                      child: const Text('继续处理'),
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
                      child: const Text('取消本次'),
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
                      child: const Text('重试'),
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
                        run.receipts.length == 1 ? '撤销本批修改' : '撤销本次全部修改',
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
