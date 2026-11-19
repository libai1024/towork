import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:towork/app/free_workspace_bootstrap.dart';
import 'package:towork/app/model_settings_provider.dart';
import 'package:towork/app/local_database_provider.dart';
import 'package:towork/app/local_workspace_session.dart';
import 'package:towork/app/notification_provider.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/shell/router.dart';
import 'package:towork/app/routes.dart';
import 'package:towork/core/widgets/app_button.dart';
import 'package:towork/core/widgets/app_pressable.dart';
import 'package:towork/core/widgets/app_toast.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/domain/settings/model_settings_service.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';
import 'package:towork/main.dart';

import '../test/support/free/fake_model_gateway.dart';
import '../test/support/free/fake_notifications.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'real table UI creates, edits, reopens and deletes with durable undo and history',
    (tester) async {
      final dir = await Directory(
        '${(await getApplicationSupportDirectory()).path}/business-ui-${DateTime.now().microsecondsSinceEpoch}',
      ).create();
      final file = File('${dir.path}/db.sqlite');
      AppDatabase? db;
      ProviderContainer? container;
      final model = FakeKimiGateway(), vault = FakeKeyVault();
      DataTableStore data() => container!.read(dataTableProvider.notifier);
      Future<void> until(bool Function() condition) async {
        final watch = Stopwatch()..start();
        while (!condition() && watch.elapsed < const Duration(seconds: 15)) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(condition(), isTrue);
        await tester.pumpAndSettle();
      }

      Future<void> open() async {
        final current = AppDatabase.background(file);
        db = current;
        container = ProviderContainer(
          overrides: [
            localDatabaseProvider.overrideWith((ref) async => current),
            modelSettingsServiceProvider.overrideWith(
              (ref) async => ModelSettingsService(current, vault, model),
            ),
            notificationServiceProvider.overrideWith(
              (ref) => FakeNotifications(),
            ),
            initialAppLocationProvider.overrideWithValue(AppRoutes.dataTables),
          ],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container!,
            child: const FreeWorkspaceBootstrap(child: ToWorkApp()),
          ),
        );
        await until(
          () => container!.read(localWorkspaceSessionProvider) != null,
        );
        await until(() => !data().snapshot.historyLoading);
      }

      Future<void> close() async {
        AppToast.dismiss();
        await tester.pumpWidget(const SizedBox());
        container?.dispose();
        container = null;
        await db?.close();
        db = null;
      }

      Future<void> tapButton(String text) async {
        await until(
          () => find
              .widgetWithText(AppButton, text)
              .hitTestable()
              .evaluate()
              .isNotEmpty,
        );
        final finder = find.widgetWithText(AppButton, text).hitTestable().last;
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      Future<void> tapNamed(String label) async {
        final finder = find
            .byWidgetPredicate(
              (w) => w is AppPressable && w.semanticLabel == label,
            )
            .last;
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      Future<void> enter(String value) async {
        await tester.enterText(find.byType(TextField).last, value);
        // Hide the keyboard without submitting a second command.
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
      }

      try {
        await open();
        expect(data().snapshot.tables, isEmpty);
        expect(find.text('股票持仓'), findsNothing);
        await tapNamed('新增类型');
        await tester.enterText(find.byType(TextField).last, '现场记录');
        await tapButton('创建');
        await until(() => data().snapshot.types.length == 1);
        // The bottom action opens the existing new-table sheet.
        await tapNamed('新建表');
        await enter('持久化验收表');
        await tapButton('创建');
        await until(() => data().snapshot.tables.length == 1);
        final tableId = data().snapshot.tables.single.id;
        expect(
          data().snapshot.tables.single.typeId,
          data().snapshot.types.single.id,
        );
        await tapNamed('新建行');
        await tester.tap(find.text('未填写').first);
        await tester.pumpAndSettle();
        await enter('第一条业务记录');
        await tapButton('保存');
        await until(
          () => find.widgetWithText(AppButton, '保存').evaluate().length == 1,
        );
        await tapButton('保存');
        await until(() => data().rowsOf(tableId).length == 1);
        final rowId = data().rowsOf(tableId).single.id;
        await tester.tap(find.text('第一条业务记录').first);
        await tester.pumpAndSettle();
        await tapNamed('编辑备注');
        await enter('离线填写的备注');
        await tapButton('保存');
        await until(
          () => data().rowsOf(tableId).single.values['备注'] == '离线填写的备注',
        );
        await tapNamed('变更历史');
        await until(() => data().logsOfRow(rowId).length == 2);
        expect(find.text('新建了这行'), findsOneWidget);
        await close();
        await open();
        expect(data().rowsOf(tableId).single.values['备注'], '离线填写的备注');
        expect(data().logsOfRow(rowId), hasLength(2));
        await tester.tap(find.text('持久化验收表').first);
        await tester.pumpAndSettle();
        expect(find.text('1 行'), findsOneWidget);
        await tester.longPress(find.text('第一条业务记录').first);
        await tester.pumpAndSettle();
        await tapNamed('删除');
        await tapButton('删除');
        await until(() => data().rowsOf(tableId).isEmpty);
        await tester.tap(find.text('撤销').last);
        await tester.pumpAndSettle();
        await until(() => data().rowsOf(tableId).length == 1);
        await close();
        await open();
        expect(data().rowsOf(tableId).single.values['备注'], '离线填写的备注');
        expect(
          container!
              .read(localWorkspaceSessionProvider)!
              .snapshot
              .find(WorkspaceEntityKind.dataRow, rowId)!
              .version,
          4,
        );
        expect(data().logsOfRow(rowId), hasLength(4));
        expect(model.calls, 0);
        expect(tester.takeException(), isNull);
      } finally {
        await close();
        await dir.delete(recursive: true);
      }
    },
  );
}
