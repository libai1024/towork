import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/data/platform/system_key_vault.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/settings/model_settings_service.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';

import '../test/support/free/fake_model_gateway.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native vault lifecycle and SQLite reopen preserve configuration', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: Text('ToWork 本地存储验证')),
      ),
    );
    await tester.runAsync(() async {
      final support = await getApplicationSupportDirectory();
      final directory = await Directory(
        '${support.path}/native-fixture-${DateTime.now().microsecondsSinceEpoch}',
      ).create(recursive: true);
      final file = File('${directory.path}/fixture.sqlite');
      final vault = SystemKeyVault();
      var db = AppDatabase.background(file);
      final refs = <String>[];
      try {
        var service = ModelSettingsService(db, vault, FakeKimiGateway());
        final profile = ModelProfile(
          model: 'fixture-only',
          product: ProviderKind.kimiCode,
        );
        final first = await service.save(
          profile: profile,
          expectedVersion: 0,
          newKey: 'synthetic-native-secret-one',
        );
        refs.add(first.configuration.credentialRef!);
        expect(first.hasKey, isTrue);
        final localProfile = await db.loadOrCreateProfile();
        await db.renameProfile('原生资料测试', expectedVersion: localProfile.version);
        final workspace = SqliteWorkspaceCommandStore(db);
        await workspace.execute(
          WorkspaceCommand(
            operationId: 'native-create',
            actions: [
              WorkspaceMutation(
                actionId: 'category',
                kind: WorkspaceEntityKind.category,
                entityId: 'native-category',
                mutation: WorkspaceMutationKind.create,
                patch: {'name': '原生分类'},
              ),
              WorkspaceMutation(
                actionId: 'todo',
                kind: WorkspaceEntityKind.todo,
                entityId: 'native-todo',
                mutation: WorkspaceMutationKind.create,
                patch: {'title': '原生待办', 'category_id': 'native-category'},
              ),
            ],
          ),
        );
        await db.close();
        db = AppDatabase.background(file);
        service = ModelSettingsService(db, vault, FakeKimiGateway());
        expect((await service.load()).hasKey, isTrue);
        final restoredProfile = await db.loadOrCreateProfile();
        expect(restoredProfile.id, localProfile.id);
        expect(restoredProfile.nickname, '原生资料测试');
        final restoredWorkspace = SqliteWorkspaceCommandStore(db);
        final snapshot = await restoredWorkspace.load();
        expect(snapshot.todos.single.data['title'], '原生待办');
        expect(snapshot.categories.single.data['name'], '原生分类');
        await restoredWorkspace.undo(
          'native-create',
          operationId: 'native-undo',
        );
        expect((await restoredWorkspace.load()).todos, isEmpty);
        expect((await restoredWorkspace.load()).categories, isEmpty);
        final second = await service.save(
          profile: profile,
          expectedVersion: 1,
          newKey: 'synthetic-native-secret-two',
        );
        refs.add(second.configuration.credentialRef!);
        expect(await vault.read(refs.first), isNull);
        expect(await vault.read(refs.last), 'synthetic-native-secret-two');
        final removed = await service.deleteKey(expectedVersion: 2);
        expect(removed.hasKey, isFalse);
        expect(removed.cleanupPending, isFalse);
        expect(await vault.read(refs.last), isNull);
      } finally {
        for (final reference in refs) {
          await vault.delete(reference);
        }
        await db.close();
        await directory.delete(recursive: true);
      }
    });
    expect(tester.takeException(), isNull);
  });
}
