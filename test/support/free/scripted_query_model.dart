import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/domain/ai/model_gateway.dart';

/// Requests discover IDs from real tool results rather than fixture IDs.
class ScriptedQueryModel implements ModelGateway {
  final requests = <ModelRequest>[];
  final results = <String, JsonObject>{};
  final note = StringBuffer();
  @override
  Stream<ModelEvent> stream(
    ModelRequest request, {
    required String apiKey,
    ModelCancellation? cancellation,
  }) async* {
    expect(apiKey, startsWith('synthetic-'));
    requests.add(request);
    final last = request.messages.last;
    if (last['role'] == 'user') {
      yield _tool('categories', 'category_list', {'query': '工作'});
      return;
    }
    final id = last['tool_call_id']! as String;
    final result = (jsonDecode(last['content']! as String) as Map)
        .cast<String, Object?>();
    results[id] = result;
    expect(result['error'], isNull);
    switch (id) {
      case 'categories':
        final items = result['items']! as List;
        expect(items, hasLength(1));
        yield _tool('filtered', 'todo_list', {
          'status': 'active',
          'category_id': (items.single as Map)['id'],
          'include_descendants': true,
          'tags': ['周会'],
          'priority': 'high',
          'due_from': '2026-09-23T16:00:00Z',
          'due_before': '2026-09-24T16:00:00Z',
          'order_by': 'due_at',
        });
      case 'filtered':
        final items = result['items']! as List;
        expect(items, hasLength(1));
        final item = items.single as Map;
        yield _tool('detail0', 'todo_get', {
          'id': item['id'],
          'expected_version': item['version'],
        });
      case 'detail0':
        note.write(result['note_segment']);
        expect(result['next_note_offset'], 2000);
        yield _tool('detail1', 'todo_get', {
          'id': result['id'],
          'expected_version': result['version'],
          'note_offset': result['next_note_offset'],
        });
      case 'detail1':
        note.write(result['note_segment']);
        expect(result['next_note_offset'], isNull);
        yield _tool('complete', 'todo_complete', {
          'id': result['id'],
          'expected_version': result['version'],
        });
      case 'complete':
        yield ModelCompleted(
          assistantMessage: {
            'role': 'assistant',
            'content': '已核对完整备注，并完成筛选出的待办。',
          },
          finishReason: 'stop',
        );
      default:
        fail('Unexpected scripted query response');
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
