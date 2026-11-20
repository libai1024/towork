import 'package:towork/app/reminder_wording.dart';

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/notification_coordinator.dart';
import 'package:towork/data/jobs/local_job_store.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/app_preferences_store.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/jobs/local_job.dart';
import 'package:towork/domain/notifications/notification_service.dart';
import 'package:towork/domain/notifications/reminder_plans.dart';
import 'package:towork/domain/settings/app_preferences.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';

import '../support/free/fake_notifications.dart';

void main() {
  late Directory dir;
  late File file;
  late AppDatabase db;
  late LocalJobStore jobs;
  late FakeNotifications native;
  late NotificationCoordinator worker;
  late DateTime now;
  Future<void> prefs(Map<String, Object?> changes) async {
    final store = SqliteAppPreferencesStore(db);
    final current = await store.loadOrCreate();
    await store.update(changes, expectedVersion: current.version);
  }

  Future<void> todo({
    String id = 't',
    Map<String, Object?> patch = const {},
    bool deleting = false,
  }) async {
    final store = SqliteWorkspaceCommandStore(db);
    final old = (await store.load()).find(WorkspaceEntityKind.todo, id);
    await store.execute(
      WorkspaceCommand(
        operationId: newWorkspaceId('test'),
        actions: [
          WorkspaceMutation(
            actionId: 'a',
            kind: WorkspaceEntityKind.todo,
            entityId: id,
            expectedVersion: old?.version,
            mutation: deleting
                ? WorkspaceMutationKind.delete
                : old == null
                ? WorkspaceMutationKind.create
                : WorkspaceMutationKind.update,
            patch: deleting
                ? {}
                : old == null
                ? {
                    'title': '提醒待办',
                    'due_at': now
                        .add(const Duration(hours: 1))
                        .toIso8601String(),
                    'remind_rules': [
                      {'id': 'r', 'offset_minutes': 10},
                    ],
                    ...patch,
                  }
                : patch,
          ),
        ],
      ),
    );
  }

  setUp(() async {
    now = DateTime.utc(2026, 9, 24);
    dir = await Directory.systemTemp.createTemp('notification-test');
    file = File('${dir.path}/db.sqlite');
    db = AppDatabase.background(file);
    jobs = LocalJobStore(db, clock: () => now, jitter: () => 0);
    native = FakeNotifications();
    worker = NotificationCoordinator(
      jobs,
      native,
      onOpen: (_) {},
      clock: () => now,
      automatic: false,
    );
    await prefs({'notify_morning': false});
  });
  tearDown(() async {
    worker.dispose();
    await db.close();
    await dir.delete(recursive: true);
  });
  test('schedule, source changes, completion and undo reconcile without repeating unchanged requests', () async {
    await todo();
    await worker.refresh();
    expect(native.notices, hasLength(1));
    final oldId = native.notices.keys.single;
    expect(
      native.notices.values.single.at,
      now.add(const Duration(minutes: 50)),
    );
    await worker.refresh();
    expect(native.schedules, 1);
    await todo(
      patch: {'due_at': now.add(const Duration(hours: 2)).toIso8601String()},
    );
    await worker.refresh();
    expect(native.notices, hasLength(1));
    expect(native.cancelled, contains(oldId));
    await todo(patch: {'status': 'done'});
    await worker.refresh();
    expect(native.notices, isEmpty);
    await todo(patch: {'status': 'pending'});
    await worker.refresh();
    expect(native.notices, hasLength(1));
    await todo(deleting: true);
    await worker.refresh();
    expect(native.notices, isEmpty);
  });
  test('permission denied keeps data and waiting jobs; granting schedules without prompting at startup', () async {
    native.access = const NotificationAccess(enabled: false, exact: false);
    await todo();
    await worker.refresh();
    expect(native.permissionRequests, 0);
    expect(native.schedules, 0);
    expect(
      (await jobs.list(type: NotificationCoordinator.type)).single.status,
      JobStatus.waitingPermission,
    );
    await worker.requestPermission();
    expect(native.permissionRequests, 1);
    expect(native.notices, hasLength(1));
    native.access = const NotificationAccess(enabled: false, exact: false);
    await worker.refresh();
    expect(native.notices, isEmpty);
    expect((await SqliteWorkspaceCommandStore(db).load()).todos, hasLength(1));
  });
  test('failed acknowledgement cancels uncertain own ID and retries with a fresh identity', () async {
    await todo();
    native.failAfterSchedule = true;
    await worker.refresh();
    expect(native.notices, isEmpty);
    expect(worker.current.failed, 1);
    final old = native.cancelled.single;
    now = now.add(const Duration(seconds: 31));
    await worker.refresh();
    expect(native.notices, hasLength(1));
    expect(native.notices.keys.single, isNot(old));
  });
  test('late old worker cannot cancel or overwrite a newer registration after source changes', () async {
    await todo();
    var fired = false;
    final newer = NotificationCoordinator(
      jobs,
      native,
      onOpen: (_) {},
      clock: () => now,
      automatic: false,
    );
    native.beforeSchedule = () async {
      if (fired) return;
      fired = true;
      await todo(patch: {'title': '更新后的提醒'});
      await newer.refresh();
    };
    try {
      await worker.refresh();
      expect(native.notices, hasLength(1));
      expect(native.notices.values.single.body, '更新后的提醒');
      expect(
        (await jobs.list(type: NotificationCoordinator.type)).single.status,
        JobStatus.succeeded,
      );
    } finally {
      newer.dispose();
    }
  });
  test('missing OS registrations are repaired after reopen, not mistaken for delivery', () async {
    await todo();
    await worker.refresh();
    final old = native.notices.keys.single;
    native.notices.clear();
    worker.dispose();
    await db.close();
    db = AppDatabase.background(file);
    jobs = LocalJobStore(db, clock: () => now);
    worker = NotificationCoordinator(
      jobs,
      native,
      onOpen: (_) {},
      clock: () => now,
      automatic: false,
    );
    await worker.refresh();
    expect(native.notices, hasLength(1));
    expect(native.notices.keys.single, isNot(old));
  });
  test(
    'mismatched OS payload is repaired even if the notification ID exists',
    () async {
      await todo();
      await worker.refresh();
      final id = native.notices.keys.single;
      final notice = native.notices[id]!;
      native.notices[id] = (
        at: notice.at,
        title: notice.title,
        body: notice.body,
        payload: '{}',
        exact: notice.exact,
      );
      await worker.refresh();
      expect(native.notices, hasLength(1));
      expect(native.notices.keys.single, isNot(id));
      expect(native.cancelled, contains(id));
    },
  );
  test(
    'outside-horizon rules stay deferred and enter the rolling window later',
    () async {
      await todo(
        patch: {'due_at': now.add(const Duration(days: 35)).toIso8601String()},
      );
      await worker.refresh();
      expect(native.notices, isEmpty);
      expect(worker.current.deferred, 1);
      now = now.add(const Duration(days: 6));
      await worker.refresh();
      expect(native.notices, hasLength(1));
      expect(worker.current.deferred, 0);
    },
  );
  test('past reminders are not backfilled; empty rules remain off, globals cancel, only due can be exact', () async {
    await todo(
      patch: {
        'due_at': now.subtract(const Duration(hours: 1)).toIso8601String(),
      },
    );
    await worker.refresh();
    expect(native.notices, isEmpty);
    await todo(
      patch: {
        'due_at': now.add(const Duration(hours: 1)).toIso8601String(),
        'remind_rules': <Object?>[],
      },
    );
    await worker.refresh();
    expect(native.notices, isEmpty);
    await todo(
      patch: {
        'remind_rules': [
          {'id': 'r', 'offset_minutes': 0},
        ],
      },
    );
    await worker.requestExactPermission();
    expect(native.notices.values.single.exact, isTrue);
    await prefs({'notify_morning': true});
    await worker.refresh();
    expect(
      native.notices.values
          .where((n) => n.title == '每日待办摘要')
          .every((n) => !n.exact),
      isTrue,
    );
    await prefs({'notify_due': false, 'notify_morning': false});
    await worker.refresh();
    expect(native.notices, isEmpty);
  });
  test(
    'rolling queue is bounded and completion admits the next candidate',
    () async {
      for (var i = 0; i < 65; i++) {
        await todo(
          id: 't$i',
          patch: {'due_at': now.add(Duration(hours: i + 1)).toIso8601String()},
        );
      }
      await worker.refresh();
      expect(native.notices, hasLength(60));
      expect(worker.current.deferred, 5);
      await todo(id: 't0', patch: {'status': 'done'});
      await worker.refresh();
      expect(native.notices, hasLength(60));
      expect(worker.current.deferred, 4);
    },
  );
  test('absolute and relative duplicate times collapse, missing due skips only relative rule', () async {
    final at = now.add(const Duration(hours: 1));
    await todo(
      patch: {
        'due_at': null,
        'remind_rules': [
          {'id': 'relative', 'offset_minutes': 5},
          {'id': 'a', 'absolute_at': at.toIso8601String()},
          {'id': 'b', 'absolute_at': at.toIso8601String()},
        ],
      },
    );
    final plans = reminderPlans(
      await SqliteWorkspaceCommandStore(db).load(),
      const AppPreferences(notifyMorning: false),
      now,
      reminderWording('zh'),
    );
    expect(plans, hasLength(1));
    expect(plans.single.at, at);
    await worker.refresh();
    expect(native.notices, hasLength(1));
  });
  test(
    'oversized imported offsets cannot wrap into a near-future reminder',
    () async {
      await todo(
        patch: {
          'remind_rules': [
            {'id': 'huge', 'offset_minutes': 9223372036854775807},
          ],
        },
      );
      await worker.refresh();
      expect(worker.current.error, isFalse);
      expect(native.notices, isEmpty);
    },
  );
}
