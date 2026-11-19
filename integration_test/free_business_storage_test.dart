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
import 'package:towork/data/local/app_database.dart';
import 'package:towork/domain/settings/model_settings_service.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';
import 'package:towork/main.dart';

import '../test/support/free/fake_model_gateway.dart';
import '../test/support/free/fake_notifications.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'business entities survive native bootstrap, mixed commit, reopen and undo',
    (tester) async {
      final dir = await Directory(
        '${(await getApplicationSupportDirectory()).path}/business-storage-${DateTime.now().microsecondsSinceEpoch}',
      ).create();
      final file = File('${dir.path}/db.sqlite');
      final model = FakeKimiGateway();
      final vault = FakeKeyVault();
      AppDatabase? db;
      ProviderContainer? container;
      LocalWorkspaceSession session() =>
          container!.read(localWorkspaceSessionProvider)!;
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
        while (container!.read(localWorkspaceSessionProvider) == null &&
            watch.elapsed < const Duration(seconds: 15)) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(container!.read(localWorkspaceSessionProvider), isNotNull);
        await tester.pumpAndSettle();
      }

      Future<void> close() async {
        await tester.pumpWidget(const SizedBox());
        container?.dispose();
        container = null;
        await db?.close();
        db = null;
      }

      WorkspaceMutation create(
        WorkspaceEntityKind kind,
        String id,
        Map<String, Object?> patch,
      ) => WorkspaceMutation(
        actionId: id,
        kind: kind,
        entityId: id,
        mutation: WorkspaceMutationKind.create,
        patch: patch,
      );
      final command = WorkspaceCommand(
        operationId: 'native-business',
        actions: [
          create(WorkspaceEntityKind.dataRow, 'row', {
            'table_id': 'table',
            'values': {'amount': '12345678901234567890.10', 'paid': false},
          }),
          create(WorkspaceEntityKind.dataTable, 'table', {
            'name': '原生账本',
            'fields': [
              {'id': 'amount', 'name': '金额', 'type': 'money', 'required': true},
              {'id': 'paid', 'name': '已付款', 'type': 'boolean'},
            ],
          }),
          create(WorkspaceEntityKind.todo, 'todo', {'title': '核对本地业务记录'}),
        ],
      );
      try {
        await open();
        await session().execute(command);
        await tester.pumpAndSettle();
        expect(container!.read(todoListProvider).single.title, '核对本地业务记录');
        expect(find.text('核对本地业务记录'), findsWidgets);
        await close();
        await open();
        expect(session().snapshot.dataRows.single.data['values'], {
          'amount': '12345678901234567890.10',
          'paid': false,
        });
        expect(session().snapshot.dataTables.single.data['name'], '原生账本');
        await session().execute(command);
        expect(session().snapshot.dataRows, hasLength(1));
        await session().undo('native-business', 'native-business-undo');
        await close();
        await open();
        expect(session().snapshot.dataRows, isEmpty);
        expect(session().snapshot.dataTables, isEmpty);
        expect(container!.read(todoListProvider), isEmpty);
        expect(
          session().snapshot.find(WorkspaceEntityKind.dataRow, 'row')!.version,
          2,
        );
        expect(model.calls, 0);
        expect(tester.takeException(), isNull);
      } finally {
        await close();
        await dir.delete(recursive: true);
      }
    },
  );
}
