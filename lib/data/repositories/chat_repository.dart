import '../../domain/models/models.dart';
import '../../domain/repositories/chat_store.dart';
import '../seeds/chat_seed.dart';
import '../../domain/repositories/repository_error.dart';
import 'repository_validation.dart';

class ChatRepository extends ChatStore {
  ChatRepository({
    List<ChatSession>? initial,
    Map<String, List<ChatMessage>>? messages,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(
         requireUniqueIds(
           initial ?? seedSessions((clock ?? DateTime.now)()),
           (ChatSession session) => session.id,
         ),
       ) {
    _messages = {
      for (final entry
          in (messages ??
                  (initial == null
                      ? seedMessages(_clock())
                      : <String, List<ChatMessage>>{}))
              .entries)
        entry.key: List.of(entry.value),
    };
    for (final session in state) {
      _messages.putIfAbsent(
        session.id,
        () => [
          ChatMessage(
            id: '${session.id}_question',
            sessionId: session.id,
            role: ChatRole.user,
            type: ChatMessageType.text,
            content: session.title,
            createdAt: session.createdAt,
          ),
          ChatMessage(
            id: '${session.id}_answer',
            sessionId: session.id,
            role: ChatRole.assistant,
            type: ChatMessageType.text,
            content: session.lastMessagePreview,
            createdAt: session.updatedAt,
            modelId: 'K3-256k-Max',
            durationMs: 1800,
          ),
        ],
      );
    }
    final all = <ChatMessage>[];
    for (final entry in _messages.entries) {
      if (sessionById(entry.key) == null ||
          entry.value.any((m) => m.sessionId != entry.key)) {
        throw const RepositoryException(
          RepositoryErrorCode.invalidInput,
          '消息所属会话无效',
        );
      }
      all.addAll(entry.value);
    }
    requireUniqueIds(all, (ChatMessage message) => message.id);
  }

  final DateTime Function() _clock;
  @override
  void deleteSession(String id) {
    _messages.remove(id);
    state = state.where((s) => s.id != id).toList();
  }

  int _seq = 100;

  late Map<String, List<ChatMessage>> _messages;

  @override
  List<ChatMessage> messagesOf(String sessionId) =>
      List.unmodifiable(_messages[sessionId] ?? const []);

  /// 按 id 查找消息（详情页 AI 溯源用）。
  @override
  ChatMessage? messageById(String? id) {
    if (id == null) return null;
    for (final list in _messages.values) {
      for (final m in list) {
        if (m.id == id) return m;
      }
    }
    return null;
  }

  /// 按 id 查找会话（详情页 AI 溯源用）。
  @override
  ChatSession? sessionById(String? id) {
    if (id == null) return null;
    for (final s in state) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// 新建空会话并返回。
  @override
  ChatSession createSession() {
    final now = _clock();
    String id;
    do {
      id = 's_gen_${_seq++}';
    } while (sessionById(id) != null);
    final session = ChatSession(
      id: id,
      title: '新的对话',
      createdAt: now,
      updatedAt: now,
    );
    state = [session, ...state];
    _messages[session.id] = [];
    return session;
  }

  @override
  void appendMessage(ChatMessage message) {
    if (sessionById(message.sessionId) == null) {
      throw const RepositoryException(RepositoryErrorCode.notFound, '会话不存在');
    }
    if (messageById(message.id) != null) {
      throw const RepositoryException(
        RepositoryErrorCode.conflict,
        '消息 ID 已存在',
      );
    }
    _messages[message.sessionId] = [...messagesOf(message.sessionId), message];
    _touch(message.sessionId);
  }

  @override
  void insertMessageAt(int index, ChatMessage message) {
    if (sessionById(message.sessionId) == null) {
      throw const RepositoryException(RepositoryErrorCode.notFound, '会话不存在');
    }
    final existing = messageById(message.id);
    if (existing != null) {
      if (existing.sessionId != message.sessionId) {
        throw const RepositoryException(
          RepositoryErrorCode.conflict,
          '消息 ID 已用于另一会话',
        );
      }
      return;
    }
    final messages = List<ChatMessage>.of(messagesOf(message.sessionId));
    messages.insert(index.clamp(0, messages.length), message);
    _messages[message.sessionId] = messages;
    _touch(message.sessionId);
  }

  @override
  void updateMessage(ChatMessage message) {
    final original = messageById(message.id);
    if (original == null) return;
    if (original.sessionId != message.sessionId) {
      throw const RepositoryException(
        RepositoryErrorCode.invalidInput,
        '消息不能移到其他会话',
      );
    }
    _messages[message.sessionId] = [
      for (final item in messagesOf(message.sessionId))
        item.id == message.id ? message : item,
    ];
    _touch(message.sessionId);
  }

  @override
  void removeMessage(String sessionId, String messageId) {
    if (sessionById(sessionId) == null) return;
    _messages[sessionId] = messagesOf(sessionId)
        .where((m) => m.id != messageId)
        .toList();
    _touch(sessionId);
  }

  @override
  String nextMessageId() {
    String id;
    do {
      id = 'm_gen_${_seq++}';
    } while (messageById(id) != null);
    return id;
  }

  @override
  void renameSession(String id, String title) {
    state = [
      for (final s in state)
        s.id == id ? s.copyWith(title: requireText(title, '会话名称')) : s,
    ];
  }

  void _touch(String sessionId) {
    final messages = messagesOf(sessionId).reversed;
    final preview =
        messages
            .where((message) => message.content.trim().isNotEmpty)
            .firstOrNull
            ?.content ??
        '';
    state = [
      for (final s in state)
        s.id == sessionId
            ? s.copyWith(updatedAt: _clock(), lastMessagePreview: preview)
            : s,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
}
