import '../../domain/models/data_table.dart';
import '../../domain/repositories/data_table_bundle.dart';
import '../../domain/workspace/workspace_commands.dart';

DataTableDef businessTable(WorkspaceEntity e) => DataTableDef(
  id: e.id,
  version: e.version,
  schemaVersion: e.data['schema_version']! as int,
  name: e.data['name']! as String,
  createdAt: e.createdAt.toLocal(),
  description: e.data['description']! as String,
  iconKey: e.data['icon_key']! as String,
  archived: e.data['archived']! as bool,
  typeId: e.data['type_id'] as String?,
  columns: [
    for (final raw in e.data['fields']! as List)
      DataColumnDef(
        id: (raw as Map)['id']! as String,
        name: raw['name']! as String,
        type: switch (raw['type']) {
          'selection' => 'enum',
          'boolean' => 'bool',
          final String type => type,
          _ => throw const FormatException(),
        },
        isRequired: raw['required']! as bool,
        enumOptions: (raw['options']! as List).cast<String>(),
        unit: raw['unit'] as String?,
        scale: raw['scale'] as int? ?? 2,
      ),
  ],
);

Map<String, String> businessDisplayValues(
  DataTableDef table,
  Map<String, Object?> values,
) => {
  for (final entry in values.entries)
    if (entry.value != null)
      table.columns.where((f) => f.id == entry.key).firstOrNull?.name ??
          entry.key: entry.value
          .toString(),
};

DataTableBundle businessBundle(
  WorkspaceSnapshot snapshot, {
  List<DataChangeLog> logs = const [],
  bool historyLoading = false,
  bool historyError = false,
}) {
  final tables = snapshot.dataTables.map(businessTable).toList();
  final allTables = {
    for (final e in snapshot.entities.values)
      if (e.kind == WorkspaceEntityKind.dataTable) e.id: businessTable(e),
  };
  return DataTableBundle(
    tables: tables,
    types: [
      for (final e in snapshot.tableTypes)
        DataTableType(
          id: e.id,
          name: e.data['name']! as String,
          version: e.version,
        ),
    ],
    rows: [
      for (final e in snapshot.dataRows)
        DataRow(
          id: e.id,
          tableId: e.data['table_id']! as String,
          version: e.version,
          values: businessDisplayValues(
            allTables[e.data['table_id']]!,
            e.data['values']! as Map<String, Object?>,
          ),
          updatedAt: e.updatedAt.toLocal(),
          source: e.data['source'] == 'ai'
              ? DataChangeSource.ai
              : DataChangeSource.manual,
        ),
    ],
    logs: logs,
    historyLoading: historyLoading,
    historyError: historyError,
  );
}

Map<String, Object?> businessInputValues(
  DataTableDef table,
  Map<String, String> values,
) {
  if (values.keys.any((name) => !table.columns.any((f) => f.name == name))) {
    throw const WorkspaceFailure(WorkspaceFailureCode.validation);
  }
  return {
    for (final field in table.columns)
      if (values.containsKey(field.name))
        field.id!: _inputValue(field, values[field.name]!),
  };
}

Object? _inputValue(DataColumnDef field, String value) {
  if (value.isEmpty) return null;
  if (field.fieldType == DataFieldType.boolean) {
    if (!{'true', 'false'}.contains(value)) {
      throw const WorkspaceFailure(WorkspaceFailureCode.validation);
    }
    return value == 'true';
  }
  if (field.fieldType == DataFieldType.datetime) {
    final match = RegExp(
      r'^(\d{4}-\d\d-\d\d)[ T](\d\d:\d\d)(:\d\d(?:\.\d{1,6})?)?(Z|[+-]\d\d:\d\d)?$',
    ).firstMatch(value);
    if (match == null || value.startsWith('0000')) {
      throw const WorkspaceFailure(WorkspaceFailureCode.validation);
    }
    final wall = '${match[1]}T${match[2]}${match[3] ?? ':00'}';
    final calendar = DateTime.tryParse('${wall}Z');
    final offset = match[4];
    if (calendar == null ||
        calendar.toIso8601String().substring(0, 19) != wall.substring(0, 19)) {
      throw const WorkspaceFailure(WorkspaceFailureCode.validation);
    }
    if (offset != null && offset != 'Z') {
      final hour = int.parse(offset.substring(1, 3)),
          minute = int.parse(offset.substring(4));
      if (hour > 14 || minute > 59 || (hour == 14 && minute != 0)) {
        throw const WorkspaceFailure(WorkspaceFailureCode.validation);
      }
    }
    final parsed = DateTime.tryParse('$wall${offset ?? ''}');
    if (parsed == null ||
        (offset == null &&
            parsed.toIso8601String().substring(0, 19) !=
                wall.substring(0, 19))) {
      throw const WorkspaceFailure(WorkspaceFailureCode.validation);
    }
    return parsed.toUtc().toIso8601String();
  }
  return value;
}
