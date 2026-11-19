import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/agent/agent_runner.dart';
import 'package:towork/data/local/agent_run_store.dart';
import 'package:towork/data/local/agent_tool_executor.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/app_preferences_store.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/data_tables/business_queries.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';

import '../support/free/business_agent_fixture.dart';
import '../support/free/scripted_business_model.dart';

void main() {
  late Directory dir;
  late AppDatabase db;
  late SqliteWorkspaceCommandStore workspace;
  late SqliteAgentRunStore runs;
  late SqliteAgentToolExecutor tools;
  var serial = 0;
  void connect() {
    db = AppDatabase.background(File('${dir.path}/test.sqlite'));
    workspace = SqliteWorkspaceCommandStore(db);
    runs = SqliteAgentRunStore(db);
    tools = SqliteAgentToolExecutor(db);
  }

  Future<void> policy(String permission) async {
    final prefs = SqliteAppPreferencesStore(db);
    final old = await prefs.loadOrCreate();
    await prefs.update({
      'permission': permission,
    }, expectedVersion: old.version);
  }

  AgentRun initial() => AgentRun(
    id: 'run${++serial}',
    sessionId: 'session',
    inputId: 'input$serial',
    profile: ModelProfile(model: 'fixture'),
    history: [
      {'role': 'user', 'content': '管理项目账本'},
    ],
  );
  Future<AgentRun> propose(List<JsonObject> calls) async {
    final queued = await runs.create(initial());
    final run = await runs.save(
      queued.next(AgentRunStatus.generating, round: 1),
      expectedRevision: queued.revision,
    );
    return tools.propose(run, businessCalls(calls));
  }

  AgentApproval approve(
    AgentRun run, {
    List<String>? selected,
    bool reject = false,
  }) => AgentApproval(
    runRevision: run.revision,
    proposalId: run.proposal!['id']! as String,
    digest: run.proposal!['digest']! as String,
    selectedToolCallIds: selected,
    reject: reject,
  );
  JsonObject target([String row = 'keep']) => {
    'table_id': 'ledger',
    'expected_table_version': 1,
    'id': row,
    'expected_version': 1,
  };
  Future<void> edit(WorkspaceEntity entity, JsonObject patch) => workspace
      .execute(
        WorkspaceCommand(
          operationId: 'manual${++serial}',
          actions: [
            WorkspaceMutation(
              actionId: 'edit',
              kind: entity.kind,
              entityId: entity.id,
              mutation: WorkspaceMutationKind.update,
              expectedVersion: entity.version,
              patch: patch,
            ),
          ],
        ),
      )
      .then((_) {});
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('business-agent');
    connect();
    await workspace.execute(businessAgentFixture());
    await policy('auto');
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  for (final permission in ['auto', 'askOnChange', 'askAll']) {
    test(
      'real discovery and row CRUD with $permission, reopen and multi-batch undo',
      () async {
        await policy(permission);
        final model = ScriptedBusinessModel();
        final runner = AgentRunner(gateway: model, store: runs, tools: tools);
        var run = await runner.start(initial(), apiKey: 'synthetic-business');
        {
          expect(run.status, AgentRunStatus.awaitingConfirmation);
          final before = await workspace.load();
          expect(before.dataRows, hasLength(2));
          expect(
            (before.find(WorkspaceEntityKind.dataRow, 'keep')!.data['values']!
                as Map)['amount'],
            '12345678901234567890.10',
          );
          expect((run.proposal!['calls']! as List).length, 3);
          run = await runner.resume(
            run.id,
            apiKey: 'synthetic-business',
            approval: approve(run),
          );
        }
        expect(run.status, AgentRunStatus.succeeded);
        expect(model.requests, hasLength(5));
        final snapshot = await workspace.load();
        expect(snapshot.dataRows, hasLength(2));
        final keep = snapshot.find(WorkspaceEntityKind.dataRow, 'keep')!;
        expect((keep.data['values']! as Map)['note'], businessLongNote);
        expect((keep.data['values']! as Map)['amount'], '9.50');
        final created = snapshot.dataRows.singleWhere((r) => r.id != 'keep');
        expect(created.data['source'], 'ai');
        expect(created.data['source_message_id'], run.inputId);
        expect((created.data['values']! as Map)['amount'], '0.10');
        final toolMessages = run.history
            .where((m) => m['role'] == 'tool')
            .toList();
        expect(toolMessages, hasLength(6));
        expect((toolMessages.last['content']! as String).length, lessThan(500));
        await db.close();
        connect();
        expect((await runs.read(run.id)).receipts, run.receipts);
        await workspace.undoMany(run.receipts, operationId: 'undo-run');
        final undone = await workspace.load();
        expect(undone.dataRows.map((r) => r.id).toSet(), {'keep', 'remove'});
        expect(
          (undone.find(WorkspaceEntityKind.dataRow, 'keep')!.data['values']!
              as Map)['amount'],
          '12345678901234567890.10',
        );
      },
    );
  }

  test('partial approve and reject survives reopen; exact decision replay is idempotent', () async {
    await policy('askAll');
    var run = await tools.execute(
      await propose([
        businessCall('edit', 'data_row_update', {
          ...target(),
          'values': {'amount': '2'},
        }),
        businessCall('delete', 'data_row_delete', target('remove')),
      ]),
    );
    final decision = approve(run, selected: ['edit']);
    final original = run;
    run = await tools.execute(run, approval: decision);
    expect(run.status, AgentRunStatus.awaitingConfirmation);
    expect(
      (await tools.execute(original, approval: decision)).toJson(),
      run.toJson(),
    );
    await db.close();
    connect();
    run = await runs.read(run.id);
    run = await tools.execute(run, approval: approve(run, reject: true));
    expect((await workspace.load()).dataRows, hasLength(2));
    expect(run.receipts, hasLength(1));
    expect(
      jsonDecode(run.history.last['content']! as String)['reason'],
      'user_rejected',
    );
  });

  test('schema and row changes reject stale approval; refreshed sparse intent preserves concurrent cell', () async {
    await policy('askAll');
    var run = await tools.execute(
      await propose([
        businessCall('edit', 'data_row_update', {
          ...target(),
          'values': {'amount': '7.5'},
        }),
      ]),
    );
    final oldApproval = approve(run);
    var snapshot = await workspace.load();
    final table = snapshot.dataTables.single;
    await edit(table, {
      'fields': [
        for (final f in BusinessQueries.fields(table))
          if (f['id'] == 'amount') {...f, 'name': '含税金额'} else f,
      ],
      'schema_version': 2,
    });
    await expectLater(
      tools.execute(run, approval: oldApproval),
      throwsA(isA<WorkspaceFailure>()),
    );
    final row = snapshot.find(WorkspaceEntityKind.dataRow, 'keep')!;
    await edit(row, {
      'values': {...row.data['values']! as JsonObject, 'note': '人工最新备注'},
    });
    run = await tools.refreshProposal(run.id, expectedRevision: run.revision);
    expect(run.status, AgentRunStatus.awaitingConfirmation);
    await expectLater(
      tools.execute(run, approval: oldApproval),
      throwsA(isA<AgentFailure>()),
    );
    final call = (run.proposal!['calls']! as List).single as Map;
    expect(
      ((call['business_table']! as Map)['fields']! as List).any(
        (f) => f['name'] == '含税金额',
      ),
      isTrue,
    );
    await tools.execute(run, approval: approve(run));
    snapshot = await workspace.load();
    final values =
        snapshot.find(WorkspaceEntityKind.dataRow, 'keep')!.data['values']!
            as Map;
    expect(values['note'], '人工最新备注');
    expect(values['amount'], '7.50');
  });

  test('mixed todo and business command rolls back on journal failure then commits once', () async {
    await policy('askAll');
    final run = await tools.execute(
      await propose([
        businessCall('todo', 'todo_complete', {
          'id': 'todo',
          'expected_version': 1,
        }),
        businessCall('edit', 'data_row_update', {
          ...target(),
          'values': {'paid': true},
        }),
      ]),
    );
    final decision = approve(run);
    final broken = SqliteAgentToolExecutor(
      db,
      beforeJournal: () => throw StateError('fault'),
    );
    await expectLater(
      broken.execute(run, approval: decision),
      throwsA(isA<AgentFailure>()),
    );
    var snapshot = await workspace.load();
    expect(snapshot.todos.single.data['status'], 'pending');
    expect(snapshot.find(WorkspaceEntityKind.dataRow, 'keep')!.version, 1);
    expect((await runs.read(run.id)).revision, run.revision);
    expect(await db.select(db.workspaceOperations).get(), hasLength(1));
    final result = await tools.execute(run, approval: decision);
    await tools.execute(run, approval: decision);
    snapshot = await workspace.load();
    expect(snapshot.todos.single.data['status'], 'done');
    expect(snapshot.find(WorkspaceEntityKind.dataRow, 'keep')!.version, 2);
    expect(result.receipts, hasLength(1));
    expect(await db.select(db.workspaceOperations).get(), hasLength(2));
  });

  test('invalid typed value, forged provenance, cross-table target and duplicate writes reject whole batch', () async {
    for (final values in <JsonObject>[
      {'amount': 0.1},
      {'paid': 'false'},
      {'missing': 'x'},
      {'title': null},
      {'amount': '1.001'},
    ]) {
      await expectLater(
        propose([
          businessCall('todo', 'todo_complete', {
            'id': 'todo',
            'expected_version': 1,
          }),
          businessCall('edit', 'data_row_update', {
            ...target(),
            'values': values,
          }),
        ]),
        throwsA(isA<WorkspaceFailure>()),
      );
    }
    await expectLater(
      propose([
        businessCall('create', 'data_row_create', {
          'table_id': 'ledger',
          'expected_table_version': 1,
          'values': {'title': '伪造'},
          'source': 'manual',
        }),
      ]),
      throwsA(isA<WorkspaceFailure>()),
    );
    await expectLater(
      propose([
        businessCall('a', 'data_row_update', {
          ...target(),
          'values': {'paid': true},
        }),
        businessCall('b', 'data_row_delete', target()),
      ]),
      throwsA(isA<AgentFailure>()),
    );
    await expectLater(
      propose([
        businessCall('edit', 'data_row_update', {
          ...target(),
          'table_id': 'missing',
          'values': {'paid': true},
        }),
      ]),
      throwsA(isA<WorkspaceFailure>()),
    );
    expect((await workspace.load()).todos.single.data['status'], 'pending');
    expect(await db.select(db.workspaceOperations).get(), hasLength(1));
  });

  test('bounded Unicode cell reads, schema option paging, versioned row cursor and no implicit all-row write', () async {
    var snapshot = await workspace.load();
    JsonObject query(String name, JsonObject args) =>
        BusinessQueries.query(name, snapshot, args);
    final first = query('data_row_list', {'table_id': 'ledger', 'limit': 1});
    final item = (first['items']! as List).single as Map;
    expect(item['truncated_fields'], ['note']);
    expect(((item['values']! as Map)['note']! as String).runes.length, 200);
    final cell = query('data_row_get', {
      ...target(),
      'field_id': 'note',
      'limit': 2000,
    });
    final rest = query('data_row_get', {
      ...target(),
      'field_id': 'note',
      'offset': cell['next_offset'],
      'limit': 2000,
    });
    expect('${cell['value']}${rest['value']}', businessLongNote);
    final options = query('data_table_get', {
      'table_id': 'ledger',
      'field_id': 'stage',
      'limit': 20,
    });
    expect(((options['options']! as Map)['items']! as List), hasLength(20));
    final more = query('data_table_get', {
      'table_id': 'ledger',
      'field_id': 'stage',
      'limit': 20,
      'page_token': (options['options']! as Map)['next_page_token'],
    });
    expect(((more['options']! as Map)['items']! as List), hasLength(5));
    final next = query('data_row_list', {
      'table_id': 'ledger',
      'limit': 1,
      'page_token': first['next_page_token'],
    });
    expect(((next['items']! as List).single as Map)['id'], 'remove');
    await edit(snapshot.find(WorkspaceEntityKind.dataRow, 'keep')!, {
      'values': {'title': '人工修改'},
    });
    snapshot = await workspace.load();
    expect(
      query('data_row_list', {
        'table_id': 'ledger',
        'limit': 1,
        'page_token': first['next_page_token'],
      })['error'],
      'cursor_stale',
    );
    expect(
      () => query('data_row_get', {
        ...target(),
        'field_id': 'note',
        'offset': 2000,
      }),
      throwsA(isA<WorkspaceFailure>()),
    );
    expect(
      () => query('data_row_list', {
        'table_id': 'ledger',
        'sql': 'DROP TABLE work_data_rows',
      }),
      throwsA(isA<WorkspaceFailure>()),
    );
  });
}
