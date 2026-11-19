import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../../../tool/free_probes/database_probe.dart';

void main() {
  late Directory directory;
  late File file;
  late ProbeDatabase db;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('towork-sqlite-test-');
    file = File('${directory.path}/probe.sqlite');
    db = ProbeDatabase.background(file);
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  test(
    'real file survives reopen and exact replay returns the original receipt',
    () async {
      const creation = [ProbeMutation('a', '离线创建')];
      final first = await db.applyBatch('create', creation);
      await db.applyBatch('edit', const [
        ProbeMutation('a', '后续修改', expectedVersion: 1),
      ]);
      await db.close();
      db = ProbeDatabase.background(file);
      expect(await db.applyBatch('create', creation), first);
      final row = (await db.readItems()).single;
      expect(row.title, '后续修改');
      expect(row.version, 2);
      await expectLater(
        db.applyBatch('create', const [ProbeMutation('b', 'different')]),
        throwsA(isA<ProbeConflict>()),
      );
      expect((await db.readItems()).length, 1);
    },
  );

  test(
    'failure after the first write rolls back all rows and receipt',
    () async {
      await db.applyBatch('seed', const [ProbeMutation('existing', '保留')]);
      await expectLater(
        db.applyBatch('batch', const [
          ProbeMutation('new', '必须回滚'),
          ProbeMutation('existing', '错误版本', expectedVersion: 7),
        ]),
        throwsA(isA<ProbeConflict>()),
      );
      final rows = await db.readItems();
      expect(rows.map((e) => e.id), ['existing']);
      expect(rows.single.title, '保留');
      expect(await db.select(db.probeReceipts).get(), hasLength(1));
    },
  );

  test('competing stale edits cannot overwrite a committed edit', () async {
    await db.applyBatch('seed', const [ProbeMutation('a', 'before')]);
    final results = await Future.wait([
      for (var i = 0; i < 2; i++)
        db
            .applyBatch('edit-$i', [
              ProbeMutation('a', 'edit-$i', expectedVersion: 1),
            ])
            .then<Object>((value) => value, onError: (Object error) => error),
    ]);
    expect(results.whereType<String>(), hasLength(1));
    expect(results.whereType<ProbeConflict>(), hasLength(1));
    expect((await db.readItems()).single.version, 2);
  });

  test('v1 real file migrates with existing data preserved', () async {
    await db.close();
    final legacy = sqlite.sqlite3.open(file.path);
    legacy.execute(
      'CREATE TABLE probe_items (id TEXT NOT NULL PRIMARY KEY, title TEXT NOT NULL)',
    );
    legacy.execute('INSERT INTO probe_items VALUES (?, ?)', ['legacy', '旧记录']);
    legacy.execute('PRAGMA user_version = 1');
    legacy.close();
    db = ProbeDatabase.background(file);
    final row = (await db.readItems()).single;
    expect(row.id, 'legacy');
    expect(row.title, '旧记录');
    expect(row.version, 1);
    await db.applyBatch('edit', const [
      ProbeMutation('legacy', '升级后修改', expectedVersion: 1),
    ]);
  });

  test(
    'failed migration rolls back schema changes without wiping the file',
    () async {
      await db.close();
      final legacy = sqlite.sqlite3.open(file.path);
      legacy.execute(
        'CREATE TABLE probe_items (id TEXT NOT NULL PRIMARY KEY, title TEXT NOT NULL)',
      );
      legacy.execute('INSERT INTO probe_items VALUES (?, ?)', ['a', '保留原库']);
      legacy.execute('PRAGMA user_version = 1');
      legacy.close();
      db = ProbeDatabase(
        NativeDatabase.createInBackground(file),
        migrationCheckpoint: () async =>
            throw StateError('injected migration failure'),
      );
      // Background-isolate errors are transported as DriftRemoteException.
      await expectLater(db.readItems(), throwsA(isA<Exception>()));
      await db.close();
      final preserved = sqlite.sqlite3.open(file.path);
      expect(
        preserved.select('SELECT title FROM probe_items').single['title'],
        '保留原库',
      );
      expect(preserved.select('PRAGMA user_version').single['user_version'], 1);
      expect(
        preserved
            .select('PRAGMA table_info(probe_items)')
            .map((r) => r['name']),
        ['id', 'title'],
      );
      preserved.close();
      db = ProbeDatabase.background(file);
      expect((await db.readItems()).single.title, '保留原库');
    },
  );

  test(
    'SQLite read-only fault leaves committed rows and receipts intact',
    () async {
      await db.applyBatch('seed', const [ProbeMutation('a', '原始数据')]);
      await db.customStatement('PRAGMA query_only = ON');
      await expectLater(
        db.applyBatch('failed', const [
          ProbeMutation('a', '不能写入', expectedVersion: 1),
        ]),
        throwsA(isA<Exception>()),
      );
      expect((await db.readItems()).single.title, '原始数据');
      expect(await db.select(db.probeReceipts).get(), hasLength(1));
    },
  );
}
