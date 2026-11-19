import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:towork/app/free_workspace_bootstrap.dart';
import 'package:towork/app/local_database_provider.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/shell/router.dart';
import 'package:towork/app/routes.dart';
import 'package:towork/core/widgets/app_pressable.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';
import 'package:towork/main.dart';
import 'package:towork/core/todo/todo_detail_sheet.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'repeat rule, timezone and preview persist through native UI and reopen',
    (tester) async {
      final folder = await Directory(
        '${(await getApplicationSupportDirectory()).path}/repeat-test-${DateTime.now().microsecondsSinceEpoch}',
      ).create();
      final file = File('${folder.path}/fixture.sqlite');
      AppDatabase? db;
      ProviderContainer? container;
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
                  entityId: 'repeat',
                  mutation: WorkspaceMutationKind.create,
                  patch: {
                    'title': '月底整理资料',
                    'due_at': '2026-01-31T01:00:00Z',
                    'repeat_rule': 'FREQ=MONTHLY;BYMONTHDAY=31;COUNT=4',
                    'repeat_timezone': 'Asia/Shanghai',
                  },
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

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      Future<void> committed(bool Function() ready) async {
        final time = Stopwatch()..start();
        while (!ready() && time.elapsed < const Duration(seconds: 5)) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(ready(), isTrue);
        await tester.pumpAndSettle();
      }

      Future<void> editor() async {
        await tap(find.byKey(const ValueKey('repeat')));
        await tap(
          find.byWidgetPredicate(
            (w) =>
                w is AppPressable &&
                (w.semanticLabel?.startsWith('重复，') ?? false),
          ),
        );
      }

      try {
        await open(seed: true);
        await editor();
        expect(find.text('2026/02/28 09:00'), findsOneWidget);
        await tap(find.text('每天'));
        await tap(find.text('保存重复设置'));
        await tap(find.text('确认修改'));
        await committed(
          () =>
              container!
                  .read(todoListProvider)
                  .singleWhere((t) => t.id == 'repeat')
                  .repeatRule ==
              'FREQ=DAILY;COUNT=4',
        );
        expect(find.text('2026/02/01 09:00'), findsOneWidget);
        await tap(find.text('每月'));
        await tap(find.text('保存重复设置'));
        await tap(find.text('确认修改'));
        await committed(
          () =>
              container!
                  .read(todoListProvider)
                  .singleWhere((t) => t.id == 'repeat')
                  .repeatRule ==
              'FREQ=MONTHLY;BYMONTHDAY=31;COUNT=4',
        );
        expect(find.text('2026/02/28 09:00'), findsOneWidget);
        await tap(find.byKey(const ValueKey('repeat-timezone')));
        await tap(find.text('Asia/Tokyo').last);
        await tap(find.text('保存重复设置'));
        await tap(find.text('确认修改'));
        await committed(
          () =>
              container!
                  .read(todoListProvider)
                  .singleWhere((t) => t.id == 'repeat')
                  .repeatTimezone ==
              'Asia/Tokyo',
        );
        expect(find.text('2026/02/28 10:00'), findsOneWidget);
        await close();
        await open();
        expect(
          container!
              .read(todoListProvider)
              .singleWhere((t) => t.id == 'repeat')
              .repeatTimezone,
          'Asia/Tokyo',
        );
        await editor();
        expect(find.text('2026/03/31 10:00'), findsOneWidget);
        final title = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == '待办标题',
        );
        await tester.ensureVisible(title);
        await tap(title);
        await tester.enterText(title, '只改本次标题');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(find.text('仅本次'), findsOneWidget);
        await tap(find.text('确认修改'));
        await committed(
          () =>
              container!
                  .read(todoListProvider)
                  .where((t) => t.title == '只改本次标题')
                  .length ==
              1,
        );
        await tap(find.text('撤销'));
        await committed(
          () => container!
              .read(todoListProvider)
              .every((t) => t.title == '月底整理资料'),
        );
        expect(tester.widget<TextField>(title).controller!.text, '月底整理资料');
        await tap(title);
        await tester.enterText(title, '后续整理资料');
        expect(tester.widget<TextField>(title).controller!.text, '后续整理资料');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(
          find.text('本次及以后'),
          findsOneWidget,
          reason: tester
              .widgetList<Text>(find.byType(Text))
              .map((w) => w.data)
              .join('|'),
        );
        await tap(find.text('本次及以后'));
        await tap(find.text('确认修改'));
        await committed(
          () => container!
              .read(todoListProvider)
              .every((t) => t.title == '后续整理资料'),
        );
        if (find.byKey(const ValueKey('toast-dismiss')).evaluate().isNotEmpty) {
          await tap(find.byKey(const ValueKey('toast-dismiss')));
        }
        await tester.scrollUntilVisible(
          find.text('删除这条待办'),
          300,
          scrollable: find
              .descendant(
                of: find.byType(TodoDetailSheet),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tap(find.text('删除这条待办'));
        await tap(find.text('本次及以后'));
        await tap(find.text('取消'));
        expect(container!.read(todoListProvider), hasLength(4));
        await tester.scrollUntilVisible(
          find.text('删除这条待办'),
          300,
          scrollable: find
              .descendant(
                of: find.byType(TodoDetailSheet),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tap(find.text('删除这条待办'));
        await tap(find.text('本次及以后'));
        await tap(find.text('确认删除'));
        await committed(() => container!.read(todoListProvider).isEmpty);
        await tap(find.text('撤销'));
        await committed(() => container!.read(todoListProvider).length == 4);
        await close();
        await open();
        expect(
          container!.read(todoListProvider).every((t) => t.title == '后续整理资料'),
          isTrue,
        );
        await editor();
        await tap(find.text('清除重复'));
        await tap(find.text('确认清除？'));
        await tap(find.text('确认修改'));
        await committed(
          () =>
              container!
                  .read(todoListProvider)
                  .singleWhere((t) => t.id == 'repeat')
                  .repeatRule ==
              null,
        );
        expect(
          container!
              .read(todoListProvider)
              .singleWhere((t) => t.id == 'repeat')
              .repeatTimezone,
          isNull,
        );
        await close();
        await open();
        expect(
          container!
              .read(todoListProvider)
              .singleWhere((t) => t.id == 'repeat')
              .repeatRule,
          isNull,
        );
        expect(
          container!
              .read(todoListProvider)
              .singleWhere((t) => t.id == 'repeat')
              .repeatTimezone,
          isNull,
        );
      } finally {
        await close();
        await folder.delete(recursive: true);
      }
    },
  );
}
