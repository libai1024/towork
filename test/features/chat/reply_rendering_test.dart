import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/core/todo/todo_checkbox.dart';
import 'package:towork/core/widgets/ai_code_block.dart';
import 'package:towork/core/widgets/ai_markdown.dart';
import 'package:towork/core/widgets/app_toast.dart';
import 'package:towork/domain/models/models.dart';
import 'package:towork/features/chat/widgets/chat_messages.dart';
import 'package:towork/theme/app_theme.dart';

Widget host(Widget child, {bool reduceMotion = true, double scale = 1}) =>
    MaterialApp(
      theme: AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(
          disableAnimations: reduceMotion,
          textScaler: TextScaler.linear(scale),
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(width: 320, child: child),
          ),
        ),
      ),
    );

void main() {
  const markdown =
      '# 工作安排\n\n先完成 **方案**，再处理消息。\n\n'
      '1. 整理资料\n2. 核对附件\n\n> 保留讨论时间。\n\n'
      '```dart\nfinal result = await saveDocumentAndNotifyEveryone();\n```\n\n'
      '| 工作 | 时间 | 负责人 | 备注 |\n| --- | --- | --- | --- |\n'
      '| 需求评审会议 | 明天下午两点半 | 产品与研发团队 | 请带上完整项目资料 |';
  final message = ChatMessage(
    id: 'reply',
    sessionId: 'session',
    role: ChatRole.assistant,
    type: ChatMessageType.text,
    content: markdown,
    createdAt: DateTime(2026, 11, 16),
  );

  testWidgets(
    'streaming and saved replies share rich blocks, code copy and wide tables',
    (tester) async {
      final clipboard = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      for (final streaming in [true, false]) {
        await tester.pumpWidget(
          host(AiTextMessage(message: message, streaming: streaming)),
        );
        await tester.pumpAndSettle();
        expect(find.byType(AiMarkdown), findsOneWidget);
        expect(find.byType(AiCodeBlock), findsOneWidget);
        expect(find.byType(Table), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(find.text('# 工作安排'), findsNothing);
      }
      await tester.ensureVisible(find.byTooltip('复制代码'));
      await tester.tap(find.byTooltip('复制代码'));
      await tester.pump();
      expect(
        clipboard.single,
        'final result = await saveDocumentAndNotifyEveryone();\n',
      );
      AppToast.dismiss();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('partial fences and large text remain usable at phone width', (
    tester,
  ) async {
    for (final text in ['**正在整理', '```dart\nfinal value = 1;', markdown]) {
      await tester.pumpWidget(host(AiMarkdown(text: text), scale: 2));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('reply blocks retain small type and compact paragraph spacing', (
    tester,
  ) async {
    await tester.pumpWidget(host(const AiMarkdown(text: '第一段。\n\n第二段。')));
    final markdown = tester.widget<MarkdownBody>(find.byType(MarkdownBody));
    expect(markdown.styleSheet!.p!.fontSize, 15);
    expect(markdown.styleSheet!.blockSpacing, 8);
    expect(
      tester.getSize(find.byType(AiMarkdown)).height,
      lessThanOrEqualTo(56),
    );
  });

  testWidgets(
    'reduced motion keeps a pending save static and shows live status',
    (tester) async {
      final save = Completer<void>();
      final todo = Todo(
        id: 'pending-save',
        title: '等待保存',
        status: TodoStatus.inProgress,
        createdAt: DateTime(2026, 11, 16),
      );
      await tester.pumpWidget(
        host(AiTodoCard(todo: todo, onToggleDone: () => save.future)),
      );
      expect(find.text('进行中'), findsOneWidget);
      await tester.tap(find.byType(TodoCheckbox));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.binding.transientCallbackCount, 0);
      save.complete();
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        host(AiTodoCard(todo: todo.copyWith(status: TodoStatus.cancelled))),
      );
      expect(find.text('已取消'), findsOneWidget);
    },
  );

  testWidgets(
    'task card waits for persistence, prevents duplicate taps and animates completion',
    (tester) async {
      var todo = Todo(
        id: 'task',
        title: '整理项目方案',
        createdAt: DateTime(2026, 11, 16),
      );
      final save = Completer<void>();
      var calls = 0;
      late StateSetter update;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return AiTodoCard(
                todo: todo,
                onToggleDone: () async {
                  calls++;
                  await save.future;
                  update(() => todo = todo.copyWith(status: TodoStatus.done));
                },
              );
            },
          ),
          reduceMotion: false,
        ),
      );
      await tester.tap(find.byType(TodoCheckbox));
      await tester.pump();
      await tester.tapAt(tester.getCenter(find.byType(TodoCheckbox)));
      expect(calls, 1);
      expect(
        tester.widget<TodoCheckbox>(find.byType(TodoCheckbox)).checked,
        isFalse,
      );
      save.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.text('已完成'), findsOneWidget);
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
      expect(
        tester.widget<TodoCheckbox>(find.byType(TodoCheckbox)).checked,
        isTrue,
      );
    },
  );

  testWidgets('failed save keeps the task open and allows retry', (
    tester,
  ) async {
    var calls = 0;
    final todo = Todo(
      id: 'task',
      title: '整理项目方案',
      createdAt: DateTime(2026, 11, 16),
    );
    await tester.pumpWidget(
      host(
        AiTodoCard(
          todo: todo,
          onToggleDone: () async {
            calls++;
            throw StateError('synthetic storage failure');
          },
        ),
      ),
    );
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byType(TodoCheckbox));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TodoCheckbox>(find.byType(TodoCheckbox)).checked,
        isFalse,
      );
      AppToast.dismiss();
    }
    expect(calls, 2);
    await tester.pumpAndSettle();
  });
}
