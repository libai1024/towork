import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/app/workspace_state.dart';
import 'package:towork/core/widgets/mobile_sidebar_reveal.dart';
import 'package:towork/features/chat/widgets/chat_drawer.dart';
import 'package:towork/main.dart';
import 'package:towork/theme/app_theme.dart';

const surface = ValueKey('mobile-reveal-surface');

Future<void> mount(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const ProviderScope(child: ToWorkApp()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('外部交接选择会话时收起侧栏并显示该会话', (tester) async {
    await mount(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ToWorkApp)),
    );
    await tester.tap(find.byTooltip('打开菜单'));
    await tester.pumpAndSettle();
    final session = container.read(sessionListProvider).first;
    container.read(currentSessionIdProvider.notifier).state = session.id;
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(surface)).left, 0);
    expect(find.byType(ChatDrawer), findsNothing);
    expect(container.read(currentSessionIdProvider), session.id);
  });

  testWidgets('手机侧栏的六个入口与桌面排列一致', (tester) async {
    await mount(tester);
    await tester.tap(find.byTooltip('打开菜单'));
    await tester.pumpAndSettle();
    final grid = find.byKey(const ValueKey('sidebar-feature-grid'));
    final points = [
      for (final label in ['待办', '日程', '报告', '数据', '记忆', '设置'])
        tester.getCenter(find.descendant(of: grid, matching: find.text(label))),
    ];
    expect(points[0].dy, points[1].dy);
    expect(points[1].dy, points[2].dy);
    expect(points[3].dy, greaterThan(points[0].dy));
    expect(points[3].dy, points[4].dy);
    expect(points[4].dy, points[5].dy);
    for (var column = 0; column < 3; column++) {
      expect(points[column].dx, points[column + 3].dx);
    }
  });

  testWidgets('浮层下方可滚动，首尾行留出空间，高对比度切换为实底', (tester) async {
    await mount(tester);
    await tester.tap(find.byTooltip('打开菜单'));
    await tester.pumpAndSettle();
    final list = find.byKey(const ValueKey('sidebar-list'));
    final profile = find.byKey(const ValueKey('sidebar-profile'));
    final search = find.byKey(const ValueKey('sidebar-search'));
    final glass = find.byWidgetPredicate(
      (w) => w is BackdropFilter && w.enabled,
    );
    final top = tester.getRect(profile);
    final bottom = tester.getRect(search);
    final viewport = tester.getRect(list);
    expect(viewport.contains(top.center), isTrue);
    expect(viewport.contains(bottom.center), isTrue);
    expect(tester.getTopLeft(find.text('待办')).dy, greaterThan(top.bottom));
    expect(find.descendant(of: profile, matching: glass), findsOneWidget);
    expect(find.descendant(of: search, matching: glass), findsOneWidget);
    final scroll = tester
        .state<ScrollableState>(
          find.descendant(of: list, matching: find.byType(Scrollable)).first,
        )
        .position;
    scroll.jumpTo(scroll.maxScrollExtent);
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(list));
    final last = find.text(container.read(sessionListProvider).last.title);
    expect(tester.getRect(last).bottom, lessThan(bottom.top));
    expect(last.hitTestable(), findsOneWidget);
    expect(tester.getRect(profile), top);
    expect(tester.getRect(search), bottom);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(highContrast: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpAndSettle();
    expect(find.descendant(of: profile, matching: glass), findsNothing);
    expect(find.descendant(of: search, matching: glass), findsNothing);
    await tester.tap(find.byKey(const ValueKey('sidebar-search')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('workspace-search-controls')),
      findsOneWidget,
    );
  });

  testWidgets('left quarter starts a reveal while the center does not', (
    tester,
  ) async {
    await mount(tester);
    expect(
      tester.getSize(find.byKey(const ValueKey('mobile-sidebar-edge'))).width,
      97.5,
    );
    await tester.dragFrom(const Offset(110, 350), const Offset(260, 0));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(surface)).left, 0);
    await tester.dragFrom(const Offset(90, 350), const Offset(280, 0));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(surface)).left, closeTo(331.5, .1));
    await tester.tapAt(const Offset(382, 180));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('打开菜单'));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(surface)).left, closeTo(331.5, .1));
  });

  testWidgets(
    'quarter gesture region preserves content taps and vertical scroll',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      var taps = 0;
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Material(
            child: MobileSidebarReveal(
              sidebar: const Text('菜单'),
              child: ListView(
                controller: scroll,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 90,
                      height: 60,
                      child: TextButton(
                        onPressed: () => taps++,
                        child: const Text('原按钮'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2000),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tapAt(const Offset(45, 30));
      expect(taps, 1);
      await tester.dragFrom(const Offset(75, 500), const Offset(0, -240));
      await tester.pumpAndSettle();
      expect(scroll.offset, greaterThan(100));
      expect(tester.getRect(find.byKey(surface)).left, 0);
    },
  );

  testWidgets('page slides at full width and preserves the draft when closed', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(find.byKey(const ValueKey('switch-to-keyboard')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('chat-text-input')),
      '保留这段草稿',
    );
    await tester.tap(find.byTooltip('打开菜单'));
    await tester.pumpAndSettle();
    final page = tester.getRect(find.byKey(surface));
    expect(page.left, closeTo(331.5, .1));
    expect(page.width, 390);
    expect(tester.getRect(find.byType(ChatDrawer)).left, 0);
    expect(
      tester.widget<ClipRSuperellipse>(find.byKey(surface)).borderRadius,
      BorderRadius.circular(36),
    );
    await tester.tapAt(const Offset(382, 180));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(surface)).left, 0);
    expect(find.text('保留这段草稿'), findsOneWidget);
    expect(find.byType(ChatDrawer), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edge drag follows the finger and the exposed page swipes shut', (
    tester,
  ) async {
    await mount(tester);
    final drag = await tester.startGesture(const Offset(8, 350));
    await drag.moveBy(const Offset(30, 0));
    await tester.pump();
    await drag.moveBy(const Offset(90, 0));
    await tester.pump();
    final intermediate = tester.getRect(find.byKey(surface)).left;
    expect(intermediate, greaterThan(50));
    expect(intermediate, lessThan(200));
    await drag.moveBy(const Offset(170, 0));
    await tester.pump(const Duration(milliseconds: 100));
    await drag.up();
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(surface)).left, closeTo(331.5, .1));
    await tester.dragFrom(const Offset(375, 350), const Offset(-290, 0));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(surface)).left, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'system back closes the sidebar and feature navigation remains valid',
    (tester) async {
      await mount(tester);
      await tester.tap(find.byTooltip('打开菜单'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(surface)).left, 0);
      await tester.tap(find.byTooltip('打开菜单'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('待办'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(surface)).left, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'resizing an open sidebar into desktop removes its local history',
    (tester) async {
      await mount(tester);
      await tester.tap(find.byTooltip('打开菜单'));
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(1280, 844);
      await tester.pumpAndSettle();
      expect(find.byType(MobileSidebarReveal), findsNothing);
      expect(find.byType(ChatDrawer), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reduced motion opens and closes without an animation delay', (
    tester,
  ) async {
    await mount(tester);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pump();
    await tester.tap(find.byTooltip('打开菜单'));
    await tester.pump();
    expect(tester.getRect(find.byKey(surface)).left, closeTo(331.5, .1));
    await tester.tapAt(const Offset(382, 180));
    await tester.pump();
    expect(tester.getRect(find.byKey(surface)).left, 0);
    expect(tester.takeException(), isNull);
  });
}
