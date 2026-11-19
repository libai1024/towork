import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:towork/data/local/app_database.dart';
import 'package:towork/domain/settings/local_profile.dart';

void main() {
  late Directory directory;
  late File file;
  late AppDatabase db;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('towork-profile-');
    file = File('${directory.path}/profile.sqlite');
    db = AppDatabase.background(file);
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  test(
    'rename survives reopening without changing the stable local identity',
    () async {
      final original = await db.loadOrCreateProfile();
      final renamed = await db.renameProfile(
        '  王小明 👨‍👩‍👦  ',
        expectedVersion: original.version,
      );
      expect(renamed.id, original.id);
      expect(renamed.createdAt, original.createdAt);
      expect(renamed.nickname, '王小明 👨‍👩‍👦');
      expect(renamed.version, 2);
      await db.close();
      db = AppDatabase.background(file);
      final restored = await db.loadOrCreateProfile();
      expect(restored.id, original.id);
      expect(restored.nickname, renamed.nickname);
      expect(restored.version, 2);
    },
  );
  test(
    'name validation uses displayed characters and rejects control characters',
    () {
      expect(
        normalizeNickname(List.filled(40, '👨‍👩‍👦').join()).isNotEmpty,
        isTrue,
      );
      for (final invalid in [
        '',
        '   ',
        'a\nb',
        'a\u0000b',
        List.filled(41, '中').join(),
      ]) {
        expect(
          () => normalizeNickname(invalid),
          throwsA(isA<ProfileFailure>()),
        );
      }
    },
  );
  test('simultaneous first reads create exactly one profile', () async {
    final profiles = await Future.wait(
      List.generate(4, (_) => db.loadOrCreateProfile()),
    );
    expect(profiles.map((p) => p.id).toSet(), hasLength(1));
    expect(await db.select(db.localProfiles).get(), hasLength(1));
  });
  test('stale rename cannot overwrite a newer name', () async {
    await db.loadOrCreateProfile();
    await db.renameProfile('已提交', expectedVersion: 1);
    await expectLater(
      db.renameProfile('过期写入', expectedVersion: 1),
      throwsA(
        isA<ProfileFailure>().having(
          (e) => e.code,
          'code',
          ProfileFailureCode.conflict,
        ),
      ),
    );
    expect((await db.loadOrCreateProfile()).nickname, '已提交');
  });
  test('disk write failure keeps the previously committed profile', () async {
    final before = await db.loadOrCreateProfile();
    await db.customStatement('PRAGMA query_only = ON');
    await expectLater(
      db.renameProfile('无法提交', expectedVersion: 1),
      throwsA(isA<ProfileFailure>()),
    );
    expect((await db.loadOrCreateProfile()).nickname, before.nickname);
  });
  test(
    'v1 migration preserves Kimi configuration and cleanup references',
    () async {
      await db.close();
      final legacy = sqlite.sqlite3.open(file.path);
      legacy.execute(
        'CREATE TABLE provider_configurations (id INTEGER NOT NULL PRIMARY KEY, product TEXT NOT NULL, region TEXT NOT NULL, model TEXT NOT NULL, disable_thinking INTEGER NOT NULL, version INTEGER NOT NULL, credential_ref TEXT)',
      );
      legacy.execute(
        'CREATE TABLE credential_cleanup (reference TEXT NOT NULL PRIMARY KEY)',
      );
      legacy.execute(
        'INSERT INTO provider_configurations VALUES (1, ?, ?, ?, 1, 7, ?)',
        ['code', 'china', 'kimi-for-coding', 'reference-only'],
      );
      legacy.execute('INSERT INTO credential_cleanup VALUES (?)', [
        'cleanup-only',
      ]);
      legacy.execute('PRAGMA user_version = 1');
      legacy.close();
      db = AppDatabase.background(file);
      final profile = await db.loadOrCreateProfile();
      expect(profile.nickname, '本地用户');
      final config = await db.readConfiguration();
      expect(config.version, 7);
      expect(config.credentialRef, 'reference-only');
      expect(await db.pendingCleanup(), ['cleanup-only']);
    },
  );
  test('future schema failure never deletes the original database', () async {
    final before = await db.loadOrCreateProfile();
    await db.close();
    final future = sqlite.sqlite3.open(file.path);
    future.execute('PRAGMA user_version = 99');
    future.close();
    db = AppDatabase.background(file);
    await expectLater(db.loadOrCreateProfile(), throwsA(isA<ProfileFailure>()));
    await db.close();
    final preserved = sqlite.sqlite3.open(file.path);
    expect(
      preserved
          .select('SELECT local_user_id FROM local_profiles')
          .single['local_user_id'],
      before.id,
    );
    expect(preserved.select('PRAGMA user_version').single['user_version'], 99);
    preserved.execute('PRAGMA user_version = ${db.schemaVersion}');
    preserved.close();
    db = AppDatabase.background(file);
  });
}
