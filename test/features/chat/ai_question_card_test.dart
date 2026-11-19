import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/domain/chat/chat_question.dart';
import 'package:towork/core/widgets/app_pressable.dart';
import 'package:towork/features/chat/widgets/ai_question_card.dart';
import 'package:towork/theme/app_theme.dart';

void main() {
  Future<void> mount(
    WidgetTester tester, {
    bool multiple = false,
    bool enabled = true,
    bool answered = false,
    String? answer,
    double scale = 1,
    required Future<bool> Function(String) send,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 760);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: AiQuestionCard(
                  question: ChatQuestion(
                    question: '先处理哪些事项？',
                    options: ['今日待办', '紧急待办', '本周全部待办与未安排时间的事项'],
                    multiple: multiple,
                  ),
                  enabled: enabled,
                  answered: answered,
                  answer: answer,
                  onAnswer: send,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('single tap sends once and failed send can retry', (
    tester,
  ) async {
    final pending = Completer<bool>();
    final sent = <String>[];
    await mount(
      tester,
      send: (text) {
        sent.add(text);
        return pending.future;
      },
    );
    Finder button(String option) => find.ancestor(
      of: find.text(option),
      matching: find.byType(AppPressable),
    );
    final first = tester.getRect(button('今日待办'));
    final second = tester.getRect(button('紧急待办'));
    expect(first.height, 44);
    expect(second.top, first.bottom);
    expect(find.byKey(const ValueKey('question-custom-answer')), findsNothing);
    await tester.tap(find.text('今日待办'));
    await tester.pump();
    await tester.tap(find.text('紧急待办'));
    expect(sent, ['先处理哪些事项？\n- 今日待办']);
    pending.complete(false);
    await tester.pumpAndSettle();
    expect(find.text('未发送，请重试'), findsOneWidget);
    await tester.tap(find.text('今日待办'));
    await tester.pumpAndSettle();
    expect(sent, hasLength(2));
  });

  testWidgets(
    'multiple choices wait for confirmation and retain custom answer',
    (tester) async {
      final sent = <String>[];
      await mount(
        tester,
        multiple: true,
        scale: 1.8,
        send: (text) async {
          sent.add(text);
          return true;
        },
      );
      await tester.tap(find.text('今日待办'));
      await tester.tap(find.text('紧急待办'));
      await tester.pumpAndSettle();
      expect(sent, isEmpty);
      expect(find.text('发送 2 项'), findsOneWidget);
      await tester.tap(find.byTooltip('补充回答'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('question-custom-answer')),
        '先排上午',
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('question-submit')));
      await tester.tap(find.byKey(const ValueKey('question-submit')));
      await tester.pumpAndSettle();
      expect(sent, ['先处理哪些事项？\n- 今日待办\n- 紧急待办\n先排上午']);
      expect(find.text('已回答'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'other answer can be sent on its own from a single-choice question',
    (tester) async {
      final sent = <String>[];
      await mount(
        tester,
        send: (text) async {
          sent.add(text);
          return true;
        },
      );
      expect(find.byKey(const ValueKey('question-submit')), findsNothing);
      await tester.tap(find.text('其他回答'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('发送'));
      expect(sent, isEmpty);
      await tester.enterText(
        find.byKey(const ValueKey('question-custom-answer')),
        '明天再排',
      );
      await tester.pump();
      await tester.tap(find.text('发送'));
      await tester.pumpAndSettle();
      expect(sent, ['先处理哪些事项？\n明天再排']);
    },
  );

  testWidgets('persisted answered card is read-only', (tester) async {
    var calls = 0;
    await mount(
      tester,
      enabled: false,
      answered: true,
      answer: '先处理哪些事项？\n- 今日待办',
      send: (_) async {
        calls++;
        return true;
      },
    );
    expect(find.text('紧急待办'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('question-answered-options')));
    await tester.pumpAndSettle();
    expect(find.text('今日待办'), findsOneWidget);
    await tester.tap(find.text('紧急待办'));
    expect(calls, 0);
    await tester.tap(find.byKey(const ValueKey('question-answered-options')));
    await tester.pumpAndSettle();
    expect(find.text('紧急待办'), findsNothing);
    expect(find.text('已回答'), findsOneWidget);
    expect(find.text('其他回答'), findsNothing);
  });
}
