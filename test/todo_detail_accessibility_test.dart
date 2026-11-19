import 'package:towork/data/repositories/todo_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/app/workspace_ui_commands.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';
import 'package:towork/core/widgets/app_pressable.dart';
import 'package:towork/domain/models/models.dart';
import 'package:towork/core/todo/todo_detail_sheet.dart';
import 'package:towork/theme/app_colors.dart';
import 'package:towork/theme/app_theme.dart';

class _FailRepeatCommands extends WorkspaceUiCommands {
  _FailRepeatCommands(super.todos, super.categories);
  @override
  Future<void> updateTodo(Todo todo) async {
    throw const WorkspaceFailure(WorkspaceFailureCode.storageUnavailable);
  }
}

const _id = 'detail-a11y';

Finder _action(String label) => find.byWidgetPredicate(
  (widget) => widget is AppPressable && widget.semanticLabel == label,
);

Finder _field(String label) => find.byWidgetPredicate(
  (widget) =>
      widget is AppPressable &&
      (widget.semanticLabel?.startsWith('$label，') ?? false),
);

Future<ProviderContainer> _open(
  WidgetTester tester, {
  bool dark = false,
  double scale = 2,
  bool failRepeat = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 780);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final todos = TodoRepository(initial: []);
  final container = ProviderContainer(
    overrides: [
      todoListProvider.overrideWith((ref) => todos),
      if (failRepeat)
        workspaceUiCommandsProvider.overrideWith(
          (ref) => _FailRepeatCommands(
            ref.watch(todoListProvider.notifier),
            ref.watch(categoryListProvider.notifier),
          ),
        ),
    ],
  );
  addTearDown(container.dispose);
  final now = DateTime.now();
  todos.insertRaw(
    Todo(
      id: _id,
      title: '整理项目资料并核对附件',
      source: TodoSource.ai,
      priority: TodoPriority.urgent,
      dueAt: now.add(const Duration(hours: 1)),
      createdAt: now,
    ),
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showTodoDetailSheet(context, _id, onDeleted: (_) {}),
              child: const Text('打开详情'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('打开详情'));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return container;
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets(
    'detail source, urgency and countdown are neutral until overdue',
    (tester) async {
      final container = await _open(tester);
      final colors = AppColors.light;
      expect(
        tester.widget<Text>(find.text('AI')).style!.color,
        colors.labelSecondary,
      );
      expect(
        tester.widget<Text>(find.text('紧急')).style!.color,
        colors.labelPrimary,
      );
      expect(
        tester.widget<Text>(find.textContaining('还剩').first).style!.color,
        colors.labelSecondary,
      );
      await tester.scrollUntilVisible(
        find.text('原始对话已删除'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        _field('截止'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      final store = container.read(todoListProvider.notifier);
      final overdue = store
          .byId(_id)!
          .copyWith(dueAt: DateTime.now().subtract(const Duration(hours: 2)));
      await container.read(workspaceUiCommandsProvider).updateTodo(overdue);
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.textContaining('已逾期').first).style!.color,
        colors.overdueForeground,
      );
      await container
          .read(workspaceUiCommandsProvider)
          .updateTodo(overdue.copyWith(status: TodoStatus.done));
      await tester.pumpAndSettle();
      expect(find.textContaining('已逾期'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'narrow large-text dark calendar keeps 44px cells and readable selection',
    (tester) async {
      final container = await _open(tester, dark: true);
      await _tapVisible(tester, _field('截止'));
      await _tapVisible(tester, find.text('选日期…'));
      final calendarCells = find.byWidgetPredicate(
        (widget) =>
            widget is AppPressable &&
            RegExp(r'^\d{4}年\d{1,2}月\d{1,2}日$')
                .hasMatch(widget.semanticLabel ?? ''),
      );
      expect(calendarCells.evaluate().length, greaterThanOrEqualTo(28));
      for (final cell in calendarCells.evaluate()) {
        final rect = tester.getRect(find.byWidget(cell.widget));
        expect(rect.width, greaterThanOrEqualTo(44));
        expect(rect.height, greaterThanOrEqualTo(44));
      }
      expect(tester.getSize(_action('下个月')), const Size(44, 44));
      final now = DateTime.now();
      final first = _action('${now.year}年${now.month}月1日');
      await _tapVisible(tester, first);
      expect(
        container.read(todoListProvider.notifier).byId(_id)!.dueAt!.day,
        1,
      );
      final number = tester.widget<Text>(
        find.descendant(of: first, matching: find.text('1')),
      );
      expect(number.style!.color, AppColors.dark.onBrand);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('repeat editor wraps at 2x and stepper stays fully tappable', (
    tester,
  ) async {
    final container = await _open(tester);
    await _tapVisible(tester, _field('重复'));
    final increase = _action('增加重复间隔');
    await tester.ensureVisible(increase);
    await tester.pumpAndSettle();
    expect(tester.getSize(increase), const Size(44, 44));
    final rect = tester.getRect(increase);
    await tester.tapAt(rect.topLeft + const Offset(3, 3));
    await tester.pumpAndSettle();
    expect(
      container.read(todoListProvider.notifier).byId(_id)!.repeatRule,
      isNull,
    );
    await _tapVisible(tester, find.text('保存重复设置'));
    expect(
      container.read(todoListProvider.notifier).byId(_id)!.repeatRule,
      contains('INTERVAL=2'),
    );
    expect(tester.takeException(), isNull);
    await _tapVisible(tester, find.text('每月'));
    await _tapVisible(tester, _action('增加每月日期'));
    await _tapVisible(tester, find.text('保存重复设置'));
    expect(
      container.read(todoListProvider.notifier).byId(_id)!.repeatRule,
      contains('BYMONTHDAY=2'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'failed repeat save restores controls and leaves committed rule unchanged',
    (tester) async {
      final container = await _open(tester, scale: 1, failRepeat: true);
      await _tapVisible(tester, _field('重复'));
      await _tapVisible(tester, find.text('每月'));
      await _tapVisible(tester, find.text('保存重复设置'));
      expect(
        container.read(todoListProvider.notifier).byId(_id)!.repeatRule,
        isNull,
      );
      expect(
        container.read(todoListProvider.notifier).byId(_id)!.repeatTimezone,
        isNull,
      );
      expect(find.textContaining('摘要：每周'), findsOneWidget);
      expect(find.text('保存失败，原数据已保留，请重试'), findsOneWidget);
    },
  );

  testWidgets('custom reminder layout wraps and saves the chosen offset', (
    tester,
  ) async {
    final container = await _open(tester);
    await _tapVisible(tester, _field('提醒'));
    await _tapVisible(tester, _action('添加提醒'));
    await _tapVisible(tester, _action('增加提醒提前量'));
    expect(tester.getSize(_action('增加提醒提前量')), const Size(44, 44));
    await _tapVisible(tester, _action('添加'));
    final rules = container
        .read(todoListProvider.notifier)
        .byId(_id)!
        .remindRules;
    expect(rules.single.offsetMinutes, 31);
    expect(tester.takeException(), isNull);
  });
}
