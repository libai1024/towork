import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/shell/router.dart';
import 'package:towork/app/routes.dart';
import 'package:towork/app/workspace_clock.dart';
import 'package:towork/core/widgets/app_pressable.dart';
import 'package:towork/features/todo/todo_list_page.dart';
import 'package:towork/core/widgets/glass_surface.dart';
import 'package:towork/data/repositories/todo_repository.dart';
import 'package:towork/domain/models/models.dart';
import 'package:towork/core/todo/todo_utils.dart';
import 'package:towork/features/todo/widgets/todo_quick_filter_bar.dart';
import 'package:towork/main.dart';
import 'package:towork/theme/app_theme.dart';

Finder filterButton(TodoQuickFilter filter) => find.byWidgetPredicate(
  (widget) =>
      widget is AppPressable &&
      (widget.semanticLabel?.startsWith('按${filter.label}过滤') ?? false),
);

void main() {
  testWidgets(
    'todos first-level page drops the desktop back-to-home control, keeps it on mobile',
    (tester) async {
      Finder backHome() => find.byWidgetPredicate(
        (widget) => widget is Tooltip && widget.message == '返回对话首页',
      );
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 840);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const ProviderScope(child: ToWorkApp()));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ToWorkApp)),
      );
      container.read(appRouterProvider).go(AppRoutes.todos);
      await tester.pumpAndSettle();
      // 桌面端一级目的地由常驻侧栏导航，不再放返回对话首页箭头。
      expect(backHome(), findsNothing);
      expect(
        find.descendant(
          of: find.byType(TodoListPage),
          matching: find.text('待办'),
        ),
        findsOneWidget,
      );

      // 同一一级路由在移动端全屏页仍保留返回。
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      expect(backHome(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('overview header states pending and overdue counts separately', (
    tester,
  ) async {
    // 复刻 03 号审阅 P2 场景：逾期 1 条与当天 2 条并存时，
    // 头部「待完成」只计当天，逾期单独标注，不再出现"0 项待完成却挂着逾期"。
    final now = DateTime(2026, 9, 23, 12);
    Todo task(String title, DateTime? due) => Todo(
      id: title,
      title: title,
      createdAt: now,
      categoryId: 'cat_stock_position',
      status: TodoStatus.pending,
      dueAt: due,
    );
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workspaceNowProvider.overrideWithValue(() => now),
          todoListProvider.overrideWith(
            (ref) => TodoRepository(
              initial: [
                task('逾期一条', DateTime(2026, 9, 22, 18)),
                task('今天第一条', DateTime(2026, 9, 23, 18)),
                task('今天第二条', DateTime(2026, 9, 23, 20)),
              ],
              clock: () => now,
            ),
          ),
        ],
        child: const ToWorkApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('打开今日总览'));
    await tester.pumpAndSettle();
    expect(find.textContaining('待完成 2 项'), findsOneWidget);
    expect(find.textContaining(' 逾期 1 项'), findsOneWidget);
    expect(find.text('逾期'), findsOneWidget);
    expect(find.text('0 / 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact desktop track selects every filter with touch targets', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 600);
    addTearDown(tester.view.reset);
    var selected = TodoQuickFilter.all;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => TodoQuickFilterBar(
              selected: selected,
              counts: const {
                TodoQuickFilter.all: 27,
                TodoQuickFilter.overdue: 1,
              },
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(SingleChildScrollView)).width,
      lessThan(650),
    );
    // 单一玻璃材质：整个控件只有轨道一层 BackdropFilter，选中滑块是
    // 实色填充（不再叠一层 GlassSurface/渐变）。
    expect(
      find.descendant(
        of: find.byType(TodoQuickFilterBar),
        matching: find.byType(BackdropFilter),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(TodoQuickFilterBar),
        matching: find.byType(GlassSurface),
      ),
      findsNothing,
    );
    final semantics = tester.ensureSemantics();
    for (final filter in TodoQuickFilter.values) {
      final button = filterButton(filter);
      expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(selected, filter);
      expect(
        tester.getSemantics(button),
        matchesSemantics(
          label:
              '按${filter.label}过滤${filter == TodoQuickFilter.all
                  ? '，27 项'
                  : filter == TodoQuickFilter.overdue
                  ? '，1 项'
                  : '，0 项'}，已选中',
          isButton: true,
          isSelected: true,
          isInMutuallyExclusiveGroup: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasSelectedState: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
    }
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'large text and counts keep the selected filter visible on resize',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 600);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: TodoQuickFilterBar(
              selected: TodoQuickFilter.done,
              counts: {
                for (final filter in TodoQuickFilter.values) filter: 12890,
              },
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(320, 600);
      await tester.pumpAndSettle();
      final selected = tester.getRect(filterButton(TodoQuickFilter.done));
      expect(selected.left, greaterThanOrEqualTo(0));
      expect(selected.right, lessThanOrEqualTo(320));
      expect(tester.takeException(), isNull);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(1600, 0),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getRect(filterButton(TodoQuickFilter.all)).left,
        closeTo(2, .1),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('dark high contrast uses solid controls and reduced motion', (
    tester,
  ) async {
    var selected = TodoQuickFilter.all;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(highContrast: true, disableAnimations: true),
          child: child!,
        ),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => TodoQuickFilterBar(
              selected: selected,
              counts: const {},
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(filterButton(TodoQuickFilter.week));
    await tester.pump();
    expect(selected, TodoQuickFilter.week);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });
}
