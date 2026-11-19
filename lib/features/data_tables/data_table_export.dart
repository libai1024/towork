import 'dart:io';

import '../../domain/models/data_table.dart';

/// Writes a UTF-8 BOM CSV that opens correctly in common spreadsheet tools.
/// The export is intentionally one-way: it contains table rows, not credentials
/// or a restore manifest.
Future<File> exportDataTableCsv({
  required DataTableDef table,
  required Iterable<DataRow> rows,
  required Directory directory,
  DateTime Function()? clock,
}) async {
  await directory.create(recursive: true);
  final stamp = (clock ?? DateTime.now)().millisecondsSinceEpoch;
  final fileName = '${_safeFilePart(table.name)}_$stamp.csv';
  final file = File('${directory.path}/$fileName');
  final buffer = StringBuffer()
    ..writeln(
      [for (final column in table.columns) _cell(column.name)].join(','),
    );
  for (final row in rows) {
    buffer.writeln(
      [for (final column in table.columns) _cell(row.values[column.name])]
          .join(','),
    );
  }
  await file.writeAsString('\uFEFF${buffer.toString()}', flush: true);
  return file;
}

String _cell(String? value) {
  final text = value ?? '';
  if (!text.contains(RegExp(r'[,"\n\r]'))) return text;
  return '"${text.replaceAll('"', '""')}"';
}

String _safeFilePart(String value) {
  final safe = value
      .replaceAll(RegExp(r'[\\/:*?"<>|\u0000-\u001F]'), '_')
      .trim();
  return safe.isEmpty ? 'data_table' : safe;
}
