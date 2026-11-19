import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/local_workspace_session.dart';
import 'package:towork/app/recurrence_window.dart';
import 'package:towork/app/recurrence_window_provider.dart';
import 'package:towork/core/widgets/app_toast.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/recurrence/recurrence_plans.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';
import 'package:towork/core/todo/recurrence_action_sheet.dart';
import 'package:towork/features/todo/widgets/recurrence_window_status.dart';
import 'package:towork/theme/app_theme.dart';

Future<void> _withWorkspace(
  WidgetTester tester,
  Future<void> Function(AppDatabase, LocalWorkspaceSession, RecurrenceWindow)
  body,
) async {
  late Directory dir;
  late AppDatabase db;
  late LocalWorkspaceSession session;
  final now = DateTime.utc(2026, 9, 24);
  await tester.runAsync(() async {
    dir = await Directory.systemTemp.createTemp('window-status');
    db = AppDatabase.background(File('${dir.path}/db.sqlite'));
    final store = SqliteWorkspaceCommandStore(db);
    await store.execute(
      WorkspaceCommand(
        operationId: 'seed',
        actions: [
          WorkspaceMutation(
            actionId: 'task',
            kind: WorkspaceEntityKind.todo,
            entityId: 'task',
            mutation: WorkspaceMutationKind.create,
            patch: {'title': '测试系列', 'due_at': now.toIso8601String()},
          ),
        ],
      ),
    );
    await store.execute(
      RecurrencePlans(await store.load(), now: now).start(
        'task',
        rule: 'FREQ=DAILY;COUNT=5',
        timezone: 'Asia/Shanghai',
        operationId: 'start',
        through: now,
      ),
    );
    session = LocalWorkspaceSession(
      store,
      await store.load(),
      elapsed: () => Duration.zero,
    );
  });
  final worker = RecurrenceWindow(
    session,
    clock: () => now,
    autoSchedule: false,
  );
  final container = ProviderContainer(
    overrides: [recurrenceWindowProvider.overrideWithValue(worker)],
  );
  container.read(localWorkspaceSessionProvider.notifier).state = session;
  tester.view.physicalSize = const Size(320, 780);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = 2;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  try {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Column(
              children: [
                const RecurrenceWindowStatus(),
                Consumer(
                  builder: (context, ref, _) => TextButton(
                    onPressed: () {
                      final before = session.todos.byId('task')!;
                      saveTodoEdit(
                        context,
                        ref,
                        before,
                        before.copyWith(note: '需要确认'),
                      );
                    },
                    child: const Text('修改系列'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await body(db, session, worker);
  } finally {
    AppToast.dismiss();
    await tester.pumpWidget(const SizedBox());
    worker.dispose();
    container.dispose();
    await tester.runAsync(() async {
      await session.dispose();
      session.todos.dispose();
      session.categories.dispose();
      await db.close();
      await dir.delete(recursive: true);
    });
  }
}

void main() {
  testWidgets(
    'storage failure remains usable, retry button really fills the window at large text',
    (tester) async {
      await _withWorkspace(tester, (db, session, worker) async {
        await tester.runAsync(() async {
          await db.customStatement('PRAGMA query_only = ON');
          await worker.refresh();
        });
        await tester.pumpAndSettle();
        expect(find.textContaining('已有记录已保留'), findsOneWidget);
        expect(session.todos.snapshot, hasLength(1));
        final retry = find.byKey(const ValueKey('recurrence-window-retry'));
        expect(tester.getSize(retry).height, greaterThanOrEqualTo(44));
        await tester.runAsync(
          () => db.customStatement('PRAGMA query_only = OFF'),
        );
        await tester.tap(retry);
        for (
          var i = 0;
          i < 100 && worker.current.phase != RecurrenceWindowPhase.ready;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 50));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
        }
        await tester.pumpAndSettle();
        expect(session.todos.snapshot, hasLength(5));
        expect(find.textContaining('重复待办已补齐至'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('recurrence-window-retry')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      });
    },
  );

  testWidgets('production scope sheet holds generation until cancellation', (
    tester,
  ) async {
    await _withWorkspace(tester, (db, session, worker) async {
      await tester.tap(find.text('修改系列'));
      await tester.pumpAndSettle();
      expect(session.automaticWorkHeld, isTrue);
      await tester.runAsync(() => worker.refresh());
      await tester.pump();
      expect(worker.current.phase, RecurrenceWindowPhase.waiting);
      expect(session.todos.snapshot, hasLength(1));
      final cancel = find.text('取消');
      await tester.ensureVisible(cancel);
      await tester.pumpAndSettle();
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      expect(session.automaticWorkHeld, isFalse);
      await tester.runAsync(() => worker.refresh());
      await tester.pumpAndSettle();
      expect(session.todos.snapshot, hasLength(5));
      expect(session.todos.snapshot.every((e) => e.note == null), isTrue);
      expect(tester.takeException(), isNull);
    });
  });
}
