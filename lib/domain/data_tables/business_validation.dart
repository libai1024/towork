import '../workspace/workspace_commands.dart';

bool isBusinessEntity(WorkspaceEntityKind kind) => const {
  WorkspaceEntityKind.dataTable,
  WorkspaceEntityKind.dataRow,
  WorkspaceEntityKind.tableType,
}.contains(kind);

Never _invalid() =>
    throw const WorkspaceFailure(WorkspaceFailureCode.validation);

String _id(Object? value) {
  if (value is! String || !RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(value)) {
    _invalid();
  }
  return value;
}

String _text(Object? value, int max) {
  if (value is! String ||
      value.trim().isEmpty ||
      value.length > max ||
      value.contains('\u0000')) {
    _invalid();
  }
  return value.trim();
}

void _keys(Map<String, Object?> value, Set<String> allowed) {
  if (value.keys.any((key) => !allowed.contains(key))) _invalid();
}

/// Numeric cells use decimal strings; JSON doubles never enter business data.
/// Money keeps the declared scale, including trailing zeros, without rounding.
String canonicalBusinessDecimal(Object? value, {int? scale}) {
  if (value is! String ||
      value.length > 80 ||
      !RegExp(r'^-?(?:0|[1-9]\d*)(?:\.\d+)?$').hasMatch(value)) {
    _invalid();
  }
  final negative = value.startsWith('-');
  final parts = (negative ? value.substring(1) : value).split('.');
  if (parts.first.length > 38) _invalid();
  var fraction = parts.length == 2 ? parts.last : '';
  if (scale != null) {
    if (scale < 0 || scale > 6 || fraction.length > scale) _invalid();
    fraction = fraction.padRight(scale, '0');
  } else {
    if (fraction.length > 18) _invalid();
    fraction = fraction.replaceFirst(RegExp(r'0+$'), '');
  }
  final zero = parts.first == '0' && !RegExp('[1-9]').hasMatch(fraction);
  return '${negative && !zero ? '-' : ''}${parts.first}'
      '${fraction.isEmpty ? '' : '.$fraction'}';
}

List<Map<String, Object?>> _fields(Object? raw) {
  if (raw is! List || raw.isEmpty || raw.length > 100) _invalid();
  final ids = <String>{}, names = <String>{};
  return raw.map((item) {
    if (item is! Map<String, Object?>) _invalid();
    _keys(item, {'id', 'name', 'type', 'required', 'options', 'scale', 'unit'});
    final id = _id(item['id']);
    final name = _text(item['name'], 200);
    final type = item['type'];
    if (!ids.add(id) ||
        !names.add(name) ||
        !const {
          'text',
          'number',
          'money',
          'date',
          'datetime',
          'selection',
          'boolean',
        }.contains(type)) {
      _invalid();
    }
    final required = item['required'] ?? false;
    final options = item['options'] ?? <Object?>[];
    if (required is! bool || options is! List || options.length > 100) {
      _invalid();
    }
    final normalizedOptions = options.map((v) => _text(v, 200)).toList();
    if (normalizedOptions.toSet().length != options.length ||
        (type == 'selection' ? options.isEmpty : options.isNotEmpty)) {
      _invalid();
    }
    final scale = item['scale'] ?? (type == 'money' ? 2 : null);
    if (type == 'money'
        ? scale is! int || scale < 0 || scale > 6
        : scale != null) {
      _invalid();
    }
    final unit = item['unit'];
    if (unit != null) _text(unit, 80);
    return <String, Object?>{
      'id': id,
      'name': name,
      'type': type,
      'required': required,
      'options': normalizedOptions,
      'scale': scale,
      'unit': unit,
    };
  }).toList();
}

Map<String, Object?> applyBusinessPatch(
  WorkspaceEntityKind kind,
  Map<String, Object?>? before,
  Map<String, Object?> patch,
) {
  final Map<String, Object?> defaults = switch (kind) {
    WorkspaceEntityKind.dataTable => {
      'name': '',
      'description': '',
      'icon_key': 'table',
      'type_id': null,
      'archived': false,
      'schema_version': 1,
      'fields': <Object?>[],
      'retired_field_ids': <Object?>[],
    },
    WorkspaceEntityKind.dataRow => {
      'table_id': '',
      'values': <String, Object?>{},
      'source': 'manual',
      'source_message_id': null,
    },
    WorkspaceEntityKind.tableType => {'name': ''},
    _ => _invalid(),
  };
  _keys(patch, defaults.keys.toSet()..remove('retired_field_ids'));
  final data = <String, Object?>{...defaults, ...?before, ...patch};
  if (kind == WorkspaceEntityKind.tableType) {
    data['name'] = _text(data['name'], 200);
  } else if (kind == WorkspaceEntityKind.dataRow) {
    _id(data['table_id']);
    if (data['values'] is! Map<String, Object?> ||
        (data['values']! as Map).length > 100 ||
        !{'manual', 'ai'}.contains(data['source'])) {
      _invalid();
    }
    if (data['source_message_id'] != null) _id(data['source_message_id']);
    if (before != null) {
      for (final key in ['table_id', 'source', 'source_message_id']) {
        if (data[key] != before[key]) _invalid();
      }
    }
  } else {
    data['name'] = _text(data['name'], 200);
    data['icon_key'] = _text(data['icon_key'], 80);
    final description = data['description'];
    if (description is! String ||
        description.length > 10000 ||
        description.contains('\u0000') ||
        data['archived'] is! bool) {
      _invalid();
    }
    if (data['type_id'] != null) _id(data['type_id']);
    final fields = _fields(data['fields']);
    data['fields'] = fields;
    final oldFields = before == null
        ? <Map<String, Object?>>[]
        : _fields(before['fields']);
    final schemaChanged =
        before != null &&
        canonicalWorkspaceJson(oldFields) != canonicalWorkspaceJson(fields);
    final expected = before == null
        ? 1
        : (before['schema_version']! as int) + (schemaChanged ? 1 : 0);
    // A caller must explicitly acknowledge a schema change, never a silent bump.
    if (data['schema_version'] is! int || data['schema_version'] != expected) {
      _invalid();
    }
    final retired = (before?['retired_field_ids'] as List? ?? const [])
        .cast<String>()
        .toSet();
    final newById = {for (final field in fields) field['id']: field};
    for (final field in fields) {
      if (retired.contains(field['id'])) _invalid();
    }
    for (final old in oldFields) {
      final next = newById[old['id']];
      if (next == null) {
        retired.add(old['id']! as String);
      } else if (next['type'] != old['type'] || next['scale'] != old['scale']) {
        // Changing representation requires a future explicit conversion command.
        _invalid();
      }
    }
    data['retired_field_ids'] = retired.toList()..sort();
  }
  return freezeWorkspaceJson(data);
}

String _calendar(Object? value, {required bool instant}) {
  if (value is! String) _invalid();
  final pattern = instant
      ? r'^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d{1,6})?Z$'
      : r'^\d{4}-\d\d-\d\d$';
  if (!RegExp(pattern).hasMatch(value) || value.startsWith('0000')) _invalid();
  final parsed = DateTime.tryParse(instant ? value : '${value}T00:00:00Z');
  final prefix = instant ? 19 : 10;
  if (parsed == null ||
      parsed.toIso8601String().substring(0, prefix) !=
          value.substring(0, prefix)) {
    _invalid();
  }
  return instant ? parsed.toUtc().toIso8601String() : value;
}

/// Normalize against the final schema, including a table created in this batch.
Map<String, Object?> normalizeBusinessValues(
  Map<String, Object?> table,
  Map<String, Object?> values,
) {
  final fields = _fields(table['fields']);
  final ids = fields.map((f) => f['id']).toSet();
  if (values.keys.any((key) => !ids.contains(key))) _invalid();
  final result = <String, Object?>{};
  for (final field in fields) {
    final id = field['id']! as String;
    final value = values[id];
    if (value == null) {
      if (field['required'] == true) _invalid();
      if (values.containsKey(id)) result[id] = null;
      continue;
    }
    result[id] = switch (field['type']) {
      'text' =>
        value is String &&
                value.length <= 100000 &&
                !value.contains('\u0000') &&
                (field['required'] != true || value.trim().isNotEmpty)
            ? value
            : _invalid(),
      'number' => canonicalBusinessDecimal(value),
      'money' => canonicalBusinessDecimal(value, scale: field['scale']! as int),
      'date' => _calendar(value, instant: false),
      'datetime' => _calendar(value, instant: true),
      'selection' =>
        (field['options']! as List).contains(value) ? value : _invalid(),
      'boolean' => value is bool ? value : _invalid(),
      _ => _invalid(),
    };
  }
  return freezeWorkspaceJson(result);
}

void validateBusinessGraph(Iterable<WorkspaceEntity> entities) {
  final active = entities.where((e) => !e.isDeleted).toList();
  final types = {
    for (final e in active)
      if (e.kind == WorkspaceEntityKind.tableType) e.id,
  };
  final tables = {
    for (final e in active)
      if (e.kind == WorkspaceEntityKind.dataTable) e.id: e,
  };
  for (final table in tables.values) {
    if (table.data['type_id'] != null &&
        !types.contains(table.data['type_id'])) {
      _invalid();
    }
  }
  for (final row in active.where(
    (e) => e.kind == WorkspaceEntityKind.dataRow,
  )) {
    final table = tables[row.data['table_id']];
    if (table == null) _invalid();
    final values = row.data['values'];
    if (values is! Map<String, Object?>) _invalid();
    // Existing rows must already be canonical; schema edits never rewrite them.
    if (canonicalWorkspaceJson(normalizeBusinessValues(table.data, values)) !=
        canonicalWorkspaceJson(values)) {
      _invalid();
    }
  }
}
