import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/app_database.dart';
import '../data/local/sqlite_row_query.dart';
import '../data/local/workspace_command_store.dart';
import 'local_database_provider.dart';

/// FE-facing wrapper over the SQL row query path. Each call loads the light
/// table snapshot so results always reflect committed schema state.
class BusinessRowSearch {
  BusinessRowSearch(this._db);
  final AppDatabase _db;

  Future<Map<String, Object?>> rows(Map<String, Object?> args) async {
    final tables = await SqliteWorkspaceCommandStore(_db).loadTables();
    return SqliteRowQuery.rows(_db, tables, args);
  }
}

/// Null when no local database is mounted (demo mode falls back to the
/// in-memory repository search).
final businessRowSearchProvider = FutureProvider<BusinessRowSearch?>((
  ref,
) async {
  final db = await ref.watch(localDatabaseProvider.future);
  return BusinessRowSearch(db);
});
