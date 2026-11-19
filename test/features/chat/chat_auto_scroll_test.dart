import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/features/chat/widgets/chat_auto_scroll.dart';
import 'package:towork/features/chat/widgets/chat_composer_layout.dart';
import 'package:towork/theme/app_theme.dart';

void main() {
  testWidgets(
    'follows streamed layout, pauses for reading and resumes on send',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      late StateSetter update;
      var count = 30;
      var user = 'user-1';
      var session = 'session-1';
      var height = 300.0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return SizedBox(
                  height: height,
                  child: ChatAutoScroll(
                    controller: controller,
                    sessionId: session,
                    latestUserId: user,
                    child: ListView.builder(
                      controller: controller,
                      itemCount: count,
                      itemBuilder: (_, i) =>
                          SizedBox(height: 48, child: Text('内容 $i')),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.position.extentAfter, lessThan(1));
      update(() => count += 15);
      await tester.pumpAndSettle();
      expect(controller.position.extentAfter, lessThan(1));
      await tester.drag(find.byType(ListView), const Offset(0, 230));
      await tester.pumpAndSettle();
      final held = controller.offset;
      expect(find.byKey(const ValueKey('chat-jump-latest')), findsOneWidget);
      update(() => count += 20);
      await tester.pumpAndSettle();
      expect(controller.offset, closeTo(held, 1));
      await tester.tap(find.byKey(const ValueKey('chat-jump-latest')));
      await tester.pumpAndSettle();
      expect(controller.position.extentAfter, lessThan(1));
      expect(find.byKey(const ValueKey('chat-jump-latest')), findsNothing);
      update(() => height = 180);
      await tester.pumpAndSettle();
      expect(controller.position.extentAfter, lessThan(1));
      await tester.drag(find.byType(ListView), const Offset(0, 150));
      await tester.pumpAndSettle();
      update(() => user = 'user-2');
      await tester.pumpAndSettle();
      expect(controller.position.extentAfter, lessThan(1));
      update(() {
        session = 'session-2';
        count = 100;
      });
      await tester.pumpAndSettle();
      expect(controller.position.extentAfter, lessThan(1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('resume control stays above a measured overlay composer', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ChatComposerLayout(
            messages: (bottomPadding) => ChatAutoScroll(
              controller: controller,
              sessionId: 'session',
              latestUserId: 'user',
              bottomInset: bottomPadding,
              child: ListView.builder(
                controller: controller,
                itemCount: 60,
                padding: EdgeInsets.only(bottom: bottomPadding),
                itemBuilder: (_, i) =>
                    SizedBox(height: 48, child: Text('内容 $i')),
              ),
            ),
            composer: Container(
              key: const ValueKey('overlay-composer'),
              height: 190,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 200));
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('chat-jump-latest'));
    expect(
      tester.getBottomRight(button).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey('overlay-composer'))).dy,
      ),
    );
    await tester.tap(button, warnIfMissed: true);
    await tester.pumpAndSettle();
    expect(controller.position.extentAfter, lessThan(1));
    expect(button, findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
