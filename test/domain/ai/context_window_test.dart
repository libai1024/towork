import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/ai/context_window.dart';
import 'package:towork/domain/ai/model_gateway.dart';

JsonObject message(String role, String text) => {'role': role, 'content': text};
JsonObject call(String id) => {
  'id': id,
  'type': 'function',
  'function': {'name': 'todo_list', 'arguments': '{}'},
};
Matcher failure(ModelFailureCode code) =>
    throwsA(isA<ModelFailure>().having((e) => e.code, 'code', code));

void main() {
  test(
    'trims complete oldest turns, retains policy, clock and parallel exchanges',
    () {
      final history = <JsonObject>[
        message('system', 'App policy'),
        message('system', 'old clock'),
        message('user', '旧' * 1000),
        message('assistant', 'old answer'),
        message('system', 'current clock'),
        message('user', '最新请求'),
        {
          'role': 'assistant',
          'content': null,
          'reasoning_content': 'retained provider reasoning',
          'tool_calls': [call('a'), call('b')],
        },
        {'role': 'tool', 'tool_call_id': 'b', 'content': '{"rows":[]}'},
        {'role': 'tool', 'tool_call_id': 'a', 'content': '{"rows":[]}'},
      ];
      const window = ContextWindow(tokenBudget: 2200);
      final result = window.select(history, outputReserve: 100);
      expect(result.omittedTurns, 1);
      expect(result.messages, [
        history.first,
        ContextWindow.notice,
        ...history.skip(4),
      ]);
      expect(
        result.estimatedInputTokens,
        ContextWindow.estimateInput(result.messages, []),
      );
      expect(history, hasLength(9));
      expect(
        () => result.messages.last['content'] = 'changed',
        throwsUnsupportedError,
      );
    },
  );

  test('UTF-8, tools and output reserve all consume budget without splitting current input', () {
    final history = [message('user', '中文🙂' * 30)];
    final tools = [
      <String, Object?>{'schema': '字段' * 100},
    ];
    final required = ContextWindow.estimateInput(history, tools) + 500;
    expect(
      ContextWindow(tokenBudget: required)
          .select(history, tools: tools, outputReserve: 500)
          .messages,
      history,
    );
    expect(
      () =>
          ContextWindow(tokenBudget: required - 1)
              .select(history, tools: tools, outputReserve: 500),
      failure(ModelFailureCode.contextBudget),
    );
    expect(
      ContextWindow.estimateInput(history, []),
      greaterThan(jsonEncode(history).length),
    );
  });

  test('current tool result cannot be dropped to force a request to fit', () {
    final history = <JsonObject>[
      message('user', '查询'),
      {
        'role': 'assistant',
        'tool_calls': [call('a')],
      },
      {'role': 'tool', 'tool_call_id': 'a', 'content': '数据' * 1000},
    ];
    expect(
      () => const ContextWindow(tokenBudget: 2000).select(history),
      failure(ModelFailureCode.contextBudget),
    );
  });

  test(
    'malformed tool associations fail even when an old turn would be omitted',
    () {
      final head = message('user', '旧' * 1000);
      final tail = message('user', '新');
      for (final exchange in <List<JsonObject>>[
        [
          {'role': 'tool', 'tool_call_id': 'missing', 'content': '{}'},
        ],
        [
          {
            'role': 'assistant',
            'tool_calls': [call('a')],
          },
        ],
        [
          {
            'role': 'assistant',
            'tool_calls': [call('a'), call('a')],
          },
        ],
        [
          {
            'role': 'assistant',
            'tool_calls': [call('a')],
          },
          {'role': 'tool', 'tool_call_id': 'wrong', 'content': '{}'},
        ],
        [
          {
            'role': 'assistant',
            'tool_calls': [call('a')],
          },
          {'role': 'tool', 'tool_call_id': 'a', 'content': '{}'},
          {'role': 'tool', 'tool_call_id': 'a', 'content': '{}'},
        ],
      ]) {
        expect(
          () =>
              const ContextWindow(tokenBudget: 1600)
                  .select([head, ...exchange, tail]),
          failure(ModelFailureCode.protocol),
        );
      }
    },
  );

  test(
    'already omitted history adds one notice; snapshots can omit the notice',
    () {
      final history = [message('system', 'policy'), message('user', 'now')];
      final result = const ContextWindow().select(
        history,
        previouslyOmittedTurns: 20,
      );
      expect(result.omittedTurns, 0);
      expect(result.messages, [
        history.first,
        ContextWindow.notice,
        history.last,
      ]);
      expect(
        const ContextWindow()
            .select(history, previouslyOmittedTurns: 20, includeNotice: false)
            .messages,
        history,
      );
    },
  );

  test('old runs round-trip without changing idempotency JSON; context metadata survives next', () {
    final original = AgentRun(
      id: 'r',
      sessionId: 's',
      inputId: 'i',
      profile: ModelProfile(model: 'fixture'),
      history: [message('user', 'hello')],
    );
    final json = original.toJson();
    expect(json.containsKey('history_omitted_turns'), isFalse);
    expect(AgentRun.fromJson(json).toJson(), json);
    final next = AgentRun.fromJson({...json, 'history_omitted_turns': 3})
        .next(
          AgentRunStatus.generating,
          round: 1,
          requestOmittedTurns: 2,
          estimatedInputTokens: 1000,
        )
        .next(AgentRunStatus.interrupted);
    final decoded = AgentRun.fromJson(next.toJson());
    expect(decoded.contextOmittedTurns, 5);
    expect(decoded.estimatedInputTokens, 1000);
    expect(decoded.usage, isEmpty);
  });
}
