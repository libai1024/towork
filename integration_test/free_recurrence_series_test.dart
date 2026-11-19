import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:towork/app/free_workspace_bootstrap.dart';
import 'package:towork/app/local_database_provider.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/app/recurrence_commands.dart';
import 'package:towork/shell/router.dart';
import 'package:towork/app/routes.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/models/todo.dart';
import 'package:towork/domain/recurrence/recurrence_plans.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';
import 'package:towork/core/todo/todo_checkbox.dart';
import 'package:towork/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'durable series commands integrate with the production UI completion and restart',
    (tester) async {
      final folder = await Directory(
        '${(await getApplicationSupportDirectory()).path}/series-test-${DateTime.now().microsecondsSinceEpoch}',
      ).create();
      final file = File('${folder.path}/data.sqlite');
      AppDatabase? db;
      ProviderContainer? container;
      final through = DateTime.utc(2026, 10, 1);
      RecurrenceCommands commands() =>
          container!.read(recurrenceCommandsProvider)!;
      List<Todo> todos() => container!.read(todoListProvider);
      Future<void> open({bool seed = false}) async {
        final current = AppDatabase.background(file);
        db = current;
        if (seed) {
          await SqliteWorkspaceCommandStore(current).execute(
            WorkspaceCommand(
              operationId: 'seed',
              actions: [
                WorkspaceMutation(
                  actionId: 'a',
                  kind: WorkspaceEntityKind.todo,
                  entityId: 'task',
                  mutation: WorkspaceMutationKind.create,
                  patch: {'title': '原生系列待办', 'due_at': '2026-09-24T01:00:00Z'},
                ),
              ],
            ),
          );
        }
        container = ProviderContainer(
          overrides: [
            localDatabaseProvider.overrideWith((ref) async => current),
            initialAppLocationProvider.overrideWithValue(AppRoutes.todos),
          ],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container!,
            child: const FreeWorkspaceBootstrap(child: ToWorkApp()),
          ),
        );
        await tester.pumpAndSettle();
      }

      Future<void> close() async {
        await tester.pumpWidget(const SizedBox());
        container?.dispose();
        container = null;
        await db?.close();
        db = null;
      }

      Future<void> until(bool Function() condition) async {
        final time = Stopwatch()..start();
        while (!condition() && time.elapsed < const Duration(seconds: 5)) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(condition(), isTrue);
        await tester.pumpAndSettle();
      }

      try {
        await open(seed: true);
        await commands().execute(
          commands().plans.start(
            'task',
            rule: 'FREQ=DAILY;COUNT=4',
            timezone: 'Asia/Shanghai',
            operationId: 'start',
            through: through,
          ),
        );
        await until(() => todos().length == 4);
        final checkbox = find
            .byWidgetPredicate(
              (w) => w is TodoCheckbox && w.semanticLabel == '完成待办：原生系列待办',
            )
            .first;
        await tester.ensureVisible(checkbox);
        await tester.pumpAndSettle();
        await tester.tap(checkbox);
        await until(
          () => todos().where((t) => t.status == TodoStatus.done).length == 1,
        );
        final completedId = todos()
            .singleWhere((t) => t.status == TodoStatus.done)
            .id;
        final target = todos().singleWhere((t) => t.occurrenceIndex == 1);
        final split = commands().plans.edit(
          target.id,
          {'title': '后续系列标题'},
          scope: RecurrenceScope.currentAndFuture,
          operationId: 'split',
          through: through,
        );
        await commands().execute(split);
        expect(todos(), hasLength(4));
        await close();
        await open();
        expect(todos(), hasLength(4));
        expect(
          todos().singleWhere((t) => t.id == target.id).seriesId,
          RecurrencePlans.seriesIdFor('split'),
        );
        final repeated = await commands().execute(split);
        expect(todos(), hasLength(4));
        await repeated.undo();
        expect(
          todos().every(
            (t) => t.seriesId == RecurrencePlans.seriesIdFor('start'),
          ),
          isTrue,
        );
        expect(
          todos().singleWhere((t) => t.status == TodoStatus.done).id,
          completedId,
        );
        await close();
        await open();
        expect(todos(), hasLength(4));
        expect(todos().every((t) => t.title == '原生系列待办'), isTrue);
        expect(tester.takeException(), isNull);
      } finally {
        await close();
        await folder.delete(recursive: true);
      }
    },
  );
}
