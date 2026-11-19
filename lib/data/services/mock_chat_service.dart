import '../../domain/models/chat_reply.dart';
import '../../domain/repositories/chat_gateway.dart';
import 'mock_ai_parser.dart';

class MockChatService implements ChatGateway {
  MockChatService({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;
  final DateTime Function() _clock;

  @override
  Future<ChatReply> respond(String input) async =>
      MockAiParser.respond(input, now: _clock());
}
