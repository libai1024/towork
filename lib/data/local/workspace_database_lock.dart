import 'dart:io';

import 'package:sqlite3/sqlite3.dart';
import 'package:drift/isolate.dart' show DriftRemoteException;

void configureWorkspaceConnection(Database database) {
  database.execute('PRAGMA busy_timeout = 5000');
  // WAL 让前台与后台维护两个连接互不阻塞（读不阻塞写）。
  // journal_mode 切换可能直接返回 SQLITE_BUSY，busy_timeout 对这一步
  // 不保证等待。各后台 isolate 在有界时间内重试首次建库的竞争。
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (true) {
    try {
      database.execute('PRAGMA journal_mode=WAL');
      break;
    } on SqliteException catch (error) {
      if (error.resultCode != 5 || DateTime.now().isAfter(deadline)) {
        rethrow;
      }
      sleep(const Duration(milliseconds: 25));
    }
  }
}

/// Both Flutter engines can enter onCreate before either has committed. Retry
/// only lock acquisition, never a partially executed migration.
Future<void> beginWorkspaceMigration(
  Future<void> Function(String) execute,
) async {
  final elapsed = Stopwatch()..start();
  // Yield between short waits so the lock holder can finish opening the DB
  // even when multiple background isolates share a busy worker pool.
  await execute('PRAGMA busy_timeout = 100');
  try {
    while (true) {
      try {
        await execute('BEGIN IMMEDIATE');
        return;
      } catch (error) {
        // Drift's isolate protocol can serialize the cause to a string.
        final busy = switch (error) {
          SqliteException() => (error.resultCode & 255) == 5,
          DriftRemoteException() => error.toString().startsWith(
            'SqliteException(5):',
          ),
          _ => false,
        };
        if (!busy || elapsed.elapsed >= const Duration(seconds: 15)) {
          rethrow;
        }
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }
    }
  } finally {
    await execute('PRAGMA busy_timeout = 5000');
  }
}
