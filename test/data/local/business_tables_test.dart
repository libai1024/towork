import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/data_tables/business_validation.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';

const tableKind = WorkspaceEntityKind.dataTable;
const rowKind = WorkspaceEntityKind.dataRow;
const typeKind = WorkspaceEntityKind.tableType;

Map<String, Object?> field(
  String id,
  String type, {
  String? name,
  bool required = false,
  List<String>? options,
  int? scale,
}) => {
  'id': id,
  'name': name ?? id,
  'type': type,
  'required': required,
  'options': ?options,
  'scale': ?scale,
};

final fields = [
  field('title', 'text', name: '标题', required: true),
  field('amount', 'money', name: '金额'),
  field('quantity', 'number'),
  field('paid', 'boolean'),
  field('day', 'date'),
  field('at', 'datetime'),
  field('stage', 'selection', options: ['未处理', '已处理']),
];

WorkspaceMutation mutation(
  WorkspaceEntityKind kind,
  String id,
  Map<String, Object?> patch, {
  int? version,
  bool delete = false,
}) => WorkspaceMutation(
  actionId: '${kind.name}_$id',
  kind: kind,
  entityId: id,
  mutation: delete
      ? WorkspaceMutationKind.delete
      : version == null
      ? WorkspaceMutationKind.create
      : WorkspaceMutationKind.update,
  expectedVersion: version,
  patch: patch,
);

Matcher failure(WorkspaceFailureCode code) =>
    throwsA(isA<WorkspaceFailure>().having((e) => e.code, 'code', code));

void main() {
  late Directory dir;
  late File file;
  late AppDatabase db;
  late SqliteWorkspaceCommandStore store;
  final now = DateTime.utc(2026, 9, 24, 12, 1, 2, 3, 4);
  Future<WorkspaceReceipt> run(
    String id,
    List<WorkspaceMutation> actions, {
    String source = 'manual',
  }) => store.execute(
    WorkspaceCommand(operationId: id, actions: actions, source: source),
  );
  WorkspaceMutation table({String id = 'table', String? type}) => mutation(
    tableKind,
    id,
    {'name': '业务记录', 'type_id': type, 'fields': fields},
  );
  WorkspaceMutation row(
    String id, {
    String owner = 'table',
    Map<String, Object?> values = const {'title': '客户甲', 'amount': '0.10'},
  }) => mutation(rowKind, id, {'table_id': owner, 'values': values});
  Future<void> seed() => run('seed', [table(), row('row')]);
  Future<void> reopen() async {
    await db.close();
    db = AppDatabase.background(file);
    store = SqliteWorkspaceCommandStore(db, clock: () => now);
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('towork-business-');
    file = File('${dir.path}/workspace.sqlite');
    db = AppDatabase.background(file);
    store = SqliteWorkspaceCommandStore(db, clock: () => now);
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  test(
    'exact decimals reject rounding, exponent, doubles and non-finite input',
    () {
      expect(canonicalBusinessDecimal('0.1', scale: 2), '0.10');
      expect(canonicalBusinessDecimal('-0.00', scale: 2), '0.00');
      expect(
        canonicalBusinessDecimal('123456789012345678901234567890.12', scale: 2),
        '123456789012345678901234567890.12',
      );
      expect(canonicalBusinessDecimal('1.2300'), '1.23');
      for (final value in <Object?>[
        0.1,
        1,
        '1e2',
        'NaN',
        'Infinity',
        '01',
        '1.001',
        '+1',
        ' 1',
        '',
        '.1',
        '1.',
      ]) {
        expect(
          () => canonicalBusinessDecimal(value, scale: 2),
          failure(WorkspaceFailureCode.validation),
        );
      }
    },
  );

  test('mixed rows, schema, types and todo commit once, reopen with exact values and receipt', () async {
    final actions = [
      row(
        'row',
        values: {
          'title': '客户甲😀',
          'amount': '12345678901234567890.1',
          'quantity': '-1.2300',
          'paid': false,
          'day': '2024-02-29',
          'at': '2026-09-24T04:01:02Z',
          'stage': '未处理',
        },
      ),
      table(type: 'type'),
      mutation(typeKind, 'type', {'name': '财务'}),
      mutation(WorkspaceEntityKind.todo, 'todo', {'title': '核对金额'}),
    ];
    final receipt = await run('mixed', actions, source: 'agent');
    await reopen();
    final snapshot = await store.load();
    expect(snapshot.todos.single.data['title'], '核对金额');
    final saved = snapshot.dataRows.single;
    expect(saved.data['values'], {
      'title': '客户甲😀',
      'amount': '12345678901234567890.10',
      'quantity': '-1.23',
      'paid': false,
      'day': '2024-02-29',
      'at': '2026-09-24T04:01:02.000Z',
      'stage': '未处理',
    });
    expect(saved.updatedAt, now);
    expect(
      snapshot.dataTables.single.data['type_id'],
      snapshot.tableTypes.single.id,
    );
    expect(
      (await run('mixed', actions, source: 'agent')).toJson(),
      receipt.toJson(),
    );
    final log = await db.select(db.workspaceOperations).get();
    expect(log, hasLength(1));
    expect(log.single.source, 'agent');
    expect((jsonDecode(log.single.changes) as List), hasLength(4));
    expect((await db.select(db.workDataRows).get()).single.tableId, 'table');
  });

  test('rename preserves field identity and values; schema versions require acknowledgement', () async {
    await seed();
    final renamed = [
      for (final f in fields)
        if (f['id'] == 'amount') {...f, 'name': '含税金额'} else f,
    ];
    await expectLater(
      run('missing-revision', [
        mutation(tableKind, 'table', {'fields': renamed}, version: 1),
      ]),
      failure(WorkspaceFailureCode.validation),
    );
    await run('rename', [
      mutation(tableKind, 'table', {
        'fields': renamed,
        'schema_version': 2,
      }, version: 1),
    ]);
    await reopen();
    final snapshot = await store.load();
    expect(snapshot.dataTables.single.version, 2);
    expect(snapshot.dataRows.single.version, 1);
    expect((snapshot.dataRows.single.data['values']! as Map)['amount'], '0.10');
    await store.undo('rename', operationId: 'restore-name');
    expect((await store.load()).dataTables.single.data['schema_version'], 1);
  });

  test(
    'bad typed cells fail the whole mixed command without partial todo writes',
    () async {
      await run('table', [table()]);
      final invalid = <Map<String, Object?>>[
        {'title': ''},
        {'title': '  '},
        {'title': 123},
        {'amount': '1.00'},
        {'title': '甲', 'unknown': 'x'},
        {'title': '甲', 'amount': 0.1},
        {'title': '甲', 'amount': '1.009'},
        {'title': '甲', 'quantity': '1e10'},
        {'title': '甲', 'paid': 'false'},
        {'title': '甲', 'day': '2026-02-29'},
        {'title': '甲', 'day': '0000-01-01'},
        {'title': '甲', 'at': '2026-09-24T25:00:00Z'},
        {'title': '甲', 'at': '2026-09-24T12:00:00'},
        {'title': '甲', 'stage': '未知'},
      ];
      for (var i = 0; i < invalid.length; i++) {
        await expectLater(
          run('bad_$i', [
            mutation(WorkspaceEntityKind.todo, 'todo_$i', {'title': '不能提前落盘'}),
            row('row_$i', values: invalid[i]),
          ]),
          failure(WorkspaceFailureCode.validation),
        );
      }
      final snapshot = await store.load();
      expect(snapshot.dataRows, isEmpty);
      expect(snapshot.todos, isEmpty);
      expect(await db.select(db.workspaceOperations).get(), hasLength(1));
    },
  );

  test('schema guards reject duplicates, invalid metadata and conversion; required field is atomic', () async {
    for (final badFields in [
      <Map<String, Object?>>[],
      [fields.first, fields.first],
      [fields.first, field('different', 'text', name: '标题')],
      [field('bad', 'selection', options: [])],
      [field('bad', 'money', scale: 7)],
      [field('bad', 'sql')],
      [field('bad', 'number', scale: 2)],
    ]) {
      await expectLater(
        run('invalid-schema', [
          mutation(tableKind, 'bad', {'name': '非法结构', 'fields': badFields}),
        ]),
        failure(WorkspaceFailureCode.validation),
      );
    }
    await seed();
    final converted = [
      for (final f in fields)
        if (f['id'] == 'amount') field('amount', 'text') else f,
    ];
    await expectLater(
      run('conversion', [
        mutation(tableKind, 'table', {
          'fields': converted,
          'schema_version': 2,
        }, version: 1),
      ]),
      failure(WorkspaceFailureCode.validation),
    );
    final required = [...fields, field('new', 'text', required: true)];
    await expectLater(
      run('missing-backfill', [
        mutation(tableKind, 'table', {
          'fields': required,
          'schema_version': 2,
        }, version: 1),
      ]),
      failure(WorkspaceFailureCode.validation),
    );
    await run('backfill', [
      mutation(tableKind, 'table', {
        'fields': required,
        'schema_version': 2,
      }, version: 1),
      mutation(rowKind, 'row', {
        'values': {'title': '客户甲', 'amount': '0.10', 'new': '明确补值'},
      }, version: 1),
    ]);
    await store.undo('backfill', operationId: 'undo-backfill');
    expect((await store.load()).dataRows.single.data['values'], {
      'title': '客户甲',
      'amount': '0.10',
    });
  });

  test('column deletion cannot silently discard cells, retired IDs cannot be reused', () async {
    await seed();
    final fewer = fields.where((f) => f['id'] != 'amount').toList();
    await expectLater(
      run('drop-alone', [
        mutation(tableKind, 'table', {
          'fields': fewer,
          'schema_version': 2,
        }, version: 1),
      ]),
      failure(WorkspaceFailureCode.validation),
    );
    await run('drop-explicitly', [
      mutation(tableKind, 'table', {
        'fields': fewer,
        'schema_version': 2,
      }, version: 1),
      mutation(rowKind, 'row', {
        'values': {'title': '客户甲'},
      }, version: 1),
    ]);
    await expectLater(
      run('reuse', [
        mutation(tableKind, 'table', {
          'fields': fields,
          'schema_version': 3,
        }, version: 2),
      ]),
      failure(WorkspaceFailureCode.validation),
    );
    await expectLater(
      run('forge-retired', [
        mutation(tableKind, 'table', {
          'retired_field_ids': <String>[],
        }, version: 2),
      ]),
      failure(WorkspaceFailureCode.validation),
    );
    await store.undo('drop-explicitly', operationId: 'undo-drop');
    expect((await store.load()).dataRows.single.data['values'], {
      'title': '客户甲',
      'amount': '0.10',
    });
  });

  test(
    'row/type ownership, deletion and undo enforce final references',
    () async {
      await run('seed', [
        table(type: 'type'),
        mutation(typeKind, 'type', {'name': '财务'}),
        row('row'),
      ]);
      for (final pair in [(typeKind, 'type'), (tableKind, 'table')]) {
        await expectLater(
          run('orphan_${pair.$2}', [
            mutation(pair.$1, pair.$2, {}, version: 1, delete: true),
          ]),
          failure(WorkspaceFailureCode.validation),
        );
      }
      await expectLater(
        run('move', [
          table(id: 'other'),
          mutation(rowKind, 'row', {'table_id': 'other'}, version: 1),
        ]),
        failure(WorkspaceFailureCode.validation),
      );
      await run('delete-all', [
        mutation(typeKind, 'type', {}, version: 1, delete: true),
        mutation(tableKind, 'table', {}, version: 1, delete: true),
        mutation(rowKind, 'row', {}, version: 1, delete: true),
      ]);
      expect((await store.load()).dataRows, isEmpty);
      await reopen();
      await store.undo('delete-all', operationId: 'undo-delete');
      expect((await store.load()).dataRows.single.version, 3);
      expect((await store.load()).dataTables.single.version, 3);
    },
  );

  test('concurrent connections allow one CAS edit; stale undo and changed replay are rejected', () async {
    await seed();
    final secondDb = AppDatabase.background(file);
    final second = SqliteWorkspaceCommandStore(secondDb);
    try {
      WorkspaceCommand edit(String op) => WorkspaceCommand(
        operationId: op,
        actions: [
          mutation(rowKind, 'row', {
            'values': {'title': op},
          }, version: 1),
        ],
      );
      final results = await Future.wait(
        [store, second].indexed.map((pair) async {
          try {
            return await pair.$2.execute(edit('edit_${pair.$1}'));
          } on WorkspaceFailure catch (e) {
            return e;
          }
        }),
      );
      expect(results.whereType<WorkspaceReceipt>(), hasLength(1));
      expect(
        results.whereType<WorkspaceFailure>().single.code,
        WorkspaceFailureCode.versionConflict,
      );
      await expectLater(
        store.undo('seed', operationId: 'stale-undo'),
        failure(WorkspaceFailureCode.versionConflict),
      );
      final won = results.whereType<WorkspaceReceipt>().single;
      await expectLater(
        run(won.operationId, [
          mutation(rowKind, 'row', {
            'values': {'title': 'different'},
          }, version: 1),
        ]),
        failure(WorkspaceFailureCode.idempotencyMismatch),
      );
      await store.undo(won.operationId, operationId: 'undo-edit');
      expect((await store.load()).dataRows.single.data['values'], {
        'title': '客户甲',
        'amount': '0.10',
      });
    } finally {
      await secondDb.close();
    }
  });

  test('mixed commit failures never publish data or receipt; watch sees committed rows', () async {
    await store.load();
    for (final point in WorkspaceCommitCheckpoint.values) {
      store = SqliteWorkspaceCommandStore(
        db,
        checkpoint: (at) {
          if (at == point) throw StateError('fault');
        },
      );
      await expectLater(
        seed(),
        failure(WorkspaceFailureCode.storageUnavailable),
      );
      expect((await store.load()).entities, isEmpty);
      expect(await db.select(db.workspaceOperations).get(), isEmpty);
    }
    store = SqliteWorkspaceCommandStore(db);
    final observed = store.watch().firstWhere(
      (snapshot) => snapshot.dataRows.isNotEmpty,
    );
    await seed();
    expect((await observed).dataTables.single.id, 'table');
    await reopen();
    expect((await store.load()).dataRows.single.id, 'row');
  });

  test('v8 migrates without losing jobs/history/profile; foreign table rolls entire migration back', () async {
    await db.close();
    var raw = sqlite.sqlite3.open(file.path);
    raw.execute(File('test/fixtures/local/schema_v8.sql').readAsStringSync());
    raw.execute(
      "INSERT INTO local_profiles VALUES(1,'v8-user','本地资料',2,1700000000)",
    );
    raw.execute(
      "INSERT INTO local_job_rows VALUES('job','unique','fixture','{}','digest',"
      "'scheduled',1,1,0,5,0,NULL,NULL,NULL,NULL,NULL)",
    );
    raw.execute(
      "INSERT INTO chat_conversations VALUES('chat','原对话',1,1,1,NULL)",
    );
    raw.execute('CREATE TABLE work_data_rows (alien TEXT)');
    raw.close();
    db = AppDatabase.background(file);
    await expectLater(
      db.customSelect('SELECT * FROM work_data_tables').get(),
      throwsA(anything),
    );
    await db.close();
    raw = sqlite.sqlite3.open(file.path);
    expect(raw.select('PRAGMA user_version').single['user_version'], 8);
    expect(
      raw.select(
        "SELECT name FROM sqlite_master WHERE name='work_data_tables'",
      ),
      isEmpty,
    );
    expect(raw.select('SELECT * FROM local_job_rows'), hasLength(1));
    raw.execute('DROP TABLE work_data_rows');
    raw.close();
    db = AppDatabase.background(file);
    store = SqliteWorkspaceCommandStore(db);
    await seed();
    expect((await db.loadOrCreateProfile()).nickname, '本地资料');
    expect((await db.select(db.localJobRows).get()).single.id, 'job');
    expect((await db.select(db.chatConversations).get()).single.title, '原对话');
    expect(
      (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
        'user_version',
      ),
      13,
    );
    expect(
      (await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='index' AND name LIKE 'work_data_%'",
          )
          .get()),
      hasLength(2),
    );
  });
}
