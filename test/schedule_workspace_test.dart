import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/app/workspace_clock.dart';
import 'package:towork/data/repositories/todo_repository.dart';
import 'package:towork/domain/models/models.dart';
import 'package:towork/core/todo/create_todo_sheet.dart';
import 'package:towork/features/visualization/view_models/schedule_overview.dart';
import 'package:towork/features/visualization/visualization_page.dart';
import 'package:towork/theme/app_theme.dart';

final now = DateTime(2026, 9, 23, 12);
Todo _task(
  String title,
  int? day, {
  TodoStatus status = TodoStatus.pending,
  String category = 'cat_stock_position',
}) => Todo(
  id: title,
  title: title,
  createdAt: now,
  status: status,
  categoryId: category,
  dueAt: day == null ? null : DateTime(2026, 9, day, 18),
);
final fixtures = [
  _task('今日持仓', 23),
  _task('明日持仓', 24),
  _task('今日完成', 23, status: TodoStatus.done),
  _task('取消事项', 23, status: TodoStatus.cancelled),
  _task('未定日期', null),
];

Future<ProviderContainer> _mount(
  WidgetTester tester, {
  Size size = const Size(375, 812),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        workspaceNowProvider.overrideWithValue(() => now),
        todoListProvider.overrideWith(
          (ref) => TodoRepository(initial: fixtures, clock: () => now),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const VisualizationPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(
    tester.element(find.byType(VisualizationPage)),
  );
}

Finder _date(int month, int day) =>
    find.bySemanticsLabel(RegExp('^2026年$month月$day日'));

void main() {
  test(
    'agenda excludes cancelled and undated tasks; scope and search share marks',
    () {
      const categories = [
        Category(id: 'cat_stock', name: '炒股', color: Colors.grey),
        Category(
          id: 'cat_stock_position',
          name: '持仓',
          color: Colors.grey,
          parentId: 'cat_stock',
        ),
      ];
      final overview = ScheduleOverview.from(
        todos: fixtures,
        categories: categories,
        day: now,
        now: now,
        search: '炒股',
        selectedRoots: {'cat_stock'},
      );
      expect(overview.total, 2);
      expect(overview.pending.single.title, '今日持仓');
      expect(overview.completed.single.title, '今日完成');
      expect(overview.dayCounts, {
        DateTime(2026, 9, 23): 2,
        DateTime(2026, 9, 24): 1,
      });
      final searched = ScheduleOverview.from(
        todos: fixtures,
        categories: categories,
        day: DateTime(2026, 9, 24),
        now: now,
        search: '明日',
      );
      expect(searched.total, 1);
      expect(searched.dayCounts.length, 1);
    },
  );

  testWidgets(
    '375px calendar selects a day, completes with undo and adds on that day',
    (tester) async {
      final container = await _mount(tester);
      expect(
        find.byKey(const ValueKey('schedule-stacked-layout')),
        findsOneWidget,
      );
      expect(find.text('2 项'), findsOneWidget);
      await tester.tap(_date(9, 24));
      await tester.pumpAndSettle();
      expect(find.text('9月24日 周四'), findsOneWidget);
      expect(find.text('今日持仓'), findsNothing);
      expect(find.text('明日持仓'), findsOneWidget);
      await tester.ensureVisible(find.bySemanticsLabel('完成待办：明日持仓'));
      await tester.tap(find.bySemanticsLabel('完成待办：明日持仓'));
      await tester.pumpAndSettle();
      expect(
        container.read(todoListProvider.notifier).byId('明日持仓')!.status,
        TodoStatus.done,
      );
      await tester.tap(find.text('撤销'));
      await tester.pumpAndSettle();
      expect(
        container.read(todoListProvider.notifier).byId('明日持仓')!.status,
        TodoStatus.pending,
      );

      await tester.tap(find.bySemanticsLabel('新建所选日待办'));
      await tester.pumpAndSettle();
      final editor = find.byType(CreateTodoSheet);
      expect(
        tester.widget<CreateTodoSheet>(editor).dueAt,
        DateTime(2026, 9, 24, 18),
      );
      await tester.enterText(
        find.byKey(const ValueKey('todo-create-title')),
        '按选定日创建',
      );
      await tester.pump();
      final create = find.byTooltip('创建');
      await tester.ensureVisible(create);
      await tester.tap(create);
      await tester.pumpAndSettle();
      final created = container
          .read(todoListProvider)
          .singleWhere((t) => t.title == '按选定日创建');
      expect(created.dueAt, DateTime(2026, 9, 24, 18));
      expect(find.text('按选定日创建'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'desktop agenda search, week mode and cross-month navigation remain linked',
    (tester) async {
      await _mount(tester, size: const Size(1100, 800));
      expect(
        find.byKey(const ValueKey('schedule-split-layout')),
        findsOneWidget,
      );
      final calendar = tester.getRect(
        find.byKey(const ValueKey('schedule-calendar-pane')),
      );
      final agenda = tester.getRect(
        find.byKey(const ValueKey('schedule-agenda-list')),
      );
      expect(calendar.right, lessThanOrEqualTo(agenda.left));
      await tester.enterText(find.byType(TextField), '明日');
      await tester.pump();
      expect(find.text('没有匹配的待办'), findsOneWidget);
      await tester.tap(_date(9, 24));
      await tester.pump();
      expect(find.text('明日持仓'), findsOneWidget);
      expect(find.text('1 项'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('清除搜索'));
      await tester.pump();
      await tester.tap(_date(9, 30));
      await tester.pump();
      await tester.tap(find.text('周'));
      await tester.pump();
      expect(find.bySemanticsLabel('下一周'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('下一周'));
      await tester.pump();
      expect(find.text('10月7日 周三'), findsOneWidget);
      expect(find.text('这一天没有待办'), findsOneWidget);
      await tester.tap(find.text('月'));
      await tester.pump();
      expect(find.bySemanticsLabel('下个月'), findsOneWidget);
      expect(find.text('2026 年 10 月'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
