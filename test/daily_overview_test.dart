import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/app/workspace_clock.dart';
import 'package:towork/data/repositories/todo_repository.dart';
import 'package:towork/domain/models/models.dart';
import 'package:towork/app/todo/daily_overview.dart';
import 'package:towork/core/todo/daily_overview_panel.dart';
import 'package:towork/main.dart';

final now = DateTime(2026, 9, 23, 12);
Todo task(
  String id,
  int? day, {
  String category = 'cat_stock_position',
  TodoStatus status = TodoStatus.pending,
}) => Todo(
  id: id,
  title: id,
  createdAt: now,
  categoryId: category,
  status: status,
  dueAt: day == null ? null : DateTime(2026, 9, day, 18),
);
final fixtures = [
  task('旧待办', 22),
  task('今天持仓', 23),
  task('今天交易', 23, category: 'cat_stock_plan'),
  task('明天持仓', 24),
  task('今天已完成', 23, status: TodoStatus.done),
  task('取消任务', 23, status: TodoStatus.cancelled),
  task('无截止', null),
];

Future<ProviderContainer> mount(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  List<Todo>? todos,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        workspaceNowProvider.overrideWithValue(() => now),
        todoListProvider.overrideWith(
          (ref) => TodoRepository(initial: todos ?? fixtures, clock: () => now),
        ),
      ],
      child: const ToWorkApp(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(ToWorkApp)));
}

void main() {
  test('day projection separates carryover, scopes children and excludes cancelled or undated', () {
    final today = DailyOverview.from(todos: fixtures, day: now, now: now);
    expect(today.overdue.map((t) => t.id), ['旧待办']);
    expect(today.pending.map((t) => t.id), ['今天持仓', '今天交易']);
    expect(today.total, 3);
    expect(today.progress, closeTo(1 / 3, .001));
    final tomorrow = DailyOverview.from(
      todos: fixtures,
      day: DateTime(2026, 9, 24),
      now: now,
    );
    expect(tomorrow.overdue, isEmpty);
    expect(tomorrow.pending.single.id, '明天持仓');
    final past = DailyOverview.from(
      todos: fixtures,
      day: DateTime(2026, 9, 22),
      now: now,
    );
    expect(past.pending.single.id, '旧待办');
    final child = DailyOverview.from(
      todos: fixtures,
      day: now,
      now: now,
      categoryIds: {'cat_stock_plan'},
    );
    expect(child.overdue, isEmpty);
    expect(child.total, 1);
    expect(child.pending.single.id, '今天交易');
  });

  testWidgets('right quarter mirrors reveal and back restores conversation', (
    tester,
  ) async {
    await mount(tester);
    await tester.dragFrom(const Offset(275, 350), const Offset(-260, 0));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const ValueKey('mobile-reveal-surface'))).left,
      0,
    );
    await tester.dragFrom(const Offset(310, 350), const Offset(-270, 0));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const ValueKey('mobile-reveal-surface'))).left,
      closeTo(-331.5, .1),
    );
    expect(find.byType(DailyOverviewPanel), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const ValueKey('mobile-reveal-surface'))).left,
      0,
    );
    await tester.tap(find.byTooltip('打开菜单'));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const ValueKey('mobile-reveal-surface'))).left,
      closeTo(331.5, .1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('category, date, completion and capture share repository state', (
    tester,
  ) async {
    final container = await mount(tester);
    await tester.tap(find.byTooltip('打开今日总览'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('overview-category-cat_stock')));
    await tester.pumpAndSettle();
    expect(find.text('今天交易'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('overview-category-cat_stock_position')),
      findsNothing,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('overview-category-rail')))
          .width,
      60,
    );
    expect(find.text('1 / 3'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('完成待办：今天持仓'));
    await tester.pumpAndSettle();
    expect(
      container.read(todoListProvider.notifier).byId('今天持仓')!.status,
      TodoStatus.done,
    );
    expect(find.text('2 / 3'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('toast-action')));
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('overview-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('24'));
    await tester.pumpAndSettle();
    expect(find.text('明天持仓'), findsOneWidget);
    expect(find.text('今天持仓'), findsNothing);
    expect(find.text('旧待办'), findsNothing);
    await tester.tap(find.byTooltip('新建待办'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('todo-create-title')),
      '日期分类继承',
    );
    await tester.pump();
    await tester.tap(find.byTooltip('创建'));
    await tester.pumpAndSettle();
    final created = container
        .read(todoListProvider)
        .singleWhere((t) => t.title == '日期分类继承');
    expect(created.categoryId, 'cat_stock');
    expect(created.dueAt, DateTime(2026, 9, 24, 18));
    expect(find.text('日期分类继承'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('corner add stays reachable while the last task clears it', (
    tester,
  ) async {
    await mount(
      tester,
      size: const Size(320, 740),
      todos: [for (var i = 0; i < 40; i++) task('待办 $i', 23)],
    );
    tester.view.padding = const FakeViewPadding(bottom: 20);
    await tester.tap(find.byTooltip('打开今日总览'));
    await tester.pumpAndSettle();
    final add = find.byTooltip('新建待办');
    final panel = find.byType(DailyOverviewPanel);
    final button = tester.getRect(add);
    expect(button.size, const Size.square(52));
    expect(tester.getRect(panel).right - button.right, 12);
    expect(tester.getRect(panel).bottom - button.bottom, 30);
    expect(find.descendant(of: add, matching: find.byType(Text)), findsNothing);
    final list = find.byKey(
      ValueKey('overview-list-${DateUtils.dateOnly(now)}-null'),
    );
    final last = find.descendant(of: list, matching: find.text('已完成'));
    await tester.dragUntilVisible(last, list, const Offset(0, -260));
    await tester.pumpAndSettle();
    expect(last.hitTestable(), findsOneWidget);
    expect(tester.getRect(last).bottom, lessThan(button.top));
    expect(tester.getRect(add), button);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('todo-create-title')), findsOneWidget);
  });

  testWidgets(
    'quick capture keeps the draft while choosing a calendar day above the keyboard',
    (tester) async {
      final container = await mount(tester, size: const Size(320, 740));
      await tester.tap(find.byTooltip('打开今日总览'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('新建待办'));
      await tester.pumpAndSettle();
      final draft = find.byKey(const ValueKey('todo-create-title'));
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.enterText(draft, '跟进预算');
      await tester.pumpAndSettle();
      final commit = find.byTooltip('创建');
      final dates = find.byTooltip('截止日期');
      expect(tester.getCenter(commit).dy, lessThan(tester.getCenter(draft).dy));
      expect(tester.getBottomLeft(dates).dy, lessThanOrEqualTo(740 - 280));
      await tester.tap(dates);
      await tester.pumpAndSettle();
      await tester.tap(find.text('选择日期').hitTestable());
      await tester.pumpAndSettle();
      final day = find.bySemanticsLabel(RegExp('2026年9月26日')).last;
      await tester.ensureVisible(day);
      await tester.tap(day);
      await tester.pumpAndSettle();
      expect(find.text('9月26日 18:00'), findsOneWidget);
      expect(tester.widget<TextField>(draft).controller!.text, '跟进预算');
      await tester.tap(commit.hitTestable());
      await tester.pumpAndSettle();
      final saved = container
          .read(todoListProvider)
          .singleWhere((t) => t.title == '跟进预算');
      expect(saved.dueAt, DateTime(2026, 9, 26, 18));
      expect(draft, findsNothing);
    },
  );

  testWidgets('narrow phone calendar and constrained desktop fit', (
    tester,
  ) async {
    await mount(tester, size: const Size(320, 740));
    await tester.tap(find.byTooltip('打开今日总览'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('overview-date')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('回到今天'));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(920, 800);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('打开今日总览'));
    await tester.pumpAndSettle();
    expect(find.byType(DailyOverviewPanel), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
