import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../workspace/workspace_commands.dart';
import '../workspace/workspace_validation.dart';

/// Bounded model-facing reads. SQLite remains authoritative; these projections
/// currently use the shared snapshot, not SQL-level pagination.
class BusinessQueries {
  static const names = {
    'data_table_list',
    'data_table_get',
    'data_row_list',
    'data_row_get',
  };

  static Map<String, Object?> query(
    String name,
    WorkspaceSnapshot snapshot,
    Map<String, Object?> args,
  ) => switch (name) {
    'data_table_list' => _tables(snapshot, args),
    'data_table_get' => _schema(snapshot, args),
    'data_row_list' => _rows(snapshot, args),
    'data_row_get' => _cell(snapshot, args),
    _ => _invalid(),
  };

  static Never _invalid() =>
      throw const WorkspaceFailure(WorkspaceFailureCode.validation);
  static void keys(
    Map<String, Object?> args,
    Set<String> allowed,
    Set<String> required,
  ) {
    if (args.keys.any((k) => !allowed.contains(k)) ||
        required.any((k) => !args.containsKey(k))) {
      _invalid();
    }
  }

  static String id(Object? value) {
    if (value is! String) _invalid();
    validateWorkspaceId(value);
    return value;
  }

  static int integer(Object? value, int fallback, int min, int max) {
    if (value == null) return fallback;
    if (value is! int || value < min || value > max) _invalid();
    return value;
  }

  static WorkspaceEntity table(
    WorkspaceSnapshot snapshot,
    Object? rawId,
    Object? version,
  ) {
    final entity = snapshot.find(WorkspaceEntityKind.dataTable, id(rawId));
    if (entity == null || entity.isDeleted) {
      throw const WorkspaceFailure(WorkspaceFailureCode.notFound);
    }
    checkVersion(entity, version);
    return entity;
  }

  static void checkVersion(WorkspaceEntity entity, Object? version) {
    if (version != null) {
      if (version is! int || version < 1) _invalid();
      if (version != entity.version) {
        throw const WorkspaceFailure(WorkspaceFailureCode.versionConflict);
      }
    }
  }

  static List<Map<String, Object?>> fields(WorkspaceEntity table) =>
      (table.data['fields']! as List).cast<Map<String, Object?>>();
  static Map<String, Object?> tableHeader(WorkspaceEntity table) => {
    'id': table.id,
    'name': table.data['name'],
    'version': table.version,
    'schema_version': table.data['schema_version'],
    'archived': table.data['archived'],
    'type_id': table.data['type_id'],
    'field_count': fields(table).length,
  };
  static String search(Map<String, Object?> args) {
    final query = args['query'] ?? '';
    if (query is! String || query.length > 200) _invalid();
    return query.toLowerCase();
  }

  static Map<String, Object?> _tables(
    WorkspaceSnapshot snapshot,
    Map<String, Object?> args,
  ) {
    keys(args, {'query', 'include_archived', 'limit', 'page_token'}, {});
    final query = search(args);
    final archived = args['include_archived'] ?? false;
    if (archived is! bool) _invalid();
    final tables =
        snapshot.dataTables
            .where(
              (t) =>
                  (archived || t.data['archived'] != true) &&
                  (t.data['name']! as String).toLowerCase().contains(query),
            )
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    return _page(
      tables.map(tableHeader).toList(),
      args,
      tables.map((t) => [t.id, t.version]).toList(),
    );
  }

  static Map<String, Object?> _schema(
    WorkspaceSnapshot snapshot,
    Map<String, Object?> args,
  ) {
    keys(
      args,
      {'table_id', 'expected_table_version', 'field_id', 'limit', 'page_token'},
      {'table_id'},
    );
    final t = table(snapshot, args['table_id'], args['expected_table_version']);
    final all = fields(t);
    final fieldId = args['field_id'];
    if (fieldId != null) {
      id(fieldId);
      final matching = all.where((f) => f['id'] == fieldId);
      if (matching.isEmpty) {
        throw const WorkspaceFailure(WorkspaceFailureCode.notFound);
      }
      final field = matching.single;
      final options = (field['options']! as List).cast<String>();
      return {
        ...tableHeader(t),
        'field': {...field}..remove('options'),
        'options': _page(options, args, [t.id, t.version]),
      };
    }
    return {
      ...tableHeader(t),
      ..._page(
        [
          for (final f in all)
            {...f, 'option_count': (f['options']! as List).length}
              ..remove('options'),
        ],
        args,
        [t.id, t.version],
      ),
    };
  }

  static Map<String, Object?> rowPreview(
    WorkspaceEntity row,
    List<String> fieldIds,
  ) => rowPreviewValues(
    id: row.id,
    version: row.version,
    tableId: row.data['table_id']! as String,
    source: row.data['source'],
    sourceMessageId: row.data['source_message_id'],
    values: row.data['values']! as Map<String, Object?>,
    fieldIds: fieldIds,
  );

  static Map<String, Object?> rowPreviewValues({
    required String id,
    required int version,
    required String tableId,
    required Object? source,
    required Object? sourceMessageId,
    required Map<String, Object?> values,
    required List<String> fieldIds,
  }) {
    final truncated = <String>[];
    final preview = <String, Object?>{};
    for (final fieldId in fieldIds) {
      if (!values.containsKey(fieldId)) continue;
      final value = values[fieldId];
      if (value is String && value.runes.length > 200) {
        preview[fieldId] = String.fromCharCodes(value.runes.take(200));
        truncated.add(fieldId);
      } else {
        preview[fieldId] = value;
      }
    }
    return {
      'id': id,
      'version': version,
      'table_id': tableId,
      'source': source,
      'source_message_id': sourceMessageId,
      'values': preview,
      'truncated_fields': truncated,
      'omitted_field_ids': values.keys
          .where((k) => !fieldIds.contains(k))
          .toList(),
    };
  }

  static Map<String, Object?> _rows(
    WorkspaceSnapshot snapshot,
    Map<String, Object?> args,
  ) {
    keys(
      args,
      {
        'table_id',
        'expected_table_version',
        'query',
        'field_ids',
        'limit',
        'page_token',
      },
      {'table_id'},
    );
    final t = table(snapshot, args['table_id'], args['expected_table_version']);
    final query = search(args);
    final allIds = fields(t).map((f) => f['id']! as String).toList();
    final rawIds = args['field_ids'] ?? allIds.take(8).toList();
    if (rawIds is! List ||
        rawIds.isEmpty ||
        rawIds.length > 8 ||
        rawIds.any((v) => v is! String || !allIds.contains(v)) ||
        rawIds.toSet().length != rawIds.length) {
      _invalid();
    }
    final ids = rawIds.cast<String>();
    final rows =
        snapshot.dataRows
            .where(
              (r) =>
                  r.data['table_id'] == t.id &&
                  (query.isEmpty ||
                      (r.data['values']! as Map).values.any(
                        (v) => v is String && v.toLowerCase().contains(query),
                      )),
            )
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    return {
      'table': tableHeader(t),
      'selected_field_ids': ids,
      ..._page(rows.map((r) => rowPreview(r, ids)).toList(), args, [
        t.id,
        t.version,
        for (final row in rows) [row.id, row.version],
      ]),
    };
  }

  static Map<String, Object?> _cell(
    WorkspaceSnapshot snapshot,
    Map<String, Object?> args,
  ) {
    keys(
      args,
      {
        'table_id',
        'expected_table_version',
        'id',
        'expected_version',
        'field_id',
        'offset',
        'limit',
      },
      {'table_id', 'id', 'field_id'},
    );
    final t = table(snapshot, args['table_id'], args['expected_table_version']);
    final row = snapshot.find(WorkspaceEntityKind.dataRow, id(args['id']));
    if (row == null || row.isDeleted || row.data['table_id'] != t.id) {
      throw const WorkspaceFailure(WorkspaceFailureCode.notFound);
    }
    checkVersion(row, args['expected_version']);
    final fieldId = id(args['field_id']);
    if (!fields(t).any((f) => f['id'] == fieldId)) _invalid();
    final offset = integer(args['offset'], 0, 0, 100000);
    final limit = integer(args['limit'], 2000, 1, 4000);
    if (offset > 0 &&
        (args['expected_version'] == null ||
            args['expected_table_version'] == null)) {
      _invalid();
    }
    final values = row.data['values']! as Map;
    final value = values[fieldId];
    final runes = value is String ? value.runes.toList() : null;
    if (offset > (runes?.length ?? 0)) _invalid();
    final next = runes != null && offset + limit < runes.length
        ? offset + limit
        : null;
    return {
      'id': row.id,
      'version': row.version,
      'table_id': t.id,
      'table_version': t.version,
      'field_id': fieldId,
      'present': values.containsKey(fieldId),
      'value': runes == null
          ? value
          : String.fromCharCodes(runes.skip(offset).take(limit)),
      'offset': offset,
      'next_offset': next,
      'total_code_points': runes?.length,
    };
  }

  static Map<String, Object?> _page(
    List<Object?> items,
    Map<String, Object?> args,
    Object stamp,
  ) {
    final limit = integer(args['limit'], 10, 1, 20);
    final criteria = {...args}..remove('page_token');
    final digest = sha256
        .convert(
          utf8.encode(
            canonicalWorkspaceJson({'criteria': criteria, 'stamp': stamp}),
          ),
        )
        .toString();
    var start = 0;
    if (args.containsKey('page_token')) {
      final token = args['page_token'];
      if (token is! String || token.length > 1024) _invalid();
      final parts = token.split(':');
      if (parts.length != 2 || int.tryParse(parts.last) == null) _invalid();
      if (parts.first != digest) {
        return {
          'error': 'cursor_stale',
          'items': <Object?>[],
          'next_page_token': null,
        };
      }
      start = int.parse(parts.last);
      if (start < 0 || start > items.length) _invalid();
    }
    final end = (start + limit).clamp(0, items.length);
    return {
      'items': items.sublist(start, end),
      'total': items.length,
      'next_page_token': end < items.length ? '$digest:$end' : null,
    };
  }
}
