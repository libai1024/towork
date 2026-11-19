import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/data/local/workspace_model_codec.dart';
import 'package:towork/domain/recurrence/recurrence_plans.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';
import 'package:towork/domain/workspace/workspace_validation.dart';

void main() {
  late Directory folder;
  late File file;
  late AppDatabase db;
  late SqliteWorkspaceCommandStore store;
  final now = DateTime.utc(2026, 9, 24);
  final through = DateTime.utc(2026, 10, 31);
  setUp(() async {
    folder = await Directory.systemTemp.createTemp('towork-repeat-');
    file = File('${folder.path}/data.sqlite');
    db = AppDatabase.background(file);
    store = SqliteWorkspaceCommandStore(db, clock: () => now);
  });
  tearDown(() async {
    await db.close();
    await folder.delete(recursive: true);
  });
  Future<RecurrencePlans> plans() async =>
      RecurrencePlans(await store.load(), now: now);
  Future<void> seed({String due = '2026-09-24T01:00:00Z'}) => store
      .execute(
        WorkspaceCommand(
          operationId: 'seed',
          actions: [
            WorkspaceMutation(
              actionId: 'task',
              kind: WorkspaceEntityKind.todo,
              entityId: 'task',
              mutation: WorkspaceMutationKind.create,
              patch: {
                'title': '整理资料',
                'due_at': due,
                'note': '模板备注',
                'remind_at': '2026-09-24T00:00:00Z',
                'remind_rules': [
                  {'id': 'relative', 'offset_minutes': 30},
                  {'id': 'absolute', 'absolute_at': '2026-09-24T00:00:00Z'},
                ],
              },
            ),
          ],
        ),
      )
      .then((_) {});
  String series([String operation = 'start']) =>
      RecurrencePlans.seriesIdFor(operation);
  Future<WorkspaceReceipt> start({
    String rule = 'FREQ=DAILY;COUNT=5',
    int limit = 64,
    String zone = 'Asia/Shanghai',
  }) async {
    return store.execute(
      (await plans()).start(
        'task',
        rule: rule,
        timezone: zone,
        operationId: 'start',
        through: through,
        limit: limit,
      ),
    );
  }

  Future<WorkspaceEntity> occurrence(
    int index, [
    String operation = 'start',
  ]) async => (await store.load()).todos.singleWhere(
    (e) =>
        e.data['series_id'] == series(operation) &&
        e.data['occurrence_index'] == index,
  );
  Future<void> reopen() async {
    await db.close();
    db = AppDatabase.background(file);
    store = SqliteWorkspaceCommandStore(db, clock: () => now);
  }

  Matcher conflict = throwsA(
    isA<WorkspaceFailure>().having(
      (e) => e.code,
      'code',
      WorkspaceFailureCode.versionConflict,
    ),
  );

  test('start and bounded generation persist independent instances, template and cursor', () async {
    await seed();
    final first = await start(limit: 2);
    expect(first.affected, hasLength(4)); // series, original + two new slots
    expect((await store.load()).todos, hasLength(3));
    final root = workspaceTodo(await occurrence(0));
    expect(root.id, 'task');
    expect(root.remindRules, hasLength(2));
    final child = workspaceTodo(await occurrence(1));
    expect(child.remindAt, isNull);
    expect(child.remindRules.single.id, 'relative');
    expect(child.copyWith(title: '保留身份').occurrenceKey, child.occurrenceKey);
    await reopen();
    final command = (await plans()).materialize(
      series(),
      through: through,
      operationId: 'generate',
      limit: 2,
    )!;
    final receipt = await store.execute(command);
    await reopen();
    expect((await store.execute(command)).toJson(), receipt.toJson());
    expect((await store.load()).todos, hasLength(5));
    expect(
      (await plans()).materialize(
        series(),
        through: through,
        operationId: 'finished',
      ),
      isNull,
    );
    expect((await store.load()).series.single.data['cursor_index'], 4);
  });

  test(
    'completion and undo affect one instance and never create another series',
    () async {
      await seed();
      await start();
      final target = await occurrence(1);
      final command = (await plans()).complete(
        target.id,
        operationId: 'complete',
      );
      await store.execute(command);
      await store.execute(command);
      expect(
        (await store.load()).todos.where((e) => e.data['status'] == 'done'),
        hasLength(1),
      );
      expect((await occurrence(2)).data['status'], 'pending');
      expect((await store.load()).series.single.version, 1);
      await store.undo('complete', operationId: 'undo-complete');
      expect((await occurrence(1)).data['status'], 'pending');
    },
  );

  test(
    'single reschedule keeps original identity and does not shift later dates',
    () async {
      await seed();
      await start(limit: 1);
      final old = await occurrence(1);
      await store.execute(
        (await plans()).edit(
          old.id,
          {'due_at': '2026-09-29T02:00:00Z', 'note': '仅本次'},
          scope: RecurrenceScope.current,
          operationId: 'exception',
          through: through,
        ),
      );
      final changed = await occurrence(1);
      expect(changed.data['occurrence_key'], old.data['occurrence_key']);
      expect(changed.data['occurrence_at'], old.data['occurrence_at']);
      await store.execute(
        (await plans()).materialize(
          series(),
          through: through,
          operationId: 'fill',
        )!,
      );
      expect((await occurrence(2)).data['due_at'], '2026-09-26T01:00:00.000Z');
      expect((await occurrence(2)).data['note'], '模板备注');
    },
  );

  test('single deletion remains a tombstone across reopening and overlapping generation', () async {
    await seed();
    await start(limit: 1);
    final old = await occurrence(1);
    await store.execute(
      (await plans()).delete(
        old.id,
        scope: RecurrenceScope.current,
        operationId: 'delete-one',
      ),
    );
    await reopen();
    await store.execute(
      (await plans()).materialize(
        series(),
        through: through,
        operationId: 'fill',
      )!,
    );
    expect(
      (await store.load()).find(WorkspaceEntityKind.todo, old.id)!.isDeleted,
      isTrue,
    );
    expect((await store.load()).todos, hasLength(4));
    await store.undo('delete-one', operationId: 'undo-delete');
    expect((await occurrence(1)).id, old.id);
  });

  test('future edit splits series, preserves prior history and carries remaining COUNT', () async {
    await seed();
    await start();
    await store.execute(
      (await plans()).complete('task', operationId: 'complete-first'),
    );
    final target = await occurrence(2);
    final before = (await occurrence(1)).toJson();
    await store.execute(
      (await plans()).edit(
        target.id,
        {'title': '新的标题'},
        scope: RecurrenceScope.currentAndFuture,
        operationId: 'split',
        through: through,
      ),
    );
    expect((await occurrence(1)).toJson(), before);
    expect((await occurrence(0)).data['status'], 'done');
    expect(
      (await store.load())
          .find(WorkspaceEntityKind.series, series())!
          .data['stop_before'],
      2,
    );
    expect(
      (await store.load())
          .find(WorkspaceEntityKind.series, series('split'))!
          .data['rule'],
      'FREQ=DAILY;COUNT=3',
    );
    expect((await occurrence(0, 'split')).id, target.id);
    expect(
      (await store.load()).todos.where((e) => e.data['title'] == '新的标题'),
      hasLength(3),
    );
    await store.undo('split', operationId: 'undo-split');
    expect((await store.load()).todos, hasLength(5));
    expect((await occurrence(2)).id, target.id);
    expect((await occurrence(0)).data['status'], 'done');
  });

  test('future edit preserves a current-only exception without leaking it into the template', () async {
    await seed();
    await start();
    final target = await occurrence(2);
    await store.execute(
      (await plans()).edit(
        target.id,
        {'due_at': '2026-09-26T05:00:00Z', 'note': '当前例外'},
        scope: RecurrenceScope.current,
        operationId: 'one',
        through: through,
      ),
    );
    await store.execute(
      (await plans()).edit(
        target.id,
        {'title': '新模板'},
        scope: RecurrenceScope.currentAndFuture,
        operationId: 'split',
        through: through,
      ),
    );
    expect(
      (await occurrence(0, 'split')).data['due_at'],
      '2026-09-26T05:00:00.000Z',
    );
    expect(
      (await occurrence(1, 'split')).data['due_at'],
      '2026-09-27T01:00:00.000Z',
    );
    expect((await occurrence(0, 'split')).data['note'], '当前例外');
    expect((await occurrence(1, 'split')).data['note'], '模板备注');
  });

  test('completed future facts survive split and are not regenerated as pending duplicates', () async {
    await seed();
    await start();
    final complete = await occurrence(3);
    await store.execute(
      (await plans()).complete(complete.id, operationId: 'finish-ahead'),
    );
    final target = await occurrence(1);
    await store.execute(
      (await plans()).edit(
        target.id,
        {'title': '新模板'},
        scope: RecurrenceScope.currentAndFuture,
        operationId: 'split',
        through: through,
      ),
    );
    expect(
      (await store.load())
          .find(WorkspaceEntityKind.todo, complete.id)!
          .data['status'],
      'done',
    );
    expect(
      (await store.load())
          .find(WorkspaceEntityKind.series, series('split'))!
          .data['excluded_indices'],
      [2],
    );
    expect((await store.load()).todos, hasLength(5));
    expect(
      (await store.load()).todos.where(
        (e) =>
            e.data['series_id'] == series('split') &&
            e.data['occurrence_index'] == 2,
      ),
      isEmpty,
    );
  });

  test('editing before an existing split closes all descendants without overlapping futures', () async {
    await seed();
    await start();
    final target = await occurrence(2);
    await store.execute(
      (await plans()).edit(
        target.id,
        {'title': '第二段'},
        scope: RecurrenceScope.currentAndFuture,
        operationId: 'split',
        through: through,
      ),
    );
    final last = await occurrence(2, 'split');
    await store.execute(
      (await plans()).complete(last.id, operationId: 'finished-child'),
    );
    final older = await occurrence(1);
    await store.execute(
      (await plans()).edit(
        older.id,
        {'title': '重新安排'},
        scope: RecurrenceScope.currentAndFuture,
        operationId: 'replace',
        through: through,
      ),
    );
    expect(
      (await store.load())
          .find(WorkspaceEntityKind.series, series('split'))!
          .data['stop_before'],
      0,
    );
    expect(
      (await store.load())
          .find(WorkspaceEntityKind.series, series('replace'))!
          .data['excluded_indices'],
      [3],
    );
    expect((await store.load()).todos, hasLength(5));
    expect(
      (await store.load()).todos
          .where((e) => e.data['title'] == '第二段')
          .single
          .id,
      last.id,
    );
  });

  test('future delete cancels pending successors but preserves completed history and can undo', () async {
    await seed();
    await start();
    final complete = await occurrence(3);
    await store.execute(
      (await plans()).complete(complete.id, operationId: 'finish'),
    );
    final target = await occurrence(1);
    await store.execute(
      (await plans()).delete(
        target.id,
        scope: RecurrenceScope.currentAndFuture,
        operationId: 'delete-future',
      ),
    );
    expect((await store.load()).todos.map((e) => e.id).toSet(), {
      'task',
      complete.id,
    });
    expect(
      (await plans()).materialize(
        series(),
        through: through,
        operationId: 'fill',
      ),
      isNull,
    );
    await store.undo('delete-future', operationId: 'undo');
    expect((await store.load()).todos, hasLength(5));
    expect((await occurrence(3)).data['status'], 'done');
  });

  test('clearing recurrence from this point retains current task and removes future repetition', () async {
    await seed();
    await start();
    final target = await occurrence(2);
    await store.execute(
      (await plans()).edit(
        target.id,
        {'repeat_rule': null},
        scope: RecurrenceScope.currentAndFuture,
        operationId: 'clear',
        through: through,
      ),
    );
    final item = (await store.load()).find(
      WorkspaceEntityKind.todo,
      target.id,
    )!;
    expect(item.data['series_id'], isNull);
    expect(item.data['repeat_rule'], isNull);
    expect((await store.load()).todos, hasLength(3));
    await store.undo('clear', operationId: 'undo');
    expect((await store.load()).todos, hasLength(5));
  });

  test('stale future preview conflicts after another connection materializes more slots', () async {
    await seed();
    await start(limit: 1);
    final target = await occurrence(1);
    final command = (await plans()).edit(
      target.id,
      {'title': '未来修改'},
      scope: RecurrenceScope.currentAndFuture,
      operationId: 'stale',
      through: through,
    );
    final otherDb = AppDatabase.background(file);
    try {
      final other = SqliteWorkspaceCommandStore(otherDb, clock: () => now);
      final p = RecurrencePlans(await other.load(), now: now);
      await other.execute(
        p.materialize(series(), through: through, operationId: 'other')!,
      );
      await expectLater(store.execute(command), conflict);
      expect((await store.load()).todos, hasLength(5));
      expect(
        (await store.load()).todos.every((e) => e.data['title'] == '整理资料'),
        isTrue,
      );
    } finally {
      await otherDb.close();
    }
  });

  test(
    'concurrent generators cannot produce two instances for a slot',
    () async {
      await seed();
      await start(limit: 1);
      final otherDb = AppDatabase.background(file);
      try {
        final other = SqliteWorkspaceCommandStore(otherDb, clock: () => now);
        final p = await plans();
        Future<Object> attempt(
          SqliteWorkspaceCommandStore target,
          String id,
        ) async {
          try {
            return await target.execute(
              p.materialize(series(), through: through, operationId: id)!,
            );
          } on WorkspaceFailure catch (e) {
            return e;
          }
        }

        final result = await Future.wait([
          attempt(store, 'worker-one'),
          attempt(other, 'worker-two'),
        ]);
        expect(result.whereType<WorkspaceReceipt>(), hasLength(1));
        expect(result.whereType<WorkspaceFailure>(), hasLength(1));
        expect((await store.load()).todos, hasLength(5));
        final rows = await db
            .customSelect(
              'SELECT series_id, occurrence_key, COUNT(*) AS n FROM work_todos GROUP BY series_id, occurrence_key HAVING n > 1',
            )
            .get();
        expect(rows, isEmpty);
      } finally {
        await otherDb.close();
      }
    },
  );

  test('receipt failure rolls back series, instances and cursor, then retry is safe', () async {
    await seed();
    final command = (await plans()).start(
      'task',
      rule: 'FREQ=DAILY;COUNT=5',
      timezone: 'Asia/Shanghai',
      operationId: 'start',
      through: through,
    );
    final failing = SqliteWorkspaceCommandStore(
      db,
      clock: () => now,
      checkpoint: (point) {
        if (point == WorkspaceCommitCheckpoint.entitiesWritten) {
          throw StateError('fixture');
        }
      },
    );
    await expectLater(
      failing.execute(command),
      throwsA(isA<WorkspaceFailure>()),
    );
    expect((await store.load()).series, isEmpty);
    expect((await store.load()).todos.single.data['series_id'], isNull);
    await store.execute(command);
    expect((await store.load()).todos, hasLength(5));
  });

  test(
    'undo conflict preserves whole split after a new instance edit',
    () async {
      await seed();
      await start();
      final target = await occurrence(2);
      await store.execute(
        (await plans()).edit(
          target.id,
          {'title': '未来'},
          scope: RecurrenceScope.currentAndFuture,
          operationId: 'split',
          through: through,
        ),
      );
      final child = await occurrence(1, 'split');
      await store.execute(
        (await plans()).edit(
          child.id,
          {'note': '保留后续修改'},
          scope: RecurrenceScope.current,
          operationId: 'manual',
          through: through,
        ),
      );
      final before = (await store.load()).entities.map(
        (k, v) => MapEntry(k, v.toJson()),
      );
      await expectLater(store.undo('split', operationId: 'undo'), conflict);
      expect(
        (await store.load()).entities.map((k, v) => MapEntry(k, v.toJson())),
        before,
      );
    },
  );

  test(
    'SQL unique index independently rejects a different ID for the same slot',
    () async {
      await seed();
      await start();
      final raw = sqlite.sqlite3.open(file.path);
      try {
        expect(
          () => raw.execute(
            "INSERT INTO work_todos (id,version,category_id,status,due_at,sort_order,payload,created_at,updated_at,deleted_at,series_id,occurrence_key,occurrence_index) SELECT 'duplicate',version,category_id,status,due_at,sort_order,payload,created_at,updated_at,deleted_at,series_id,occurrence_key,occurrence_index FROM work_todos WHERE id='task'",
          ),
          throwsA(
            isA<sqlite.SqliteException>().having(
              (e) => e.extendedResultCode,
              'unique constraint',
              2067,
            ),
          ),
        );
      } finally {
        raw.close();
      }
      expect((await store.load()).todos, hasLength(5));
    },
  );

  test('start undo restores the original task and hides all generated instances atomically', () async {
    await seed();
    final before = (await store.load()).todos.single.data;
    await start();
    await store.undo('start', operationId: 'undo-start');
    expect((await store.load()).series, isEmpty);
    expect((await store.load()).todos.single.data, before);
    await reopen();
    expect((await store.load()).todos.single.id, 'task');
  });
  test('explicit count and interval changes start a fresh remaining rule at the split', () async {
    await seed();
    await start();
    final target = await occurrence(2);
    await store.execute(
      (await plans()).edit(
        target.id,
        {'repeat_rule': 'FREQ=WEEKLY;COUNT=2'},
        scope: RecurrenceScope.currentAndFuture,
        operationId: 'weekly',
        through: through,
      ),
    );
    expect((await store.load()).todos, hasLength(4));
    expect(
      (await occurrence(1, 'weekly')).data['due_at'],
      '2026-10-03T01:00:00.000Z',
    );
  });
  test('a completed superseded slot permits current edits but cannot fork overlapping futures', () async {
    await seed();
    await start();
    final historical = await occurrence(4);
    await store.execute(
      (await plans()).complete(historical.id, operationId: 'done'),
    );
    final target = await occurrence(1);
    await store.execute(
      (await plans()).edit(
        target.id,
        {'title': '未来'},
        scope: RecurrenceScope.currentAndFuture,
        operationId: 'split',
        through: through,
      ),
    );
    final p = await plans();
    expect(
      () => p.edit(
        historical.id,
        {'title': '冲突'},
        scope: RecurrenceScope.currentAndFuture,
        operationId: 'invalid',
        through: through,
      ),
      throwsA(isA<WorkspaceFailure>()),
    );
    expect(
      () => p.delete(
        historical.id,
        scope: RecurrenceScope.currentAndFuture,
        operationId: 'invalid-delete',
      ),
      throwsA(isA<WorkspaceFailure>()),
    );
    await store.execute(
      p.edit(
        historical.id,
        {'note': '补充历史备注'},
        scope: RecurrenceScope.current,
        operationId: 'historical-edit',
        through: through,
      ),
    );
    expect(
      (await store.load())
          .find(WorkspaceEntityKind.todo, historical.id)!
          .data['note'],
      '补充历史备注',
    );
  });
  test(
    'missing anchor and malformed rule fail before any series write',
    () async {
      await seed();
      final p = await plans();
      expect(
        () => p.start(
          'task',
          rule: 'FREQ=DAILY;INTERVAL=0',
          timezone: 'Asia/Shanghai',
          operationId: 'invalid',
          through: through,
        ),
        throwsA(isA<WorkspaceFailure>()),
      );
      expect(
        () => p.start(
          'task',
          rule: 'FREQ=DAILY',
          timezone: 'PST',
          operationId: 'invalid-zone',
          through: through,
        ),
        throwsA(isA<WorkspaceFailure>()),
      );
      expect((await store.load()).series, isEmpty);
      await store.execute(
        WorkspaceCommand(
          operationId: 'remove-anchor',
          actions: [
            WorkspaceMutation(
              actionId: 'a',
              kind: WorkspaceEntityKind.todo,
              entityId: 'task',
              mutation: WorkspaceMutationKind.update,
              expectedVersion: 1,
              patch: {'due_at': null},
            ),
          ],
        ),
      );
      final missing = await plans();
      expect(
        () => missing.start(
          'task',
          rule: 'FREQ=DAILY',
          timezone: 'Asia/Shanghai',
          operationId: 'no-anchor',
          through: through,
        ),
        throwsA(isA<WorkspaceFailure>()),
      );
    },
  );

  test(
    'ordinary commands cannot change a linked slot identity or its series rule',
    () async {
      await seed();
      await start();
      for (final patch in <Map<String, Object?>>[
        {'occurrence_index': 50},
        {'occurrence_at': '2026-09-25T01:00:00Z'},
        {'repeat_rule': 'FREQ=WEEKLY'},
        {'repeat_timezone': 'America/New_York'},
      ]) {
        await expectLater(
          store.execute(
            WorkspaceCommand(
              operationId: 'invalid-${patch.keys.single}',
              actions: [
                WorkspaceMutation(
                  actionId: 'a',
                  kind: WorkspaceEntityKind.todo,
                  entityId: 'task',
                  mutation: WorkspaceMutationKind.update,
                  expectedVersion: 2,
                  patch: patch,
                ),
              ],
            ),
          ),
          throwsA(isA<WorkspaceFailure>()),
        );
      }
      expect((await occurrence(0)).version, 2);
    },
  );

  test('single deletions remain excluded after repeated edits from an earlier segment', () async {
    await seed();
    await start();
    final deleted = await occurrence(4);
    await store.execute(
      (await plans()).delete(
        deleted.id,
        scope: RecurrenceScope.current,
        operationId: 'delete-one',
      ),
    );
    final target = await occurrence(2);
    await store.execute(
      (await plans()).edit(
        target.id,
        {'title': '第二段'},
        scope: RecurrenceScope.currentAndFuture,
        operationId: 'split',
        through: through,
      ),
    );
    expect((await store.load()).todos, hasLength(4));
    final earlier = await occurrence(1);
    await store.execute(
      (await plans()).edit(
        earlier.id,
        {'title': '覆盖以后'},
        scope: RecurrenceScope.currentAndFuture,
        operationId: 'replace',
        through: through,
      ),
    );
    expect((await store.load()).todos, hasLength(4));
    expect(
      (await store.load())
          .find(WorkspaceEntityKind.series, series('replace'))!
          .data['excluded_indices'],
      [3],
    );
  });
  test(
    'editing an earlier segment preserves a later explicit deletion boundary',
    () async {
      await seed();
      await start();
      final last = await occurrence(3);
      await store.execute(
        (await plans()).delete(
          last.id,
          scope: RecurrenceScope.currentAndFuture,
          operationId: 'stop',
        ),
      );
      final target = await occurrence(1);
      await store.execute(
        (await plans()).edit(
          target.id,
          {'title': '仍然三次'},
          scope: RecurrenceScope.currentAndFuture,
          operationId: 'split',
          through: through,
        ),
      );
      expect((await store.load()).todos, hasLength(3));
      expect(
        (await store.load())
            .find(WorkspaceEntityKind.series, series('split'))!
            .data['rule'],
        'FREQ=DAILY;COUNT=2',
      );
    },
  );

  for (final ending in ['', ';COUNT=2', ';UNTIL=20260930']) {
    test('earlier edit preserves the successor ending $ending', () async {
      await seed();
      await start();
      final later = await occurrence(2);
      await store.execute(
        (await plans()).edit(
          later.id,
          {'repeat_rule': 'FREQ=DAILY$ending'},
          scope: RecurrenceScope.currentAndFuture,
          operationId: 'later-ending',
          through: DateTime.utc(2026, 9, 30, 23),
        ),
      );
      final earlier = await occurrence(1);
      await store.execute(
        (await plans()).edit(
          earlier.id,
          {'title': '保留结束条件'},
          scope: RecurrenceScope.currentAndFuture,
          operationId: 'earlier-edit',
          through: DateTime.utc(2026, 9, 30, 23),
        ),
      );
      final expected = ending == ';COUNT=2' ? ';COUNT=3' : ending;
      final snapshot = await store.load();
      expect(
        snapshot
            .find(WorkspaceEntityKind.series, series('earlier-edit'))!
            .data['rule'],
        'FREQ=DAILY$expected',
      );
      expect(snapshot.todos, hasLength(ending == ';COUNT=2' ? 4 : 7));
    });
  }

  test(
    'v6 migration retains existing data and no series is invented',
    () async {
      await db.close();
      final raw = sqlite.sqlite3.open(file.path);
      raw.execute(File('test/fixtures/local/schema_v6.sql').readAsStringSync());
      raw.execute(
        "INSERT INTO local_profiles VALUES(1,'v6-user','旧资料',2,1700000000)",
      );
      raw.execute(
        "INSERT INTO chat_conversations VALUES('c','旧会话',1,1,1,NULL)",
      );
      final legacyTodo = {
        ...todoDefaults,
        'title': '旧重复待办',
        'repeat_rule': 'FREQ=DAILY',
        'repeat_timezone': 'Asia/Shanghai',
        'due_at': '2026-09-24T01:00:00.000Z',
      }..removeWhere((k, _) => k == 'series_id' || k.startsWith('occurrence_'));
      raw.execute(
        'INSERT INTO work_todos (id,version,status,due_at,sort_order,payload,created_at,updated_at) VALUES(?,?,?,?,?,?,?,?)',
        [
          'legacy',
          3,
          'pending',
          DateTime.utc(2026, 9, 24, 1).microsecondsSinceEpoch,
          0,
          jsonEncode(legacyTodo),
          1,
          1,
        ],
      );
      raw.close();
      db = AppDatabase.background(file);
      store = SqliteWorkspaceCommandStore(db, clock: () => now);
      expect((await store.load()).series, isEmpty);
      final task = workspaceTodo((await store.load()).todos.single);
      expect(task.id, 'legacy');
      expect(task.title, '旧重复待办');
      expect(task.repeatRule, 'FREQ=DAILY');
      expect(task.repeatTimezone, 'Asia/Shanghai');
      expect(task.dueAt?.toUtc(), DateTime.utc(2026, 9, 24, 1));
      expect(task.seriesId, isNull);
      expect((await db.loadOrCreateProfile()).nickname, '旧资料');
      expect((await db.select(db.chatConversations).get()).single.title, '旧会话');
      expect(
        (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
          'user_version',
        ),
        13,
      );
    },
  );

  test(
    'malformed pre-existing series table rolls back v6 migration and can retry',
    () async {
      await db.close();
      var raw = sqlite.sqlite3.open(file.path);
      raw.execute(File('test/fixtures/local/schema_v6.sql').readAsStringSync());
      raw.execute('CREATE TABLE work_todo_series (unexpected TEXT)');
      raw.close();
      db = AppDatabase.background(file);
      store = SqliteWorkspaceCommandStore(db);
      await expectLater(store.load(), throwsA(isA<WorkspaceFailure>()));
      await db.close();
      raw = sqlite.sqlite3.open(file.path);
      expect(raw.select('PRAGMA user_version').single['user_version'], 6);
      expect(
        raw
            .select('PRAGMA table_info(work_todos)')
            .any((r) => r['name'] == 'series_id'),
        isFalse,
      );
      raw.execute('DROP TABLE work_todo_series');
      raw.close();
      db = AppDatabase.background(file);
      store = SqliteWorkspaceCommandStore(db);
      expect((await store.load()).series, isEmpty);
    },
  );
}
