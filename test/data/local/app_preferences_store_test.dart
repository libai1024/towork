import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/app_preferences_store.dart';
import 'package:towork/domain/settings/app_preferences.dart';
import 'package:towork/domain/ai/permission_policy.dart';

void main() {
  late Directory directory;
  late File file;
  late AppDatabase db;
  late SqliteAppPreferencesStore store;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('preferences-test');
    file = File('${directory.path}/prefs.sqlite');
    db = AppDatabase.background(file);
    store = SqliteAppPreferencesStore(db);
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  test(
    'legacy input migrates once; all preferences survive reopening',
    () async {
      final first = await store.loadOrCreate(legacyInputMode: 'keyboard');
      expect(first.inputMode, 'keyboard');
      expect(first.permission, AiWritePermission.askOnChange);
      await store.update({
        'theme': 'dark',
        'input_mode': 'voice',
        'permission': 'askAll',
        'memory_paused': true,
        'notify_due': false,
        'notify_morning': false,
        'morning_hour': 23,
        'morning_minute': 59,
        'notify_report': false,
        'auto_route': true,
        'custom_instructions': '回答尽量简短',
        'speech_vocabulary': ['立创', '嘉立创'],
      }, expectedVersion: first.version);
      await db.close();
      db = AppDatabase.background(file);
      store = SqliteAppPreferencesStore(db);
      final result = await store.loadOrCreate(legacyInputMode: 'keyboard');
      expect(result.version, 2);
      expect(result.toJson(), {
        'theme': 'dark',
        'input_mode': 'voice',
        'permission': 'askAll',
        'memory_paused': true,
        'notify_due': false,
        'notify_morning': false,
        'morning_hour': 23,
        'morning_minute': 59,
        'notify_report': false,
        'font_scale': 1.0,
        'last_export_at': 0,
        'auto_route': true,
        'custom_instructions': '回答尽量简短',
        'speech_vocabulary': ['立创', '嘉立创'],
      });
      expect(
        result.toJson().keys.any(
          (key) => key.contains('key') || key.contains('credential'),
        ),
        isFalse,
      );
    },
  );
  test('stale policy writes cannot widen newer permissions', () async {
    await store.loadOrCreate();
    await store.update({'permission': 'askAll'}, expectedVersion: 1);
    await expectLater(
      store.update({'permission': 'auto'}, expectedVersion: 1),
      throwsA(
        isA<PreferenceFailure>().having(
          (e) => e.code,
          'code',
          PreferenceFailureCode.conflict,
        ),
      ),
    );
    expect((await store.loadOrCreate()).permission, AiWritePermission.askAll);
  });
  test(
    'invalid fields and read-only writes preserve the committed configuration',
    () async {
      await store.loadOrCreate();
      for (final patch in <Map<String, Object?>>[
        {'permission': 'unknown'},
        {'memory_paused': null},
        {'morning_hour': 24},
        {'morning_minute': -1},
        {'input_mode': 'audio'},
        {'api_key': 'synthetic-secret'},
      ]) {
        await expectLater(
          store.update(patch, expectedVersion: 1),
          throwsA(isA<PreferenceFailure>()),
        );
      }
      await db.customStatement('PRAGMA query_only = ON');
      await expectLater(
        store.update({'memory_paused': true}, expectedVersion: 1),
        throwsA(isA<PreferenceFailure>()),
      );
      expect((await store.loadOrCreate()).version, 1);
      await db.customStatement('PRAGMA query_only = OFF');
      expect(
        (await store.update({
          'memory_paused': true,
        }, expectedVersion: 1)).memoryPaused,
        isTrue,
      );
    },
  );
  test(
    'unrecognized stored permission fails closed instead of resetting defaults',
    () async {
      await store.loadOrCreate();
      await db.customStatement(
        "UPDATE app_preference_rows SET payload = replace(payload, 'askOnChange', 'unknown')",
      );
      await expectLater(
        store.loadOrCreate(),
        throwsA(isA<PreferenceFailure>()),
      );
      final raw = await db
          .customSelect('SELECT payload FROM app_preference_rows')
          .getSingle();
      expect(raw.read<String>('payload'), contains('unknown'));
    },
  );
  test('v3 upgrade preserves identity and provider configuration', () async {
    await db.close();
    final raw = sqlite.sqlite3.open(file.path);
    raw.execute(File('test/fixtures/local/schema_v3.sql').readAsStringSync());
    raw.execute(
      "INSERT INTO local_profiles VALUES(1,'stable-user','旧昵称',3,1700000000)",
    );
    raw.execute(
      "INSERT INTO provider_configurations VALUES(1,'code','china','fixture',0,2,'secret-reference')",
    );
    raw.close();
    db = AppDatabase.background(file);
    store = SqliteAppPreferencesStore(db);
    expect((await store.loadOrCreate()).version, 1);
    expect((await db.loadOrCreateProfile()).nickname, '旧昵称');
    expect((await db.readConfiguration()).credentialRef, 'secret-reference');
    expect(
      (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
        'user_version',
      ),
      13,
    );
  });
  test('failed v3 migration retains version and identity and can be retried', () async {
    await db.close();
    var raw = sqlite.sqlite3.open(file.path);
    raw.execute(File('test/fixtures/local/schema_v3.sql').readAsStringSync());
    raw.execute(
      "INSERT INTO local_profiles VALUES(1,'stable-user','迁移保护',3,1700000000)",
    );
    raw.execute('CREATE TABLE app_preference_rows (unexpected TEXT)');
    raw.close();
    db = AppDatabase.background(file);
    store = SqliteAppPreferencesStore(db);
    await expectLater(store.loadOrCreate(), throwsA(isA<PreferenceFailure>()));
    await db.close();
    raw = sqlite.sqlite3.open(file.path);
    expect(raw.select('PRAGMA user_version').single['user_version'], 3);
    expect(
      raw.select('SELECT nickname FROM local_profiles').single['nickname'],
      '迁移保护',
    );
    raw.execute('DROP TABLE app_preference_rows');
    raw.close();
    db = AppDatabase.background(file);
    store = SqliteAppPreferencesStore(db);
    expect((await store.loadOrCreate()).version, 1);
    expect((await db.loadOrCreateProfile()).nickname, '迁移保护');
  });
}
