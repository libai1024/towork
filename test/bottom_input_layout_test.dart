import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/core/todo/create_todo_sheet.dart';
import 'package:towork/core/widgets/app_pressable.dart';
import 'package:towork/core/widgets/workspace_nav_bar.dart';
import 'package:towork/domain/models/todo.dart';
import 'package:towork/features/data_tables/data_table_detail_page.dart';
import 'package:towork/features/settings/settings_page.dart';
import 'package:towork/features/todo/todo_list_page.dart';
import 'package:towork/theme/app_theme.dart';

Future<void> mount(WidgetTester tester, Widget page) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(theme: AppTheme.light, home: page),
    ),
  );
  await tester.pumpAndSettle();
}

Finder action(String label) => find.byWidgetPredicate(
  (w) => w is AppPressable && w.semanticLabel == label,
);

void main() {
  final pages = <String, Widget>{
    '搜索设置': const SettingsPage(),
    '搜索待办': const TodoListPage(),
    '搜索行': Consumer(
      builder: (context, ref, _) {
        final tables = ref.watch(dataTableProvider).tables;
        final repo = ref.read(dataTableProvider.notifier);
        final table = tables.firstWhere(
          (table) => repo.batchesOf(table.id).isEmpty,
        );
        return DataTableDetailPage(tableId: table.id);
      },
    ),
  };
  for (final entry in pages.entries) {
    testWidgets('${entry.key} follows the keyboard and stays tappable', (
      tester,
    ) async {
      await mount(tester, entry.value);
      final input = find.widgetWithText(TextField, entry.key);
      for (final keyboard in [0.0, 315.0, 0.0]) {
        tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
        await tester.pumpAndSettle();
        final gap = 844 - keyboard - tester.getBottomLeft(input).dy;
        expect(gap, inInclusiveRange(0, 36));
        expect(input.hitTestable(), findsOneWidget);
      }
      await tester.enterText(input, '无匹配');
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(WorkspaceSearchField),
          matching: action('清除搜索'),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(input).controller!.text, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('board bottom editor creates a task in the chosen column', (
    tester,
  ) async {
    await mount(tester, const TodoListPage());
    await tester.tap(find.byTooltip('切换到看板'));
    await tester.pumpAndSettle();
    await tester.tap(action('在进行中列新建'));
    await tester.pumpAndSettle();
    final sheet = find.byType(CreateTodoSheet);
    final input = find.byKey(const ValueKey('todo-create-title'));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    final date = find.byTooltip('截止日期');
    expect(tester.getBottomLeft(input).dy, lessThan(tester.getCenter(date).dy));
    expect(844 - 300 - tester.getBottomLeft(date).dy, inInclusiveRange(0, 340));
    await tester.enterText(input, '看板输入测试');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    final note = find.byKey(const ValueKey('todo-create-note'));
    expect(tester.widget<TextField>(note).focusNode!.hasFocus, isTrue);
    await tester.enterText(note, '在周会上确认');
    await tester.tap(find.byTooltip('创建'));
    await tester.pumpAndSettle();
    final state = ProviderScope.containerOf(
      tester.element(find.byType(TodoListPage)),
    );
    final created = state
        .read(todoListProvider)
        .singleWhere((todo) => todo.title == '看板输入测试');
    expect(created.status, TodoStatus.inProgress);
    expect(created.note, '在周会上确认');
    expect(sheet, findsNothing);
  });
}
