import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';

void main() {
  late Directory dir;
  late File file;
  final connections = <AppDatabase>[];
  AppDatabase open() {
    final db = AppDatabase.background(file);
    connections.add(db);
    return db;
  }

  Future<void> closeAll() async {
    for (final db in connections) {
      await db.close();
    }
    connections.clear();
  }

  final previous = driftRuntimeOptions.dontWarnAboutMultipleDatabases;
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  tearDownAll(
    () => driftRuntimeOptions.dontWarnAboutMultipleDatabases = previous,
  );
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('mobile-migration-');
    file = File('${dir.path}/workspace.sqlite');
  });
  tearDown(() async {
    await closeAll();
    await dir.delete(recursive: true);
  });
  String fixture(String name) =>
      File('test/fixtures/local/$name.sql').readAsStringSync();

  test('retained schema 13 fixture matches a freshly initialized database', () async {
    final db = open();
    const query =
        "SELECT type, name, sql FROM sqlite_master WHERE sql IS NOT NULL AND name NOT LIKE 'sqlite_%' ORDER BY type, name";
    final fresh = await db.customSelect(query).get();
    final archived = sqlite.sqlite3.openInMemory();
    addTearDown(archived.close);
    archived.execute(fixture('schema_v13'));
    expect(
      archived.select(query).map((r) => Map.of(r)).toList(),
      fresh.map((r) => r.data).toList(),
    );
    expect(
      db.schemaVersion,
      13,
      reason: 'Keep this archive for the next real migration and add its successor.',
    );
  });

  test('two cold connections migrate version 12, retry once and reopen after a failed commit', () async {
    final raw = sqlite.sqlite3.open(file.path);
    raw.execute(fixture('schema_v12'));
    raw.execute(fixture('workspace_migration_seed'));
    raw.execute(
      "INSERT INTO provider_configurations VALUES(1,'code','china','kimi-for-coding',1,7,'fixture-key-ref')",
    );
    raw.execute('PRAGMA user_version = 12');
    final oldJournal = raw
        .select('SELECT * FROM workspace_operations ORDER BY operation_id')
        .map((r) => Map.of(r))
        .toList();
    raw.close();
    final first = open();
    final peer = open();
    final stores = [
      SqliteWorkspaceCommandStore(first),
      SqliteWorkspaceCommandStore(peer),
    ];
    final snapshots = await Future.wait(stores.map((store) => store.load()));
    final old = snapshots.first.todos.single;
    expect(old.data['status'], 'done');
    expect(old.version, 2);
    for (final db in [first, peer]) {
      expect(
        (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
          'user_version',
        ),
        13,
      );
      expect(
        (await db.select(db.providerAccounts).getSingle()).credentialRef,
        'fixture-key-ref',
      );
      final journal = await db
          .customSelect(
            'SELECT * FROM workspace_operations ORDER BY operation_id',
          )
          .get();
      expect(journal.map((row) => row.data).toList(), oldJournal);
    }
    expect(snapshots.last.todos.single.toJson(), old.toJson());
    WorkspaceCommand edit(String op, int version, String note) =>
        WorkspaceCommand(
          operationId: op,
          actions: [
            WorkspaceMutation(
              actionId: 'edit',
              kind: WorkspaceEntityKind.todo,
              entityId: old.id,
              expectedVersion: version,
              mutation: WorkspaceMutationKind.update,
              patch: {'note': note},
            ),
          ],
        );
    final request = edit('both-engines', 2, 'committed');
    final receipts = await Future.wait(stores.map((s) => s.execute(request)));
    expect(receipts.first.toJson(), receipts.last.toJson());
    expect(receipts.first.affected.single.version, 3);
    final interrupted = SqliteWorkspaceCommandStore(
      peer,
      checkpoint: (stage) {
        if (stage == WorkspaceCommitCheckpoint.receiptWritten) {
          throw StateError('injected');
        }
      },
    );
    await expectLater(
      interrupted.execute(edit('interrupted', 3, 'discarded')),
      throwsA(
        isA<WorkspaceFailure>().having(
          (e) => e.code,
          'code',
          WorkspaceFailureCode.storageUnavailable,
        ),
      ),
    );
    await closeAll();
    final reopened = open();
    final store = SqliteWorkspaceCommandStore(reopened);
    final restored = (await store.load()).todos.single;
    expect(restored.version, 3);
    expect(restored.data['note'], 'committed');
    expect(
      await reopened.select(reopened.workspaceOperations).get(),
      hasLength(3),
    );
    expect((await store.execute(request)).toJson(), receipts.first.toJson());
  });
}
