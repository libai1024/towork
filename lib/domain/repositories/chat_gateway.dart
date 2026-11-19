import '../models/chat_reply.dart';

/// Replace the mock implementation here when the assistant API is available.
abstract interface class ChatGateway {
  Future<ChatReply> respond(String input);
}
