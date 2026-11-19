import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/data/ai/chat_stream_assembler.dart';
import 'package:towork/data/ai/sse_decoder.dart';
import 'package:towork/domain/ai/model_gateway.dart';

Matcher fails(ModelFailureCode code) =>
    throwsA(isA<ModelFailure>().having((e) => e.code, 'code', code));

String chunk(JsonObject delta, {String? finish}) => jsonEncode({
  'choices': [
    {'index': 0, 'delta': delta, 'finish_reason': finish},
  ],
});

void main() {
  group('SSE framing', () {
    test(
      'every possible byte split preserves Chinese and CRLF frames',
      () async {
        final bytes = utf8.encode(
          ': keepalive\r\ndata: 中文\r\n\r\ndata: [DONE]\n\n',
        );
        for (var split = 0; split <= bytes.length; split++) {
          final frames = await decodeSse(
            Stream.fromIterable([
              bytes.sublist(0, split),
              bytes.sublist(split),
            ]),
          ).toList();
          expect(frames, ['中文', '[DONE]']);
        }
      },
    );

    test(
      'multiline data, comments and metadata follow SSE semantics',
      () async {
        expect(
          await decodeSse(
            Stream.value(
              utf8.encode(
                'event: message\nid: 3\ndata: one\ndata:two\n: ping\n\n',
              ),
            ),
          ).toList(),
          ['one\ntwo'],
        );
      },
    );

    test(
      'unterminated frames, malformed UTF-8 and budgets fail closed',
      () async {
        await expectLater(
          decodeSse(Stream.value(utf8.encode('data: partial\n'))).toList(),
          fails(ModelFailureCode.truncated),
        );
        await expectLater(
          decodeSse(Stream.value([0xff])).toList(),
          fails(ModelFailureCode.protocol),
        );
        await expectLater(
          decodeSse(
            Stream.value(List.filled(9, 65)),
            maxResponseBytes: 8,
          ).toList(),
          fails(ModelFailureCode.budget),
        );
      },
    );

    test('leading UTF-8 BOM does not swallow the first frame', () async {
      expect(
        await decodeSse(
          Stream.value(utf8.encode('﻿data: 中文\n\ndata: [DONE]\n\n')),
        ).toList(),
        ['中文', '[DONE]'],
      );
    });

    test(
      'EOF right after a [DONE] frame without the closing blank line',
      () async {
        expect(
          await decodeSse(
            Stream.value(utf8.encode('data: {"choices":[]}\n\ndata: [DONE]')),
          ).toList(),
          ['{"choices":[]}', '[DONE]'],
        );
        // 多行一起悬空（含 [DONE]）仍按截断失败，不放宽到半帧。
        await expectLater(
          decodeSse(Stream.value(utf8.encode('data: one\ndata: [DONE]')))
              .toList(),
          fails(ModelFailureCode.truncated),
        );
      },
    );
  });

  group('tool completion boundary', () {
    test('interleaved tool fragments are only returned after valid DONE', () {
      final a = ChatStreamAssembler();
      expect(a.add(chunk({'reasoning_content': '检索后修改'})), isEmpty);
      expect(
        a.add(
          chunk({
            'tool_calls': [
              {
                'index': 1,
                'id': 'b',
                'function': {'name': 'todo.update', 'arguments': '{"id":'},
              },
              {
                'index': 0,
                'id': 'a',
                'type': 'function',
                'function': {'name': 'todo.query', 'arguments': '{}'},
              },
            ],
          }),
        ),
        isEmpty,
      );
      expect(
        a.add(
          chunk({
            'tool_calls': [
              {
                'index': 1,
                'function': {'arguments': '"中文"}'},
              },
            ],
          }, finish: 'tool_calls'),
        ),
        isEmpty,
      );
      a.add(
        jsonEncode({
          'choices': <Object?>[],
          'usage': {'prompt_tokens': 12, 'completion_tokens': 9},
        }),
      );
      final done = a.add('[DONE]').single as ModelCompleted;
      final tools = done.assistantMessage['tool_calls']! as List<Object?>;
      expect((tools.first! as JsonObject)['id'], 'a');
      expect((tools.last! as JsonObject)['id'], 'b');
      expect(done.assistantMessage['reasoning_content'], '检索后修改');
      expect(done.usage?['completion_tokens'], 9);
      expect(() => tools.clear(), throwsUnsupportedError);
      expect(() => a.add('[DONE]'), fails(ModelFailureCode.protocol));
    });

    test('invalid/incomplete arguments never produce a completed message', () {
      for (final arguments in ['{', '[]', 'null', '"title"']) {
        final a = ChatStreamAssembler();
        a.add(
          chunk({
            'tool_calls': [
              {
                'index': 0,
                'id': 'a',
                'function': {'name': 'todo.create', 'arguments': arguments},
              },
            ],
          }, finish: 'tool_calls'),
        );
        expect(() => a.add('[DONE]'), fails(ModelFailureCode.protocol));
      }
    });

    test(
      'missing finish, token exhaustion and mismatched tool finish reject',
      () {
        final missing = ChatStreamAssembler()
          ..add(chunk({'content': 'partial'}));
        expect(() => missing.add('[DONE]'), fails(ModelFailureCode.truncated));
        final limited = ChatStreamAssembler()
          ..add(chunk({'content': 'partial'}, finish: 'length'));
        expect(() => limited.add('[DONE]'), fails(ModelFailureCode.budget));
        final missingTool = ChatStreamAssembler()
          ..add(chunk({}, finish: 'tool_calls'));
        expect(
          () => missingTool.add('[DONE]'),
          fails(ModelFailureCode.protocol),
        );
      },
    );

    test('text completion retains absent usage as unknown', () {
      final a = ChatStreamAssembler();
      expect(
        (a.add(chunk({'content': '好'})).single as ModelTextDelta).text,
        '好',
      );
      a.add(chunk({}, finish: 'stop'));
      final done = a.add('[DONE]').single as ModelCompleted;
      expect(done.text, '好');
      expect(done.usage, isNull);
    });

    test('array-style text content parts are folded', () {
      final a = ChatStreamAssembler();
      expect(
        (a
                    .add(
                      chunk({
                        'content': [
                          {'type': 'text', 'text': '第一段'},
                        ],
                      }),
                    )
                    .single
                as ModelTextDelta)
            .text,
        '第一段',
      );
      expect(
        (a
                    .add(
                      chunk({
                        'content': [
                          {'type': 'text', 'text': '第二段'},
                          {'text': '（无type同样视为文本）'},
                        ],
                      }),
                    )
                    .single
                as ModelTextDelta)
            .text,
        '第二段（无type同样视为文本）',
      );
      a.add(chunk({}, finish: 'stop'));
      final done = a.add('[DONE]').single as ModelCompleted;
      expect(done.text, '第一段第二段（无type同样视为文本）');
    });

    test('array-style content with non-text parts still rejects', () {
      final a = ChatStreamAssembler();
      expect(
        () => a.add(
          chunk({
            'content': [
              {
                'type': 'image_url',
                'image_url': {'url': 'https://x'},
              },
            ],
          }),
        ),
        fails(ModelFailureCode.protocol),
      );
    });

    test('upstream errors never expose private content in exceptions', () {
      final a = ChatStreamAssembler();
      expect(
        () => a.add('{"error":{"message":"private-header-value"}}'),
        throwsA(
          isA<ModelFailure>().having(
            (e) => e.toString(),
            'redacted',
            isNot(contains('private-header-value')),
          ),
        ),
      );
    });
  });

  test(
    'request is a deep immutable copy, profile cannot set arbitrary host',
    () {
      final source = <JsonObject>[
        {'role': 'user', 'content': 'before'},
      ];
      final request = ModelRequest(
        profile: ModelProfile(model: 'test'),
        messages: source,
      );
      source.first['content'] = 'after';
      expect(request.messages.first['content'], 'before');
      expect(
        () => request.messages.first['content'] = 'after',
        throwsUnsupportedError,
      );
      expect(request.profile.completionsUri.host, 'api.moonshot.cn');
      expect(
        ModelProfile(
          model: 'test',
          region: ProviderRegion.international,
        ).completionsUri.host,
        'api.moonshot.ai',
      );
      expect(request.toJson().containsKey('apiKey'), isFalse);
      expect(
        () => ModelProfile(model: ' '),
        fails(ModelFailureCode.configuration),
      );
    },
  );

  test('Code credentials use a separate official product endpoint', () {
    for (final region in ProviderRegion.values) {
      final profile = ModelProfile(
        model: 'kimi-for-coding',
        product: ProviderKind.kimiCode,
        region: region,
      );
      expect(profile.completionsUri.path, '/coding/v1/chat/completions');
      expect(
        profile.completionsUri.host,
        region == ProviderRegion.china ? 'api.kimi.com' : 'api.kimi.ai',
      );
      expect(profile.disableThinking, isFalse);
    }
  });

  test('cancellation listeners detach and cancellation is idempotent', () {
    final signal = ModelCancellation();
    var calls = 0;
    final remove = signal.onCancel(() => calls++);
    remove();
    signal.onCancel(() => calls++);
    signal.cancel();
    signal.cancel();
    signal.onCancel(() => calls++);
    expect(calls, 2);
  });
}
