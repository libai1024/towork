import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart'
    show CustomSemanticsAction, SemanticsAction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/core/widgets/app_pressable.dart';
import 'package:towork/features/categories/categories_page.dart';
import 'package:towork/core/categories/widgets/category_edit_sheet.dart';
import 'package:towork/main.dart';
import 'package:towork/theme/app_theme.dart';

void _phone(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
}

Future<ProviderContainer> _categories(WidgetTester tester) async {
  _phone(tester);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(theme: AppTheme.light, home: const CategoriesPage()),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(CategoriesPage)));
}

void main() {
  testWidgets('cancel deletion keeps categories and tasks unchanged', (
    tester,
  ) async {
    final container = await _categories(tester);
    final categories = container.read(categoryListProvider);
    final todos = container.read(todoListProvider);
    await tester.tap(find.bySemanticsLabel('炒股 更多操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('待办与子分类一并删除'));
    await tester.pump();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(container.read(categoryListProvider), orderedEquals(categories));
    expect(container.read(todoListProvider), orderedEquals(todos));
    expect(find.text('删除「炒股」？'), findsNothing);
  });

  testWidgets('even an empty category can be kept by cancelling deletion', (
    tester,
  ) async {
    final container = await _categories(tester);
    final repo = container.read(categoryListProvider.notifier);
    final created = repo.createCategory(
      name: '空分类',
      color: const Color(0xFF456789),
      iconKey: 'folder',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('空分类 更多操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(find.text('删除「空分类」？'), findsOneWidget);
    expect(find.text('里面有。'), findsNothing);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(repo.byId(created.id), created);
  });

  testWidgets('category disclosure and more actions have full touch targets', (
    tester,
  ) async {
    await _categories(tester);
    for (final finder in [
      find.bySemanticsLabel('展开子分类').first,
      find.bySemanticsLabel('炒股 更多操作'),
    ]) {
      final bounds = tester.getRect(finder);
      expect(bounds.width, greaterThanOrEqualTo(44));
      expect(bounds.height, greaterThanOrEqualTo(44));
    }
    final arrow = tester.getRect(find.bySemanticsLabel('展开子分类').first);
    await tester.tapAt(arrow.topLeft + const Offset(2, 2));
    await tester.pumpAndSettle();
    expect(find.text('持仓'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing a category name preserves a custom stored color', (
    tester,
  ) async {
    final container = await _categories(tester);
    final repo = container.read(categoryListProvider.notifier);
    const customColor = Color(0xFF456789);
    repo.updateCategory('cat_family', color: customColor);
    await tester.pumpAndSettle();
    await tester.tap(find.text('家庭'));
    await tester.pumpAndSettle();
    expect(find.byType(CategoryEditSheet), findsOneWidget);
    await tester.enterText(find.byType(TextField), '家庭事务');
    await tester.tap(find.text('完  成'));
    await tester.pumpAndSettle();
    expect(repo.byId('cat_family')!.color, customColor);
    expect(repo.byId('cat_family')!.name, '家庭事务');
  });

  testWidgets(
    'sidebar shares cancellable delete and undo restores the category',
    (tester) async {
      _phone(tester);
      await tester.pumpWidget(const ProviderScope(child: ToWorkApp()));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ToWorkApp)),
      );
      final beforeCategories = container.read(categoryListProvider);
      final beforeTodos = container.read(todoListProvider);
      await tester.tap(find.byTooltip('打开菜单'));
      await tester.pumpAndSettle();
      final disclosure = tester.getRect(
        find.byWidgetPredicate(
          (widget) => widget is AppPressable && widget.semanticLabel == '收起分类',
        ),
      );
      expect(disclosure.height, greaterThanOrEqualTo(44));
      await tester.longPress(find.text('炒股'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('编辑炒股'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('删除此分类'));
      await tester.tap(find.text('删除此分类'));
      await tester.pumpAndSettle();
      expect(find.text('取消'), findsOneWidget);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(
        container.read(categoryListProvider),
        orderedEquals(beforeCategories),
      );
      expect(container.read(todoListProvider), orderedEquals(beforeTodos));

      await tester.tap(find.byTooltip('编辑炒股'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('删除此分类'));
      await tester.tap(find.text('删除此分类'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();
      expect(
        container.read(categoryListProvider.notifier).byId('cat_stock'),
        isNull,
      );
      final undo = tester.getRect(find.byKey(const ValueKey('toast-action')));
      await tester.tapAt(undo.topLeft + const Offset(2, 2));
      await tester.pumpAndSettle();
      expect(
        container.read(categoryListProvider),
        orderedEquals(beforeCategories),
      );
      expect(container.read(todoListProvider), orderedEquals(beforeTodos));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('sorting mode has an explicit entry and accessible moves', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(const ProviderScope(child: ToWorkApp()));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ToWorkApp)),
    );
    await tester.tap(find.byTooltip('打开菜单'));
    await tester.pumpAndSettle();

    // 显式入口：排序模式不再只靠长按分类名进入。
    expect(find.byTooltip('编辑炒股'), findsNothing);
    await tester.tap(find.byTooltip('分类排序'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('编辑炒股'), findsOneWidget, reason: '已进入排序模式');

    // 拖拽手柄对读屏暴露 上移/下移 自定义操作，无需完成拖拽手势。
    // 炒股是首个根分类：越界方向（上移）不提供。
    final semantics = tester.ensureSemantics();
    final handle = find.bySemanticsLabel('拖动排序炒股');
    expect(handle, findsOneWidget);
    var node = tester.getSemantics(handle);
    var data = node.getSemanticsData();
    var ids = data.customSemanticsActionIds ?? const <int>[];
    var labels = [
      for (final id in ids) CustomSemanticsAction.getAction(id)!.label,
    ];
    expect(labels, ['下移'], reason: '首项没有上移');

    int stockOrder() => container
        .read(categoryListProvider)
        .firstWhere((c) => c.id == 'cat_stock')
        .sortOrder;
    expect(stockOrder(), 0);
    node.owner!.performAction(
      node.id,
      SemanticsAction.customAction,
      ids[labels.indexOf('下移')],
    );
    await tester.pumpAndSettle();
    expect(stockOrder(), 1, reason: '下移与归档交换');

    // 移到中间后两个方向都可用；上移移回原位，仍走同一条落库链路。
    node = tester.getSemantics(handle);
    data = node.getSemanticsData();
    ids = data.customSemanticsActionIds ?? const <int>[];
    labels = [for (final id in ids) CustomSemanticsAction.getAction(id)!.label];
    expect(labels, containsAll(['上移', '下移']));
    node.owner!.performAction(
      node.id,
      SemanticsAction.customAction,
      ids[labels.indexOf('上移')],
    );
    await tester.pumpAndSettle();
    expect(stockOrder(), 0);
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });
}
