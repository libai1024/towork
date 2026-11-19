import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/jobs/local_job_store.dart';
import '../data/local/app_database.dart';
import '../data/local/app_preferences_store.dart';
import '../data/local/workspace_command_store.dart';
import '../domain/jobs/local_job.dart';
import '../domain/notifications/notification_service.dart';
import '../domain/notifications/reminder_plans.dart';
import '../domain/workspace/workspace_commands.dart';

class NotificationState {
  const NotificationState({
    this.access,
    this.busy = false,
    this.registered = 0,
    this.deferred = 0,
    this.failed = 0,
    this.error = false,
    this.through,
  });
  final NotificationAccess? access;
  final bool busy, error;
  final int registered, deferred, failed;
  final DateTime? through;
}

/// Reconciles durable intent with the OS. System scheduling is not part of a SQL
/// transaction; every lease gets a separate OS ID so a late worker can only
/// cancel its own registration. Delivery itself remains controlled by the OS.
class NotificationCoordinator extends StateNotifier<NotificationState> {
  NotificationCoordinator(
    this.jobs,
    this.service, {
    required this.onOpen,
    DateTime Function()? clock,
    bool automatic = true,
    this.canRun,
  }) : clock = clock ?? DateTime.now,
       super(const NotificationState()) {
    if (automatic) {
      _changes = jobs.db
          .customSelect(
            'SELECT version FROM work_todos UNION ALL SELECT version FROM app_preference_rows',
            readsFrom: {jobs.db.workTodos, jobs.db.appPreferenceRows},
          )
          .watch()
          .listen((_) => request(), onError: (Object _) => _error());
      _timer = Timer.periodic(const Duration(minutes: 1), (_) => request());
      request();
    }
  }
  final LocalJobStore jobs;
  final NotificationService service;
  final void Function(String?) onOpen;
  final DateTime Function() clock;
  final bool Function()? canRun;
  bool get _canContinue => mounted && _active && canRun?.call() != false;
  final owner = newWorkspaceId('notifier');
  static const type = 'local_notification';
  static final _immediate = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  StreamSubscription<Object?>? _changes;
  Timer? _timer, _debounce;
  Future<void>? _work;
  bool _again = false, _initialized = false, _active = true;
  NotificationState get current => state;
  void _error() {
    if (mounted) state = NotificationState(access: state.access, error: true);
  }

  void setActive(bool active) {
    final changed = _active != active;
    _active = active;
    if (changed && active) request();
  }

  void request() {
    if (!mounted || !_active || _debounce?.isActive == true) return;
    _debounce = Timer(
      const Duration(milliseconds: 200),
      () => unawaited(refresh()),
    );
  }

  Future<void> refresh({bool retryFailures = false}) {
    if (_work != null) {
      _again = true;
      return _work!;
    }
    final task = _run(retryFailures);
    _work = task;
    return task.whenComplete(() {
      _work = null;
    });
  }

  Future<Map<String, ReminderPlan>> _plans() async => {
    for (final p in reminderPlans(
      await SqliteWorkspaceCommandStore(jobs.db).load(),
      await SqliteAppPreferencesStore(jobs.db).loadOrCreate(),
      clock(),
    ))
      p.key: p,
  };
  Map<String, Object?> _payload(ReminderPlan plan, NotificationAccess access) =>
      {...plan.payload, 'exact': access.exact && plan.payload['kind'] == 'due'};
  Future<bool> _valid(LocalJob job, NotificationAccess access) async {
    final candidate = (await _plans())[job.uniqueKey];
    return candidate != null &&
        canonicalWorkspaceJson(_payload(candidate, access)) ==
            canonicalWorkspaceJson(job.payload);
  }

  String _notificationPayload(LocalJob job) => jsonEncode({
    'towork': 1,
    'job_id': job.id,
    'epoch': job.epoch,
    'todo_id': job.payload['todo_id'],
    'kind': job.payload['kind'],
  });
  Future<void> _cancelAttempt(int id) async {
    await service.cancel(id);
    await (jobs.db.update(jobs.db.notificationAttempts)
          ..where((r) => r.id.equals(id)))
        .write(const NotificationAttemptsCompanion(cancelled: Value(true)));
  }

  Future<void> _cleanup(NotificationAccess access) async {
    final attempts = await (jobs.db.select(
      jobs.db.notificationAttempts,
    )..where((r) => r.cancelled.equals(false))).get();
    for (final attempt in attempts) {
      final job = await jobs.read(attempt.jobId);
      final valid =
          access.enabled &&
          job != null &&
          job.epoch == attempt.leaseEpoch &&
          (job.status == JobStatus.succeeded ||
              job.status == JobStatus.running &&
                  job.leaseExpiresAt!.isAfter(clock().toUtc()));
      if (!valid) await _cancelAttempt(attempt.id);
    }
  }

  Future<void> _run(bool retryFailures) async {
    try {
      if (!_initialized) {
        await service.initialize(onOpen);
        _initialized = true;
      }
      if (retryFailures) await jobs.wake(type, JobStatus.failed);
      do {
        _again = false;
        if (!_canContinue) return;
        state = NotificationState(access: state.access, busy: true);
        final access = await service.inspect();
        if (!access.supported) {
          if (mounted) state = NotificationState(access: access);
          return;
        }
        final now = clock().toUtc();
        late List<ReminderPlan> future;
        late List<ReminderPlan> selected;
        late Set<String> desired;
        await jobs.db.transaction(() async {
          final plans = await _plans();
          future = plans.values.where((p) => p.at.isAfter(now)).toList()
            ..sort(
              (a, b) =>
                  a.at == b.at ? a.key.compareTo(b.key) : a.at.compareTo(b.at),
            );
          // A bounded rolling window avoids exhausting OS queues. Farther rules
          // remain in the business DB and enter this window on future reconciles.
          selected = future
              .where((p) => !p.at.isAfter(now.add(const Duration(days: 30))))
              .take(60)
              .toList();
          desired = selected.map((p) => p.key).toSet();
          for (final old in await jobs.list(type: type)) {
            final plan = plans[old.uniqueKey];
            final keepPast =
                plan != null &&
                !plan.at.isAfter(now) &&
                canonicalWorkspaceJson(_payload(plan, access)) ==
                    canonicalWorkspaceJson(old.payload);
            if (!desired.contains(old.uniqueKey) && !keepPast) {
              await jobs.cancel(old.id);
            }
          }
          for (final plan in selected) {
            await jobs.enqueue(
              key: plan.key,
              type: type,
              dueAt: _immediate,
              payload: _payload(plan, access),
            );
          }
        });
        if (access.enabled) await jobs.wake(type, JobStatus.waitingPermission);
        await _cleanup(access);
        final pending = {
          for (final p in await service.pending()) p.id: p.payload,
        };
        for (final job in await jobs.list(type: type)) {
          final id = job.outcome?['notification_id'];
          if (job.status == JobStatus.succeeded &&
              id is int &&
              desired.contains(job.uniqueKey) &&
              pending[id] != _notificationPayload(job)) {
            await jobs.db.customUpdate(
              "UPDATE local_job_rows SET status='scheduled', attempts=0, lease_epoch=lease_epoch+1, next_attempt_at=?, outcome=NULL WHERE id=? AND lease_epoch=? AND status='succeeded'",
              variables: [
                Variable(now.millisecondsSinceEpoch),
                Variable(job.id),
                Variable(job.epoch),
              ],
              updates: {jobs.db.localJobRows},
            );
          }
        }
        for (var n = 0; n < 60 && _canContinue; n++) {
          final job = await jobs.claim(owner: owner, type: type);
          if (job == null) break;
          int? notificationId;
          try {
            if (!await _valid(job, access)) {
              await jobs.cancelLease(job);
              _again = true;
              continue;
            }
            final at = DateTime.parse(job.payload['at']! as String);
            if (!at.isAfter(clock().toUtc())) {
              await jobs.complete(job, outcome: {'status': 'missed'});
              continue;
            }
            if (!access.enabled) {
              await jobs.fail(
                job,
                code: 'permission_denied',
                waiting: JobStatus.waitingPermission,
              );
              continue;
            }
            notificationId = await jobs.allocateNotification(job);
            final payload = _notificationPayload(job);
            await service.schedule(
              id: notificationId,
              at: at,
              title: job.payload['title']! as String,
              body: job.payload['body']! as String,
              payload: payload,
              exact: job.payload['exact']! as bool,
            );
            if (!await _valid(job, access)) {
              await jobs.cancelLease(job);
              await _cancelAttempt(notificationId);
              _again = true;
              continue;
            }
            await jobs.complete(
              job,
              outcome: {
                'status': 'registered',
                'notification_id': notificationId,
              },
            );
          } catch (_) {
            // A timed-out or superseded attempt never cancels a newer lease's ID.
            if (notificationId != null) {
              try {
                await _cancelAttempt(notificationId);
              } catch (_) {}
            }
            if (await jobs.isCurrent(job)) {
              await jobs.fail(job, code: 'platform_error');
            }
          }
        }
        await _cleanup(access);
        final currentJobs = await jobs.list(type: type);
        final registered = currentJobs
            .where(
              (j) =>
                  j.status == JobStatus.succeeded &&
                  j.outcome?['status'] == 'registered' &&
                  desired.contains(j.uniqueKey),
            )
            .length;
        if (mounted) {
          state = NotificationState(
            access: access,
            registered: registered,
            deferred: future.length - selected.length,
            failed: currentJobs
                .where(
                  (j) => {
                    JobStatus.failed,
                    JobStatus.retryWait,
                  }.contains(j.status),
                )
                .length,
            through: selected.lastOrNull?.at,
          );
        }
      } while (_again && _canContinue);
    } catch (_) {
      _error();
    }
  }

  Future<void> requestPermission() async {
    await service.requestPermission();
    await refresh();
  }

  Future<void> requestExactPermission() async {
    await service.requestExactPermission();
    await refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _debounce?.cancel();
    unawaited(_changes?.cancel());
    super.dispose();
  }
}
