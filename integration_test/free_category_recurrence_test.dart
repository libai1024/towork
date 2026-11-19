import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:towork/app/free_workspace_bootstrap.dart';
import 'package:towork/app/local_database_provider.dart';
import 'package:towork/app/local_workspace_session.dart';
import 'package:towork/shell/router.dart';
import 'package:towork/app/routes.dart';
import 'package:towork/core/widgets/app_pressable.dart';
import 'package:towork/core/widgets/app_toast.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/recurrence/recurrence_plans.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';
import 'package:towork/domain/workspace/workspace_plans.dart';
import 'package:towork/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native category deletion includes template impact, cancellation, both policies and undo',
    (tester) async {
      final folder = await Directory(
        '${(await getApplicationSupportDirectory()).path}/category-repeat-${DateTime.now().microsecondsSinceEpoch}',
      ).create();
      final file = File('${folder.path}/db.sqlite');
      AppDatabase? db;
      ProviderContainer? container;
      final now = DateTime.utc(2026, 9, 24);
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
                  actionId: 'cat',
                  kind: WorkspaceEntityKind.category,
                  entityId: 'project',
                  mutation: WorkspaceMutationKind.create,
                  patch: {'name': '重复项目'},
                ),
                WorkspaceMutation(
                  actionId: 'other',
                  kind: WorkspaceEntityKind.category,
                  entityId: 'other',
                  mutation: WorkspaceMutationKind.create,
                  patch: {'name': '其他项目'},
                ),
                WorkspaceMutation(
                  actionId: 'todo',
                  kind: WorkspaceEntityKind.todo,
                  entityId: 'task',
                  mutation: WorkspaceMutationKind.create,
                  patch: {
                    'title': '每日整理',
                    'category_id': 'project',
                    'due_at': now.toIso8601String(),
                  },
                ),
              ],
            ),
          );
          await store.execute(
            RecurrencePlans(await store.load(), now: now).start(
              'task',
              rule: 'FREQ=DAILY;COUNT=8',
              timezone: 'Asia/Shanghai',
              operationId: 'start',
              through: now.add(const Duration(days: 30)),
              limit: 2,
            ),
          );
          final moved = (await store.load()).todos.singleWhere(
            (e) => e.data['occurrence_index'] == 1,
          );
          await store.execute(
            WorkspaceCommand(
              operationId: 'move',
              actions: [
                WorkspacePlans.update(moved, {
                  'category_id': 'other',
                  'note': '需要保留',
                }),
              ],
            ),
          );
        }
        container = ProviderContainer(
          overrides: [
            localDatabaseProvider.overrideWith((ref) async => current),
            initialAppLocationProvider.overrideWithValue(AppRoutes.categories),
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
        AppToast.dismiss();
        await tester.pumpWidget(const SizedBox());
        container?.dispose();
        container = null;
        await db?.close();
        db = null;
      }

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      Future<void> ready(bool Function() predicate) async {
        final watch = Stopwatch()..start();
        while (!predicate() && watch.elapsed < const Duration(seconds: 5)) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(predicate(), isTrue);
        await tester.pumpAndSettle();
      }

      LocalWorkspaceSession session() =>
          container!.read(localWorkspaceSessionProvider)!;
      Future<void> confirmSheet() async {
        final toast = find.byKey(const ValueKey('toast-dismiss'));
        if (toast.evaluate().isNotEmpty) await tap(toast);
        await tap(
          find.byWidgetPredicate(
            (w) => w is AppPressable && w.semanticLabel == '重复项目 更多操作',
          ),
        );
        await tap(find.text('删除'));
        expect(find.textContaining('1 个重复系列'), findsOneWidget);
      }

      try {
        await open(seed: true);
        await ready(() => session().todos.snapshot.length == 8);
        await confirmSheet();
        await tap(find.text('待办与子分类一并删除'));
        expect(find.textContaining('1 条待办保留，并取消重复'), findsOneWidget);
        await tap(find.text('取消'));
        expect(session().todos.snapshot, hasLength(8));
        expect(session().snapshot.series.single.data['stop_before'], isNull);

        await confirmSheet();
        await tap(find.text('删除'));
        await ready(() => session().categories.byId('project') == null);
        expect(
          session().todos.snapshot.where((e) => e.categoryId == null),
          hasLength(7),
        );
        expect(
          (session().snapshot.series.single.data['template']!
              as Map)['category_id'],
          isNull,
        );
        await tap(find.text('撤销'));
        await ready(() => session().categories.byId('project') != null);
        expect(
          (session().snapshot.series.single.data['template']!
              as Map)['category_id'],
          'project',
        );

        await confirmSheet();
        await tap(find.text('待办与子分类一并删除'));
        await tap(find.text('删除'));
        await ready(() => session().categories.byId('project') == null);
        expect(session().todos.snapshot, hasLength(1));
        expect(session().todos.snapshot.single.seriesId, isNull);
        expect(session().todos.snapshot.single.note, '需要保留');
        expect(session().snapshot.series.single.data['stop_before'], 0);
        await tap(find.text('撤销'));
        await ready(() => session().categories.byId('project') != null);
        expect(session().todos.snapshot, hasLength(8));
        expect(
          session().todos.snapshot.every((e) => e.seriesId != null),
          isTrue,
        );

        await confirmSheet();
        await tap(find.text('待办与子分类一并删除'));
        await tap(find.text('删除'));
        await ready(() => session().categories.byId('project') == null);
        await close();
        await open();
        expect(session().todos.snapshot, hasLength(1));
        expect(session().todos.snapshot.single.categoryId, 'other');
        expect(session().todos.snapshot.single.seriesId, isNull);
        expect(session().snapshot.series.single.data['stop_before'], 0);
        expect(tester.takeException(), isNull);
      } finally {
        await close();
        await folder.delete(recursive: true);
      }
    },
  );
}
