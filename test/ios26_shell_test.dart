import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/workspace_state.dart';
import 'package:towork/features/chat/chat_page.dart';
import 'package:towork/features/chat/widgets/chat_drawer.dart';
import 'package:towork/main.dart';
import 'package:towork/app/providers.dart';

void main() {
  testWidgets('desktop conversation actions align with the right edge', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 820);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ProviderScope(child: ToWorkApp()));
    await tester.pumpAndSettle();
    final page = find.byType(ChatPage);
    final action = find.descendant(
      of: page,
      matching: find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == '新建会话',
      ),
    );
    expect(
      tester.getRect(page).right - tester.getRect(action).right,
      closeTo(16, .1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'narrow phone supports large text and keeps sidebar action at right',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 740);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(const ProviderScope(child: ToWorkApp()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('内容由 AI 生成'), findsNothing);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ToWorkApp)),
      );
      container.read(currentSessionIdProvider.notifier).state = container
          .read(sessionListProvider)
          .first
          .id;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('选择模型'), findsOneWidget);
      await tester.tap(find.byTooltip('打开菜单'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final sidebar = tester.getRect(find.byType(ChatDrawer));
      final action = tester.getRect(
        find.byKey(const ValueKey('sidebar-new-conversation')),
      );
      expect(sidebar.right - action.right, closeTo(14, 0.1));
      expect(action.width, greaterThanOrEqualTo(44));
      expect(find.byTooltip('关闭菜单'), findsNothing);
      expect(find.byKey(const ValueKey('sidebar-search')), findsOneWidget);
    },
  );
}
