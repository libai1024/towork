import 'package:flutter_test/flutter_test.dart';
import 'package:towork/data/repositories/data_table_repository.dart';
import 'package:towork/data/seeds/data_table_seed.dart';
import 'package:towork/domain/models/models.dart';
import 'package:towork/domain/repositories/data_table_store.dart';

final _now = DateTime(2026, 9, 23, 12, 30);
final _invalid = isA<RepositoryException>().having(
  (error) => error.code,
  'code',
  RepositoryErrorCode.invalidInput,
);

List<DataColumnDef> _columns() => [
  DataColumnDef(name: '标题', type: 'text', isRequired: true),
  DataColumnDef(name: '数量', type: 'number'),
  DataColumnDef(name: '金额', type: 'money'),
  DataColumnDef(name: '旧金额', type: 'currency'),
  DataColumnDef(name: '日期', type: 'date'),
  DataColumnDef(name: '时间', type: 'datetime'),
  DataColumnDef(name: '阶段', type: 'enum', enumOptions: ['草稿', '完成']),
  DataColumnDef(name: '确认', type: 'bool'),
];

DataTableRepository _repository() => DataTableRepository(
  clock: () => _now,
  initial: DataTableBundle(
    tables: [
      DataTableDef(
        id: 'table',
        name: '校验',
        columns: _columns(),
        createdAt: _now,
      ),
    ],
    rows: [],
    logs: [],
  ),
);

void main() {
  test(
    'editor storage formats and currency alias survive writes unchanged',
    () {
      final repo = _repository();
      addTearDown(repo.dispose);
      final values = {
        '标题': '合法值',
        '数量': '-12.5',
        '金额': '0.01',
        '旧金额': '1e3',
        '日期': '2024-02-29',
        '时间': '2026-09-23 12:30',
        '阶段': '草稿',
        '确认': 'false',
      };
      final row = repo.addRow('table', values);
      expect(row.values, values);
      repo.updateRowMulti(row.id, {'数量': '2', '确认': 'true'});
      expect(repo.rowsOf('table').single.values['标题'], '合法值');
      expect(repo.rowsOf('table').single.values['确认'], 'true');
      for (final value in [
        '2024-02-29T23:59:59.123456Z',
        '2026-09-23T12:30+08:00',
        '2026-09-23 12:30:01-05:30',
      ]) {
        repo.updateCell(row.id, '时间', value);
        expect(repo.rowsOf('table').single.values['时间'], value);
      }
      repo.updateRowMulti(row.id, {
        for (final field in values.keys.where((key) => key != '标题')) field: '',
      });
      expect(repo.rowsOf('table').single.values['标题'], '合法值');
      expect(repo.rowsOf('table').single.values['日期'], '');
    },
  );

  test('missing and blank required cells cannot be added or cleared', () {
    final repo = _repository();
    addTearDown(repo.dispose);
    for (final values in [
      <String, String>{},
      {'标题': ''},
      {'标题': ' \n '},
    ]) {
      expect(() => repo.addRow('table', values), throwsA(_invalid));
    }
    final row = repo.addRow('table', {'标题': '保留', '数量': '1'});
    final before = repo.snapshot;
    expect(() => repo.updateCell(row.id, '标题', ''), throwsA(_invalid));
    expect(
      () => repo.updateRowMulti(row.id, {'数量': '2', '标题': '  '}),
      throwsA(_invalid),
    );
    expect(repo.snapshot, same(before));
  });

  final invalidValues = <String, List<String>>{
    '数量': ['NaN', 'Infinity', '-Infinity', '1e999', '12股', '1,000', ' '],
    '金额': ['NaN', 'Infinity', '¥12', '1,000.00'],
    '旧金额': ['Infinity'],
    '日期': ['2026-02-29', '2024-02-30', '2026-13-01', '2026-04-31', '2026-9-1'],
    '时间': [
      '2026-02-29 12:30',
      '2026-09-23 24:00',
      '2026-09-23 12:60',
      '2026-09-23T12:30:60Z',
      '2026-09-23T12:30+14:30',
      '2026-09-23T12:30+08:60',
      '2026-09-23',
    ],
    '阶段': ['未知', ' 草稿'],
    '确认': ['是', '1', 'TRUE', 'false '],
  };
  for (final entry in invalidValues.entries) {
    test('${entry.key} rejects invalid external values without any write', () {
      final repo = _repository();
      addTearDown(repo.dispose);
      final row = repo.addRow('table', {'标题': '保留'});
      final before = repo.snapshot;
      var notifications = 0;
      final unsubscribe = repo.addListener(
        (_) => notifications++,
        fireImmediately: false,
      );
      addTearDown(unsubscribe);
      for (final value in entry.value) {
        expect(
          () => repo.addRow('table', {'标题': '无效', entry.key: value}),
          throwsA(_invalid),
          reason: value,
        );
        expect(
          () => repo.updateCell(row.id, entry.key, value),
          throwsA(_invalid),
          reason: value,
        );
        expect(repo.snapshot, same(before));
      }
      expect(notifications, 0);
    });
  }

  test('unknown field IDs and invalid schemas are rejected unchanged', () {
    final repo = _repository();
    addTearDown(repo.dispose);
    final row = repo.addRow('table', {'标题': '保留'});
    final before = repo.snapshot;
    expect(
      () => repo.updateRowMulti(row.id, {'数量': '1', '不存在': 'x'}),
      throwsA(_invalid),
    );
    for (final columns in [
      <DataColumnDef>[],
      [DataColumnDef(name: '', type: 'text')],
      [DataColumnDef(name: ' 标题', type: 'text')],
      [
        DataColumnDef(name: '标题', type: 'text'),
        DataColumnDef(name: '标题', type: 'number'),
      ],
      [DataColumnDef(name: '阶段', type: 'enum')],
      [
        DataColumnDef(name: '阶段', type: 'enum', enumOptions: ['草稿', '草稿']),
      ],
      [
        DataColumnDef(name: '阶段', type: 'enum', enumOptions: [' ']),
      ],
    ]) {
      expect(
        () => repo.createTable(name: '无效表', columns: columns),
        throwsA(_invalid),
      );
      expect(repo.snapshot, same(before));
    }
  });

  test('invalid seed and raw restore cannot bypass row validation', () {
    final repo = _repository();
    addTearDown(repo.dispose);
    final before = repo.snapshot;
    expect(
      () => repo.createTable(
        name: '无效种子',
        columns: _columns(),
        seedRows: [
          {'标题': '第一行', '数量': '1'},
          {'标题': '第二行', '数量': 'NaN'},
        ],
      ),
      throwsA(_invalid),
    );
    final invalidRow = DataRow(
      id: 'invalid',
      tableId: 'table',
      values: {'标题': '无效日期', '日期': '2026-02-30'},
      updatedAt: _now,
    );
    expect(() => repo.insertRowRaw(invalidRow), throwsA(_invalid));
    expect(
      () => DataTableRepository(initial: before.copyWith(rows: [invalidRow])),
      throwsA(_invalid),
    );
    expect(repo.snapshot, same(before));
  });

  for (final createInvalid in [true, false]) {
    test(
      'AI batch rejects a later invalid ${createInvalid ? 'creation' : 'update'} atomically',
      () {
        final repo = _repository();
        addTearDown(repo.dispose);
        final row = repo.addRow('table', {'标题': '保留', '数量': '1'});
        final batch = repo.pushPendingBatch(
          tableId: 'table',
          reason: '测试',
          sourceLabel: '测试',
          changes: [
            PendingRowChange(
              id: 'valid',
              action: DataChangeAction.update,
              rowId: row.id,
              rowLabel: '保留',
              fields: [
                const PendingFieldChange(
                  field: '数量',
                  oldValue: '1',
                  newValue: '2',
                ),
              ],
            ),
            if (createInvalid)
              PendingRowChange(
                id: 'invalid',
                action: DataChangeAction.create,
                rowLabel: '无效',
                createValues: {'数量': '3'},
              )
            else
              PendingRowChange(
                id: 'invalid',
                action: DataChangeAction.update,
                rowId: row.id,
                rowLabel: '保留',
                fields: [
                  const PendingFieldChange(
                    field: '日期',
                    oldValue: '',
                    newValue: '2026-02-30',
                  ),
                ],
              ),
          ],
        );
        final before = repo.snapshot;
        var notifications = 0;
        final unsubscribe = repo.addListener(
          (_) => notifications++,
          fireImmediately: false,
        );
        addTearDown(unsubscribe);
        expect(
          () => repo.applyPendingBatch(batch.id, {'valid', 'invalid'}),
          throwsA(_invalid),
        );
        expect(repo.snapshot, same(before));
        expect(notifications, 0);
        repo.applyPendingBatch(batch.id, {'valid'});
        expect(repo.rowsOf('table').single.values['数量'], '2');
        expect(repo.batchesOf('table').single.changes.single.id, 'invalid');
        expect(notifications, 1);
      },
    );
  }

  test('bundled rows and template schemas satisfy the same boundary', () {
    final repo = DataTableRepository(clock: () => _now);
    addTearDown(repo.dispose);
    for (final template in dataTableTemplates) {
      repo.createTable(
        name: template.name,
        columns: template.columns,
        seedRows: template.seedRows,
      );
    }
    expect(repo.snapshot.tables, hasLength(3 + dataTableTemplates.length));
  });

  test(
    'stale editors and dismissed batches report a controlled missing target',
    () {
      final repo = _repository();
      addTearDown(repo.dispose);
      final missing = isA<RepositoryException>().having(
        (error) => error.code,
        'code',
        RepositoryErrorCode.notFound,
      );
      final before = repo.snapshot;
      expect(() => repo.updateCell('missing', '标题', '内容'), throwsA(missing));
      expect(
        () => repo.updateRowMulti('missing', {'标题': '内容'}),
        throwsA(missing),
      );
      expect(() => repo.renameTable('missing', '新名称'), throwsA(missing));
      expect(() => repo.archiveTable('missing'), throwsA(missing));
      expect(
        () => repo.applyPendingBatch('missing', {'change'}),
        throwsA(missing),
      );
      expect(repo.snapshot, same(before));
    },
  );

  test(
    'corrected deletion fixture and generated schema examples can apply',
    () {
      final repo = DataTableRepository(clock: () => _now);
      addTearDown(repo.dispose);
      final stock = repo.batchesOf('dt_stock').single;
      repo.applyPendingBatch(
        stock.id,
        stock.changes.map((change) => change.id).toSet(),
      );
      expect(repo.rowsOf('dt_stock').any((row) => row.id == 'dr3'), isFalse);
      for (final tableId in ['dt_archive', 'dt_fitness']) {
        final count = repo.rowsOf(tableId).length;
        final batch = repo.simulateAiPush(tableId)!;
        repo.applyPendingBatch(
          batch.id,
          batch.changes.map((change) => change.id).toSet(),
        );
        expect(repo.rowsOf(tableId), hasLength(count + 1));
      }
      final custom = repo.createTable(name: '自定义', columns: _columns());
      final batch = repo.simulateAiPush(custom.id)!;
      repo.applyPendingBatch(
        batch.id,
        batch.changes.map((change) => change.id).toSet(),
      );
      expect(repo.rowsOf(custom.id).single.values['时间'], '2026-09-23 12:30');
      expect(repo.rowsOf(custom.id).single.values['阶段'], '草稿');
    },
  );
}
