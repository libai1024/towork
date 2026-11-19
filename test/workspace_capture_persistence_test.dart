import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/local_workspace_session.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';
import 'package:towork/core/todo/create_todo_sheet.dart';
import 'package:towork/core/widgets/app_sheet.dart';
import 'package:towork/core/todo/todo_detail_sheet.dart';
import 'package:towork/core/widgets/app_pressable.dart';
import 'package:towork/theme/app_theme.dart';

class DelayedWorkspaceStore implements WorkspaceCommandStore {
  DelayedWorkspaceStore(this.delegate);
  final WorkspaceCommandStore delegate;
  Completer<void> gate = Completer<void>();
  Completer<void> settled = Completer<void>();
  bool fail = false;
  final List<String> operationIds = [];

  @override
  Future<WorkspaceSnapshot> load() => delegate.load();
  @override
  Stream<WorkspaceSnapshot> watch() => const Stream.empty();
  @override
  Future<WorkspaceReceipt> execute(WorkspaceCommand command) async {
    operationIds.add(command.operationId);
    try {
      await gate.future;
      if (fail) {
        throw const WorkspaceFailure(WorkspaceFailureCode.storageUnavailable);
      }
      return await delegate.execute(command);
    } finally {
      settled.complete();
    }
  }

  @override
  Future<WorkspaceReceipt> undo(
    String changesetId, {
    required String operationId,
  }) => delegate.undo(changesetId, operationId: operationId);
}

Future<void> releaseWrite(
  WidgetTester tester,
  DelayedWorkspaceStore store,
) async {
  store.gate.complete();
  for (
    var attempt = 0;
    attempt < 100 && !store.settled.isCompleted;
    attempt++
  ) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
  }
  expect(
    store.settled.isCompleted,
    isTrue,
    reason: 'SQLite write should settle within 2 seconds',
  );
  await tester.pump();
}

void main() {
  testWidgets('capture waits for disk, retains failed input and retries once', (
    tester,
  ) async {
    late Directory directory;
    late AppDatabase db;
    late DelayedWorkspaceStore store;
    late LocalWorkspaceSession session;
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp('capture-widget');
      db = AppDatabase.background(File('${directory.path}/db.sqlite'));
      store = DelayedWorkspaceStore(SqliteWorkspaceCommandStore(db));
      session = LocalWorkspaceSession(store, await store.load());
    });
    final container = ProviderContainer();
    container.read(localWorkspaceSessionProvider.notifier).state = session;
    // Register ownership of both projections before teardown.
    container.read(todoListProvider);
    container.read(categoryListProvider);
    try {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => AppSheet.show<void>(
                    context,
                    child: const CreateTodoSheet(),
                  ),
                  child: const Text('打开记录'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('打开记录'));
      await tester.pumpAndSettle();
      final input = find.byKey(const ValueKey('todo-create-title'));
      await tester.enterText(input, '本地持久化验证');
      await tester.enterText(
        find.byKey(const ValueKey('todo-create-note')),
        '带预算明细',
      );
      Future<void> choose(String field, String value) async {
        final row = find.byTooltip(field);
        await tester.ensureVisible(row);
        await tester.tap(row);
        await tester.pumpAndSettle();
        await tester.tap(find.text(value).hitTestable().last);
        await tester.pumpAndSettle();
      }

      await choose('截止日期', '明天');
      await choose('优先级', '紧急');
      await choose('提醒', '提前 15 分钟');
      await tester.pump();
      await tester.tap(find.byTooltip('创建'));
      await tester.pump();
      expect(find.bySemanticsLabel(RegExp('保存中')), findsOneWidget);
      expect(session.todos.snapshot, isEmpty);
      expect(store.operationIds, hasLength(1));
      // The button and input cannot submit or mutate a second draft in flight.
      expect(tester.widget<TextField>(input).enabled, isFalse);
      expect(
        tester
            .widget<AppPressable>(
              find.descendant(
                of: find.byTooltip('创建'),
                matching: find.byType(AppPressable),
              ),
            )
            .onTap,
        isNull,
      );
      store.fail = true;
      await releaseWrite(tester, store);
      await tester.pumpAndSettle();
      expect(find.text('保存失败，原数据已保留，请重试'), findsOneWidget);
      expect(tester.widget<TextField>(input).controller!.text, '本地持久化验证');
      expect(session.todos.snapshot, isEmpty);
      store.fail = false;
      store.gate = Completer<void>();
      store.settled = Completer<void>();
      await tester.tap(find.byTooltip('创建'));
      await tester.pump();
      await releaseWrite(tester, store);
      await tester.pumpAndSettle();
      expect(input, findsNothing);
      expect(session.todos.snapshot.single.title, '本地持久化验证');
      expect(store.operationIds, hasLength(2));
      expect(store.operationIds.toSet(), hasLength(1));
      await tester.runAsync(() async {
        final data = (await store.load()).todos.single.data;
        expect(data['title'], '本地持久化验证');
        expect(data['note'], '带预算明细');
        expect(data['priority'], 'urgent');
        expect((data['remind_rules'] as List).single['offset_minutes'], 15);
      });
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        await session.dispose();
        container.dispose();
        await db.close();
        await directory.delete(recursive: true);
      });
    }
  });
  testWidgets(
    'detail close waits for title save and preserves draft on disk failure',
    (tester) async {
      late Directory directory;
      late AppDatabase db;
      late DelayedWorkspaceStore store;
      late LocalWorkspaceSession session;
      await tester.runAsync(() async {
        directory = await Directory.systemTemp.createTemp('detail-widget');
        db = AppDatabase.background(File('${directory.path}/db.sqlite'));
        final disk = SqliteWorkspaceCommandStore(db);
        await disk.execute(
          WorkspaceCommand(
            operationId: 'seed',
            actions: [
              WorkspaceMutation(
                actionId: 'create',
                kind: WorkspaceEntityKind.todo,
                entityId: 'task',
                mutation: WorkspaceMutationKind.create,
                patch: {'title': '原始标题'},
              ),
            ],
          ),
        );
        store = DelayedWorkspaceStore(disk);
        session = LocalWorkspaceSession(store, await store.load());
      });
      final container = ProviderContainer();
      container.read(localWorkspaceSessionProvider.notifier).state = session;
      container.read(todoListProvider);
      container.read(categoryListProvider);
      try {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.light,
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () =>
                        showTodoDetailSheet(context, 'task', onDeleted: (_) {}),
                    child: const Text('打开详情'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('打开详情'));
        await tester.pumpAndSettle();
        final title = find.byType(TextField).first;
        await tester.enterText(title, '尚未失焦的新标题');
        final close = find.byWidgetPredicate(
          (widget) => widget is AppPressable && widget.semanticLabel == '关闭',
        );
        await tester.tap(close);
        await tester.pump();
        expect(find.byType(TodoDetailSheet), findsOneWidget);
        expect(session.todos.byId('task')!.title, '原始标题');
        store.fail = true;
        await releaseWrite(tester, store);
        await tester.pumpAndSettle();
        expect(find.byType(TodoDetailSheet), findsOneWidget);
        expect(tester.widget<TextField>(title).controller!.text, '尚未失焦的新标题');
        store.fail = false;
        store.gate = Completer<void>();
        store.settled = Completer<void>();
        await tester.tap(close);
        await tester.pump();
        await releaseWrite(tester, store);
        await tester.pumpAndSettle();
        expect(find.byType(TodoDetailSheet), findsNothing);
        expect(session.todos.byId('task')!.title, '尚未失焦的新标题');
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(() async {
          await session.dispose();
          container.dispose();
          await db.close();
          await directory.delete(recursive: true);
        });
      }
    },
  );
}
