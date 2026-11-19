import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/domain/ai/model_gateway.dart';

JsonObject businessCall(String id, String name, JsonObject args) => {
  'id': id,
  'type': 'function',
  'function': {'name': name, 'arguments': jsonEncode(args)},
};
ModelCompleted businessCalls(List<JsonObject> calls) => ModelCompleted(
  assistantMessage: {'role': 'assistant', 'content': null, 'tool_calls': calls},
  finishReason: 'tool_calls',
);

/// Discover table/field/row identities from production tool results, then issue
/// one mixed batch. No model-generated success text stands in for persistence.
class ScriptedBusinessModel implements ModelGateway {
  final requests = <ModelRequest>[];
  JsonObject? table;
  String? amountField, titleField;
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
      yield businessCalls([
        businessCall('tables', 'data_table_list', {'query': '项目账本'}),
      ]);
      return;
    }
    final result = (jsonDecode(last['content']! as String) as Map)
        .cast<String, Object?>();
    expect(result['error'], isNull);
    switch (last['tool_call_id']) {
      case 'tables':
        table = ((result['items']! as List).single as Map)
            .cast<String, Object?>();
        yield businessCalls([
          businessCall('schema', 'data_table_get', {'table_id': table!['id']}),
        ]);
      case 'schema':
        final fields = (result['items']! as List).cast<JsonObject>();
        amountField =
            fields.singleWhere((f) => f['name'] == '金额')['id']! as String;
        titleField =
            fields.singleWhere((f) => f['name'] == '项目')['id']! as String;
        yield businessCalls([
          businessCall('rows', 'data_row_list', {'table_id': table!['id']}),
        ]);
      case 'rows':
        final rows = (result['items']! as List).cast<JsonObject>();
        final keep = rows.singleWhere(
          (r) => (r['values']! as Map)[titleField] == '项目甲',
        );
        final remove = rows.singleWhere(
          (r) => (r['values']! as Map)[titleField] == '待删除项目',
        );
        final target = {
          'table_id': table!['id'],
          'expected_table_version': table!['version'],
        };
        yield businessCalls([
          businessCall('edit', 'data_row_update', {
            ...target,
            'id': keep['id'],
            'expected_version': keep['version'],
            'values': {amountField!: '9.5'},
          }),
          businessCall('create', 'data_row_create', {
            ...target,
            'values': {titleField!: '新增项目', amountField!: '0.1'},
          }),
          businessCall('delete', 'data_row_delete', {
            ...target,
            'id': remove['id'],
            'expected_version': remove['version'],
          }),
        ]);
      case 'delete':
        yield ModelCompleted(
          assistantMessage: {
            'role': 'assistant',
            'content': '已更新项目甲金额、新增项目，并删除指定记录。',
          },
          finishReason: 'stop',
        );
      default:
        fail('Unexpected business tool result');
    }
  }
}
