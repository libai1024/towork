import 'package:towork/domain/models/todo.dart';
import 'package:towork/app/todo/async_todo_commands.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/core/widgets/workspace_scope_rail.dart';
import 'package:towork/core/categories/widgets/category_edit_sheet.dart';
import 'package:towork/features/todo/todo_list_page.dart';
import 'package:towork/core/todo/create_todo_sheet.dart';
import 'package:towork/core/todo/todo_item.dart';
import 'package:towork/theme/app_theme.dart';

Future<ProviderContainer> mount(WidgetTester tester, {double scale = 1}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(375, 812);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const TodoListPage(categoryId: 'cat_stock'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(TodoListPage)));
}

void main() {
  testWidgets('select all excludes collapsed completed tasks', (tester) async {
    final container = await mount(tester);
    final repository = container.read(todoListProvider.notifier);
    final closed = await container
        .read(asyncTodoCommandsProvider)
        .create(
          title: '已完成保留项',
          categoryId: 'cat_stock',
          status: TodoStatus.done,
        );
    await tester.pumpAndSettle();
    final expected = container.read(activeTodoCountProvider('cat_stock'));
    expect(find.text('已完成保留项'), findsNothing);
    await tester.longPress(find.byType(TodoListItem).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('全选'));
    await tester.pumpAndSettle();
    expect(find.text('已选 $expected 项'), findsOneWidget);
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(find.text('删除 $expected 条待办？'), findsOneWidget);
    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();
    expect(repository.byId(closed.id), isNotNull);
    expect(container.read(activeTodoCountProvider('cat_stock')), 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('archived type is not inherited by a new task', (tester) async {
    final container = await mount(tester);
    await tester.tap(find.text('持仓').first);
    await tester.pumpAndSettle();
    container
        .read(categoryListProvider.notifier)
        .setArchived('cat_stock_position', true);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('新建待办'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<CreateTodoSheet>(find.byType(CreateTodoSheet)).categoryId,
      'cat_stock',
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('category scope composes with search and completes with undo', (
    tester,
  ) async {
    final container = await mount(tester);
    expect(find.text('分类：炒股'), findsOneWidget);
    expect(tester.getSize(find.byType(WorkspaceScopeRail)).width, 375);
    await tester.tap(find.text('持仓').first);
    await tester.pumpAndSettle();
    final visible = tester
        .widgetList<TodoListItem>(find.byType(TodoListItem))
        .toList();
    expect(visible, isNotEmpty);
    expect(
      visible.every((item) => item.todo.categoryId == 'cat_stock_position'),
      isTrue,
    );
    final todo = visible.first.todo;
    await tester.enterText(find.byType(TextField), todo.title);
    await tester.pumpAndSettle();
    expect(find.byType(TodoListItem), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('完成待办：${todo.title}'));
    await tester.pumpAndSettle();
    expect(
      container.read(todoListProvider.notifier).byId(todo.id)!.isActive,
      isFalse,
    );
    await tester.tap(find.byKey(const ValueKey('toast-action')));
    await tester.pumpAndSettle();
    expect(
      container.read(todoListProvider.notifier).byId(todo.id)!.isActive,
      isTrue,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('new type is a real subcategory and new todo inherits it', (
    tester,
  ) async {
    final container = await mount(tester);
    await tester.tap(find.byTooltip('新增类型'));
    await tester.pumpAndSettle();
    expect(find.byType(CategoryEditSheet), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byType(CategoryEditSheet),
        matching: find.byType(TextField),
      ),
      '行业研究',
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('完  成'));
    await tester.tap(find.text('完  成'));
    await tester.pumpAndSettle();
    final category = container
        .read(categoryListProvider)
        .singleWhere((c) => c.name == '行业研究');
    expect(category.parentId, 'cat_stock');
    expect(
      tester
          .widget<WorkspaceScopeRail>(find.byType(WorkspaceScopeRail))
          .selectedId,
      category.id,
    );
    await tester.tap(find.byTooltip('新建待办'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(CreateTodoSheet),
        matching: find.byKey(const ValueKey('todo-create-title')),
      ),
      '整理研究资料',
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('创建'));
    await tester.tap(find.text('创建'));
    await tester.pumpAndSettle();
    final todo = container
        .read(todoListProvider)
        .singleWhere((t) => t.title == '整理研究资料');
    expect(todo.categoryId, category.id);
    expect(find.text('整理研究资料'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('compact category index remains usable with enlarged text', (
    tester,
  ) async {
    await mount(tester, scale: 1.6);
    await tester.tap(find.text('交易计划').first);
    await tester.pumpAndSettle();
    expect(find.text('分类：炒股'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
