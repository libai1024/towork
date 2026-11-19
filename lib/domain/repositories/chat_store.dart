import '../models/models.dart';
import 'list_store.dart';

abstract class ChatStore extends ListStore<ChatSession> {
  ChatStore(super.initial);
  List<ChatMessage> messagesOf(String sessionId);
  ChatMessage? messageById(String? id);
  ChatSession? sessionById(String? id);
  ChatSession createSession();
  void appendMessage(ChatMessage message);
  void insertMessageAt(int index, ChatMessage message);
  void updateMessage(ChatMessage message);
  void removeMessage(String sessionId, String messageId);
  String nextMessageId();
  void renameSession(String id, String title);
  void deleteSession(String id) =>
      throw UnsupportedError('Async command required');
}
