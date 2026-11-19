import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/agent/todo_agent_tools.dart';
import 'package:towork/data/local/agent_run_store.dart';
import 'package:towork/data/local/agent_tool_executor.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/app_preferences_store.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/ai/permission_policy.dart';
import 'package:towork/domain/recurrence/recurrence_plans.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';

final _now = DateTime.utc(2026, 9, 24);
JsonObject _call(String name, JsonObject args, [String id = 'call']) => {
  'id': id,
  'type': 'function',
  'function': {'name': name, 'arguments': jsonEncode(args)},
};
ModelCompleted _tools(List<JsonObject> calls) => ModelCompleted(
  assistantMessage: {'role': 'assistant', 'content': null, 'tool_calls': calls},
  finishReason: 'tool_calls',
);
JsonObject _create([String title = '每天复盘']) => {
  'title': title,
  'due_at': '2026-09-24T01:00:00.000Z',
  'repeat_rule': 'FREQ=DAILY;COUNT=4',
  'repeat_timezone': 'Asia/Shanghai',
};

void main() {
  late Directory directory;
  late AppDatabase db;
  late SqliteWorkspaceCommandStore workspace;
  late SqliteAgentRunStore runs;
  late SqliteAgentToolExecutor tools;
  var sequence = 0;
  void connect() {
    db = AppDatabase.background(File('${directory.path}/db.sqlite'));
    workspace = SqliteWorkspaceCommandStore(db, clock: () => _now);
    runs = SqliteAgentRunStore(db);
    tools = SqliteAgentToolExecutor(db, clock: () => _now);
  }

  Future<void> policy(AiWritePermission value) async {
    final store = SqliteAppPreferencesStore(db);
    final old = await store.loadOrCreate();
    await store.update({
      'permission': value.name,
    }, expectedVersion: old.version);
  }

  Future<AgentRun> propose(List<JsonObject> calls) async {
    sequence++;
    final queued = await runs.create(
      AgentRun(
        id: 'run$sequence',
        sessionId: 'session',
        inputId: 'input$sequence',
        profile: ModelProfile(model: 'fixture', product: ProviderKind.kimiCode),
        history: const [
          {'role': 'user', 'content': '管理重复待办'},
        ],
      ),
    );
    final generating = await runs.save(
      queued.next(AgentRunStatus.generating, round: 1),
      expectedRevision: queued.revision,
    );
    return tools.propose(generating, _tools(calls));
  }

  AgentApproval approve(
    AgentRun run, {
    List<String>? ids,
    bool reject = false,
  }) => AgentApproval(
    runRevision: run.revision,
    proposalId: run.proposal!['id']! as String,
    digest: run.proposal!['digest']! as String,
    selectedToolCallIds: ids,
    reject: reject,
  );
  Future<WorkspaceSnapshot> seed() async {
    await policy(AiWritePermission.auto);
    await tools.execute(
      await propose([_call('todo_repeat_create', _create())]),
    );
    return workspace.load();
  }

  JsonObject target(
    WorkspaceSnapshot snapshot,
    WorkspaceEntity todo, [
    String scope = 'current_and_future',
  ]) => {
    'id': todo.id,
    'expected_version': todo.version,
    'expected_series_version': snapshot
        .find(WorkspaceEntityKind.series, todo.data['series_id']! as String)!
        .version,
    'scope': scope,
  };
  Future<void> edit(WorkspaceEntity item, JsonObject patch) => workspace
      .execute(
        WorkspaceCommand(
          operationId: newWorkspaceId('manual'),
          actions: [
            WorkspaceMutation(
              actionId: 'edit',
              kind: item.kind,
              entityId: item.id,
              mutation: WorkspaceMutationKind.update,
              expectedVersion: item.version,
              patch: patch,
            ),
          ],
        ),
      )
      .then((_) {});
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('recurrence-agent');
    sequence = 0;
    connect();
    await policy(AiWritePermission.askAll);
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  test('create series is one approval, atomic after reopen, exact decision replay and undo', () async {
    final proposed = await propose([_call('todo_repeat_create', _create())]);
    final waiting = await tools.execute(proposed);
    expect(waiting.status, AgentRunStatus.awaitingConfirmation);
    expect((await workspace.load()).todos, isEmpty);
    final call = (waiting.proposal!['calls']! as List).single as Map;
    expect(call['mutations'], hasLength(5));
    expect(call['operation'], 'create');
    await db.close();
    connect();
    final stored = await runs.read(waiting.id);
    final done = await tools.execute(stored, approval: approve(stored));
    final snapshot = await workspace.load();
    expect(snapshot.todos, hasLength(4));
    expect(snapshot.series, hasLength(1));
    expect(snapshot.todos.map((e) => e.data['source_message_id']).toSet(), {
      'input1',
    });
    expect(snapshot.todos.map((e) => e.version).toSet(), {1});
    expect(
      (await tools.execute(stored, approval: approve(stored))).toJson(),
      done.toJson(),
    );
    expect(
      jsonDecode(done.history.last['content']! as String)['changed_count'],
      5,
    );
    await workspace.undo(done.receipts.single, operationId: 'undo');
    expect((await workspace.load()).todos, isEmpty);
    expect((await workspace.load()).series, isEmpty);
  });

  test('partial selection chooses whole series and rejects another without effects', () async {
    final waiting = await tools.execute(
      await propose([
        _call('todo_repeat_create', _create('第一系列'), 'a'),
        _call('todo_repeat_create', _create('第二系列'), 'b'),
      ]),
    );
    final partial = await tools.execute(
      waiting,
      approval: approve(waiting, ids: ['a']),
    );
    expect(partial.status, AgentRunStatus.awaitingConfirmation);
    expect((await workspace.load()).todos.map((e) => e.data['title']).toSet(), {
      '第一系列',
    });
    final done = await tools.execute(
      partial,
      approval: approve(partial, ids: ['b'], reject: true),
    );
    expect(done.status, AgentRunStatus.generating);
    expect((await workspace.load()).series, hasLength(1));
    expect(
      jsonDecode(done.history.last['content']! as String)['reason'],
      'user_rejected',
    );
  });

  for (final permission in AiWritePermission.values) {
    test(
      '${permission.name}: future edit uses logical edit permission, delete uses deletion permission',
      () async {
        var snapshot = await seed();
        final todo = snapshot.todos.first;
        await policy(permission);
        final proposed = await propose([
          _call('todo_repeat_update', {
            ...target(snapshot, todo),
            'patch': {'title': '新系列'},
          }),
        ]);
        final executed = await tools.execute(proposed);
        if (permission == AiWritePermission.askAll) {
          expect(executed.status, AgentRunStatus.awaitingConfirmation);
          await tools.execute(executed, approval: approve(executed));
        } else {
          expect(executed.status, AgentRunStatus.generating);
        }
        snapshot = await workspace.load();
        expect(snapshot.todos.every((e) => e.data['title'] == '新系列'), isTrue);
        final deleting = await tools.execute(
          await propose([
            _call(
              'todo_repeat_delete',
              target(
                snapshot,
                snapshot.find(WorkspaceEntityKind.todo, todo.id)!,
              ),
            ),
          ]),
        );
        expect(
          deleting.status,
          permission == AiWritePermission.auto
              ? AgentRunStatus.generating
              : AgentRunStatus.awaitingConfirmation,
        );
      },
    );
  }

  test('current edit and ordinary complete/delete do not mutate templates or other instances', () async {
    var snapshot = await seed();
    final todo = snapshot.todos.first;
    await tools.execute(
      await propose([
        _call('todo_repeat_update', {
          ...target(snapshot, todo, 'current'),
          'patch': {'title': '仅本次'},
        }),
      ]),
    );
    snapshot = await workspace.load();
    expect(snapshot.series.single.version, 1);
    expect(snapshot.todos.where((e) => e.data['title'] == '仅本次'), hasLength(1));
    var updated = snapshot.find(WorkspaceEntityKind.todo, todo.id)!;
    await tools.execute(
      await propose([
        _call('todo_complete', {
          'id': updated.id,
          'expected_version': updated.version,
        }),
      ]),
    );
    snapshot = await workspace.load();
    updated = snapshot.find(WorkspaceEntityKind.todo, todo.id)!;
    expect(updated.data['status'], 'done');
    await tools.execute(
      await propose([
        _call('todo_delete', {
          'id': updated.id,
          'expected_version': updated.version,
        }),
      ]),
    );
    snapshot = await workspace.load();
    expect(snapshot.todos, hasLength(3));
    expect(snapshot.series.single.version, 1);
  });

  test('start existing ordinary todo; query returns series version and slot identity', () async {
    await policy(AiWritePermission.auto);
    await tools.execute(
      await propose([
        _call('todo_create', {'title': '已有任务', 'due_at': _create()['due_at']}),
      ]),
    );
    final todo = (await workspace.load()).todos.single;
    await tools.execute(
      await propose([
        _call('todo_repeat_start', {
          'id': todo.id,
          'expected_version': todo.version,
          'repeat_rule': 'FREQ=WEEKLY;COUNT=3',
          'repeat_timezone': 'Asia/Shanghai',
        }),
      ]),
    );
    final query = await tools.execute(await propose([_call('todo_list', {})]));
    final rows =
        jsonDecode(query.history.last['content']! as String)['items'] as List;
    expect(rows, hasLength(3));
    expect(
      rows.every(
        (e) => e['series_version'] == 1 && e['occurrence_key'] != null,
      ),
      isTrue,
    );
  });

  test('refresh rebases unexecuted intent, keeps latest other fields and requires new approval', () async {
    var snapshot = await seed();
    final todo = snapshot.todos.first;
    await policy(AiWritePermission.askAll);
    final waiting = await tools.execute(
      await propose([
        _call('todo_repeat_update', {
          ...target(snapshot, todo),
          'patch': {'title': '提案标题'},
        }),
      ]),
    );
    await edit(todo, {'note': '用户新备注'});
    await expectLater(
      tools.execute(waiting, approval: approve(waiting)),
      throwsA(isA<WorkspaceFailure>()),
    );
    final refreshed = await tools.refreshProposal(
      waiting.id,
      expectedRevision: waiting.revision,
    );
    expect(refreshed.status, AgentRunStatus.awaitingConfirmation);
    expect(refreshed.proposal!['digest'], isNot(waiting.proposal!['digest']));
    expect(
      (await tools.execute(refreshed)).status,
      AgentRunStatus.awaitingConfirmation,
    );
    await expectLater(
      tools.execute(refreshed, approval: approve(waiting)),
      throwsA(isA<AgentFailure>()),
    );
    await tools.execute(refreshed, approval: approve(refreshed));
    snapshot = await workspace.load();
    expect(
      snapshot.find(WorkspaceEntityKind.todo, todo.id)!.data['note'],
      '用户新备注',
    );
    expect(snapshot.todos.every((e) => e.data['title'] == '提案标题'), isTrue);
  });

  test('generation between approval and commit conflicts; refresh includes newly generated future', () async {
    await policy(AiWritePermission.auto);
    await tools.execute(
      await propose([
        _call('todo_repeat_create', {
          ..._create(),
          'repeat_rule': 'FREQ=DAILY',
        }),
      ]),
    );
    var snapshot = await workspace.load();
    final todo = snapshot.todos.first;
    await policy(AiWritePermission.askAll);
    final waiting = await tools.execute(
      await propose([_call('todo_repeat_delete', target(snapshot, todo))]),
    );
    await workspace.execute(
      RecurrencePlans(snapshot, now: _now).materialize(
        snapshot.series.single.id,
        through: _now.add(const Duration(days: 95)),
        operationId: 'generate',
      )!,
    );
    snapshot = await workspace.load();
    expect(snapshot.todos.length, greaterThan(65));
    await expectLater(
      tools.execute(waiting, approval: approve(waiting)),
      throwsA(isA<WorkspaceFailure>()),
    );
    final refreshed = await tools.refreshProposal(
      waiting.id,
      expectedRevision: waiting.revision,
    );
    await tools.execute(refreshed, approval: approve(refreshed));
    expect((await workspace.load()).todos, isEmpty);
    expect((await workspace.load()).series.single.data['stop_before'], 0);
  });

  test('future delete retains completed facts and undo restores exact original scope', () async {
    var snapshot = await seed();
    final ordered = snapshot.todos.toList()
      ..sort(
        (a, b) => (a.data['occurrence_index']! as int).compareTo(
          b.data['occurrence_index']! as int,
        ),
      );
    await edit(ordered.last, {'status': 'done'});
    snapshot = await workspace.load();
    final done = await tools.execute(
      await propose([
        _call('todo_repeat_delete', target(snapshot, ordered[1])),
      ]),
    );
    expect((await workspace.load()).todos, hasLength(2));
    await workspace.undo(done.receipts.single, operationId: 'undo');
    snapshot = await workspace.load();
    expect(snapshot.todos, hasLength(4));
    expect(
      snapshot.find(WorkspaceEntityKind.todo, ordered.last.id)!.data['status'],
      'done',
    );
  });

  test('clearing recurrence detaches selected instance and stops future generation; undo restores series', () async {
    final snapshot = await seed();
    final selected = snapshot.todos.singleWhere(
      (e) => e.data['occurrence_index'] == 1,
    );
    final done = await tools.execute(
      await propose([
        _call('todo_repeat_update', {
          ...target(snapshot, selected),
          'patch': {'repeat_rule': null},
        }),
      ]),
    );
    expect(
      jsonDecode(done.history.last['content']! as String)['future_generation'],
      'stopped_for_selected_scope',
    );
    var after = await workspace.load();
    expect(after.todos, hasLength(2));
    expect(
      after.find(WorkspaceEntityKind.todo, selected.id)!.data['series_id'],
      isNull,
    );
    expect(
      RecurrencePlans(after, now: _now).materialize(
        after.series.single.id,
        operationId: 'no-resurrection',
        through: _now.add(const Duration(days: 100)),
      ),
      isNull,
    );
    await workspace.undo(done.receipts.single, operationId: 'restore-repeat');
    after = await workspace.load();
    expect(after.todos, hasLength(4));
    expect(
      after.find(WorkspaceEntityKind.todo, selected.id)!.data['series_id'],
      isNotNull,
    );
  });

  test(
    'monthly rule is shared with manual calendar engine and clamps month end',
    () async {
      await policy(AiWritePermission.auto);
      await tools.execute(
        await propose([
          _call('todo_repeat_create', {
            ..._create(),
            'due_at': '2026-01-31T01:00:00.000Z',
            'repeat_rule': 'FREQ=MONTHLY;COUNT=3',
          }),
        ]),
      );
      final dates =
          (await workspace.load()).todos.map((e) => e.data['due_at']).toList()
            ..sort((a, b) => '$a'.compareTo('$b'));
      expect(dates, [
        '2026-01-31T01:00:00.000Z',
        '2026-02-28T01:00:00.000Z',
        '2026-03-31T01:00:00.000Z',
      ]);
    },
  );

  test('journal failure rolls back whole series and leaves original proposal executable', () async {
    await policy(AiWritePermission.auto);
    final proposed = await propose([_call('todo_repeat_create', _create())]);
    final failing = SqliteAgentToolExecutor(
      db,
      clock: () => _now,
      beforeJournal: () => throw StateError('fault'),
    );
    await expectLater(failing.execute(proposed), throwsA(isA<AgentFailure>()));
    expect((await workspace.load()).entities, isEmpty);
    expect((await runs.read(proposed.id)).revision, proposed.revision);
    await tools.execute(proposed);
    expect((await workspace.load()).todos, hasLength(4));
  });

  test('reject overlapping effects, stale series, invented scope and injected provenance', () async {
    final snapshot = await seed();
    final todo = snapshot.todos.first;
    for (final calls in [
      [
        _call('todo_repeat_update', {
          ...target(snapshot, todo),
          'patch': {'title': 'new'},
        }, 'a'),
        _call('todo_complete', {
          'id': todo.id,
          'expected_version': todo.version,
        }, 'b'),
      ],
      [
        _call('todo_repeat_delete', {
          ...target(snapshot, todo),
          'expected_series_version': 99,
        }),
      ],
      [
        _call('todo_repeat_delete', {
          ...target(snapshot, todo),
          'scope': 'all',
        }),
      ],
      [
        _call('todo_repeat_create', {..._create(), 'source': 'manual'}),
      ],
      [
        _call('todo_repeat_update', {
          ...target(snapshot, todo, 'current'),
          'patch': {'repeat_rule': 'FREQ=MONTHLY'},
        }),
      ],
    ]) {
      await expectLater(
        propose(calls),
        throwsA(anyOf(isA<AgentFailure>(), isA<WorkspaceFailure>())),
      );
    }
    expect((await workspace.load()).todos, hasLength(4));
  });

  test('expanded batch is bounded before any proposal or write', () async {
    await expectLater(
      propose([
        for (var i = 0; i < 8; i++)
          _call('todo_repeat_create', {
            ..._create(),
            'repeat_rule': 'FREQ=DAILY',
          }, 'call$i'),
      ]),
      throwsA(
        isA<AgentFailure>().having(
          (e) => e.code,
          'code',
          AgentFailureCode.budget,
        ),
      ),
    );
    expect((await workspace.load()).entities, isEmpty);
    expect(
      TodoAgentTools.schemas
          .map((s) => (s['function']! as Map)['name'])
          .toSet(),
      {
        'data_table_create',
        'data_table_update',
        'data_table_list',
        'data_table_get',
        'data_row_list',
        'data_row_get',
        'data_row_create',
        'data_row_update',
        'data_row_delete',
        'memory_create',
        'memory_search',
        'memory_update',
        'calculate',
        'calendar_lookup',
        'todo_stats',
        'show_todo_list',
        'show_todo_overview',
        'show_question',
        'todo_list',
        'category_list',
        'todo_get',
        'todo_create',
        'todo_update',
        'todo_complete',
        'todo_delete',
        'todo_repeat_create',
        'todo_repeat_start',
        'todo_repeat_update',
        'todo_repeat_delete',
      },
    );
  });
}
