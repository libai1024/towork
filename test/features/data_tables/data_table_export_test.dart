import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/domain/models/data_table.dart';
import 'package:towork/features/data_tables/data_table_export.dart';

void main() {
  test('CSV export escapes values and sanitizes filenames', () async {
    final directory = Directory.systemTemp.createTempSync('towork_csv');
    addTearDown(() => directory.deleteSync(recursive: true));
    final table = DataTableDef(
      id: 'table',
      name: '持仓/明细',
      columns: [
        DataColumnDef(name: '名称', type: 'text'),
        DataColumnDef(name: '备注', type: 'text'),
      ],
      createdAt: DateTime(2026, 10, 1),
    );
    final file = await exportDataTableCsv(
      table: table,
      rows: [
        DataRow(
          id: 'row',
          tableId: 'table',
          values: {'名称': '基金', '备注': '含,逗号和"引号"\n换行'},
          updatedAt: DateTime(2026, 10, 1),
        ),
      ],
      directory: directory,
      clock: () => DateTime.fromMillisecondsSinceEpoch(1234),
    );
    expect(file.path, endsWith('持仓_明细_1234.csv'));
    final bytes = await file.readAsBytes();
    expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
    final text = await file.readAsString();
    expect(text, contains('"含,逗号和""引号""\n换行"'));
  });
}
