import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/agent/agent_runner.dart';
import 'package:towork/data/local/agent_run_store.dart';
import 'package:towork/data/local/agent_tool_executor.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/sqlite_row_query.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/data_tables/business_queries.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';

import '../../support/free/scripted_business_model.dart';

void main() {
  late Directory dir;
  late AppDatabase db;
  late SqliteWorkspaceCommandStore store;
  late String tableId;
  late String titleId, amountId, countId, dateId, stageId, paidId;
  const rowCount = 1200;

  Future<void> commit(List<WorkspaceMutation> actions, int seq) =>
      store.execute(
        WorkspaceCommand(
          operationId: 'seed_$seq',
          actions: actions,
          source: 'system',
        ),
      );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('towork-sql-rows-');
    db = AppDatabase.background(File('${dir.path}/db.sqlite'));
    store = SqliteWorkspaceCommandStore(db);
    tableId = 'tbl_rows';
    titleId = 'fld_title';
    amountId = 'fld_amount';
    countId = 'fld_count';
    dateId = 'fld_date';
    stageId = 'fld_stage';
    paidId = 'fld_paid';
    await commit([
      WorkspaceMutation(
        actionId: 'table_$tableId',
        kind: WorkspaceEntityKind.dataTable,
        entityId: tableId,
        mutation: WorkspaceMutationKind.create,
        patch: {
          'name': '账本',
          'fields': [
            {
              'id': titleId,
              'name': '名称',
              'type': 'text',
              'required': true,
              'options': <Object?>[],
            },
            {
              'id': amountId,
              'name': '金额',
              'type': 'money',
              'required': false,
              'scale': 2,
              'options': <Object?>[],
            },
            {
              'id': countId,
              'name': '数量',
              'type': 'number',
              'required': false,
              'options': <Object?>[],
            },
            {
              'id': dateId,
              'name': '日期',
              'type': 'date',
              'required': false,
              'options': <Object?>[],
            },
            {
              'id': stageId,
              'name': '状态',
              'type': 'selection',
              'required': false,
              'options': ['进行中', '已完成'],
            },
            {
              'id': paidId,
              'name': '到账',
              'type': 'boolean',
              'required': false,
              'options': <Object?>[],
            },
          ],
        },
      ),
    ], 0);
    // 500-action cap per command: seed in three batches.
    for (var batch = 0; batch < 3; batch++) {
      await commit([
        for (var i = batch * 400; i < (batch + 1) * 400; i++)
          WorkspaceMutation(
            actionId: 'row_$i',
            kind: WorkspaceEntityKind.dataRow,
            entityId: 'row_$i',
            mutation: WorkspaceMutationKind.create,
            patch: {
              'table_id': tableId,
              'values': {
                titleId: '项目${i.toString().padLeft(4, '0')}',
                amountId: '$i.50',
                countId: '$i',
                dateId: '2026-01-${((i % 28) + 1).toString().padLeft(2, '0')}',
                stageId: i % 2 == 0 ? '进行中' : '已完成',
                if (i % 3 == 0) paidId: true,
              },
            },
          ),
      ], batch + 1);
    }
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  Future<Map<String, Object?>> rows(Map<String, Object?> args) async =>
      SqliteRowQuery.rows(db, await store.loadTables(), args);

  test(
    'unfiltered paging walks every row exactly once with exact totals',
    () async {
      final first = await rows({
        'table_id': tableId,
        'field_ids': [titleId, countId],
        'limit': 13,
      });
      expect(first['total'], rowCount);
      expect((first['items']! as List).length, 13);
      final seen = <String>{
        for (final item in first['items']! as List)
          (item as Map)['id']! as String,
      };
      var token = first['next_page_token']! as String;
      var pages = 1;
      while (token.isNotEmpty) {
        final page = await rows({
          'table_id': tableId,
          'field_ids': [titleId, countId],
          'limit': 13,
          'page_token': token,
        });
        pages++;
        for (final item in page['items']! as List) {
          expect(seen.add((item as Map)['id']! as String), isTrue);
        }
        token = page['next_page_token'] as String? ?? '';
      }
      expect(seen.length, rowCount);
      expect(pages, (rowCount / 13).ceil());
    },
  );

  test(
    'typed filters push down: money scale, numeric range, enum, boolean, date',
    () async {
      // Money equality normalizes the caller's loose form to the stored scale.
      final money = await rows({
        'table_id': tableId,
        'filters': [
          {'field_id': amountId, 'op': 'eq', 'value': 5.5},
        ],
      });
      expect(money['total'], 1);
      expect(
        ((money['items']! as List).single as Map)['values'],
        containsPair(titleId, '项目0005'),
      );

      final range = await rows({
        'table_id': tableId,
        'filters': [
          {'field_id': amountId, 'op': 'gt', 'value': 1195},
          {'field_id': stageId, 'op': 'eq', 'value': '已完成'},
        ],
      });
      expect(range['total'], 3); // 1195/1197/1199.50 均大于 1195 且已完成
      final titles = (range['items']! as List)
          .map((r) => ((r as Map)['values'] as Map)[titleId])
          .toList();
      expect(titles, unorderedEquals(['项目1195', '项目1197', '项目1199']));

      final paid = await rows({
        'table_id': tableId,
        'filters': [
          {'field_id': paidId, 'op': 'eq', 'value': true},
        ],
        'limit': 1,
      });
      expect(paid['total'], 400);

      final day = await rows({
        'table_id': tableId,
        'filters': [
          {'field_id': dateId, 'op': 'ge', 'value': '2026-01-15'},
          {'field_id': dateId, 'op': 'le', 'value': '2026-01-15'},
        ],
      });
      expect(day['total'], 43);

      final contains = await rows({
        'table_id': tableId,
        'filters': [
          {'field_id': titleId, 'op': 'contains', 'value': '0011'},
        ],
      });
      expect(contains['total'], 1);
      expect(
        ((contains['items']! as List).single as Map)['values'],
        containsPair(titleId, '项目0011'),
      );
    },
  );

  test('free-text query matches any string cell including numbers', () async {
    final byTitle = await rows({'table_id': tableId, 'query': '项目1199'});
    expect(byTitle['total'], 1);
    final byNumber = await rows({'table_id': tableId, 'query': '1197'});
    // 名称/数量/金额任一命中都算同一行；1197 只对应一行。
    expect(byNumber['total'], 1);
  });

  test(
    'sort orders by cell value with stable id tiebreak and nulls last',
    () async {
      final desc = await rows({
        'table_id': tableId,
        'sort_field_id': amountId,
        'sort_desc': true,
        'limit': 2,
      });
      expect(
        (desc['items']! as List)
            .map((r) => ((r as Map)['values'] as Map)[titleId])
            .toList(),
        ['项目1199', '项目1198'],
      );

      final missingLast = await rows({
        'table_id': tableId,
        'sort_field_id': paidId,
        'sort_desc': true,
        'limit': 3,
      });
      for (final item in missingLast['items']! as List) {
        expect(((item as Map)['values'] as Map)[paidId], isTrue);
      }
    },
  );

  test(
    'cursor reports stale after data changes and rejects bad tokens',
    () async {
      final args = {
        'table_id': tableId,
        'filters': [
          {'field_id': stageId, 'op': 'eq', 'value': '已完成'},
        ],
        'limit': 10,
      };
      final first = await rows(args);
      final token = first['next_page_token']! as String;
      final second = await rows({...args, 'page_token': token});
      expect((second['items']! as List), isNotEmpty);

      // Changing any matching row's version must invalidate the cursor.
      await commit([
        WorkspaceMutation(
          actionId: 'row_1',
          kind: WorkspaceEntityKind.dataRow,
          entityId: 'row_1',
          mutation: WorkspaceMutationKind.update,
          expectedVersion: 1,
          patch: {
            'values': {
              titleId: '项目0001',
              amountId: '1.50',
              countId: '1',
              dateId: '2026-01-02',
              stageId: '进行中',
            },
          },
        ),
      ], 99);
      final stale = await rows({...args, 'page_token': token});
      expect(stale['error'], 'cursor_stale');

      expect(
        () => rows({...args, 'page_token': 'not-a-token'}),
        throwsA(isA<WorkspaceFailure>()),
      );
    },
  );

  test('invalid filters and sorts are rejected before SQL runs', () async {
    Future<void> reject(Map<String, Object?> args) =>
        expectLater(rows(args), throwsA(isA<WorkspaceFailure>()));
    await reject({
      'table_id': tableId,
      'filters': [
        {'field_id': 'fld_missing', 'op': 'eq', 'value': 'x'},
      ],
    });
    await reject({
      'table_id': tableId,
      'filters': [
        {'field_id': stageId, 'op': 'gt', 'value': 'x'},
      ],
    });
    await reject({
      'table_id': tableId,
      'filters': [
        {'field_id': paidId, 'op': 'eq', 'value': 'true'},
      ],
    });
    await reject({'table_id': tableId, 'sort_field_id': 'fld_missing'});
    await reject({
      'table_id': tableId,
      'filters': [
        for (var i = 0; i < 5; i++)
          {'field_id': stageId, 'op': 'eq', 'value': '已完成'},
      ],
    });
  });

  test(
    'agent read turn pages in SQL without materializing the full snapshot',
    () async {
      // The gateway replays a fixed script: one filtered data_row_list call,
      // then a plain completion. Captured tool results prove the executor took
      // the SQL path.
      final results = <String>[];
      final gateway = _ScriptedGateway([
        businessCalls([
          businessCall('q1', 'data_row_list', {
            'table_id': tableId,
            'filters': [
              {'field_id': countId, 'op': 'ge', 'value': 1198},
            ],
            'sort_field_id': countId,
          }),
        ]),
        ModelCompleted(
          assistantMessage: {'role': 'assistant', 'content': '查询完成'},
          finishReason: 'stop',
        ),
      ], results);
      final runner = AgentRunner(
        gateway: gateway,
        store: SqliteAgentRunStore(db),
        tools: SqliteAgentToolExecutor(db),
        maxRounds: 3,
        maxTokens: 2048,
      );
      AgentRun run;
      Object? thrown;
      try {
        run = await runner.start(
          AgentRun(
            id: 'sql-read-run',
            sessionId: 'session',
            inputId: 'input',
            profile: _profile,
            history: const [
              {'role': 'user', 'content': '列出数量最大的几条'},
            ],
          ),
          apiKey: 'synthetic-sql-read',
        );
      } catch (error) {
        run = (await SqliteAgentRunStore(db).read('sql-read-run'));
        thrown = error;
      }
      File('/tmp/towork-dbg-run.json').writeAsString(
        jsonEncode({
          'thrown': thrown.runtimeType.toString(),
          'run': run.toJson(),
        }),
      );
      expect(run.status, AgentRunStatus.succeeded, reason: '$thrown');
      expect(run.receipts, isEmpty);
      final toolResult = jsonDecode(results.single) as Map;
      expect(toolResult['total'], 2);
      final items = (toolResult['items']! as List).map(
        (m) => (m as Map).cast<String, Object?>(),
      );
      expect(items.map((i) => (i['values'] as Map)[titleId]).toList(), [
        '项目1198',
        '项目1199',
      ]);
    },
  );

  test('cell read serves full long text in segments', () async {
    final long = '长' * 5000;
    await commit([
      WorkspaceMutation(
        actionId: 'row_long',
        kind: WorkspaceEntityKind.dataRow,
        entityId: 'row_long',
        mutation: WorkspaceMutationKind.create,
        patch: {
          'table_id': tableId,
          'values': {titleId: long},
        },
      ),
    ], 98);
    final cell = await SqliteRowQuery.cell(db, await store.loadTables(), {
      'table_id': tableId,
      'id': 'row_long',
      'field_id': titleId,
      'limit': 4000,
    });
    expect(cell['total_code_points'], 5000);
    expect((cell['value']! as String).runes.length, 4000);
    expect(cell['next_offset'], 4000);
    final rest = await SqliteRowQuery.cell(db, await store.loadTables(), {
      'table_id': tableId,
      'id': 'row_long',
      'field_id': titleId,
      'offset': 4000,
      'limit': 4000,
      'expected_version': 1,
      'expected_table_version': 1,
    });
    expect((rest['value']! as String).runes.length, 1000);
    expect(rest['next_offset'], isNull);
    // Cross-check parity with the snapshot implementation on a small page.
    final snapshot = await store.load();
    final sqlPage = await rows({'table_id': tableId, 'limit': 5});
    final snapshotPage = BusinessQueries.query('data_row_list', snapshot, {
      'table_id': tableId,
      'limit': 5,
    });
    expect(sqlPage['total'], snapshotPage['total']);
    expect(sqlPage['items'], snapshotPage['items']);
  });
}

final _profile = ModelProfile(
  model: 'sql-fixture',
  product: ProviderKind.kimiCode,
  revision: 1,
);

class _ScriptedGateway implements ModelGateway {
  _ScriptedGateway(this._script, this.results);
  final List<ModelEvent> _script;
  final List<String> results;
  var _step = 0;

  @override
  Stream<ModelEvent> stream(
    ModelRequest request, {
    required String apiKey,
    ModelCancellation? cancellation,
  }) async* {
    final last = request.messages.last;
    if (last['tool_call_id'] is String) {
      results.add(last['content']! as String);
    }
    yield _script[_step++];
  }

  void close() {}
}
