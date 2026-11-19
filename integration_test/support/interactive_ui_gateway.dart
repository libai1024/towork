import 'dart:convert';

import 'package:towork/domain/ai/model_gateway.dart';

import '../../test/support/free/fake_model_gateway.dart';

class InteractiveUiGateway extends FakeKimiGateway {
  static const _singleQuestion = '你说的「代班」是指哪件事？';
  static const _multipleQuestion = '需要哪些清单？';

  JsonObject? createdTable;
  @override
  Stream<ModelEvent> stream(
    ModelRequest request, {
    required String apiKey,
    ModelCancellation? cancellation,
  }) async* {
    final user =
        request.messages.lastWhere((m) => m['role'] == 'user')['content']
            as String;
    if (user == '请给我长回复') {
      var text = '';
      for (var i = 1; i <= 40; i++) {
        final line = '要点 $i 核对当前事项，确认时间和下一步安排。\n\n';
        text += line;
        yield ModelTextDelta(line);
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
      yield ModelCompleted(
        assistantMessage: {'role': 'assistant', 'content': text},
        finishReason: 'stop',
      );
      return;
    }
    if (user.startsWith(_singleQuestion) ||
        user.startsWith(_multipleQuestion)) {
      yield ModelCompleted(
        assistantMessage: {'role': 'assistant', 'content': '已收到你的选择，会按这个范围继续。'},
        finishReason: 'stop',
      );
      return;
    }
    if (user == '新增采购表' || user == '编辑采购表') {
      if (request.messages.last['role'] == 'user') {
        yield ModelCompleted(
          assistantMessage: {
            'role': 'assistant',
            'tool_calls': [
              {
                'id': 'table-schema',
                'type': 'function',
                'function': {
                  'name': user == '新增采购表'
                      ? 'data_table_create'
                      : 'data_table_update',
                  'arguments': jsonEncode(
                    user == '新增采购表'
                        ? {
                            'name': '采购清单',
                            'description': '本周需要采购的物品',
                            'fields': [
                              {'name': '物品', 'type': 'text', 'required': true},
                              {'name': '预算', 'type': 'money', 'unit': '元'},
                              {'name': '已采购', 'type': 'boolean'},
                            ],
                          }
                        : {
                            'table_id': createdTable!['id'],
                            'expected_table_version': createdTable!['version'],
                            'patch': {
                              'name': '本周采购',
                              'add_fields': [
                                {'name': '到货日期', 'type': 'date'},
                              ],
                            },
                          },
                  ),
                },
              },
            ],
          },
          finishReason: 'tool_calls',
        );
      } else {
        final result =
            jsonDecode(request.messages.last['content']! as String) as Map;
        if (result['entity'] is Map) {
          createdTable = (result['entity'] as Map).cast<String, Object?>();
        }
        yield ModelCompleted(
          assistantMessage: {
            'role': 'assistant',
            'content': user == '新增采购表' ? '采购清单已创建。' : '已改名，并加入到货日期。',
          },
          finishReason: 'stop',
        );
      }
      return;
    }
    final asking = user == '今天帮我代班。' || user == '选择多个范围';
    if (request.messages.last['role'] == 'user') {
      final overview = user.contains('总览');
      final empty = user.contains('空清单');
      yield ModelCompleted(
        assistantMessage: {
          'role': 'assistant',
          'tool_calls': [
            {
              'id': 'display',
              'type': 'function',
              'function': {
                'name': asking
                    ? 'show_question'
                    : overview
                    ? 'show_todo_overview'
                    : 'show_todo_list',
                'arguments': jsonEncode(
                  asking
                      ? {
                          'question': user == '选择多个范围'
                              ? _multipleQuestion
                              : _singleQuestion,
                          'options': user == '选择多个范围'
                              ? ['今日待办', '紧急待办', '本周待办']
                              : ['处理今天截止的两件待办', '新建一条代班待办', '暂时不用处理'],
                          'multiple': user == '选择多个范围',
                        }
                      : overview
                      ? {'title': '工作总览'}
                      : {
                          'title': empty ? '待核对事项' : '今日待办',
                          'scope': 'today',
                          if (empty) 'query': 'nothing-matches-this-fixture',
                        },
                ),
              },
            },
          ],
        },
        finishReason: 'tool_calls',
      );
    } else {
      if (asking) throw StateError('Question must wait for the user');
      yield ModelCompleted(
        assistantMessage: {
          'role': 'assistant',
          'content': user.contains('总览')
              ? '先留一段时间核对待交付附件。'
              : user.contains('空清单')
              ? '可以换一个范围继续查看。'
              : '先确认交互细节，再整理周会纪要。',
        },
        finishReason: 'stop',
      );
    }
  }
}
