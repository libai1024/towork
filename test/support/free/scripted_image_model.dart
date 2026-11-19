import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/domain/ai/model_gateway.dart';

import 'scripted_business_model.dart';

class ScriptedImageModel implements ModelGateway {
  ScriptedImageModel({required this.png, this.uncertain = false});
  final Uint8List png;
  final bool uncertain;
  final requests = <ModelRequest>[];
  @override
  Stream<ModelEvent> stream(
    ModelRequest request, {
    required String apiKey,
    ModelCancellation? cancellation,
  }) async* {
    expect(apiKey, startsWith('synthetic-'));
    requests.add(request);
    final user = request.messages.lastWhere((m) => m['role'] == 'user');
    expect(user.containsKey('_towork_attachment_id'), isFalse);
    final content = user['content']! as List;
    final url = ((content.last as Map)['image_url']! as Map)['url']! as String;
    expect(base64Decode(url.split(',').last), png);
    expect(request.tools.map((t) => (t['function']! as Map)['name']).toSet(), {
      'data_table_get',
      'data_row_list',
      'data_row_get',
      'data_row_create',
      'data_row_update',
    });
    final create =
        request.tools.singleWhere(
              (t) => (t['function']! as Map)['name'] == 'data_row_create',
            )['function']!
            as Map;
    expect(
      (create['parameters']! as Map)['required'],
      contains('uncertain_field_ids'),
    );
    final tableId =
        ((((create['parameters']! as Map)['properties']! as Map)['table_id']!
                    as Map)['enum']!
                as List)
            .single;
    final last = request.messages.last;
    if (last['role'] == 'user') {
      yield businessCalls([
        businessCall('schema', 'data_table_get', {'table_id': tableId}),
      ]);
    } else if (last['tool_call_id'] == 'schema') {
      final schema = jsonDecode(last['content']! as String) as Map;
      final fields = (schema['items']! as List).cast<JsonObject>();
      final titleId =
          fields.singleWhere((f) => f['name'] == '项目')['id']! as String;
      final amountId =
          fields.singleWhere((f) => f['name'] == '金额')['id']! as String;
      yield businessCalls([
        businessCall('extract', 'data_row_create', {
          'table_id': tableId,
          'expected_table_version': schema['version'],
          'values': {titleId: '图中发票', amountId: '88.5'},
          'uncertain_field_ids': uncertain ? [amountId] : <String>[],
        }),
      ]);
    } else {
      expect(last['tool_call_id'], 'extract');
      final result = jsonDecode(last['content']! as String) as Map;
      yield ModelCompleted(
        assistantMessage: {
          'role': 'assistant',
          'content': result['status'] == 'not_executed'
              ? '未导入图片记录。'
              : '已根据图片导入一条记录。',
        },
        finishReason: 'stop',
      );
    }
  }
}
