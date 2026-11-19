import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/local_maintenance.dart';
import 'package:towork/data/jobs/local_job_store.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/app_preferences_store.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/jobs/local_job.dart';
import 'package:towork/domain/recurrence/recurrence_plans.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';

import '../support/free/fake_notifications.dart';

void main() {
  late Directory dir;
  late File file;
  late AppDatabase db;
  late DateTime now;
  late FakeNotifications native;
  late SqliteWorkspaceCommandStore store;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('maintenance');
    file = File('${dir.path}/data.sqlite');
    db = AppDatabase.background(file);
    now = DateTime.utc(2026, 9, 24, 1);
    store = SqliteWorkspaceCommandStore(db, clock: () => now);
    native = FakeNotifications();
    final prefs = SqliteAppPreferencesStore(db);
    final p = await prefs.loadOrCreate();
    await prefs.update({'notify_morning': false}, expectedVersion: p.version);
    await store.execute(
      WorkspaceCommand(
        operationId: 'seed',
        actions: [
          WorkspaceMutation(
            actionId: 'a',
            kind: WorkspaceEntityKind.todo,
            entityId: 't',
            mutation: WorkspaceMutationKind.create,
            patch: {
              'title': '后台补齐',
              'due_at': now.add(const Duration(hours: 2)).toIso8601String(),
              'remind_rules': [
                {'id': 'r', 'offset_minutes': 0},
              ],
            },
          ),
        ],
      ),
    );
    await store.execute(
      RecurrencePlans(await store.load(), now: now).start(
        't',
        rule: 'FREQ=DAILY;COUNT=5',
        timezone: 'Asia/Shanghai',
        operationId: 'start',
        through: now.add(const Duration(hours: 2)),
        limit: 1,
      ),
    );
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });
  test('recent foreground writes retain undo interval; next tick materializes and registers', () async {
    expect(await runLocalMaintenance(db, native, clock: () => now), isTrue);
    expect((await store.load()).todos, hasLength(1));
    final jobs = LocalJobStore(db, clock: () => now);
    expect(
      (await jobs.list(type: 'local_maintenance'))
          .single
          .outcome!['recurrence_deferred'],
      true,
    );
    now = now.add(const Duration(minutes: 16));
    expect(await runLocalMaintenance(db, native, clock: () => now), isTrue);
    expect((await store.load()).todos, hasLength(5));
    expect(native.notices, hasLength(5));
    final count = native.schedules;
    await runLocalMaintenance(db, native, clock: () => now);
    expect(native.schedules, count);
  });
  test(
    'separate connections share one tick lease and reopen keeps result',
    () async {
      now = now.add(const Duration(minutes: 1));
      final other = AppDatabase.background(file);
      try {
        final result = await Future.wait([
          runLocalMaintenance(db, native, clock: () => now),
          runLocalMaintenance(other, native, clock: () => now),
        ]);
        expect(result, everyElement(isTrue));
        expect((await store.load()).todos, hasLength(5));
        expect(native.schedules, 5);
        final rows = await LocalJobStore(other).list(type: 'local_maintenance');
        expect(rows.single.status, JobStatus.succeeded);
        expect(rows.single.attempts, 1);
      } finally {
        await other.close();
      }
    },
  );
  test(
    'successive wakeups rotate through more series than one batch budget',
    () async {
      for (var i = 0; i < 12; i++) {
        final id = 'extra-$i';
        final due = now.add(const Duration(hours: 3));
        await store.execute(
          WorkspaceCommand(
            operationId: 'seed-$id',
            actions: [
              WorkspaceMutation(
                actionId: 'a',
                kind: WorkspaceEntityKind.todo,
                entityId: id,
                mutation: WorkspaceMutationKind.create,
                patch: {'title': id, 'due_at': due.toIso8601String()},
              ),
            ],
          ),
        );
        await store.execute(
          RecurrencePlans(await store.load(), now: now).start(
            id,
            rule: 'FREQ=DAILY;COUNT=2',
            timezone: 'Asia/Shanghai',
            operationId: 'start-$id',
            through: due,
            limit: 1,
          ),
        );
      }
      now = now.add(const Duration(minutes: 1));
      await runLocalMaintenance(db, native, clock: () => now);
      expect((await store.load()).todos.length, lessThan(29));
      now = now.add(const Duration(minutes: 16));
      await runLocalMaintenance(db, native, clock: () => now);
      expect((await store.load()).todos, hasLength(29));
    },
  );
  test(
    'platform stop leaves bounded retry intent and never rewrites business',
    () async {
      now = now.add(const Duration(minutes: 1));
      expect(
        await runLocalMaintenance(
          db,
          native,
          clock: () => now,
          stopped: () => true,
        ),
        isFalse,
      );
      expect((await store.load()).todos, hasLength(1));
      expect(native.notices, isEmpty);
      final row = (await LocalJobStore(db).list(type: 'local_maintenance'))
          .single;
      expect(row.status, JobStatus.retryWait);
      expect(row.errorCode, 'interrupted');
    },
  );
}
