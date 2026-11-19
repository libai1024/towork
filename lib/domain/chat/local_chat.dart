import 'dart:convert';

import '../ai/agent_run.dart';
import '../models/chat.dart';
import 'todo_panel.dart';
import 'chat_question.dart';

class LocalConversation {
  const LocalConversation({
    required this.id,
    required this.title,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  final String id;
  final String title;
  final int revision;
  final DateTime createdAt, updatedAt;
  final DateTime? deletedAt;
}

class LocalChatTurn {
  const LocalChatTurn({
    required this.inputId,
    required this.sessionId,
    required this.content,
    required this.position,
    required this.historyStart,
    required this.createdAt,
    required this.agentEnabled,
    required this.run,
    this.undoneAt,
    this.createdTodoIds = const [],
    this.completedTodoIds = const [],
  });
  final String inputId, sessionId, content;
  final int position, historyStart;
  final DateTime createdAt;
  final bool agentEnabled;
  final AgentRun run;
  final DateTime? undoneAt;

  /// 本轮执行的操作里「创建」出的待办 id（来自 workspace_operations 的
  /// 变更回执；未执行/已撤销不会出现在这里）。聊天页据此追加内容卡。
  final List<String> createdTodoIds;

  /// 本轮回执中从未完成变为完成的待办，撤销后为空。
  final List<String> completedTodoIds;

  List<Map<String, Object?>> get continuationHistory {
    final history = <Map<String, Object?>>[...run.history];
    if (run.proposal case final proposal?) {
      for (final call
          in (proposal['calls']! as List).cast<Map<String, Object?>>()) {
        history.add({
          'role': 'tool',
          'tool_call_id': call['tool_call_id'],
          'content': jsonEncode({
            'status': 'not_executed',
            'reason': run.status.name,
          }),
        });
      }
    }
    if (run.status != AgentRunStatus.succeeded) {
      history.add({
        'role': 'assistant',
        'content':
            '上一次请求未完成。已有 ${run.receipts.length} 批操作提交；其余未执行。后续修改前应重新查询当前记录。',
      });
    }
    if (undoneAt != null) {
      history.add({
        'role': 'system',
        'content': '用户随后在 App 中撤销了上一请求的业务修改，后续应查询当前记录。',
      });
    }
    return history;
  }

  List<ChatMessage> get messages {
    final panels = todoPanelsFromHistory(run.history, historyStart);
    final questions = questionsFromHistory(run.history, historyStart);
    return [
      ChatMessage(
        id: inputId,
        sessionId: sessionId,
        role: ChatRole.user,
        type: ChatMessageType.text,
        content: content,
        createdAt: createdAt,
      ),
      for (var i = historyStart + 1; i < run.history.length; i++) ...[
        if (run.history[i]['role'] == 'assistant' &&
            run.history[i]['content'] is String &&
            (run.history[i]['content']! as String).trim().isNotEmpty)
          ChatMessage(
            id: 'reply_${run.id}_$i',
            sessionId: sessionId,
            role: ChatRole.assistant,
            type: ChatMessageType.text,
            content: run.history[i]['content']! as String,
            createdAt: createdAt,
            modelId: run.profile.model,
            runId: run.id,
          ),
        if (panels[i] case final panel?)
          ChatMessage(
            id: 'panel_${run.id}_$i',
            sessionId: sessionId,
            role: ChatRole.assistant,
            type: ChatMessageType.todoPanel,
            content: '',
            createdAt: createdAt,
            modelId: run.profile.model,
            runId: run.id,
            todoPanel: panel,
          ),
        if (questions[i] case final question?)
          ChatMessage(
            id: 'question_${run.id}_$i',
            sessionId: sessionId,
            role: ChatRole.assistant,
            type: ChatMessageType.question,
            content: question.question,
            createdAt: createdAt,
            modelId: run.profile.model,
            runId: run.id,
            question: question,
          ),
      ],
      ChatMessage(
        id: 'activity_${run.id}',
        sessionId: sessionId,
        role: ChatRole.assistant,
        type: ChatMessageType.agentRun,
        content: '',
        createdAt: createdAt,
        runId: run.id,
      ),
    ];
  }
}

class LocalChatSnapshot {
  LocalChatSnapshot(
    Iterable<LocalConversation> conversations,
    Iterable<LocalChatTurn> turns,
  ) : conversations = List.unmodifiable(conversations),
      turns = List.unmodifiable(turns);
  final List<LocalConversation> conversations;
  final List<LocalChatTurn> turns;
}
