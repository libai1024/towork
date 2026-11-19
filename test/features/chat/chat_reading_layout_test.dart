import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/domain/models/models.dart';
import 'package:towork/features/chat/widgets/chat_messages.dart';
import 'package:towork/main.dart';
import 'package:towork/theme/app_theme.dart';

void main() {
  for (final size in [const Size(320, 640), const Size(1280, 900)]) {
    testWidgets('首页衬线问候在 $size 与双倍字号下可用', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(const ProviderScope(child: ToWorkApp()));
      await tester.pumpAndSettle();
      final greeting = tester.widget<Text>(find.textContaining('今天想做点什么'));
      expect(greeting.style!.fontFamily, 'serif');
      expect(greeting.style!.fontSize, 21);
      expect(find.byKey(const ValueKey('voice-input')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('用户消息宽度跟随阅读栏并使用统一正文行高', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: UserBubble(
                message: ChatMessage(
                  id: 'm',
                  sessionId: 's',
                  role: ChatRole.user,
                  type: ChatMessageType.text,
                  content: '这是一段用来检查阅读栏中消息宽度和行高的长消息。' * 3,
                  createdAt: DateTime(2026, 11, 15),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final text = find.textContaining('这是一段');
    expect(tester.getSize(text).width, lessThanOrEqualTo(300 * .78 - 28));
    expect(tester.widget<Text>(text).style!.height, 23 / 15);
    expect(tester.takeException(), isNull);
  });
}
