import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:towork/app/free_workspace_bootstrap.dart';
import 'package:towork/app/local_database_provider.dart';
import 'package:towork/app/local_workspace_session.dart';
import 'package:towork/app/recurrence_window.dart';
import 'package:towork/app/recurrence_window_provider.dart';
import 'package:towork/shell/router.dart';
import 'package:towork/app/routes.dart';
import 'package:towork/app/workspace_clock.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/recurrence/recurrence_plans.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';
import 'package:towork/domain/workspace/workspace_plans.dart';
import 'package:towork/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'production startup and reopening fill a long history automatically without reviving exceptions',
    (tester) async {
      final folder = await Directory(
        '${(await getApplicationSupportDirectory()).path}/window-${DateTime.now().microsecondsSinceEpoch}',
      ).create();
      final file = File('${folder.path}/db.sqlite');
      var now = DateTime.utc(2026, 9, 24);
      final anchor = DateTime.utc(2024, 9, 24);
      AppDatabase? db;
      ProviderContainer? container;
      late String deletedId;
      Future<void> open({bool seed = false}) async {
        final current = AppDatabase.background(file);
        db = current;
        if (seed) {
          final store = SqliteWorkspaceCommandStore(current);
          await store.execute(
            WorkspaceCommand(
              operationId: 'seed',
              actions: [
                WorkspaceMutation(
                  actionId: 'task',
                  kind: WorkspaceEntityKind.todo,
                  entityId: 'task',
                  mutation: WorkspaceMutationKind.create,
                  patch: {'title': '持续整理', 'due_at': anchor.toIso8601String()},
                ),
              ],
            ),
          );
          await store.execute(
            RecurrencePlans(await store.load(), now: now).start(
              'task',
              rule: 'FREQ=DAILY',
              timezone: 'Asia/Shanghai',
              operationId: 'start',
              through: anchor.add(const Duration(days: 2)),
            ),
          );
          final initial = await store.load();
          final deleted = initial.todos.singleWhere(
            (e) => e.data['occurrence_index'] == 1,
          );
          deletedId = deleted.id;
          await store.execute(
            WorkspaceCommand(
              operationId: 'exceptions',
              actions: [
                WorkspacePlans.update(
                  initial.find(WorkspaceEntityKind.todo, 'task')!,
                  {'status': 'done'},
                ),
                WorkspacePlans.delete(deleted),
              ],
            ),
          );
        }
        container = ProviderContainer(
          overrides: [
            localDatabaseProvider.overrideWith((ref) async => current),
            workspaceNowProvider.overrideWithValue(() => now),
            initialAppLocationProvider.overrideWithValue(AppRoutes.todos),
          ],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container!,
            child: const FreeWorkspaceBootstrap(child: ToWorkApp()),
          ),
        );
        final watch = Stopwatch()..start();
        bool ready() =>
            container!.read(recurrenceWindowProvider)?.current.phase ==
            RecurrenceWindowPhase.ready;
        while (!ready() && watch.elapsed < const Duration(seconds: 20)) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(ready(), isTrue);
        await tester.pumpAndSettle();
      }

      Future<void> close() async {
        await tester.pumpWidget(const SizedBox());
        container?.dispose();
        container = null;
        await db?.close();
        db = null;
      }

      void verify() {
        final session = container!.read(localWorkspaceSessionProvider)!;
        final window = container!.read(recurrenceWindowProvider)!.current;
        final total = window.through!.difference(anchor).inDays + 1;
        expect(session.todos.snapshot, hasLength(total - 1));
        expect(session.todos.byId('task')!.completedAt, isNotNull);
        expect(session.todos.byId(deletedId), isNull);
        expect(
          session.snapshot.find(WorkspaceEntityKind.todo, deletedId)!.isDeleted,
          isTrue,
        );
        expect(
          session.todos.snapshot.map((e) => e.occurrenceIndex).toSet(),
          hasLength(total - 1),
        );
        expect(find.textContaining('重复待办已补齐至'), findsOneWidget);
        expect(find.text('正在分批补齐重复待办'), findsNothing);
        expect(tester.takeException(), isNull);
      }

      try {
        await open(seed: true);
        verify();
        final firstCount = container!
            .read(localWorkspaceSessionProvider)!
            .todos
            .snapshot
            .length;
        await close();
        now = now.add(const Duration(days: 30));
        await open();
        verify();
        expect(
          container!.read(localWorkspaceSessionProvider)!.todos.snapshot.length,
          firstCount + 30,
        );
      } finally {
        await close();
        await folder.delete(recursive: true);
      }
    },
  );
}
