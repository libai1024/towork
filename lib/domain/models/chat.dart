import '../chat/todo_panel.dart';
import '../chat/chat_question.dart';

enum ChatRole { user, assistant }

const Object _keep = Object();

enum ChatMessageType {
  text,
  todoCard,
  dataWriteCard,
  agentRun,
  todoPanel,
  question,
}

class ChatSession {
  const ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessagePreview = '',
    this.modelId = 'k3-256k',
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String lastMessagePreview;
  final String modelId;

  ChatSession copyWith({
    String? title,
    DateTime? updatedAt,
    String? lastMessagePreview,
    String? modelId,
  }) {
    return ChatSession(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      modelId: modelId ?? this.modelId,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.type,
    required this.content,
    required this.createdAt,
    this.todoId,
    this.modelId,
    this.durationMs,
    this.stoppedByUser = false,
    this.runId,
    this.todoPanel,
    this.question,
  });

  final String id;
  final String sessionId;
  final ChatRole role;
  final ChatMessageType type;

  /// 文本内容；todoCard 类型为 AI 引导语；dataWriteCard 为写入说明。
  final String content;
  final DateTime createdAt;

  /// type == todoCard 时关联的 Todo。
  final String? todoId;
  final String? modelId;
  final int? durationMs;
  final bool stoppedByUser;
  final String? runId;
  final TodoPanel? todoPanel;
  final ChatQuestion? question;

  ChatMessage copyWith({
    String? content,
    ChatMessageType? type,
    Object? todoId = _keep,
    Object? modelId = _keep,
    Object? durationMs = _keep,
    bool? stoppedByUser,
  }) {
    return ChatMessage(
      id: id,
      sessionId: sessionId,
      role: role,
      type: type ?? this.type,
      content: content ?? this.content,
      createdAt: createdAt,
      todoId: identical(todoId, _keep) ? this.todoId : todoId as String?,
      modelId: identical(modelId, _keep) ? this.modelId : modelId as String?,
      durationMs: identical(durationMs, _keep)
          ? this.durationMs
          : durationMs as int?,
      stoppedByUser: stoppedByUser ?? this.stoppedByUser,
      runId: runId,
      todoPanel: todoPanel,
      question: question,
    );
  }
}
