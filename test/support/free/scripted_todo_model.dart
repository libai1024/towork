import 'dart:convert';

import 'package:towork/domain/ai/model_gateway.dart';

/// A deterministic protocol peer. All business effects still use the real Agent
/// and SQLite stack; native tests never need a real credential or network.
class ScriptedTodoModel implements ModelGateway {
  int calls = 0;
  @override
  Stream<ModelEvent> stream(
    ModelRequest request, {
    required String apiKey,
    ModelCancellation? cancellation,
  }) async* {
    calls++;
    final last = request.messages.last;
    if (last['role'] == 'user') {
      final completing = (last['content']! as String).contains('完成');
      yield _tool(
        completing ? 'lookup' : 'create',
        completing ? 'todo_list' : 'todo_create',
        completing ? {'query': '测试任务'} : {'title': '测试任务'},
      );
    } else if (last['tool_call_id'] == 'lookup') {
      final items =
          (jsonDecode(last['content']! as String) as Map)['items'] as List;
      final item = items.single as Map;
      yield _tool('complete', 'todo_complete', {
        'id': item['id'],
        'expected_version': item['version'],
      });
    } else {
      yield const ModelTextDelta('操作');
      yield ModelCompleted(
        assistantMessage: {
          'role': 'assistant',
          'content': '操作已根据回执完成。',
          'reasoning_content': 'private reasoning should not appear in the UI',
        },
        finishReason: 'stop',
      );
    }
  }

  ModelCompleted _tool(String id, String name, JsonObject args) =>
      ModelCompleted(
        assistantMessage: {
          'role': 'assistant',
          'content': null,
          'tool_calls': [
            {
              'id': id,
              'type': 'function',
              'function': {'name': name, 'arguments': jsonEncode(args)},
            },
          ],
        },
        finishReason: 'tool_calls',
      );
}
