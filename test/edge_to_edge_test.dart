import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/features/chat/widgets/chat_drawer.dart';
import 'package:towork/main.dart';
import 'package:towork/theme/app_theme.dart';

void expectTransparentBars(Brightness icons) {
  final style = SystemChrome.latestStyle!;
  expect(style.statusBarColor, Colors.transparent);
  expect(style.systemNavigationBarColor, Colors.transparent);
  expect(style.systemNavigationBarDividerColor, Colors.transparent);
  expect(style.systemStatusBarContrastEnforced, false);
  expect(style.systemNavigationBarContrastEnforced, false);
  expect(style.statusBarIconBrightness, icons);
  expect(style.systemNavigationBarIconBrightness, icons);
}

void main() {
  testWidgets(
    'cutout and gesture insets protect controls, not page backgrounds',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.viewPadding = const FakeViewPadding(top: 54, bottom: 34);
      tester.view.padding = const FakeViewPadding(top: 54, bottom: 34);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const ProviderScope(child: ToWorkApp()));
      await tester.pumpAndSettle();

      final page = find.byKey(const ValueKey('mobile-reveal-surface'));
      expect(tester.getRect(page), const Rect.fromLTWH(0, 0, 390, 844));
      expect(
        tester.getTopLeft(find.byTooltip('打开菜单')).dy,
        greaterThanOrEqualTo(54),
      );
      expect(
        tester.getBottomRight(find.byKey(const ValueKey('chat-composer'))).dy,
        lessThanOrEqualTo(810),
      );
      expectTransparentBars(Brightness.dark);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ToWorkApp)),
      );
      container.read(themeModeProvider.notifier).state = ThemeMode.dark;
      await tester.pumpAndSettle();
      expectTransparentBars(Brightness.light);

      await tester.tap(find.byTooltip('打开菜单'));
      await tester.pumpAndSettle();
      final sidebar = tester.getRect(find.byType(ChatDrawer));
      expect(sidebar.top, 0);
      expect(sidebar.bottom, 844);
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('sidebar-new-conversation')))
            .dy,
        greaterThanOrEqualTo(54),
      );
      expectTransparentBars(Brightness.light);

      await tester.tap(find.byKey(const ValueKey('sidebar-search')));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(const ValueKey('workspace-search-surface'))),
        const Rect.fromLTWH(0, 0, 390, 844),
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      tester.view.padding = const FakeViewPadding(top: 54);
      await tester.pumpAndSettle();
      expect(
        tester
            .getBottomRight(
              find.byKey(const ValueKey('workspace-search-controls')),
            )
            .dy,
        lessThanOrEqualTo(544),
      );
      tester.view.viewInsets = const FakeViewPadding();
      tester.view.padding = const FakeViewPadding(top: 54, bottom: 34);
      await tester.pumpAndSettle();
      expectTransparentBars(Brightness.light);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Material app bars preserve transparent bars in both themes', (
    tester,
  ) async {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: Scaffold(appBar: AppBar(title: const Text('业务页面'))),
        ),
      );
      await tester.pumpAndSettle();
      expectTransparentBars(
        mode == ThemeMode.dark ? Brightness.light : Brightness.dark,
      );
    }
  });
}
