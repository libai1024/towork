import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/local_workspace_session.dart';
import 'package:towork/app/recurrence_window.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/recurrence/recurrence_plans.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';
import 'package:towork/domain/workspace/workspace_plans.dart';

class _FaultStore implements WorkspaceCommandStore {
  _FaultStore(this.inner);
  final WorkspaceCommandStore inner;
  bool failBefore = false, failAfter = false, failLoad = false;
  Future<void> Function()? beforeExecute;
  Completer<void>? loadGate;
  final submitted = <WorkspaceCommand>[];
  @override
  Future<WorkspaceSnapshot> load() async {
    await loadGate?.future;
    if (failLoad) {
      throw const WorkspaceFailure(WorkspaceFailureCode.storageUnavailable);
    }
    return inner.load();
  }

  @override
  Stream<WorkspaceSnapshot> watch() => inner.watch();
  @override
  Future<WorkspaceReceipt> execute(WorkspaceCommand command) async {
    submitted.add(command);
    if (failBefore) {
      throw const WorkspaceFailure(WorkspaceFailureCode.storageUnavailable);
    }
    final hook = beforeExecute;
    beforeExecute = null;
    await hook?.call();
    final receipt = await inner.execute(command);
    if (failAfter) {
      failAfter = false;
      throw const WorkspaceFailure(WorkspaceFailureCode.storageUnavailable);
    }
    return receipt;
  }

  @override
  Future<WorkspaceReceipt> undo(String id, {required String operationId}) =>
      inner.undo(id, operationId: operationId);
}

void main() {
  late Directory dir;
  late AppDatabase db;
  late SqliteWorkspaceCommandStore store;
  late _FaultStore fault;
  late LocalWorkspaceSession session;
  late RecurrenceWindow worker;
  late DateTime now;
  Future<void> attach({int batchSize = 64, int maxBatches = 8}) async {
    store = SqliteWorkspaceCommandStore(db, clock: () => now);
    fault = _FaultStore(store);
    session = LocalWorkspaceSession(
      fault,
      await store.load(),
      elapsed: () => now.difference(DateTime.utc(2020)),
    );
    worker = RecurrenceWindow(
      session,
      clock: () => now,
      autoSchedule: false,
      batchSize: batchSize,
      maxBatches: maxBatches,
    );
  }

  Future<void> close() async {
    worker.dispose();
    await session.dispose();
    session.todos.dispose();
    session.categories.dispose();
    await db.close();
  }

  setUp(() async {
    now = DateTime.utc(2026, 9, 24);
    dir = await Directory.systemTemp.createTemp('recurrence-window');
    db = AppDatabase.background(File('${dir.path}/db.sqlite'));
    await attach();
  });
  tearDown(() async {
    await close();
    await dir.delete(recursive: true);
  });

  String owner(String id) => RecurrencePlans.seriesIdFor('start-$id');
  Future<void> seed(
    String id, {
    DateTime? anchor,
    String zone = 'Asia/Shanghai',
    String rule = 'FREQ=DAILY',
    bool manualStart = false,
  }) async {
    final date = anchor ?? now;
    await store.execute(
      WorkspaceCommand(
        operationId: 'seed-$id',
        actions: [
          WorkspaceMutation(
            actionId: 'todo',
            kind: WorkspaceEntityKind.todo,
            entityId: id,
            mutation: WorkspaceMutationKind.create,
            patch: {'title': id, 'due_at': date.toIso8601String()},
          ),
        ],
      ),
    );
    session.accept(await store.load());
    final start = RecurrencePlans(session.snapshot, now: now).start(
      id,
      rule: rule,
      timezone: zone,
      operationId: 'start-$id',
      through: date,
      limit: 1,
    );
    if (manualStart) {
      await session.execute(start);
    } else {
      await store.execute(start);
      session.accept(await store.load());
    }
  }

  Future<void> drain({DateTime? through}) async {
    for (var i = 0; i < 40; i++) {
      await worker.refresh(through: through);
      if (worker.current.phase == RecurrenceWindowPhase.ready) return;
      expect(worker.current.problems, isEmpty);
    }
    fail('Window did not finish in bounded cycles');
  }

  List<WorkspaceEntity> instances(String id) => session.snapshot.todos
      .where((e) => e.data['series_id'] == owner(id))
      .toList();

  test(
    'long history is bounded per cycle and resumes from cursor after reopening',
    () async {
      final anchor = DateTime.utc(2024, 1, 1);
      await seed('history', anchor: anchor);
      await worker.refresh();
      expect(instances('history'), hasLength(513));
      expect(worker.current.phase, RecurrenceWindowPhase.incomplete);
      expect(fault.submitted, hasLength(8));
      expect(
        fault.submitted.every(
          (c) => c.source == 'system' && c.actions.length <= 65,
        ),
        isTrue,
      );
      await close();
      db = AppDatabase.background(File('${dir.path}/db.sqlite'));
      await attach();
      await drain();
      final records = instances('history');
      final expected = worker.current.through!.difference(anchor).inDays + 1;
      expect(records, hasLength(expected));
      expect(records.map((e) => e.data['occurrence_index']).toSet(), {
        for (var i = 0; i < expected; i++) i,
      });
      final submitted = fault.submitted.length;
      await worker.refresh();
      expect(fault.submitted.length, submitted);
    },
  );

  test('extending a ready range generates only missing dates', () async {
    await seed('task');
    await drain();
    final ids = instances('task').map((e) => e.id).toSet();
    final requested = DateTime.utc(2027, 2, 1);
    await drain(through: requested);
    expect(worker.current.through, requested);
    expect(instances('task'), hasLength(requested.difference(now).inDays + 1));
    expect(instances('task').map((e) => e.id).toSet().containsAll(ids), isTrue);
  });

  test('foreground start and undo retain the full undo window before automatic generation', () async {
    await seed('task', manualStart: true);
    await worker.refresh();
    expect(worker.current.phase, RecurrenceWindowPhase.waiting);
    expect(instances('task'), hasLength(1));
    now = now.add(const Duration(seconds: 11));
    await worker.refresh();
    expect(instances('task'), hasLength(1));
    await session.undo('start-task', 'undo-start');
    now = now.add(const Duration(seconds: 16));
    await worker.refresh();
    expect(worker.current.phase, RecurrenceWindowPhase.ready);
    expect(session.todos.snapshot, hasLength(1));
    expect(session.todos.snapshot.single.seriesId, isNull);
  });

  test('nested confirmation leases pause generation until all release; release is idempotent', () async {
    await seed('task');
    final a = session.holdAutomaticWork(), b = session.holdAutomaticWork();
    now = now.add(const Duration(minutes: 1));
    await worker.refresh();
    expect(instances('task'), hasLength(1));
    a();
    a();
    await worker.refresh();
    expect(instances('task'), hasLength(1));
    b();
    await drain();
    expect(instances('task').length, greaterThan(1));
  });

  test(
    'background pause stops work and resume fills the new date window',
    () async {
      await seed('task');
      worker.setActive(false);
      await worker.refresh();
      expect(worker.current.phase, RecurrenceWindowPhase.paused);
      expect(fault.submitted, isEmpty);
      now = now.add(const Duration(days: 20));
      worker.setActive(true);
      await drain();
      expect(instances('task'), hasLength(111));
    },
  );

  test('storage failure is suppressed until retry and uses exactly the original command', () async {
    await seed('task');
    fault.failBefore = true;
    await worker.refresh();
    expect(worker.current.problems.values, [RecurrenceWindowProblem.storage]);
    expect(instances('task'), hasLength(1));
    final original = fault.submitted.single;
    await worker.refresh(retryFailures: false);
    expect(fault.submitted, hasLength(1));
    fault.failBefore = false;
    await drain();
    expect(fault.submitted[1].toJson(), original.toJson());
    expect(instances('task'), hasLength(91));
  });

  test('lost reply after successful commit is reconciled by replay, not duplicate generation', () async {
    await seed('task');
    fault.failAfter = true;
    await worker.refresh();
    final original = fault.submitted.single;
    await drain();
    expect(fault.submitted[1].toJson(), original.toJson());
    expect(instances('task'), hasLength(91));
    expect(
      instances('task').map((e) => e.data['occurrence_index']).toSet(),
      hasLength(91),
    );
  });

  test('concurrent template edit replans from fresh version and never writes stale template', () async {
    await seed('task');
    fault.beforeExecute = () async {
      final series = (await store.load()).series.single;
      await store.execute(
        WorkspaceCommand(
          operationId: 'concurrent-edit',
          actions: [
            WorkspacePlans.update(series, {
              'template': {
                ...(series.data['template']! as Map<String, Object?>),
                'title': 'updated',
              },
            }),
          ],
        ),
      );
    };
    await drain();
    expect(
      instances('task').where((e) => e.data['title'] == 'updated'),
      hasLength(90),
    );
    expect(worker.current.problems, isEmpty);
  });

  test('one unsupported calendar does not block a healthy series or claim full readiness', () async {
    now = DateTime.utc(2038, 1, 1);
    await seed(
      'limited',
      anchor: DateTime.utc(2037, 12, 29),
      zone: 'America/New_York',
    );
    await seed('healthy', rule: 'FREQ=DAILY;COUNT=5');
    await worker.refresh();
    expect(worker.current.phase, RecurrenceWindowPhase.incomplete);
    expect(
      worker.current.problems[owner('limited')],
      RecurrenceWindowProblem.calendar,
    );
    expect(instances('healthy'), hasLength(5));
    expect(instances('limited'), hasLength(1));
    final count = fault.submitted.length;
    await worker.refresh(retryFailures: false);
    expect(fault.submitted.length, count);
  });

  test('ordinary legacy repeat field is not implicitly activated by automatic work', () async {
    await store.execute(
      WorkspaceCommand(
        operationId: 'legacy',
        actions: [
          WorkspaceMutation(
            actionId: 'legacy',
            kind: WorkspaceEntityKind.todo,
            entityId: 'legacy',
            mutation: WorkspaceMutationKind.create,
            patch: {
              'title': 'legacy',
              'due_at': now.toIso8601String(),
              'repeat_rule': 'FREQ=DAILY',
            },
          ),
        ],
      ),
    );
    await worker.refresh();
    expect(session.snapshot.series, isEmpty);
    expect(session.todos.snapshot, hasLength(1));
    expect(fault.submitted, isEmpty);
  });

  test('read failure keeps records and explicit retry resumes', () async {
    await seed('task');
    fault.failLoad = true;
    await worker.refresh();
    expect(worker.current.phase, RecurrenceWindowPhase.failed);
    expect(session.todos.snapshot, hasLength(1));
    fault.failLoad = false;
    await drain();
    expect(instances('task'), hasLength(91));
  });

  test('small transaction budget rotates series across cycles', () async {
    worker.dispose();
    worker = RecurrenceWindow(
      session,
      clock: () => now,
      autoSchedule: false,
      batchSize: 2,
      maxBatches: 1,
    );
    for (final id in ['a', 'b', 'c']) {
      await seed(id);
    }
    for (var i = 0; i < 3; i++) {
      await worker.refresh();
    }
    for (final id in ['a', 'b', 'c']) {
      expect(instances(id), hasLength(3));
    }
    expect(fault.submitted, hasLength(3));
  });

  test('two independent connections converge on unique instances under concurrent cycles', () async {
    await seed('task');
    final secondDb = AppDatabase.background(File('${dir.path}/db.sqlite'));
    final secondStore = SqliteWorkspaceCommandStore(secondDb);
    final secondSession = LocalWorkspaceSession(
      secondStore,
      await secondStore.load(),
      elapsed: () => now.difference(DateTime.utc(2020)),
    );
    final second = RecurrenceWindow(
      secondSession,
      clock: () => now,
      autoSchedule: false,
    );
    try {
      await Future.wait([worker.refresh(), second.refresh()]);
      await drain();
      await second.refresh();
      expect((await store.load()).todos, hasLength(91));
      expect(worker.current.phase, RecurrenceWindowPhase.ready);
      expect(second.current.phase, RecurrenceWindowPhase.ready);
    } finally {
      second.dispose();
      await secondSession.dispose();
      secondSession.todos.dispose();
      secondSession.categories.dispose();
      await secondDb.close();
    }
  });

  test(
    'automatic timers fill on startup and resume without an explicit refresh',
    () async {
      await seed('task');
      worker.dispose();
      worker = RecurrenceWindow(session, clock: () => now);
      Future<void> untilReady() async {
        final watch = Stopwatch()..start();
        while (worker.current.phase != RecurrenceWindowPhase.ready &&
            watch.elapsed < const Duration(seconds: 5)) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        expect(worker.current.phase, RecurrenceWindowPhase.ready);
      }

      await untilReady();
      expect(instances('task'), hasLength(91));
      worker.setActive(false);
      now = now.add(const Duration(days: 10));
      expect(worker.current.phase, RecurrenceWindowPhase.paused);
      worker.setActive(true);
      // Observe a completed range advance, not the previous ready state.
      final watch = Stopwatch()..start();
      while (instances('task').length != 101 &&
          watch.elapsed < const Duration(seconds: 5)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      await untilReady();
      expect(instances('task'), hasLength(101));
    },
  );

  test('disposing during a pending read never starts a later write', () async {
    await seed('task');
    final gate = Completer<void>();
    fault.loadGate = gate;
    final run = worker.refresh();
    worker.dispose();
    gate.complete();
    await run;
    expect(fault.submitted, isEmpty);
    fault.loadGate = null;
    worker = RecurrenceWindow(session, clock: () => now, autoSchedule: false);
  });

  test('undo protection uses elapsed time even if the calendar clock moves backwards', () async {
    worker.dispose();
    await session.dispose();
    session.todos.dispose();
    session.categories.dispose();
    var elapsed = Duration.zero;
    session = LocalWorkspaceSession(
      fault,
      await store.load(),
      elapsed: () => elapsed,
    );
    worker = RecurrenceWindow(session, clock: () => now, autoSchedule: false);
    final requested = now.add(const Duration(days: 10));
    await seed('task', manualStart: true);
    now = now.subtract(const Duration(days: 365));
    await worker.refresh(through: requested);
    expect(worker.current.phase, RecurrenceWindowPhase.waiting);
    elapsed = const Duration(seconds: 16);
    await drain(through: requested);
    expect(session.automaticWorkDelay, Duration.zero);
    expect(instances('task'), hasLength(11));
  });
}
