import 'dart:io';
import 'dart:isolate';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:towork/app/local_maintenance.dart';
import 'package:towork/app/background_maintenance.dart' as production;
import 'package:towork/data/jobs/local_job_store.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/app_preferences_store.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/data/notifications/native_notification_service.dart';
import 'package:towork/domain/jobs/local_job.dart';
import 'package:towork/domain/recurrence/recurrence_plans.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';

// Only this test entrypoint accepts a fixture basename. Production ignores all
// callback input and opens its fixed, existing workspace path.
@pragma('vm:entry-point')
void fixtureDispatcher() {
  Workmanager().executeTask((task, input) async {
    final name = input?['fixture'] as String?;
    if (task != 'towork.fixture-maintenance' ||
        name == null ||
        !RegExp(r'^maintenance-test-\d+\.sqlite$').hasMatch(name)) {
      return true;
    }
    final root = await getApplicationSupportDirectory();
    final db = AppDatabase.background(File('${root.path}/$name'));
    try {
      final result = await runLocalMaintenance(
        db,
        NativeNotificationService(background: true),
      );
      await db.customStatement(
        'INSERT INTO fixture_worker(isolate_id, result) VALUES (?, ?)',
        [Isolate.current.hashCode, result ? 1 : 0],
      );
      return result;
    } finally {
      await db.close();
    }
  });
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android WorkManager runs local maintenance in another engine', (
    tester,
  ) async {
    final root = await getApplicationSupportDirectory();
    final name =
        'maintenance-test-${DateTime.now().microsecondsSinceEpoch}.sqlite';
    final file = File('${root.path}/$name');
    final db = AppDatabase.background(file);
    final taskId = 'towork.test.${DateTime.now().microsecondsSinceEpoch}';
    final native = NativeNotificationService();
    try {
      final prefs = SqliteAppPreferencesStore(db);
      await prefs.loadOrCreate();
      await db.customStatement(
        'CREATE TABLE fixture_worker(isolate_id INTEGER, result INTEGER)',
      );
      await db.customStatement(
        "INSERT INTO sqlite_sequence(name, seq) VALUES ('notification_attempts', ?)",
        [1500000000 + DateTime.now().millisecondsSinceEpoch % 300000000],
      );
      final now = DateTime.now().toUtc();
      final store = SqliteWorkspaceCommandStore(
        db,
        clock: () => now.subtract(const Duration(minutes: 1)),
      );
      await store.execute(
        WorkspaceCommand(
          operationId: 'seed',
          actions: [
            WorkspaceMutation(
              actionId: 'a',
              kind: WorkspaceEntityKind.todo,
              entityId: 'background-todo',
              mutation: WorkspaceMutationKind.create,
              patch: {
                'title': '后台真实维护',
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
          'background-todo',
          rule: 'FREQ=DAILY;COUNT=4',
          timezone: 'Asia/Shanghai',
          operationId: 'start',
          through: now.add(const Duration(hours: 2)),
          limit: 1,
        ),
      );
      await native.initialize((_) {});
      expect(
        (await native.inspect()).enabled,
        isTrue,
        reason: 'Grant notification permission before this test',
      );
      expect(
        await production.registerBackgroundMaintenance(),
        production.MaintenanceRegistration.scheduled,
      );
      final periodic = await Workmanager().getWorkInfo(
        production.maintenanceTask,
      );
      expect(periodic?.isPeriodic, isTrue);
      await Workmanager().cancelByUniqueName(production.maintenanceTask);
      await Workmanager().initialize(fixtureDispatcher);
      await tester.pumpWidget(const SizedBox());
      await Workmanager().registerOneOffTask(
        taskId,
        'towork.fixture-maintenance',
        initialDelay: const Duration(seconds: 20),
        inputData: {'fixture': name},
      );
      debugPrint(
        'maintenance fixture registered; waiting for the real Android worker',
      );
      final timer = Stopwatch()..start();
      while (timer.elapsed < const Duration(seconds: 60)) {
        if ((await Workmanager().getWorkInfo(taskId))?.state ==
            WorkState.succeeded) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      expect(
        (await Workmanager().getWorkInfo(taskId))?.state,
        WorkState.succeeded,
      );
      final receipt = await db
          .customSelect('SELECT * FROM fixture_worker')
          .getSingle();
      expect(receipt.data['isolate_id'], isNot(Isolate.current.hashCode));
      expect(receipt.data['result'], 1);
      expect((await store.load()).todos, hasLength(4));
      final job = (await LocalJobStore(db).list(type: 'local_maintenance'))
          .single;
      expect(job.status, JobStatus.succeeded);
      expect(job.outcome!['recurrence_remaining'], 0);
      final ownIds = (await db.select(db.notificationAttempts).get())
          .map((a) => a.id)
          .toSet();
      final pending = (await native.pending()).where(
        (n) => ownIds.contains(n.id),
      );
      expect(
        pending.where((p) => p.payload?.contains('"kind":"due"') == true),
        hasLength(4),
      );
      expect(
        pending
            .where((p) => p.payload?.contains('"kind":"morning"') == true)
            .length,
        greaterThanOrEqualTo(6),
      );
      debugPrint(
        'independent Android worker committed recurrence and native notifications',
      );
    } finally {
      await Workmanager().cancelByUniqueName(taskId);
      await Workmanager().cancelByUniqueName(production.maintenanceTask);
      await Workmanager().initialize(production.callbackDispatcher);
      for (final row in await db.select(db.notificationAttempts).get()) {
        await native.cancel(row.id);
      }
      await db.close();
      for (final suffix in ['', '-wal', '-shm']) {
        final part = File('${file.path}$suffix');
        if (await part.exists()) await part.delete();
      }
    }
  }, skip: !Platform.isAndroid);
}
