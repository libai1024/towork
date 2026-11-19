import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/recurrence/recurrence_plans.dart';
import '../domain/recurrence/recurrence_schedule.dart';
import '../domain/workspace/workspace_commands.dart';
import 'local_workspace_session.dart';

enum RecurrenceWindowPhase {
  idle,
  waiting,
  working,
  ready,
  incomplete,
  failed,
  paused,
}

enum RecurrenceWindowProblem { storage, calendar, conflict, invalid }

class RecurrenceWindowState {
  RecurrenceWindowState({
    this.phase = RecurrenceWindowPhase.idle,
    this.through,
    this.seriesCount = 0,
    this.remaining = 0,
    Map<String, RecurrenceWindowProblem> problems = const {},
  }) : problems = Map.unmodifiable(problems);
  final RecurrenceWindowPhase phase;
  final DateTime? through;
  final int seriesCount;
  final int remaining;
  final Map<String, RecurrenceWindowProblem> problems;
}

/// Bounded local calendar materialization. Every batch uses the same
/// versioned workspace commands as manual operations; no model or network runs.
/// A cycle is bounded both in transactions and plans, yielding between cycles.
class RecurrenceWindow extends StateNotifier<RecurrenceWindowState> {
  RecurrenceWindow(
    this.session, {
    required this.clock,
    this.autoSchedule = true,
    this.batchSize = 64,
    this.maxBatches = 8,
    this.maxPlans = 32,
    this.canRun,
    String? afterSeries,
  }) : _lastVisited = afterSeries,
       super(RecurrenceWindowState()) {
    if (batchSize < 1 || batchSize > 400 || maxBatches < 1 || maxPlans < 1) {
      throw ArgumentError('Invalid materialization limits');
    }
    _subscription = session.events.listen((_) => _schedule(Duration.zero));
    _schedule(Duration.zero);
  }
  final LocalWorkspaceSession session;
  final DateTime Function() clock;
  final bool autoSchedule;
  final int batchSize, maxBatches, maxPlans;
  final bool Function()? canRun;
  final _ready = <String, ({int version, DateTime through})>{};
  final _failures =
      <String, ({int version, RecurrenceWindowProblem problem})>{};
  final _pending = <String, WorkspaceCommand>{};
  StreamSubscription<void>? _subscription;
  Timer? _timer;
  Future<void>? _running;
  DateTime? _through;
  String? _lastVisited;
  bool _active = true;
  RecurrenceWindowState get current => state;
  String? get lastVisited => _lastVisited;

  DateTime _defaultThrough() {
    final now = clock().toUtc();
    return DateTime.utc(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
    ).add(const Duration(days: 90));
  }

  /// Extends the requested range (e.g. a future calendar view). Explicit retry
  /// clears failure suppression but retains uncertain commands for exact replay.
  Future<void> refresh({DateTime? through, bool retryFailures = true}) {
    if (!mounted) return Future.value();
    final requested = (through ?? _defaultThrough()).toUtc();
    if (_through == null || requested.isAfter(_through!)) _through = requested;
    if (retryFailures) _failures.clear();
    if (_running != null) return _running!;
    _timer?.cancel();
    final done = Completer<void>();
    _running = done.future;
    unawaited(
      _cycle().whenComplete(() {
        _running = null;
        if (mounted) {
          if (!_active || session.automaticWorkHeld) {
            // Resume or the lease-release event starts the next cycle.
          } else if (session.automaticWorkDelay > Duration.zero) {
            _schedule(session.automaticWorkDelay);
          } else if (state.remaining > state.problems.length &&
              state.phase != RecurrenceWindowPhase.failed) {
            _schedule(const Duration(milliseconds: 200));
          } else {
            _schedule(const Duration(minutes: 1));
          }
        }
        done.complete();
      }),
    );
    return done.future;
  }

  void setActive(bool active) {
    if (!mounted) return;
    if (_active == active) return;
    _active = active;
    _timer?.cancel();
    if (active) {
      // Retry transient failures once per actual resume, not in a tight loop.
      _failures.clear();
      _schedule(Duration.zero);
    } else if (_running == null) {
      _publish(RecurrenceWindowPhase.paused);
    }
  }

  void _schedule(Duration delay) {
    if (!mounted || !autoSchedule || !_active || _running != null) return;
    _timer?.cancel();
    _timer = Timer(delay, () => unawaited(refresh(retryFailures: false)));
  }

  bool _isReady(WorkspaceEntity entity) {
    final ready = _ready[entity.id];
    return ready != null &&
        ready.version == entity.version &&
        !ready.through.isBefore(_through!);
  }

  bool _hasFailure(WorkspaceEntity entity) =>
      _failures[entity.id]?.version == entity.version;

  void _publish(RecurrenceWindowPhase phase, {bool storageFailed = false}) {
    if (!mounted) return;
    final series = session.snapshot.series.toList();
    final problems = <String, RecurrenceWindowProblem>{
      for (final e in series)
        if (_hasFailure(e)) e.id: _failures[e.id]!.problem,
      if (storageFailed) 'workspace': RecurrenceWindowProblem.storage,
    };
    state = RecurrenceWindowState(
      phase: phase,
      through: _through,
      seriesCount: series.length,
      remaining: _through == null
          ? series.length
          : series.where((e) => !_isReady(e)).length,
      problems: problems,
    );
  }

  bool _canContinue() {
    if (!mounted) return false;
    if (!_active || canRun?.call() == false) {
      _publish(RecurrenceWindowPhase.paused);
      return false;
    }
    if (session.automaticWorkHeld ||
        session.automaticWorkDelay > Duration.zero) {
      _publish(RecurrenceWindowPhase.waiting);
      return false;
    }
    return true;
  }

  Future<void> _cycle() async {
    if (!_canContinue()) return;
    _publish(RecurrenceWindowPhase.working);
    try {
      session.accept(await session.store.load());
      if (!_canContinue()) return;
      final ids =
          session.snapshot.series
              .where((e) => !_isReady(e) && !_hasFailure(e))
              .map((e) => e.id)
              .toList()
            ..sort();
      final last = _lastVisited;
      final queue = last == null
          ? ids
          : [
              ...ids.where((id) => id.compareTo(last) > 0),
              ...ids.where((id) => id.compareTo(last) <= 0),
            ];
      // An uncertain commit may have removed/replaced its series in the current
      // snapshot. Replay first; the persisted receipt is authoritative.
      for (final id in _pending.keys) {
        final version =
            session.snapshot.find(WorkspaceEntityKind.series, id)?.version ?? 0;
        if (_failures[id]?.version != version && !queue.contains(id)) {
          queue.add(id);
        }
      }
      var commits = 0, plans = 0;
      final conflicts = <String, int>{};
      while (queue.isNotEmpty && commits < maxBatches && plans < maxPlans) {
        if (!_canContinue()) return;
        final id = queue.removeAt(0);
        _lastVisited = id;
        session.accept(await session.store.load());
        if (!_canContinue()) return;
        final series = session.snapshot.find(WorkspaceEntityKind.series, id);
        if ((series == null || series.isDeleted) && !_pending.containsKey(id)) {
          continue;
        }
        plans++;
        try {
          final command =
              _pending[id] ??
              RecurrencePlans(session.snapshot, now: clock()).materialize(
                id,
                through: _through!,
                operationId: newWorkspaceId('window'),
                limit: batchSize,
              );
          if (command == null) {
            _ready[id] = (version: series!.version, through: _through!);
            _failures.remove(id);
            continue;
          }
          if (!_canContinue()) return;
          _pending[id] = command;
          await session.execute(command);
          _pending.remove(id);
          _failures.remove(id);
          commits++;
          queue.add(id); // A subsequent null plan proves the window complete.
        } on WorkspaceFailure catch (error) {
          if (error.code == WorkspaceFailureCode.storageUnavailable) {
            _failures[id] = (
              version: series?.version ?? 0,
              problem: RecurrenceWindowProblem.storage,
            );
          } else {
            _pending.remove(id);
            if (error.code == WorkspaceFailureCode.versionConflict ||
                error.code == WorkspaceFailureCode.notFound) {
              final count = (conflicts[id] ?? 0) + 1;
              conflicts[id] = count;
              if (count < 3) {
                queue.add(id);
                continue;
              }
              // Read the actual version so repeated contention doesn't spin.
              session.accept(await session.store.load());
              _failures[id] = (
                version:
                    session.snapshot
                        .find(WorkspaceEntityKind.series, id)
                        ?.version ??
                    0,
                problem: RecurrenceWindowProblem.conflict,
              );
            } else {
              _failures[id] = (
                version: series?.version ?? 0,
                problem: RecurrenceWindowProblem.invalid,
              );
            }
          }
        } on RecurrenceCoverageException {
          _failures[id] = (
            version: series!.version,
            problem: RecurrenceWindowProblem.calendar,
          );
        } on FormatException {
          _failures[id] = (
            version: series!.version,
            problem: RecurrenceWindowProblem.invalid,
          );
        }
      }
      if (!_canContinue()) return;
      final series = session.snapshot.series.toList();
      _publish(
        series.every(_isReady)
            ? RecurrenceWindowPhase.ready
            : RecurrenceWindowPhase.incomplete,
      );
    } catch (_) {
      // Never discard committed records or claim a complete range after a read
      // failure. A later explicit retry/resume uses the persisted cursor.
      _publish(RecurrenceWindowPhase.failed, storageFailed: true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
