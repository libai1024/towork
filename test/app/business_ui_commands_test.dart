import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/business_ui_commands.dart';
import 'package:towork/app/local_business_projection.dart';
import 'package:towork/app/local_workspace_session.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/business_model_codec.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/models/data_table.dart';
import 'package:towork/domain/repositories/repository_error.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';
import 'package:towork/features/data_tables/widgets/formatters.dart';

void main() {
  late Directory dir;
  late AppDatabase db;
  late LocalWorkspaceSession session;
  late LocalBusinessProjection projection;
  late BusinessUiCommands commands;
  final columns = [
    DataColumnDef(name: '名称', type: 'text', isRequired: true),
    DataColumnDef(name: '金额', type: 'money'),
    DataColumnDef(name: '已付款', type: 'bool'),
    DataColumnDef(name: '时间', type: 'datetime'),
  ];
  Future<void> attach() async {
    db = AppDatabase.background(File('${dir.path}/db.sqlite'));
    final store = SqliteWorkspaceCommandStore(db);
    session = LocalWorkspaceSession(store, await store.load());
    projection = LocalBusinessProjection(session, db);
    commands = BusinessUiCommands(projection, session: session);
  }

  Future<void> close() async {
    projection.dispose();
    await session.dispose();
    session.todos.dispose();
    session.categories.dispose();
    await db.close();
  }

  Future<void> until(bool Function() predicate) async {
    final watch = Stopwatch()..start();
    while (!predicate() && watch.elapsed < const Duration(seconds: 5)) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(predicate(), isTrue);
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('towork-business-ui-');
    await attach();
  });
  tearDown(() async {
    await close();
    await dir.delete(recursive: true);
  });

  test(
    'empty production has no demo data and sync mutations fail closed',
    () async {
      expect(projection.snapshot.tables, isEmpty);
      expect(projection.snapshot.rows, isEmpty);
      expect(
        () => projection.createType('illegal'),
        throwsA(isA<RepositoryException>()),
      );
      expect((await session.store.load()).tableTypes, isEmpty);
      await until(() => !projection.snapshot.historyLoading);
      expect(projection.snapshot.historyError, isFalse);
    },
  );

  test('manual template, type, exact cell editing, history and restart preserve committed data', () async {
    final type = await commands.createType('财务');
    final table = await commands.createTable(
      name: '费用',
      columns: columns,
      typeId: type.id,
      seedRows: [
        {
          '名称': '交通',
          '金额': '12345678901234567890.1',
          '已付款': 'false',
          '时间': '2026-09-24T01:02:03.123456Z',
        },
      ],
    );
    await until(
      () =>
          projection.snapshot.rows.length == 1 &&
          projection.snapshot.logs.length == 1,
    );
    final row = projection.rowsOf(table.id).single;
    expect(
      formatCellValue(table.columns[1], row.values['金额']),
      '¥12,345,678,901,234,567,890.10',
    );
    expect(table.columns.map((f) => f.id).toSet(), hasLength(4));
    await commands.updateCell(table, row, '名称', '交通和住宿');
    await until(
      () =>
          projection.snapshot.logs.length == 2 &&
          projection.snapshot.rows.single.version == 2,
    );
    expect(
      projection.rowsOf(table.id).single.values['时间'],
      '2026-09-24T01:02:03.123456Z',
    );
    final copy = await commands.createTable(
      name: '费用副本',
      columns: table.columns,
      typeId: type.id,
    );
    expect(
      copy.columns
          .map((f) => f.id)
          .toSet()
          .intersection(table.columns.map((f) => f.id).toSet()),
      isEmpty,
    );
    final changed = projection.rowsOf(table.id).single;
    final first = projection.logsOfRow(row.id).last;
    await commands.restoreRow(changed, first);
    await until(() => projection.snapshot.logs.length == 3);
    await close();
    await attach();
    await until(() => !projection.snapshot.historyLoading);
    expect(projection.rowsOf(table.id).single.values['名称'], '交通');
    expect(projection.logsOfRow(row.id), hasLength(3));
    expect(projection.snapshot.types.single.name, '财务');
  });

  test('stale editors and undo cannot overwrite newer rows; invalid writes keep projection', () async {
    final table = await commands.createTable(name: '费用', columns: columns);
    final row = await commands.addRow(table, {'名称': '旧值', '金额': '0.10'});
    await commands.updateCell(table, row, '名称', '新值');
    await expectLater(
      commands.updateCell(table, row, '名称', '迟到'),
      throwsA(isA<WorkspaceFailure>()),
    );
    await until(() => projection.snapshot.rows.single.version == 2);
    final current = projection.snapshot.rows.single;
    await expectLater(
      commands.updateCell(table, current, '金额', '1.001'),
      throwsA(isA<WorkspaceFailure>()),
    );
    expect((await session.store.load()).dataRows.single.version, 2);
    final deleted = await commands.deleteRow(current);
    await deleted.undo();
    await until(
      () =>
          projection.snapshot.rows.length == 1 &&
          projection.snapshot.rows.single.version == 4,
    );
    expect(projection.snapshot.rows.single.values['名称'], '新值');
    await deleted.undo(); // one undo object cannot execute twice
    expect((await session.store.load()).dataRows.single.version, 4);
  });

  test('history restoration uses field identity across rename, clearing preserves deleted-value diff', () async {
    final table = await commands.createTable(name: '费用', columns: columns);
    final row = await commands.addRow(table, {'名称': '交通', '金额': '8.10'});
    await until(() => projection.snapshot.logs.length == 1);
    final original = projection.snapshot.logs.single;
    await commands.updateCell(table, row, '金额', '');
    final rawTable = session.snapshot.dataTables.single;
    await session.execute(
      WorkspaceCommand(
        operationId: 'rename-field',
        actions: [
          WorkspaceMutation(
            actionId: 'a',
            entityId: table.id,
            kind: WorkspaceEntityKind.dataTable,
            mutation: WorkspaceMutationKind.update,
            expectedVersion: 1,
            patch: {
              'schema_version': 2,
              'fields': [
                for (final f in rawTable.data['fields']! as List)
                  if ((f as Map)['id'] == table.columns[1].id)
                    {...f.cast<String, Object?>(), 'name': '含税金额'}
                  else
                    f,
              ],
            },
          ),
        ],
      ),
    );
    await until(
      () =>
          projection.tableById(table.id)!.version == 2 &&
          projection.snapshot.rows.single.version == 2,
    );
    await commands.restoreRow(projection.snapshot.rows.single, original);
    await until(
      () =>
          projection.snapshot.logs.length == 3 &&
          projection.snapshot.rows.single.version == 3,
    );
    expect(projection.snapshot.rows.single.values['含税金额'], '8.10');
    expect(projection.snapshot.logs[1].beforeValues!['金额'], '8.10');
    expect(projection.snapshot.logs[1].afterValues!.containsKey('金额'), isFalse);
  });

  test('archive and grouping are durable, stale table metadata cannot replace the latest', () async {
    final a = await commands.createType('A'),
        b = await commands.createType('B');
    final table = await commands.createTable(
      name: '表',
      columns: columns,
      typeId: a.id,
    );
    await commands.assignType(table, b.id);
    await expectLater(
      commands.renameTable(table, '迟到'),
      throwsA(isA<WorkspaceFailure>()),
    );
    await until(() => projection.tableById(table.id)!.version == 2);
    await commands.archiveTable(projection.tableById(table.id)!);
    await close();
    await attach();
    expect(projection.tableById(table.id)!.archived, isTrue);
    expect(projection.tableById(table.id)!.typeId, b.id);
  });

  test('datetime conversion rejects calendar normalization and offsets outside the contract', () {
    final table = DataTableDef(
      id: 'table',
      name: '表',
      createdAt: DateTime.now(),
      columns: [DataColumnDef(id: 'field', name: '时间', type: 'datetime')],
    );
    for (final value in [
      '2026-02-30 12:00',
      '2026-02-30T12:00:00Z',
      '2026-09-24T12:00:00+15:00',
      '2026-09-24T12:60',
      '0000-01-01T00:00:00Z',
    ]) {
      expect(
        () => businessInputValues(table, {'时间': value}),
        throwsA(isA<WorkspaceFailure>()),
      );
    }
    expect(businessInputValues(table, {'时间': '2026-09-24T12:00:00+08:00'}), {
      'field': '2026-09-24T04:00:00.000Z',
    });
  });

  test('field rename keeps identity and values; stale handles conflict; undo restores', () async {
    final table = await commands.createTable(
      name: '字段表',
      columns: columns,
      seedRows: [
        {'名称': 'A', '金额': '12.30', '已付款': 'true'},
        {'名称': 'B'},
      ],
    );
    await until(() => projection.rowsOf(table.id).length == 2);
    final nameKey = table.columns.firstWhere((f) => f.name == '名称').id!;
    final change = await commands.renameField(table, nameKey, '项目');
    await until(
      () => projection.tableById(table.id)!.columns.first.name == '项目',
    );
    final renamed = projection.tableById(table.id)!;
    expect(renamed.schemaVersion, 2);
    expect(renamed.columns.first.id, nameKey);
    final rowA = projection
        .rowsOf(table.id)
        .firstWhere((r) => r.values['项目'] == 'A');
    expect(rowA.values['金额'], '12.30');
    // The pre-rename handle is stale and must not double-write.
    await expectLater(
      commands.renameField(table, nameKey, '别的'),
      throwsA(isA<WorkspaceFailure>()),
    );
    await change.undo();
    await until(
      () => projection.tableById(table.id)!.columns.first.name == '名称',
    );
    final undone = projection.tableById(table.id)!;
    expect(undone.schemaVersion, 1);
    expect(undone.columns.first.id, nameKey);
    expect(
      projection.rowsOf(table.id).firstWhere((r) => r.values['名称'] == 'A'),
      isNotNull,
    );
  });

  test('required field addition backfills all rows atomically; missing backfill writes nothing', () async {
    final table = await commands.createTable(
      name: '补值表',
      columns: columns,
      seedRows: [
        {'名称': 'A'},
        {'名称': 'B'},
      ],
    );
    await until(() => projection.rowsOf(table.id).length == 2);
    final status = DataColumnDef(
      name: '状态',
      type: 'enum',
      enumOptions: ['新', '旧'],
      isRequired: true,
    );
    await expectLater(
      commands.addField(projection.tableById(table.id)!, status),
      throwsA(isA<WorkspaceFailure>()),
    );
    expect(projection.tableById(table.id)!.columns, hasLength(4));
    await commands.addField(
      projection.tableById(table.id)!,
      status,
      backfillValue: '新',
    );
    await until(
      () => projection.tableById(table.id)!.columns.any((f) => f.name == '状态'),
    );
    expect(projection.tableById(table.id)!.schemaVersion, 2);
    for (final row in projection.rowsOf(table.id)) {
      expect(row.values['状态'], '新');
    }
    // Invalid backfill for the field type must fail without any partial write.
    await expectLater(
      commands.addField(
        projection.tableById(table.id)!,
        DataColumnDef(name: '计数', type: 'number'),
        backfillValue: 'abc',
      ),
      throwsA(isA<WorkspaceFailure>()),
    );
    expect(
      projection.tableById(table.id)!.columns.where((f) => f.name == '计数'),
      isEmpty,
    );
  });

  test(
    'field removal clears cells in one change; undo restores field and values',
    () async {
      final table = await commands.createTable(
        name: '删字段表',
        columns: columns,
        seedRows: [
          {'名称': 'A', '金额': '12.30'},
          {'名称': 'B', '金额': '1.00'},
        ],
      );
      await until(() => projection.rowsOf(table.id).length == 2);
      final current = projection.tableById(table.id)!;
      final moneyKey = current.columns.firstWhere((f) => f.name == '金额').id!;
      expect(commands.fieldUsageCount(current, moneyKey), 2);
      final change = await commands.removeField(current, moneyKey);
      await until(
        () =>
            !projection.tableById(table.id)!.columns.any((f) => f.name == '金额'),
      );
      final removed = projection.tableById(table.id)!;
      expect(removed.schemaVersion, 2);
      for (final row in projection.rowsOf(table.id)) {
        expect(row.values.containsKey('金额'), isFalse);
        expect(row.values['名称'], isNotNull);
      }
      await change.undo();
      await until(
        () =>
            projection.tableById(table.id)!.columns.any((f) => f.name == '金额'),
      );
      final restored = projection.tableById(table.id)!;
      expect(restored.schemaVersion, 1);
      expect(
        projection
            .rowsOf(table.id)
            .firstWhere((r) => r.values['名称'] == 'A')
            .values['金额'],
        '12.30',
      );
    },
  );

  test('table deletion removes rows atomically; stale handles fail; undo restores values', () async {
    final table = await commands.createTable(
      name: '删除表',
      columns: columns,
      seedRows: [
        {'名称': 'A', '金额': '9.90'},
        {'名称': 'B'},
      ],
    );
    await until(() => projection.rowsOf(table.id).length == 2);
    final change = await commands.deleteTable(projection.tableById(table.id)!);
    await until(() => projection.tableById(table.id) == null);
    expect(projection.rowsOf(table.id), isEmpty);
    // The pre-delete handle is stale and cannot issue a second delete.
    await expectLater(
      commands.deleteTable(table),
      throwsA(isA<WorkspaceFailure>()),
    );
    await change.undo();
    await until(() => projection.tableById(table.id) != null);
    final restored = projection.tableById(table.id)!;
    expect(restored.schemaVersion, 1);
    expect(
      projection
          .rowsOf(table.id)
          .firstWhere((r) => r.values['名称'] == 'A')
          .values['金额'],
      '9.90',
    );
  });
}
