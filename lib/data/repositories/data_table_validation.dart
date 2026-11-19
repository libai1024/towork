import '../../domain/models/models.dart';
import '../../domain/repositories/repository_error.dart';

/// Column names are the field identifiers in the current table model. Never
/// silently trim identifiers: that would detach existing cells from the schema.
void validateDataTableColumns(List<DataColumnDef> columns) {
  if (columns.isEmpty) _invalid('至少添加一个字段');
  final names = <String>{};
  for (final column in columns) {
    if (column.name.trim().isEmpty || column.name != column.name.trim()) {
      _invalid('字段名不能为空或包含首尾空白');
    }
    if (!names.add(column.name)) _invalid('字段名不能重复');
    if (column.fieldType == DataFieldType.selection) {
      final options = <String>{};
      if (column.enumOptions.isEmpty) {
        _invalid('「${column.name}」至少需要一个选项');
      }
      for (final option in column.enumOptions) {
        if (option.trim().isEmpty || option != option.trim()) {
          _invalid('「${column.name}」的选项不能为空或包含首尾空白');
        }
        if (!options.add(option)) _invalid('「${column.name}」的选项不能重复');
      }
    }
  }
}

/// Validate storage values without formatting or changing their contents.
///
/// Row writes validate the complete resulting row; [partial] is only for AI
/// field diffs whose unchanged required fields are absent from the proposal.
/// An optional cell can be cleared with an empty string. Numeric values use
/// the editor's finite double format; dates use yyyy-MM-dd and date-times use
/// yyyy-MM-dd HH:mm, with ISO time/seconds/offset variants also accepted.
void validateDataRowValues(
  DataTableDef table,
  Map<String, String> values, {
  bool partial = false,
}) {
  final columns = {for (final column in table.columns) column.name: column};
  for (final field in values.keys) {
    if (!columns.containsKey(field)) _invalid('数据包含未定义的字段「$field」');
  }
  for (final column in table.columns) {
    if (partial && !values.containsKey(column.name)) continue;
    final value = values[column.name] ?? '';
    if (column.isRequired && value.trim().isEmpty) {
      _invalid('「${column.name}」不能为空');
    }
    if (value.isEmpty) continue;
    final valid = switch (column.fieldType) {
      DataFieldType.text => true,
      DataFieldType.number ||
      DataFieldType.money => double.tryParse(value)?.isFinite ?? false,
      DataFieldType.date => _validDate(value),
      DataFieldType.datetime => _validDateTime(value),
      DataFieldType.selection => column.enumOptions.contains(value),
      DataFieldType.boolean => value == 'true' || value == 'false',
    };
    if (!valid) {
      final requirement = switch (column.fieldType) {
        DataFieldType.text => '文本',
        DataFieldType.number || DataFieldType.money => '有限数字',
        DataFieldType.date => '有效日期（yyyy-MM-dd）',
        DataFieldType.datetime => '有效日期时间（yyyy-MM-dd HH:mm）',
        DataFieldType.selection => '已有选项',
        DataFieldType.boolean => 'true 或 false',
      };
      _invalid('「${column.name}」必须是$requirement');
    }
  }
}

final _datePattern = RegExp(r'^([0-9]{4})-([0-9]{2})-([0-9]{2})$');
final _dateTimePattern = RegExp(
  r'^([0-9]{4}-[0-9]{2}-[0-9]{2})[ T]([0-9]{2}):([0-9]{2})'
  r'(?::([0-9]{2})(?:\.([0-9]{1,6}))?)?'
  r'(?:[zZ]|([+-])([0-9]{2}):([0-9]{2}))?$',
);

bool _validDate(String value) {
  final match = _datePattern.firstMatch(value);
  if (match == null || match.end != value.length) return false;
  final year = int.parse(match[1]!);
  final month = int.parse(match[2]!);
  final day = int.parse(match[3]!);
  if (year == 0 || month < 1 || month > 12 || day < 1 || day > 31) {
    return false;
  }
  // DateTime.tryParse normalizes invalid calendar dates such as February 30.
  final date = DateTime.utc(year, month, day);
  return date.year == year && date.month == month && date.day == day;
}

bool _validDateTime(String value) {
  final match = _dateTimePattern.firstMatch(value);
  if (match == null || match.end != value.length || !_validDate(match[1]!)) {
    return false;
  }
  if (int.parse(match[2]!) > 23 ||
      int.parse(match[3]!) > 59 ||
      int.parse(match[4] ?? '0') > 59) {
    return false;
  }
  if (match[6] != null) {
    final hours = int.parse(match[7]!);
    final minutes = int.parse(match[8]!);
    if (hours > 14 || minutes > 59 || (hours == 14 && minutes != 0)) {
      return false;
    }
  }
  return true;
}

Never _invalid(String message) =>
    throw RepositoryException(RepositoryErrorCode.invalidInput, message);
