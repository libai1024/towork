import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/core/widgets/app_toast.dart';
import 'package:towork/core/widgets/app_pressable.dart';
import 'package:towork/data/repositories/todo_repository.dart';
import 'package:towork/domain/chat/todo_panel.dart';
import 'package:towork/domain/models/models.dart';
import 'package:towork/features/chat/widgets/ai_todo_panel.dart';
import 'package:towork/features/chat/widgets/ai_todo_panel_item.dart';
import 'package:towork/features/chat/widgets/ai_todo_pagination.dart';
import 'package:towork/theme/app_theme.dart';

void main() {
  late TodoRepository todos;
  late ProviderContainer container;
  final now = DateTime(2026, 11, 17);
  TodoPanel panel({bool overview = false, int count = 7}) => TodoPanel(
    title: '今天优先处理的事项',
    asOfLocal: '2026-11-17T09:00+08:00',
    overview: overview,
    sections: [
      TodoPanelSection(
        title: '今日待办',
        todoIds: [for (var i = 0; i < 7; i++) 'todo-$i'],
        matchedCount: count,
      ),
      if (overview)
        TodoPanelSection(title: '紧急待办', todoIds: ['todo-1'], matchedCount: 1),
      if (overview)
        TodoPanelSection(title: '逾期待办', todoIds: [], matchedCount: 0),
    ],
  );
  setUp(() {
    todos = TodoRepository(
      initial: [
        for (var i = 0; i < 7; i++)
          Todo(
            id: 'todo-$i',
            title: '项目事项 $i',
            createdAt: now,
            dueAt: now.add(Duration(hours: i + 9)),
            priority: i == 1 ? TodoPriority.urgent : TodoPriority.none,
          ),
      ],
    );
    container = ProviderContainer(
      overrides: [todoListProvider.overrideWith((ref) => todos)],
    );
  });
  tearDown(() {
    AppToast.dismiss();
    container.dispose();
  });
  Future<void> mount(
    WidgetTester tester,
    TodoPanel value, {
    double scale = 1,
    bool dark = false,
    Future<void> Function(Todo)? toggle,
    ValueChanged<Todo>? edit,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 760);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: AiTodoPanel(
                    panel: value,
                    onToggleDone:
                        toggle ??
                        (todo) async {
                          todos.toggleDone(todo.id);
                        },
                    onEdit: edit ?? (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('five item pages edit, complete and restore live tasks', (
    tester,
  ) async {
    String? edited;
    await mount(tester, panel(), edit: (todo) => edited = todo.id);
    expect(find.text('项目事项 4'), findsOneWidget);
    expect(find.text('项目事项 5'), findsNothing);
    final height = tester
        .getSize(find.byKey(const ValueKey('ai-todo-panel')))
        .height;
    await tester.tap(find.bySemanticsLabel('下一页'));
    await tester.pumpAndSettle();
    expect(find.text('项目事项 6'), findsOneWidget);
    expect(find.text('项目事项 0'), findsNothing);
    expect(
      tester.getSize(find.byKey(const ValueKey('ai-todo-panel'))).height,
      lessThan(height),
    );
    await tester.tap(find.bySemanticsLabel('上一页'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('项目事项 1'));
    expect(edited, 'todo-1');
    await tester.tap(find.bySemanticsLabel('完成待办：项目事项 0'));
    await tester.pumpAndSettle();
    expect(todos.byId('todo-0')!.status, TodoStatus.done);
    expect(find.text('1/7 完成'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('恢复待办：项目事项 0'));
    await tester.pumpAndSettle();
    expect(todos.byId('todo-0')!.status, TodoStatus.pending);
  });

  testWidgets(
    'overview switches sections and large type stays within narrow width',
    (tester) async {
      await mount(tester, panel(overview: true), scale: 1.8, dark: true);
      expect(tester.takeException(), isNull);
      final rect = tester.getRect(find.byKey(const ValueKey('ai-todo-panel')));
      expect(rect.width, 296);
      final button = find.ancestor(
        of: find.text('紧急待办 1'),
        matching: find.byType(AppPressable),
      );
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
      final groups = tester.widget<Wrap>(
        find.ancestor(of: button, matching: find.byType(Wrap)),
      );
      expect(groups.spacing, 4);
      expect(groups.runSpacing, 0);
      final height = tester
          .getSize(find.byKey(const ValueKey('ai-todo-panel')))
          .height;
      await tester.tap(find.text('紧急待办 1'));
      await tester.pumpAndSettle();
      expect(find.text('项目事项 1'), findsOneWidget);
      expect(find.text('项目事项 0'), findsNothing);
      await tester.tap(find.text('逾期待办 0'));
      await tester.pumpAndSettle();
      expect(find.text('这个范围暂时没有待办'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('ai-todo-panel'))).height,
        height,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pending writes cannot repeat; failure leaves task usable', (
    tester,
  ) async {
    final pending = Completer<void>();
    var calls = 0;
    await mount(
      tester,
      panel(),
      toggle: (_) {
        calls++;
        return pending.future;
      },
    );
    await tester.tap(find.bySemanticsLabel('完成待办：项目事项 0'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('完成待办：项目事项 0'));
    await tester.pump();
    expect(calls, 1);
    pending.completeError(StateError('synthetic failure'));
    await tester.pumpAndSettle();
    expect(todos.byId('todo-0')!.status, TodoStatus.pending);
    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('完成待办：项目事项 0'), findsOneWidget);
  });

  testWidgets(
    'removed items and omitted matches are explained without ghost controls',
    (tester) async {
      await mount(tester, panel(count: 12));
      expect(find.textContaining('另有 5 项未展示'), findsOneWidget);
      for (var i = 0; i < 7; i++) {
        todos.removeById('todo-$i');
      }
      await tester.pumpAndSettle();
      expect(find.text('这份清单中的待办已移除'), findsOneWidget);
      expect(find.textContaining('7 项已移除'), findsOneWidget);
      expect(find.text('项目事项 0'), findsNothing);
    },
  );

  testWidgets('page selection and deletion clamp to a populated page', (
    tester,
  ) async {
    await mount(tester, panel());
    final selector = find.byKey(const ValueKey('todo-panel-page'));
    await tester.tap(selector);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2/2').last);
    await tester.pumpAndSettle();
    expect(find.text('项目事项 5'), findsOneWidget);
    todos.removeById('todo-5');
    todos.removeById('todo-6');
    await tester.pumpAndSettle();
    expect(find.byType(AiTodoPanelItem), findsNWidgets(5));
    expect(find.text('项目事项 0'), findsOneWidget);
    expect(find.byType(AiTodoPagination), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('category notices reserve equal height', (tester) async {
    await mount(tester, panel(overview: true, count: 200), scale: 1.8);
    final card = find.byKey(const ValueKey('ai-todo-panel'));
    final height = tester.getSize(card).height;
    await tester.tap(find.text('紧急待办 1'));
    await tester.pumpAndSettle();
    expect(tester.getSize(card).height, height);
    expect(find.text('已显示此范围的全部待办'), findsNothing);
    expect(find.byKey(const ValueKey('todo-panel-page')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 1.3, 1.8]) {
    testWidgets('single list has no reserved footer gaps at scale $scale', (
      tester,
    ) async {
      todos.insertRaw(
        Todo(
          id: 'todo-long',
          title: '下一页的长标题用于检查布局，当前页应保持紧凑。' * 8,
          createdAt: now,
        ),
      );
      await mount(
        tester,
        TodoPanel(
          title: '今日待办',
          asOfLocal: '2026-11-17T09:00+08:00',
          overview: false,
          sections: [
            TodoPanelSection(
              title: '今日待办',
              todoIds: [for (var i = 0; i < 7; i++) 'todo-$i', 'todo-long'],
              matchedCount: 8,
            ),
          ],
        ),
        scale: scale,
      );
      void expectTightFooter(String lastId) {
        expect(find.text('8 项'), findsNothing);
        final footer = tester.getRect(find.byType(AiTodoPagination));
        final last = tester.getRect(find.byKey(ValueKey('panel-todo-$lastId')));
        final card = tester.getRect(
          find.byKey(const ValueKey('ai-todo-panel')),
        );
        expect(footer.top, closeTo(last.bottom, .01));
        // Container includes the half-pixel border in its effective padding.
        expect(card.bottom - footer.bottom, closeTo(2.5, .01));
        final control = tester.getSize(
          find.byKey(const ValueKey('todo-panel-page')),
        );
        expect(control.height, scale == 1.8 ? 37 : 36);
        final page = tester
            .widget<DropdownButton<int>>(
              find.byKey(const ValueKey('todo-panel-page')),
            )
            .value!;
        expect(
          tester.getCenter(find.text('${page + 1}/2')).dy,
          closeTo(tester.getCenter(find.bySemanticsLabel('下一页')).dy, .01),
        );
        expect(tester.takeException(), isNull);
      }

      expectTightFooter('todo-4');
      if (scale == 1) {
        expect(tester.getSize(find.byType(AiTodoPagination)).height, 36);
      }
      final selector = tester.widget<DropdownButton<int>>(
        find.byKey(const ValueKey('todo-panel-page')),
      );
      selector.onChanged!(1);
      await tester.pumpAndSettle();
      expectTightFooter('todo-long');
    });

    testWidgets(
      '120 records keep five items and fixed height at scale $scale',
      (tester) async {
        for (var i = 7; i < 120; i++) {
          todos.insertRaw(
            Todo(
              id: 'todo-$i',
              title: i % 10 == 0
                  ? '检查长标题与放大字号的换行表现，并同步相关截图和待确认问题 $i'
                  : '项目事项 $i',
              createdAt: now,
              dueAt: now,
              priority: i.isEven ? TodoPriority.urgent : TodoPriority.none,
            ),
          );
        }
        await mount(
          tester,
          TodoPanel(
            title: '工作总览',
            asOfLocal: '2026-11-17T09:00+08:00',
            overview: true,
            sections: [
              TodoPanelSection(
                title: '今日待办',
                todoIds: [for (var i = 0; i < 120; i++) 'todo-$i'],
                matchedCount: 120,
              ),
              TodoPanelSection(
                title: '紧急待办',
                todoIds: ['todo-1'],
                matchedCount: 1,
              ),
              TodoPanelSection(title: '逾期待办', todoIds: [], matchedCount: 0),
            ],
          ),
          scale: scale,
          dark: true,
        );
        final card = find.byKey(const ValueKey('ai-todo-panel'));
        final height = tester.getSize(card).height;
        expect(find.byType(AiTodoPanelItem), findsNWidgets(5));
        if (scale == 1) expect(height, lessThan(600));
        final next = find.bySemanticsLabel('下一页');
        await tester.ensureVisible(next);
        await tester.tap(next);
        await tester.pumpAndSettle();
        expect(find.text('项目事项 5'), findsOneWidget);
        expect(tester.getSize(card).height, height);
        await tester.ensureVisible(find.text('紧急待办 1'));
        await tester.tap(find.text('紧急待办 1'));
        await tester.pumpAndSettle();
        expect(tester.getSize(card).height, height);
        await tester.ensureVisible(find.text('逾期待办 0'));
        await tester.tap(find.text('逾期待办 0'));
        await tester.pumpAndSettle();
        expect(tester.getSize(card).height, height);
        await tester.ensureVisible(find.text('今日待办 120'));
        await tester.tap(find.text('今日待办 120'));
        await tester.pumpAndSettle();
        expect(find.text('项目事项 5'), findsOneWidget);
        await tester.ensureVisible(next);
        await tester.tap(next);
        await tester.pumpAndSettle();
        expect(find.byType(AiTodoPanelItem), findsNWidgets(5));
        expect(tester.getSize(card).height, height);
        final selector = tester.widget<DropdownButton<int>>(
          find.byKey(const ValueKey('todo-panel-page')),
        );
        selector.onChanged!(23);
        await tester.pumpAndSettle();
        expect(tester.getSize(card).height, height);
        expect(find.text('项目事项 119'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
