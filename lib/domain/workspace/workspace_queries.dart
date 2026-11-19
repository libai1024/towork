import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'workspace_commands.dart';
import 'workspace_validation.dart';

typedef QueryObject = Map<String, Object?>;

/// Read-only projections of one committed snapshot. No SQL or write commands
/// are accepted. Materialized occurrences are not an infinite future calendar.
class WorkspaceQueries {
  static const _priorities = ['urgent', 'high', 'medium', 'low', 'none'];
  static const _statuses = [
    'pending',
    'inProgress',
    'done',
    'cancelled',
    'active',
  ];
  static const _sorts = ['id', 'due_at', 'priority', 'updated_at'];
  static const pageBytes = 48 * 1024;

  static QueryObject todos(WorkspaceSnapshot snapshot, QueryObject args) {
    _keys(args, {
      'query',
      'status',
      'after_id',
      'limit',
      'category_id',
      'include_descendants',
      'tags',
      'priority',
      'due_from',
      'due_before',
      'no_due',
      'order_by',
      'direction',
      'page_token',
    });
    final query = _text(
      args,
      'query',
      fallback: '',
      max: 200,
    ).trim().toLowerCase();
    final status = _option(args, 'status', _statuses);
    final priority = _option(args, 'priority', _priorities);
    final order = _option(args, 'order_by', _sorts) ?? 'id';
    final direction = _option(args, 'direction', ['asc', 'desc']) ?? 'asc';
    final limit = _integer(args, 'limit', fallback: 30, min: 1, max: 50);
    final noDue = _boolean(args, 'no_due');
    final descendants = _boolean(args, 'include_descendants');
    final from = _date(args, 'due_from');
    final before = _date(args, 'due_before');
    if ((noDue && (from != null || before != null)) ||
        (from != null && before != null && !from.isBefore(before))) {
      _invalid();
    }
    final hasCategory = args.containsKey('category_id');
    final category = args['category_id'];
    if (category != null && category is! String) _invalid();
    if (category is String) validateWorkspaceId(category);
    if (descendants && category == null) _invalid();
    final categoryIds = <String>{if (category is String) category};
    var categoryMissing = false;
    if (category is String) {
      final found = snapshot.find(WorkspaceEntityKind.category, category);
      if (found == null || found.isDeleted) {
        categoryMissing = true;
      }
      if (descendants) {
        categoryIds.addAll(
          snapshot.categories
              .where((c) => c.data['parent_id'] == category)
              .map((c) => c.id),
        );
      }
    }
    final rawTags = args['tags'] ?? const <String>[];
    if (rawTags is! List ||
        rawTags.length > 100 ||
        rawTags.any(
          (t) =>
              t is! String ||
              t.trim().isEmpty ||
              t.length > 100 ||
              t.contains('\u0000'),
        )) {
      _invalid();
    }
    final tags = rawTags.cast<String>().map((t) => t.trim()).toSet().toList()
      ..sort();
    final afterId = _optionalId(args, 'after_id');
    final token = args['page_token'];
    if (token != null &&
        (token is! String || token.length > 1024 || token.isEmpty)) {
      _invalid();
    }
    if (afterId != null &&
        (token != null || order != 'id' || direction != 'asc')) {
      _invalid();
    }
    final decoded = token is String ? _decodeToken(token) : null;
    final filter = <String, Object?>{
      'query': query,
      'status': status,
      'priority': priority,
      'has_category': hasCategory,
      'category_id': category,
      'include_descendants': descendants,
      'tags': tags,
      'due_from': from?.toIso8601String(),
      'due_before': before?.toIso8601String(),
      'no_due': noDue,
      'order_by': order,
      'direction': direction,
    };
    if (categoryMissing) {
      return {'error': 'category_not_found', 'category_id': category};
    }
    final rows = snapshot.todos.where((e) {
      final data = e.data;
      if (status == 'active'
          ? !{'pending', 'inProgress'}.contains(data['status'])
          : status != null && data['status'] != status) {
        return false;
      }
      if (priority != null && data['priority'] != priority) return false;
      if (hasCategory &&
          (category == null
              ? data['category_id'] != null
              : !categoryIds.contains(data['category_id']))) {
        return false;
      }
      if (!tags.every((tag) => (data['tags']! as List).contains(tag))) {
        return false;
      }
      final due = data['due_at'] == null
          ? null
          : DateTime.parse(data['due_at']! as String);
      if (noDue && due != null) return false;
      if (from != null && (due == null || due.isBefore(from))) return false;
      if (before != null && (due == null || !due.isBefore(before))) {
        return false;
      }
      return '${data['title']} ${data['note'] ?? ''}'.toLowerCase().contains(
        query,
      );
    }).toList();
    rows.sort((a, b) {
      int comparison;
      switch (order) {
        case 'due_at':
          final first = a.data['due_at'] as String?;
          final second = b.data['due_at'] as String?;
          if (first == null && second != null) return 1;
          if (first != null && second == null) return -1;
          comparison = first == null
              ? 0
              : DateTime.parse(first).compareTo(DateTime.parse(second!));
        case 'priority':
          comparison = _priorities
              .indexOf(a.data['priority']! as String)
              .compareTo(_priorities.indexOf(b.data['priority']! as String));
        case 'updated_at':
          comparison = a.updatedAt.compareTo(b.updatedAt);
        default:
          comparison = a.id.compareTo(b.id);
      }
      if (comparison == 0) return a.id.compareTo(b.id);
      return direction == 'desc' ? -comparison : comparison;
    });
    final fingerprint = _digest([
      for (final row in rows)
        [
          row.id,
          row.version,
          row.data['series_id'] is String
              ? snapshot
                    .find(
                      WorkspaceEntityKind.series,
                      row.data['series_id']! as String,
                    )
                    ?.version
              : null,
        ],
    ]);
    final queryHash = _digest(filter);
    var start = 0;
    if (decoded != null) {
      if (decoded['query'] != queryHash || decoded['snapshot'] != fingerprint) {
        return {'error': 'cursor_stale', 'restart_without_page_token': true};
      }
      final index = rows.indexWhere((e) => e.id == decoded['after']);
      if (index < 0) {
        return {'error': 'cursor_stale', 'restart_without_page_token': true};
      }
      start = index + 1;
    } else if (afterId != null) {
      start = rows.indexWhere((e) => e.id.compareTo(afterId) > 0);
      if (start < 0) start = rows.length;
    }
    final items = <QueryObject>[];
    var bytes = 2048;
    for (final row in rows.skip(start).take(limit)) {
      final item = _todo(snapshot, row);
      final size = utf8.encode(jsonEncode(item)).length + 1;
      if (bytes + size > pageBytes) break;
      bytes += size;
      items.add(item);
    }
    if (items.isEmpty && start < rows.length) {
      return {'error': 'record_too_large', 'id': rows[start].id};
    }
    final more = start + items.length < rows.length;
    final last = items.isEmpty ? null : items.last['id'];
    return {
      'items': items,
      // Backwards-compatible ID cursor for existing tools. New callers should
      // use next_page_token, which rejects edits between pages.
      'next_cursor': more && order == 'id' && direction == 'asc' ? last : null,
      'next_page_token': more
          ? base64Url.encode(
              utf8.encode(
                jsonEncode({
                  'v': 1,
                  'query': queryHash,
                  'snapshot': fingerprint,
                  'after': last,
                }),
              ),
            )
          : null,
      'matched_count': rows.length,
      'scope': 'materialized_records_only',
      'page_size_limited': more && items.length < limit,
    };
  }

  static QueryObject todo(WorkspaceSnapshot snapshot, QueryObject args) {
    _keys(args, {'id', 'expected_version', 'note_offset', 'note_limit'});
    final id = _optionalId(args, 'id');
    if (id == null) _invalid();
    final offset = _integer(
      args,
      'note_offset',
      fallback: 0,
      min: 0,
      max: 100000,
    );
    final limit = _integer(
      args,
      'note_limit',
      fallback: 2000,
      min: 1,
      max: 4000,
    );
    final version = args['expected_version'];
    if ((version != null && (version is! int || version < 1)) ||
        (offset > 0 && version == null)) {
      _invalid();
    }
    final row = snapshot.find(WorkspaceEntityKind.todo, id);
    if (row == null || row.isDeleted) return {'error': 'not_found', 'id': id};
    if (version != null && version != row.version) {
      return {'error': 'version_changed', 'id': id, 'version': row.version};
    }
    final note = (row.data['note'] as String?)?.runes.toList();
    if (offset > (note?.length ?? 0)) _invalid();
    final end = (offset + limit).clamp(0, note?.length ?? 0);
    return {
      ..._todo(snapshot, row, fullTags: true),
      'remind_at': row.data['remind_at'],
      'remind_rules': row.data['remind_rules'],
      'source': row.data['source'],
      'source_message_id': row.data['source_message_id'],
      'created_at': row.createdAt.toUtc().toIso8601String(),
      'note_preview': null,
      'note_truncated': offset > 0 || end < (note?.length ?? 0),
      'note_segment': note == null
          ? null
          : String.fromCharCodes(note.sublist(offset, end)),
      'note_offset': offset,
      'note_total_runes': note?.length ?? 0,
      'next_note_offset': end < (note?.length ?? 0) ? end : null,
    };
  }

  static QueryObject categories(WorkspaceSnapshot snapshot, QueryObject args) {
    _keys(args, {
      'query',
      'parent_id',
      'include_archived',
      'after_id',
      'limit',
    });
    final query = _text(
      args,
      'query',
      fallback: '',
      max: 200,
    ).trim().toLowerCase();
    final includeArchived = _boolean(args, 'include_archived');
    final hasParent = args.containsKey('parent_id');
    final parent = _optionalId(args, 'parent_id');
    final after = _optionalId(args, 'after_id');
    final limit = _integer(args, 'limit', fallback: 30, min: 1, max: 50);
    final rows =
        snapshot.categories
            .where(
              (c) =>
                  (includeArchived || c.data['archived'] == false) &&
                  (!hasParent || c.data['parent_id'] == parent) &&
                  (after == null || c.id.compareTo(after) > 0) &&
                  (c.data['name']! as String).toLowerCase().contains(query),
            )
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    final page = rows.take(limit).toList();
    return {
      'items': [
        for (final c in page)
          {
            'id': c.id,
            'version': c.version,
            ...c.data,
            'parent_name': c.data['parent_id'] == null
                ? null
                : snapshot
                      .find(
                        WorkspaceEntityKind.category,
                        c.data['parent_id']! as String,
                      )
                      ?.data['name'],
          },
      ],
      'next_cursor': rows.length > limit ? page.last.id : null,
    };
  }

  static QueryObject _todo(
    WorkspaceSnapshot snapshot,
    WorkspaceEntity e, {
    bool fullTags = false,
  }) => {
    'id': e.id,
    'version': e.version,
    for (final key in [
      'title',
      'status',
      'priority',
      'due_at',
      'category_id',
      'completed_at',
      'repeat_rule',
      'repeat_timezone',
      'series_id',
      'occurrence_key',
      'occurrence_index',
      'occurrence_at',
    ])
      key: e.data[key],
    'tags': (e.data['tags']! as List).take(fullTags ? 100 : 20).toList(),
    'tags_truncated': !fullTags && (e.data['tags']! as List).length > 20,
    'updated_at': e.updatedAt.toUtc().toIso8601String(),
    'series_version': e.data['series_id'] is String
        ? snapshot
              .find(WorkspaceEntityKind.series, e.data['series_id']! as String)
              ?.version
        : null,
    'note_preview': e.data['note'] == null
        ? null
        : String.fromCharCodes((e.data['note']! as String).runes.take(2000)),
    'note_truncated':
        (e.data['note'] as String?)?.runes.length != null &&
        (e.data['note']! as String).runes.length > 2000,
  };

  static QueryObject _decodeToken(String token) {
    try {
      final value = jsonDecode(utf8.decode(base64Url.decode(token)));
      if (value is! QueryObject ||
          value.length != 4 ||
          value['v'] != 1 ||
          value['query'] is! String ||
          value['snapshot'] is! String ||
          value['after'] is! String) {
        _invalid();
      }
      validateWorkspaceId(value['after']! as String);
      return value;
    } catch (_) {
      _invalid();
    }
  }

  static String _digest(Object value) =>
      sha256.convert(utf8.encode(canonicalWorkspaceJson(value))).toString();
  static void _keys(QueryObject args, Set<String> allowed) {
    if (args.keys.any((k) => !allowed.contains(k))) _invalid();
  }

  static String _text(
    QueryObject args,
    String key, {
    required String fallback,
    required int max,
  }) {
    final value = args[key] ?? fallback;
    if (value is! String || value.length > max || value.contains('\u0000')) {
      _invalid();
    }
    return value;
  }

  static int _integer(
    QueryObject args,
    String key, {
    required int fallback,
    required int min,
    required int max,
  }) {
    final value = args[key] ?? fallback;
    if (value is! int || value < min || value > max) _invalid();
    return value;
  }

  static bool _boolean(QueryObject args, String key) {
    final value = args[key] ?? false;
    if (value is! bool) _invalid();
    return value;
  }

  static String? _option(QueryObject args, String key, List<String> options) {
    final value = args[key];
    if (value != null && !options.contains(value)) _invalid();
    return value as String?;
  }

  static String? _optionalId(QueryObject args, String key) {
    final value = args[key];
    if (value != null) {
      if (value is! String) _invalid();
      validateWorkspaceId(value);
    }
    return value as String?;
  }

  static DateTime? _date(QueryObject args, String key) {
    final value = args[key];
    if (value == null) return null;
    if (value is! String ||
        !RegExp(r'^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d{1,6})?Z$')
            .hasMatch(value)) {
      _invalid();
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null ||
        parsed.toIso8601String().substring(0, 19) != value.substring(0, 19)) {
      _invalid();
    }
    return parsed;
  }

  static Never _invalid() =>
      throw const WorkspaceFailure(WorkspaceFailureCode.validation);
}
