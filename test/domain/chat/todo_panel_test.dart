import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/chat/local_chat.dart';
import 'package:towork/domain/chat/todo_panel.dart';
import 'package:towork/domain/models/chat.dart';

void main() {
  final panel = TodoPanel(
    title: '今日待办',
    asOfLocal: '2026-11-17T09:00+08:00',
    overview: false,
    sections: [
      TodoPanelSection(title: '今日待办', todoIds: ['a', 'b'], matchedCount: 2),
    ],
  );
  Map<String, Object?> call(String id, [String name = 'show_todo_list']) => {
    'role': 'assistant',
    'tool_calls': [
      {
        'id': id,
        'type': 'function',
        'function': {'name': name, 'arguments': '{}'},
      },
    ],
  };
  Map<String, Object?> result(String id, [Object? value]) => {
    'role': 'tool',
    'tool_call_id': id,
    'content': jsonEncode(value ?? {'ui': panel.toJson()}),
  };

  test(
    'only paired successful display results from current turn are projected',
    () {
      final history = <Map<String, Object?>>[
        {'role': 'user', 'content': 'previous'},
        call('old'),
        result('old'),
        {'role': 'user', 'content': 'show'},
        result('old'),
        result('unknown'),
        call('read', 'todo_list'),
        result('read'),
        call('new'),
        result('new'),
        result('new'),
        call('bad'),
        result('bad', {'error': 'not_executed', 'ui': panel.toJson()}),
        {
          'role': 'assistant',
          'content': jsonEncode({'ui': panel.toJson()}),
        },
        call('reused'),
        call('reused', 'todo_list'),
        result('reused'),
      ];
      final found = todoPanelsFromHistory(history, 3);
      expect(found.keys, [9]);
      expect(found[9]!.title, '今日待办');
    },
  );

  test(
    'unknown versions, malformed dates and invalid payloads are ignored',
    () {
      for (final value in <Object?>[
        null,
        [],
        {...panel.toJson(), 'version': 2},
        {...panel.toJson(), 'type': 'html'},
        {...panel.toJson(), 'title': ''},
        {...panel.toJson(), 'as_of_local': '20261117'},
        {...panel.toJson(), 'sections': <Object>[]},
        {
          ...panel.toJson(),
          'sections': [
            {
              'title': 'x',
              'todo_ids': ['a', 'a'],
              'matched_count': 2,
            },
          ],
        },
        {
          ...panel.toJson(),
          'sections': [
            {
              'title': 'x',
              'todo_ids': ['a'],
              'matched_count': 0,
            },
          ],
        },
      ]) {
        expect(
          TodoPanel.decode(value, overview: false),
          isNull,
          reason: '$value',
        );
      }
      expect(
        todoPanelsFromHistory([
          {'role': 'user'},
          call('bad'),
          {'role': 'tool', 'tool_call_id': 'bad', 'content': '{bad'},
        ], 0),
        isEmpty,
      );
    },
  );

  test('messages keep panel order, stable IDs and one terminal run row', () {
    final history = <Map<String, Object?>>[
      {'role': 'user', 'content': '今天有什么'},
      {'role': 'assistant', 'content': '先看这两件事。'},
      call('one'),
      result('one'),
      {'role': 'assistant', 'content': '可以直接勾选。'},
    ];
    final turn = LocalChatTurn(
      inputId: 'input',
      sessionId: 'session',
      content: '今天有什么',
      position: 0,
      historyStart: 0,
      createdAt: DateTime(2026, 11, 17),
      agentEnabled: true,
      run: AgentRun(
        id: 'run',
        sessionId: 'session',
        inputId: 'input',
        profile: ModelProfile(model: 'fixture'),
        status: AgentRunStatus.succeeded,
        history: history,
      ),
    );
    final messages = turn.messages;
    expect(messages.map((m) => m.type), [
      ChatMessageType.text,
      ChatMessageType.text,
      ChatMessageType.todoPanel,
      ChatMessageType.text,
      ChatMessageType.agentRun,
    ]);
    expect(messages[2].id, 'panel_run_3');
    expect(messages[2].todoPanel!.sections.single.todoIds, ['a', 'b']);
    expect(
      messages[2].copyWith(content: '').todoPanel,
      same(messages[2].todoPanel),
    );
  });
}
