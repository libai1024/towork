import '../data/jobs/local_job_store.dart';
import '../data/local/app_database.dart';
import '../data/local/workspace_command_store.dart';
import '../domain/jobs/local_job.dart';
import '../domain/notifications/notification_service.dart';
import '../domain/workspace/workspace_commands.dart';
import 'local_workspace_session.dart';
import 'notification_coordinator.dart';
import 'recurrence_window.dart';

/// A bounded local maintenance pass. It never restores or executes an Agent
/// command and does not initialize credentials or a model client.
Future<bool> runLocalMaintenance(
  AppDatabase db,
  NotificationService notices, {
  DateTime Function()? clock,
  bool Function()? stopped,
}) async {
  final now = clock ?? DateTime.now;
  final jobs = LocalJobStore(db, clock: now);
  const type = 'local_maintenance';
  final tick = now().toUtc().millisecondsSinceEpoch ~/ 900000;
  final previous = (await jobs.list(type: type)).firstOrNull;
  final payload = previous?.payload['tick'] == tick
      ? previous!.payload
      : <String, Object?>{
          'schema': 1,
          'tick': tick,
          'after_series':
              previous?.outcome?['last_series'] ??
              previous?.payload['after_series'],
        };
  await jobs.enqueue(
    key: 'maintenance:v1',
    type: type,
    dueAt: DateTime.fromMillisecondsSinceEpoch(tick * 900000, isUtc: true),
    payload: payload,
    maxAttempts: 3,
  );
  final lease = await jobs.claim(
    owner: newWorkspaceId('maintenance'),
    type: type,
    lease: const Duration(minutes: 5),
  );
  if (lease == null) return true;
  final elapsed = Stopwatch()..start();
  bool allowed() =>
      stopped?.call() != true && elapsed.elapsed < const Duration(seconds: 90);
  LocalWorkspaceSession? session;
  RecurrenceWindow? recurrence;
  NotificationCoordinator? notifications;
  try {
    if (!allowed()) throw const JobFailure('interrupted');
    final store = SqliteWorkspaceCommandStore(db, clock: now);
    session = LocalWorkspaceSession(store, await store.load());
    recurrence = RecurrenceWindow(
      session,
      clock: now,
      autoSchedule: false,
      canRun: allowed,
      afterSeries: lease.payload['after_series'] as String?,
    );
    // Give recently committed manual/Agent actions their undo interval even
    // when this worker owns another database connection or Flutter engine.
    final latestUserWrite = await db
        .customSelect(
          "SELECT MAX(committed_at) AS recent FROM workspace_operations WHERE source != 'system'",
        )
        .getSingle();
    final recent = latestUserWrite.data['recent'] as int?;
    final quiet =
        recent == null ||
        now().toUtc().microsecondsSinceEpoch - recent >= 15000000;
    if (quiet) await recurrence.refresh();
    if (!allowed() || !await jobs.isCurrent(lease)) {
      throw const JobFailure('interrupted');
    }
    notifications = NotificationCoordinator(
      jobs,
      notices,
      onOpen: (_) {},
      clock: now,
      automatic: false,
      canRun: allowed,
    );
    await notifications.refresh();
    if (!allowed() ||
        notifications.current.error ||
        recurrence.current.phase == RecurrenceWindowPhase.failed) {
      throw const JobFailure('maintenance_failed');
    }
    await jobs.complete(
      lease,
      outcome: {
        'finished_at': now().toUtc().toIso8601String(),
        'recurrence_remaining': recurrence.current.remaining,
        'recurrence_problems': recurrence.current.problems.length,
        'recurrence_deferred': !quiet,
        'last_series': recurrence.lastVisited,
        'registered': notifications.current.registered,
        'notification_failures': notifications.current.failed,
      },
    );
    return true;
  } catch (_) {
    if (await jobs.isCurrent(lease)) {
      await jobs.fail(
        lease,
        code: stopped?.call() == true ? 'interrupted' : 'maintenance_failed',
      );
    }
    return false;
  } finally {
    recurrence?.dispose();
    notifications?.dispose();
    await session?.dispose();
    session?.todos.dispose();
    session?.categories.dispose();
  }
}
