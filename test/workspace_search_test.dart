import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:towork/app/workspace_state.dart';
import 'package:towork/core/widgets/glass_surface.dart';
import 'package:towork/features/chat/widgets/workspace_search.dart';
import 'package:towork/core/todo/todo_detail_sheet.dart';
import 'package:towork/theme/app_theme.dart';

const _input = ValueKey('workspace-search-input');
const _surface = ValueKey('workspace-search-surface');

Future<(GoRouter, ProviderContainer)> _mount(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    initialLocation: '/other',
    routes: [
      ShellRoute(
        builder: (context, state, child) => child,
        routes: [
          for (final path in ['/', '/other'])
            GoRoute(
              path: path,
              builder: (context, state) => Scaffold(
                body: Center(
                  child: TextButton(
                    key: const ValueKey('open-search'),
                    onPressed: () => showWorkspaceSearch(context),
                    child: const Text('打开搜索'),
                  ),
                ),
              ),
            ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.byKey(const ValueKey('open-search'))),
  );
  await tester.tap(find.byKey(const ValueKey('open-search')));
  await tester.pumpAndSettle();
  return (router, container);
}

void main() {
  testWidgets('mobile history fills the screen without opening the keyboard', (
    tester,
  ) async {
    await _mount(tester);
    expect(tester.getSize(find.byKey(_surface)), const Size(390, 844));
    expect(find.text('历史会话'), findsOneWidget);
    expect(find.text('明天的工作台'), findsOneWidget);
    expect(find.text('已为你建好这条待办：发送季度报告给王总'), findsNothing);
    expect(tester.testTextInput.isVisible, isFalse);
    final controls = find.byKey(const ValueKey('workspace-search-controls'));
    expect(tester.getTopLeft(controls).dy, greaterThan(750));
    expect(
      find.descendant(of: controls, matching: find.byType(GlassSurface)),
      findsNWidgets(2),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('query filters titles and task notes, clear restores history', (
    tester,
  ) async {
    await _mount(tester);
    await tester.enterText(find.byKey(_input), '体检');
    await tester.pumpAndSettle();
    expect(find.text('妈妈的体检安排'), findsOneWidget);
    expect(find.byKey(const ValueKey('search-todo-t4')), findsOneWidget);
    expect(find.text('明天的工作台'), findsNothing);
    expect(find.text('待办'), findsOneWidget);
    await tester.enterText(find.byKey(_input), '微信缴费');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('search-todo-t8')), findsOneWidget);
    await tester.enterText(find.byKey(_input), 'zznonexistent');
    await tester.pumpAndSettle();
    expect(find.text('无搜索结果'), findsOneWidget);
    expect(find.text('去对话页'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('workspace-search-clear')));
    await tester.pumpAndSettle();
    expect(find.text('明天的工作台'), findsOneWidget);
    expect(find.text('无搜索结果'), findsNothing);
    expect(find.text('待办'), findsNothing);
    expect(tester.widget<TextField>(find.byKey(_input)).controller!.text, '');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'session selection opens the exact conversation across shell routes',
    (tester) async {
      final (router, container) = await _mount(tester);
      await tester.enterText(find.byKey(_input), '体检');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('search-session-s6')));
      await tester.pumpAndSettle();
      expect(container.read(currentSessionIdProvider), 's6');
      expect(router.routeInformationProvider.value.uri.path, '/');
      expect(find.byKey(_surface), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'task selection opens its editable detail and preserves the query',
    (tester) async {
      await _mount(tester);
      await tester.enterText(find.byKey(_input), '体检');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('search-todo-t4')));
      await tester.pumpAndSettle();
      final detail = tester.widget<TodoDetailSheet>(
        find.byType(TodoDetailSheet),
      );
      expect(detail.todoId, 't4');
      expect(find.widgetWithText(TextField, '给妈妈回电话，问体检报告取没取'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(TodoDetailSheet),
          matching: find.bySemanticsLabel('关闭'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TodoDetailSheet), findsNothing);
      expect(
        tester.widget<TextField>(find.byKey(_input)).controller!.text,
        '体检',
      );
      expect(find.byKey(const ValueKey('search-todo-t4')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'no-result empty state offers an exit action back to the conversation page',
    (tester) async {
      final (router, _) = await _mount(tester);
      await tester.enterText(find.byKey(_input), 'zznonexistent');
      await tester.pumpAndSettle();
      expect(find.text('无搜索结果'), findsOneWidget);
      await tester.tap(find.text('去对话页'));
      await tester.pumpAndSettle();
      expect(find.byKey(_surface), findsNothing);
      expect(router.routeInformationProvider.value.uri.path, '/');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('bottom controls stay above the mobile keyboard', (tester) async {
    await _mount(tester, size: const Size(360, 780));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    final controls = tester.getRect(
      find.byKey(const ValueKey('workspace-search-controls')),
    );
    expect(controls.bottom, lessThanOrEqualTo(480));
    expect(controls.height, 48);
    expect(controls.width, 332);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'desktop uses a large workspace overlay and Escape dismisses it',
    (tester) async {
      final (router, _) = await _mount(tester, size: const Size(1280, 840));
      expect(tester.getSize(find.byKey(_surface)), const Size(920, 720));
      expect(
        tester.widget<TextField>(find.byKey(_input)).focusNode!.hasFocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(_surface), findsNothing);
      expect(router.routeInformationProvider.value.uri.path, '/other');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('separate close control dismisses without changing the route', (
    tester,
  ) async {
    final (router, _) = await _mount(tester);
    await tester.tap(find.byKey(const ValueKey('workspace-search-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(_surface), findsNothing);
    expect(router.routeInformationProvider.value.uri.path, '/other');
    expect(tester.takeException(), isNull);
  });
}
