import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/settings/app_preferences.dart';
import 'app_database.dart';

class SqliteAppPreferencesStore implements AppPreferencesStore {
  SqliteAppPreferencesStore(this.db);
  final AppDatabase db;

  Future<AppPreferenceRow?> _row() => (db.select(
    db.appPreferenceRows,
  )..where((r) => r.singletonId.equals(1))).getSingleOrNull();
  AppPreferences _decode(AppPreferenceRow row) {
    if (row.version < 1) {
      throw const PreferenceFailure(PreferenceFailureCode.invalid);
    }
    return AppPreferences.fromJson(
      (jsonDecode(row.payload) as Map).cast<String, Object?>(),
      version: row.version,
    );
  }

  @override
  Future<AppPreferences> loadOrCreate({
    String legacyInputMode = 'voice',
  }) async {
    try {
      final existing = await _row();
      if (existing != null) return _decode(existing);
      final initial = const AppPreferences().patch({
        'input_mode': legacyInputMode,
      }, nextVersion: 1);
      await db
          .into(db.appPreferenceRows)
          .insert(
            AppPreferenceRowsCompanion.insert(
              singletonId: const Value(1),
              version: 1,
              payload: jsonEncode(initial.toJson()),
            ),
            mode: InsertMode.insertOrIgnore,
          );
      return _decode((await _row())!);
    } on PreferenceFailure {
      rethrow;
    } catch (_) {
      throw const PreferenceFailure(PreferenceFailureCode.storage);
    }
  }

  @override
  Future<AppPreferences> update(
    Map<String, Object?> changes, {
    required int expectedVersion,
  }) async {
    try {
      return await db.transaction(() async {
        final row = await _row();
        if (row == null || row.version != expectedVersion) {
          throw const PreferenceFailure(PreferenceFailureCode.conflict);
        }
        final updated = _decode(row)
            .patch(changes, nextVersion: expectedVersion + 1);
        final count =
            await (db.update(db.appPreferenceRows)..where(
                  (r) =>
                      r.singletonId.equals(1) &
                      r.version.equals(expectedVersion),
                ))
                .write(
                  AppPreferenceRowsCompanion(
                    version: Value(updated.version),
                    payload: Value(jsonEncode(updated.toJson())),
                  ),
                );
        if (count != 1) {
          throw const PreferenceFailure(PreferenceFailureCode.conflict);
        }
        return updated;
      });
    } on PreferenceFailure {
      rethrow;
    } catch (_) {
      throw const PreferenceFailure(PreferenceFailureCode.storage);
    }
  }
}
