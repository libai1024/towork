import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../domain/data_tables/business_queries.dart';
import '../../domain/data_tables/business_validation.dart';
import '../../domain/workspace/workspace_commands.dart';
import 'app_database.dart';

/// Bounded SQL row reads over the authoritative `work_data_rows` payloads.
/// Filtering, ordering, counting and paging all execute in SQLite; only the
/// returned page is decoded in Dart. Write transactions keep whole-graph FC1
/// semantics — this path never serves proposals.
class SqliteRowQuery {
  static const _textOps = {'eq', 'contains'};
  static const _rangeOps = {'eq', 'gt', 'ge', 'lt', 'le'};

  static Never _invalid() =>
      throw const WorkspaceFailure(WorkspaceFailureCode.validation);

  static String _escapeLike(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll('%', '\\%')
      .replaceAll('_', '\\_');

  /// json_extract paths are built from schema-validated workspace IDs
  /// ([A-Za-z0-9_-]); cell values always ride bound parameters.
  static String _extract(String fieldId) {
    return "json_extract(payload, '\$.values.$fieldId')";
  }

  static String _sortExpr(Map<String, Object?> field) {
    final id = field['id']! as String;
    final type = field['type']! as String;
    final extract = _extract(id);
    if (type == 'number' || type == 'money') {
      return 'CAST($extract AS REAL)';
    }
    return extract;
  }

  static String _sqlOp(String op) => switch (op) {
    'eq' => '=',
    'gt' => '>',
    'ge' => '>=',
    'lt' => '<',
    'le' => '<=',
    _ => throw const WorkspaceFailure(WorkspaceFailureCode.validation),
  };

  static double? _asNumber(Object? value) {
    if (value is int) return value.toDouble();
    if (value is double) return value.isFinite ? value : null;
    if (value is String) return double.tryParse(value);
    return null;
  }

  static Future<Map<String, Object?>> rows(
    AppDatabase db,
    WorkspaceSnapshot tables,
    Map<String, Object?> args,
  ) async {
    BusinessQueries.keys(
      args,
      {
        'table_id',
        'expected_table_version',
        'query',
        'field_ids',
        'filters',
        'sort_field_id',
        'sort_desc',
        'limit',
        'page_token',
      },
      {'table_id'},
    );
    final table = BusinessQueries.table(
      tables,
      args['table_id'],
      args['expected_table_version'],
    );
    final query = BusinessQueries.search(args);
    final fields = BusinessQueries.fields(table);
    final fieldById = {for (final f in fields) f['id']! as String: f};

    final rawIds =
        args['field_ids'] ?? fields.take(8).map((f) => f['id']).toList();
    if (rawIds is! List ||
        rawIds.isEmpty ||
        rawIds.length > 8 ||
        rawIds.any((v) => v is! String || !fieldById.containsKey(v)) ||
        rawIds.toSet().length != rawIds.length) {
      _invalid();
    }
    final previewIds = rawIds.cast<String>().toList();

    final conditions = <String>['table_id = ?', 'deleted_at IS NULL'];
    final variables = <Variable>[Variable.withString(table.id)];
    _applyFilters(args, fieldById, conditions, variables);
    _applySearch(query, fields, conditions, variables);
    final order = _orderClause(args, fieldById);

    final where = conditions.join(' AND ');
    final stampRow = await db
        .customSelect(
          'SELECT COUNT(*) AS total, COALESCE(SUM(version), 0) AS vsum, '
          'COALESCE(MAX(updated_at), 0) AS vmax FROM work_data_rows '
          'WHERE $where',
          variables: variables,
          readsFrom: {db.workDataRows},
        )
        .getSingle();
    final total = stampRow.read<int>('total');
    // The stamp mirrors the snapshot cursor contract: identical criteria over
    // changed data must report cursor_stale instead of silently reordering.
    final digest = _digest(args, [
      table.id,
      table.version,
      total,
      stampRow.read<int>('vsum'),
      stampRow.read<int>('vmax'),
    ]);

    final limit = BusinessQueries.integer(args['limit'], 10, 1, 20);
    var offset = 0;
    if (args.containsKey('page_token')) {
      final token = args['page_token'];
      if (token is! String || token.length > 1024) _invalid();
      final parts = token.split(':');
      if (parts.length != 2 || int.tryParse(parts.last) == null) _invalid();
      if (parts.first != digest) {
        return _staleCursor();
      }
      offset = int.parse(parts.last);
      if (offset < 0 || offset > total) _invalid();
    }
    final pageRows = await db
        .customSelect(
          'SELECT id, version, payload FROM work_data_rows WHERE $where '
          'ORDER BY $order LIMIT ? OFFSET ?',
          variables: [
            ...variables,
            Variable.withInt(limit),
            Variable.withInt(offset),
          ],
          readsFrom: {db.workDataRows},
        )
        .get();
    final end = (offset + limit).clamp(0, total);
    return {
      'table': BusinessQueries.tableHeader(table),
      'selected_field_ids': previewIds,
      'items': [
        for (final row in pageRows)
          _preview(
            row.read<String>('id'),
            row.read<int>('version'),
            table.id,
            row.read<String>('payload'),
            previewIds,
          ),
      ],
      'total': total,
      'next_page_token': end < total ? '$digest:$end' : null,
    };
  }

  static Map<String, Object?> _staleCursor() => {
    'error': 'cursor_stale',
    'items': <Object?>[],
    'next_page_token': null,
  };

  static String _digest(Map<String, Object?> args, Object stamp) {
    final criteria = {...args}..remove('page_token');
    return sha256
        .convert(
          utf8.encode(
            canonicalWorkspaceJson({'criteria': criteria, 'stamp': stamp}),
          ),
        )
        .toString();
  }

  static Map<String, Object?> _preview(
    String id,
    int version,
    String tableId,
    String payload,
    List<String> fieldIds,
  ) {
    final data = (jsonDecode(payload) as Map).cast<String, Object?>();
    return BusinessQueries.rowPreviewValues(
      id: id,
      version: version,
      tableId: tableId,
      source: data['source'],
      sourceMessageId: data['source_message_id'],
      values: (data['values']! as Map).cast<String, Object?>(),
      fieldIds: fieldIds,
    );
  }

  static void _applyFilters(
    Map<String, Object?> args,
    Map<String, Map<String, Object?>> fieldById,
    List<String> conditions,
    List<Variable> variables,
  ) {
    final rawFilters = args['filters'] ?? const <Object?>[];
    if (rawFilters is! List || rawFilters.length > 4) _invalid();
    for (final raw in rawFilters) {
      if (raw is! Map<String, Object?> ||
          raw.keys.any((k) => !{'field_id', 'op', 'value'}.contains(k)) ||
          !raw.containsKey('value')) {
        _invalid();
      }
      final field = fieldById[BusinessQueries.id(raw['field_id'])];
      if (field == null) _invalid();
      final op = raw['op'];
      final value = raw['value'];
      if (op is! String || value == null) _invalid();
      final type = field['type']! as String;
      final expr = _extract(field['id']! as String);
      if (type == 'text' || type == 'selection') {
        if (value is! String || !_textOps.contains(op)) _invalid();
        if (op == 'contains') {
          conditions.add("$expr LIKE ? ESCAPE '\\'");
          variables.add(
            Variable.withString('%${_escapeLike(value.toLowerCase())}%'),
          );
        } else {
          conditions.add('$expr = ?');
          variables.add(Variable.withString(value));
        }
      } else if (type == 'boolean') {
        if (value is! bool || op != 'eq') _invalid();
        conditions.add('$expr = ?');
        variables.add(Variable.withInt(value ? 1 : 0));
      } else if (type == 'number' || type == 'money') {
        if (!_rangeOps.contains(op)) _invalid();
        if (op == 'eq') {
          // Canonical decimal equality keeps money scale exact.
          final text = value is String ? value : value.toString();
          conditions.add('$expr = ?');
          variables.add(
            Variable.withString(
              canonicalBusinessDecimal(
                text,
                scale: type == 'money' ? field['scale']! as int : null,
              ),
            ),
          );
        } else {
          final number = _asNumber(value);
          if (number == null) _invalid();
          conditions.add('CAST($expr AS REAL) ${_sqlOp(op)} ?');
          variables.add(Variable.withReal(number));
        }
      } else if (type == 'date' || type == 'datetime') {
        if (value is! String || !_rangeOps.contains(op)) _invalid();
        conditions.add('$expr ${_sqlOp(op)} ?');
        variables.add(Variable.withString(value));
      } else {
        _invalid();
      }
    }
  }

  static void _applySearch(
    String query,
    List<Map<String, Object?>> fields,
    List<String> conditions,
    List<Variable> variables,
  ) {
    if (query.isEmpty) return;
    // Parity with the snapshot path: search matches any string cell.
    final like = <String>[];
    for (final field in fields) {
      if (field['type'] == 'boolean') continue;
      like.add("${_extract(field['id']! as String)} LIKE ? ESCAPE '\\'");
    }
    if (like.isEmpty) {
      conditions.add('0 = 1');
      return;
    }
    conditions.add('(${like.join(' OR ')})');
    for (var i = 0; i < like.length; i++) {
      variables.add(Variable.withString('%${_escapeLike(query)}%'));
    }
  }

  static String _orderClause(
    Map<String, Object?> args,
    Map<String, Map<String, Object?>> fieldById,
  ) {
    final rawSortField = args['sort_field_id'];
    if (rawSortField == null) return 'id ASC';
    final field = fieldById[BusinessQueries.id(rawSortField)];
    if (field == null) _invalid();
    final desc = args['sort_desc'] ?? false;
    if (desc is! bool) _invalid();
    return '${_sortExpr(field)} ${desc ? 'DESC' : 'ASC'} NULLS LAST, id ASC';
  }

  /// Single-row read; the payload page is one row, everything else mirrors
  /// the snapshot tool exactly.
  static Future<Map<String, Object?>> cell(
    AppDatabase db,
    WorkspaceSnapshot tables,
    Map<String, Object?> args,
  ) async {
    final table = BusinessQueries.table(tables, args['table_id'], null);
    final rowId = BusinessQueries.id(args['id']);
    final row = await db
        .customSelect(
          'SELECT id, version, payload, created_at, updated_at FROM '
          'work_data_rows WHERE id = ? AND table_id = ? AND deleted_at IS NULL',
          variables: [
            Variable.withString(rowId),
            Variable.withString(table.id),
          ],
          readsFrom: {db.workDataRows},
        )
        .getSingleOrNull();
    if (row == null) {
      throw const WorkspaceFailure(WorkspaceFailureCode.notFound);
    }
    final entity = WorkspaceEntity(
      kind: WorkspaceEntityKind.dataRow,
      id: row.read<String>('id'),
      version: row.read<int>('version'),
      data: (jsonDecode(row.read<String>('payload')) as Map)
          .cast<String, Object?>(),
      createdAt: DateTime.fromMicrosecondsSinceEpoch(
        row.read<int>('created_at'),
        isUtc: true,
      ),
      updatedAt: DateTime.fromMicrosecondsSinceEpoch(
        row.read<int>('updated_at'),
        isUtc: true,
      ),
    );
    return BusinessQueries.query(
      'data_row_get',
      WorkspaceSnapshot([...tables.entities.values, entity]),
      args,
    );
  }
}
