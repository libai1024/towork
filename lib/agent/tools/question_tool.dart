import '../../domain/ai/agent_run.dart';
import '../../domain/ai/model_gateway.dart';
import '../../domain/chat/chat_question.dart';
import '../agent_tool_registry.dart';

class QuestionTool implements AgentReadTool {
  const QuestionTool();

  @override
  String get name => 'show_question';

  @override
  JsonObject get schema => agentToolSchema(
    name,
    'Ask the user a clarification using compact answer buttons. Ask one '
    'question in the card title only. Omit picker instructions and repeated '
    'questions in assistant prose. Provide 2–6 concise, relevant options. Single '
    'choice sends immediately; multiple choice requires confirmation. The '
    'UI always allows a custom text answer. This ends the current run and '
    'waits for a real user message; never assume an option was selected. '
    'These answers do not replace the existing write approval controls.',
    {
      'question': {'type': 'string', 'minLength': 1, 'maxLength': 200},
      'options': {
        'type': 'array',
        'items': {'type': 'string', 'minLength': 1, 'maxLength': 60},
        'minItems': 2,
        'maxItems': 6,
        'uniqueItems': true,
      },
      'multiple': {'type': 'boolean', 'description': 'Default false.'},
    },
    required: const ['question', 'options'],
  );

  @override
  Object? call(JsonObject args, AgentToolContext context) {
    requireToolKeys(
      args,
      {'question', 'options', 'multiple'},
      required: {'question', 'options'},
    );
    final question = ChatQuestion.decode({
      ...args,
      'version': 1,
      'type': 'question',
      'multiple': args['multiple'] ?? false,
    });
    if (question == null) throw const AgentFailure(AgentFailureCode.invalid);
    return {'ui': question.toJson(), 'status': 'awaiting_user_answer'};
  }
}
