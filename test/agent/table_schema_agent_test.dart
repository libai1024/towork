import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
  late Directory directory;
  late AppDatabase db;
  late SqliteWorkspaceCommandStore workspace;
  late SqliteAgentRunStore runs;
  late SqliteAgentToolExecutor tools;
  var serial = 0;
  void connect() {
    db = AppDatabase.background(File('${directory.path}/test.sqlite'));
    workspace = SqliteWorkspaceCommandStore(db);
    runs = SqliteAgentRunStore(db);
    tools = SqliteAgentToolExecutor(db);
  }

  Future<void> permission(String value) async {
    final prefs = SqliteAppPreferencesStore(db);
    final previous = await prefs.loadOrCreate();
    await prefs.update({
      'permission': value,
    }, expectedVersion: previous.version);
  }

  Future<AgentRun> propose(String name, JsonObject args) async {
    final queued = await runs.create(
      AgentRun(
        id: 'schema-${++serial}',
        sessionId: 'session',
        inputId: 'input-$serial',
        profile: ModelProfile(model: 'fixture'),
        history: [
          {'role': 'user', 'content': '管理项目表'},
        ],
      ),
    );
    final generating = await runs.save(
      queued.next(AgentRunStatus.generating, round: 1),
      expectedRevision: queued.revision,
    );
    return tools.propose(
      generating,
      businessCalls([businessCall('schema', name, args)]),
    );
  }

  AgentApproval approval(AgentRun run, {bool reject = false}) => AgentApproval(
    runRevision: run.revision,
    proposalId: run.proposal!['id']! as String,
    digest: run.proposal!['digest']! as String,
    reject: reject,
  );
  Future<void> manual(WorkspaceEntity entity, JsonObject patch) async {
    await workspace.execute(
      WorkspaceCommand(
        operationId: 'manual-${++serial}',
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
    );
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('table-schema-agent');
    connect();
    await workspace.execute(businessAgentFixture());
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  for (final mode in ['auto', 'askOnChange', 'askAll']) {
    test(
      'table create/edit always confirm in $mode, persist and undo',
      () async {
        await permission(mode);
        var run = await tools.execute(
          await propose('data_table_create', {
            'name': '采购清单',
            'description': '本周采购',
            'fields': [
              {'name': '物品', 'type': 'text', 'required': true},
              {'name': '预算', 'type': 'money', 'unit': '元'},
            ],
          }),
        );
        expect(run.status, AgentRunStatus.awaitingConfirmation);
        expect((await workspace.load()).dataTables, hasLength(1));
        expect((await tools.execute(run)).revision, run.revision);
        final pending = run;
        final decision = approval(run);
        await db.close();
        connect();
        run = await tools.execute(await runs.read(run.id), approval: decision);
        expect(
          (await tools.execute(pending, approval: decision)).toJson(),
          run.toJson(),
        );
        final table = (await workspace.load()).dataTables.singleWhere(
          (e) => e.data['name'] == '采购清单',
        );
        final fields = BusinessQueries.fields(table);
        expect(fields.map((f) => f['id']).toSet(), hasLength(2));
        expect(fields.last['scale'], 2);
        final edit = await tools.execute(
          await propose('data_table_update', {
            'table_id': table.id,
            'expected_table_version': table.version,
            'patch': {
              'name': '采购计划',
              'update_fields': [
                {'id': fields.first['id'], 'name': '采购物品'},
              ],
              'add_fields': [
                {'name': '到货日期', 'type': 'date'},
              ],
            },
          }),
        );
        expect(edit.status, AgentRunStatus.awaitingConfirmation);
        expect(
          (await workspace.load()).find(table.kind, table.id)!.data['name'],
          '采购清单',
        );
        final committed = await tools.execute(edit, approval: approval(edit));
        final updated = (await workspace.load()).find(table.kind, table.id)!;
        expect(updated.data['schema_version'], 2);
        expect(BusinessQueries.fields(updated), hasLength(3));
        expect(BusinessQueries.fields(updated)[1], fields[1]);
        await workspace.undoMany([
          ...run.receipts,
          ...committed.receipts,
        ], operationId: 'undo-schema');
        expect((await workspace.load()).dataTables, hasLength(1));
      },
    );
  }

  test('stale schema approval fails and sparse refresh preserves concurrent fields', () async {
    await permission('auto');
    final run = await tools.execute(
      await propose('data_table_update', {
        'table_id': 'ledger',
        'expected_table_version': 1,
        'patch': {
          'name': '新账本',
          'update_fields': [
            {'id': 'amount', 'name': '含税金额'},
          ],
        },
      }),
    );
    final rowsBefore = (await workspace.load()).dataRows
        .map((e) => e.toJson())
        .toList();
    final table = (await workspace.load()).dataTables.single;
    await manual(table, {
      'fields': [
        ...BusinessQueries.fields(table),
        {'id': 'extra', 'name': '经办人', 'type': 'text'},
      ],
      'schema_version': 2,
    });
    await expectLater(
      tools.execute(run, approval: approval(run)),
      throwsA(isA<WorkspaceFailure>()),
    );
    final refreshed = await tools.refreshProposal(
      run.id,
      expectedRevision: run.revision,
    );
    expect(refreshed.status, AgentRunStatus.awaitingConfirmation);
    await expectLater(
      tools.execute(refreshed, approval: approval(run)),
      throwsA(isA<AgentFailure>()),
    );
    await tools.execute(refreshed, approval: approval(refreshed));
    final updated = (await workspace.load()).dataTables.single;
    expect(updated.data['name'], '新账本');
    expect(BusinessQueries.fields(updated).last['id'], 'extra');
    expect(updated.data['schema_version'], 3);
    expect(
      (await workspace.load()).dataRows.map((e) => e.toJson()).toList(),
      rowsBefore,
    );
  });

  test(
    'invalid schema or populated field removal never changes stored rows',
    () async {
      final before = await workspace.load();
      for (final patch in <JsonObject>[
        {
          'remove_field_ids': ['amount'],
        },
        {
          'update_fields': [
            {'id': 'missing', 'name': 'x'},
          ],
        },
        {
          'update_fields': [
            {'id': 'amount', 'type': 'text'},
          ],
        },
        {
          'add_fields': [
            {'id': 'forged', 'name': 'x', 'type': 'text'},
          ],
        },
        {
          'add_fields': [
            {'name': '项目', 'type': 'text'},
          ],
        },
        {
          'add_fields': [
            {'name': '必填新列', 'type': 'text', 'required': true},
          ],
        },
      ]) {
        await expectLater(
          propose('data_table_update', {
            'table_id': 'ledger',
            'expected_table_version': 1,
            'patch': patch,
          }),
          throwsA(anyOf(isA<AgentFailure>(), isA<WorkspaceFailure>())),
        );
      }
      expect(
        (await workspace.load()).entities.map(
          (k, v) => MapEntry(k, v.toJson()),
        ),
        before.entities.map((k, v) => MapEntry(k, v.toJson())),
      );
      final rejected = await tools.execute(
        await propose('data_table_create', {
          'name': '不保存',
          'fields': [
            {'name': '内容', 'type': 'text'},
          ],
        }),
      );
      await tools.execute(rejected, approval: approval(rejected, reject: true));
      expect((await workspace.load()).dataTables, hasLength(1));
    },
  );
}
