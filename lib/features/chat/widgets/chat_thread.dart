import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/local_chat_runtime.dart';
import '../../../app/providers.dart';
import '../../../app/todo/async_todo_commands.dart';
import '../../../app/workspace_state.dart';
import '../../../core/workspace_actions.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../domain/models/models.dart';
import '../../../domain/chat/chat_question.dart';
import '../../../core/widgets/reply_copy_button.dart';
import '../../../domain/ai/agent_run.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../chat_message_layout.dart';
import '../chat_actions.dart';
import '../../../app/chat/chat_view_model.dart';
import '../../../core/agent/agent_run_card.dart';
import 'chat_messages.dart';
import 'chat_todo_edit_sheet.dart';
import '../../../core/todo/todo_detail_sheet.dart';
import '../../../core/todo/todo_step_actions.dart';
import 'ai_todo_panel.dart';
import 'ai_question_card.dart';
import 'chat_auto_scroll.dart';

/// 一个会话的消息流：用户与助手消息、流式回复、运行卡和新建的待办卡。
class ChatThread extends ConsumerStatefulWidget {
  const ChatThread({
    super.key,
    required this.sessionId,
    required this.controller,
    this.horizontalPadding = 20,
    this.bottomPadding = 12,
    this.topPadding = 12,
    this.onContentAdded,
  });

  final String sessionId;
  final ScrollController controller;
  final double horizontalPadding;
  final double bottomPadding;
  final double topPadding;

  /// 恢复待办等让内容变长的操作完成后调用，宿主据此滚到底部。
  final VoidCallback? onContentAdded;

  @override
  ConsumerState<ChatThread> createState() => _ChatThreadState();
}

class _ChatThreadState extends ConsumerState<ChatThread> {
  final Set<String> _presentedCards = {};
  bool _loadedHistory = false;

  @override
  void didUpdateWidget(ChatThread oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId) {
      _loadedHistory = false;
      _presentedCards.clear();
    }
  }

  void _scrollToBottom() => widget.onContentAdded?.call();

  Future<void> _undoTodo(ChatMessage cardMessage, Todo todo) async {
    final controller = ref.read(chatViewModelProvider.notifier);
    final ChatTodoUndo undo;
    try {
      undo = await controller.undoTodoPersisted(cardMessage, todo);
      if (!mounted) return;
    } catch (error) {
      if (mounted) {
        AppToast.show(context, message: workspaceErrorMessage(error));
      }
      return;
    }
    HapticFeedback.mediumImpact();
    AppToast.show(
      context,
      message: '已撤销这条待办',
      actionLabel: '恢复',
      onAction: () async {
        try {
          final result = await controller.restoreTodoPersisted(undo);
          if (!mounted) return;
          if (result == ChatTodoRestoreResult.restored) {
            _scrollToBottom();
          } else {
            AppToast.show(context, message: '内容已变化，无法恢复这条待办');
          }
        } catch (error) {
          if (mounted) {
            AppToast.show(context, message: workspaceErrorMessage(error));
          }
        }
      },
    );
  }

  Future<void> _toggleDone(Todo todo) async {
    if (!await confirmRemainingSteps(context, [todo]) || !mounted) return;
    final mutation = await ref
        .read(asyncTodoCommandsProvider)
        .toggleDone(todo.id);
    if (!mounted || mutation.count == 0) return;
    final completed = todo.status != TodoStatus.done;
    AppToast.show(
      context,
      message: completed ? '已完成 ${todo.title}' : '已恢复为待办',
      completion: completed,
      actionLabel: '撤销',
      onAction: () => workspaceUi(context, () async {
        await mutation.undo();
        return true;
      }),
    );
  }

  void _editTodo(Todo todo) {
    if (todo.steps.isNotEmpty) {
      _detail(todo);
      return;
    }
    AppSheet.show<void>(
      context,
      title: '修改待办',
      child: ChatTodoEditSheet(
        todo: todo,
        onSteps: () {
          Navigator.of(context).pop();
          _detail(todo);
        },
        categories: ref.read(categoryListProvider),
        onSave: (updated) async {
          final saved = await workspaceUi(context, () async {
            await ref.read(workspaceUiCommandsProvider).updateTodo(updated);
            return true;
          });
          if (!mounted || saved != true) return;
          Navigator.of(context).pop();
          AppToast.show(context, message: '已修改');
        },
      ),
    );
  }

  void _detail(Todo todo) => showTodoDetailSheet(
    context,
    todo.id,
    onDeleted: (deleted) async {
      await workspaceUi(
        context,
        () => ref.read(asyncTodoCommandsProvider).delete([deleted.id]),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final generation = ref.watch(chatViewModelProvider);
    // 消息、待办、分类任一变化都要重排；不依赖宿主页面恰好重建。
    ref.watch(sessionListProvider);
    final repo = ref.watch(sessionListProvider.notifier);
    ref.watch(todoListProvider);
    ref.watch(categoryListProvider);
    final messages = [...repo.messagesOf(widget.sessionId)];
    final activeRun = ref
        .watch(localChatRuntimeProvider)
        ?.projection
        .turn(generation.runId ?? '')
        ?.run;
    if (activeRun?.status == AgentRunStatus.generating &&
        generation.isGenerating &&
        generation.sessionId == widget.sessionId &&
        generation.runId != null &&
        generation.messageId != null) {
      final runIndex = messages.indexWhere(
        (message) =>
            message.type == ChatMessageType.agentRun &&
            message.runId == generation.runId,
      );
      messages.insert(
        runIndex < 0 ? messages.length : runIndex,
        ChatMessage(
          id: generation.messageId!,
          sessionId: widget.sessionId,
          role: ChatRole.assistant,
          type: ChatMessageType.text,
          content: generation.streamingText,
          createdAt: runIndex < 0
              ? DateTime.now()
              : messages[runIndex].createdAt,
          modelId: ref.read(chatModelProvider),
          runId: generation.runId,
        ),
      );
    }
    // Result cards belong to the reply body. Its run controls follow them once.
    final expanded = <ChatMessage>[];
    final runsWithCards = {
      for (final message in messages)
        if (message.todoPanel != null && message.runId != null) message.runId!,
    };
    for (final msg in messages) {
      if (msg.type == ChatMessageType.agentRun && msg.runId != null) {
        final cards = _todoResultCards(msg).toList();
        if (cards.isNotEmpty) runsWithCards.add(msg.runId!);
        expanded.addAll(cards);
      }
      expanded.add(msg);
    }
    if (!_loadedHistory) {
      _presentedCards.addAll(expanded.map((message) => message.id));
      _loadedHistory = true;
    }
    final todos = ref.read(todoListProvider.notifier);
    final rows = layoutChatMessages(
      expanded,
      todoExists: (id) => todos.byId(id) != null,
    );
    return ChatAutoScroll(
      bottomInset: widget.bottomPadding,
      controller: widget.controller,
      sessionId: widget.sessionId,
      latestUserId: messages
          .where((m) => m.role == ChatRole.user)
          .lastOrNull
          ?.id,
      child: ListView.builder(
        key: const ValueKey('chat-message-list'),
        controller: widget.controller,
        padding: EdgeInsets.fromLTRB(
          widget.horizontalPadding,
          widget.topPadding,
          widget.horizontalPadding,
          widget.bottomPadding,
        ),
        itemCount: rows.length,
        findChildIndexCallback: (key) {
          final index = rows.indexWhere(
            (row) => ValueKey(row.message.id) == key,
          );
          return index < 0 ? null : index;
        },
        itemBuilder: (context, index) {
          final row = rows[index];
          final msg = row.message;
          return Column(
            key: ValueKey(msg.id),
            children: [
              if (row.showDate)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                  child: Text(
                    _dateLabel(msg.createdAt),
                    style: AppTextStyles.caption.copyWith(
                      color: c.labelTertiary,
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(
                  top: row.followsReply ? 0 : 6,
                  bottom: row.continuesReply ? 6 : 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMessage(
                      msg,
                      replyText: row.replyText,
                      hasResultCards: runsWithCards.contains(msg.runId),
                    ),
                    if (row.replyText != null &&
                        row.replyText!.isNotEmpty &&
                        msg.type != ChatMessageType.agentRun &&
                        msg.id != generation.messageId)
                      Row(
                        children: [
                          ReplyCopyButton(text: row.replyText!),
                          if (row.stopped)
                            Text(
                              '已停止',
                              style: AppTextStyles.caption.copyWith(
                                color: c.labelSecondary,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 把某次运行中成功创建或完成的待办映射成内容卡消息。
  /// id 来自投影自带的操作回执（workspace_operations）；此处按待办
  /// 仍存在过滤（被删除/撤销后卡片自动消失）。
  Iterable<ChatMessage> _todoResultCards(ChatMessage runMsg) {
    final runtime = ref.read(localChatRuntimeProvider);
    final turn = runtime?.projection.turn(runMsg.runId!);
    if (runtime == null || turn == null || turn.undoneAt != null) {
      return const [];
    }
    final todos = ref.read(todoListProvider.notifier);
    final displayed = <String>{
      for (final message in turn.messages)
        ...?message.todoPanel?.sections.expand((section) => section.todoIds),
    };
    final cards = <ChatMessage>[];
    for (final id in {...turn.createdTodoIds, ...turn.completedTodoIds}) {
      final todo = todos.byId(id);
      if (todo == null || displayed.contains(id)) continue;
      cards.add(
        ChatMessage(
          id: 'todocard_${runMsg.runId}_$id',
          sessionId: runMsg.sessionId,
          role: ChatRole.assistant,
          type: ChatMessageType.todoCard,
          content: '',
          createdAt: runMsg.createdAt,
          todoId: todo.id,
          runId: runMsg.runId,
        ),
      );
    }
    return cards;
  }

  Widget _buildMessage(
    ChatMessage msg, {
    String? replyText,
    bool hasResultCards = false,
  }) {
    if (msg.role == ChatRole.user) return UserBubble(message: msg);
    switch (msg.type) {
      case ChatMessageType.todoCard:
        final todo = ref.watch(todoListProvider.notifier).byId(msg.todoId);
        if (todo == null) return const SizedBox.shrink();
        final category = ref
            .watch(categoryListProvider.notifier)
            .byId(todo.categoryId);
        final sourceRun = msg.runId;
        final live = ref.read(localChatRuntimeProvider) != null;
        return AiTodoCard(
          todo: todo,
          category: category,
          completionResult:
              ref
                  .read(localChatRuntimeProvider)
                  ?.projection
                  .turn(sourceRun ?? '')
                  ?.completedTodoIds
                  .contains(todo.id) ??
              false,
          animateCompletion: _presentedCards.add(msg.id),
          onToggleDone: () => _toggleDone(todo),
          onEdit: () => _editTodo(todo),
          onUndo: live && sourceRun != null ? null : () => _undoTodo(msg, todo),
        );
      case ChatMessageType.todoPanel:
        final panel = msg.todoPanel;
        return panel == null
            ? const SizedBox.shrink()
            : AiTodoPanel(
                key: ValueKey(msg.id),
                panel: panel,
                onToggleDone: _toggleDone,
                onEdit: _editTodo,
              );
      case ChatMessageType.question:
        return _question(msg);
      case ChatMessageType.agentRun:
        return AgentRunCard(
          runId: msg.runId!,
          replyText: replyText,
          hasResultCards: hasResultCards,
        );
      case ChatMessageType.dataWriteCard:
        return const SizedBox.shrink();
      case ChatMessageType.text:
        return AiTextMessage(
          message: msg,
          showActions: false,
          streaming: msg.id == ref.watch(chatViewModelProvider).messageId,
        );
    }
  }

  Widget _question(ChatMessage message) {
    final question = message.question;
    if (question == null) return const SizedBox.shrink();
    final messages = ref
        .read(sessionListProvider.notifier)
        .messagesOf(message.sessionId);
    final index = messages.indexWhere((m) => m.id == message.id);
    final answered = messages
        .skip(index + 1)
        .any((m) => m.role == ChatRole.user);
    final inputId = ChatQuestion.answerInputId(message.id);
    final answer = messages.where((m) => m.id == inputId).firstOrNull;
    final source = ref
        .read(localChatRuntimeProvider)
        ?.projection
        .turn(message.runId ?? '');
    return AiQuestionCard(
      question: question,
      answered: answered,
      answer: answer?.content,
      enabled:
          !answered &&
          source != null &&
          !ref.read(chatViewModelProvider).isGenerating,
      onAnswer: (text) {
        if (ref.read(currentSessionIdProvider) != message.sessionId ||
            source == null) {
          return Future.value(false);
        }
        return sendChatMessage(
          ref,
          text,
          inputId: inputId,
          replyToInputId: source.inputId,
        );
      },
    );
  }

  String _dateLabel(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final hm =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    if (day == today) return '今天 $hm';
    if (day == today.subtract(const Duration(days: 1))) return '昨天 $hm';
    return '${t.month}月${t.day}日 $hm';
  }
}
