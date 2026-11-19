import '../models/todo_step.dart';
import '../recurrence/recurrence_rule.dart';
import '../recurrence/recurrence_schedule.dart';
import '../data_tables/business_validation.dart';
import 'workspace_commands.dart';

Never _invalid() =>
    throw const WorkspaceFailure(WorkspaceFailureCode.validation);

void validateWorkspaceId(String value) {
  if (!RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(value)) _invalid();
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

String? _date(Object? value) {
  if (value == null) return null;
  if (value is! String ||
      !RegExp(r'^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d{1,6})?Z$')
          .hasMatch(value)) {
    _invalid();
  }
  final parsed = DateTime.tryParse(value);
  // DateTime.parse normalizes impossible dates; reject those silently rolling over.
  if (parsed == null ||
      parsed.toIso8601String().substring(0, 19) != value.substring(0, 19)) {
    _invalid();
  }
  return parsed.toUtc().toIso8601String();
}

const todoDefaults = <String, Object?>{
  'title': '',
  'note': null,
  'status': 'pending',
  'priority': 'none',
  'due_at': null,
  'remind_at': null,
  'remind_rules': <Object?>[],
  'repeat_rule': null,
  'repeat_timezone': null,
  'series_id': null,
  'occurrence_key': null,
  'occurrence_index': null,
  'occurrence_at': null,
  'category_id': null,
  'source': 'manual',
  'source_message_id': null,
  'source_model': null,
  'source_provider': null,
  'steps': <Object?>[],
  'tags': <Object?>[],
  'sort_order': 0,
  'completed_at': null,
};
const categoryDefaults = <String, Object?>{
  'name': '',
  'color_value': 0xff808080,
  'icon_key': 'folder',
  'parent_id': null,
  'sort_order': 0,
  'archived': false,
};

Map<String, Object?> applyWorkspacePatch(
  WorkspaceEntityKind kind,
  Map<String, Object?>? before,
  Map<String, Object?> patch,
  DateTime now,
) {
  if (isBusinessEntity(kind)) return applyBusinessPatch(kind, before, patch);
  if (kind == WorkspaceEntityKind.series) {
    return _applySeriesPatch(before, patch, now);
  }
  final defaults = kind == WorkspaceEntityKind.todo
      ? todoDefaults
      : categoryDefaults;
  if (patch.keys.any((key) => !defaults.containsKey(key))) _invalid();
  final data = <String, Object?>{...defaults, ...?before, ...patch};
  if (data['sort_order'] is! int || (data['sort_order']! as int) < 0) {
    _invalid();
  }
  if (kind == WorkspaceEntityKind.category) {
    data['name'] = _text(data['name'], 200);
    data['icon_key'] = _text(data['icon_key'], 80);
    if (data['color_value'] is! int ||
        (data['color_value']! as int) < 0 ||
        (data['color_value']! as int) > 0xffffffff ||
        data['archived'] is! bool) {
      _invalid();
    }
    if (data['parent_id'] != null) {
      if (data['parent_id'] is! String) _invalid();
      validateWorkspaceId(data['parent_id']! as String);
    }
  } else {
    final steps = TodoStep.decode(data['steps']);
    if (steps.isEmpty) {
      data.remove(
        'steps',
      ); // Keep historical receipts and templates byte-compatible.
    } else {
      data['steps'] = [for (final s in steps) s.toJson()];
    }
    data['title'] = _text(data['title'], 2000);
    if (data['note'] != null &&
        (data['note'] is! String ||
            (data['note']! as String).length > 100000)) {
      _invalid();
    }
    if (!{
          'pending',
          'inProgress',
          'done',
          'cancelled',
        }.contains(data['status']) ||
        !{
          'none',
          'low',
          'medium',
          'high',
          'urgent',
        }.contains(data['priority']) ||
        !{'manual', 'ai'}.contains(data['source'])) {
      _invalid();
    }
    if (before != null && data['source'] != before['source']) _invalid();
    if (data['source_provider'] == null) {
      // Keep legacy proposal and undo snapshots byte-compatible.
      data.remove('source_provider');
    } else {
      _text(data['source_provider'], 80);
    }
    if (data['source_model'] != null) {
      final model = data['source_model'];
      // Display metadata only: bounded, inert, never a command.
      if (model is! String || model.isEmpty || model.length > 80) _invalid();
    }
    for (final key in ['category_id', 'source_message_id']) {
      if (data[key] != null) {
        if (data[key] is! String) _invalid();
        validateWorkspaceId(data[key]! as String);
      }
    }
    for (final key in ['due_at', 'remind_at', 'completed_at']) {
      data[key] = _date(data[key]);
    }
    // Completion affects this record. Recurrence materialization is a separate command.
    data['completed_at'] = data['status'] == 'done'
        ? data['completed_at'] ?? now.toUtc().toIso8601String()
        : null;
    final repeat = data['repeat_rule'];
    if (repeat != null &&
        (repeat is! String || repeat.trim().isEmpty || repeat.length > 2000)) {
      _invalid();
    }
    // Preserve unsupported legacy/imported rules during unrelated edits. A new
    // rule must be understood in full; never silently drop unsupported fields.
    if (repeat != null &&
        repeat != before?['repeat_rule'] &&
        RecurrenceRule.tryParse(repeat as String) == null) {
      _invalid();
    }
    final zone = data['repeat_timezone'];
    if (zone != null) {
      if (zone is! String) _invalid();
      try {
        RecurrenceTimeZones.location(zone);
      } on FormatException {
        _invalid();
      }
    }
    final identity = [
      'series_id',
      'occurrence_key',
      'occurrence_index',
      'occurrence_at',
    ];
    final present = identity.where((k) => data[k] != null).length;
    if (present != 0 && present != identity.length) _invalid();
    if (present != 0) {
      if (data['series_id'] is! String ||
          data['occurrence_key'] is! String ||
          data['occurrence_index'] is! int ||
          (data['occurrence_index']! as int) < 0) {
        _invalid();
      }
      validateWorkspaceId(data['series_id']! as String);
      final key = data['occurrence_key']! as String;
      if (key.endsWith('Z') ||
          _date('${key}Z')!.replaceFirst(RegExp(r'Z$'), '') != key) {
        _invalid();
      }
      data['occurrence_at'] = _date(data['occurrence_at']);
      if (before?['series_id'] != null &&
          before?['series_id'] == data['series_id']) {
        for (final key in [
          'occurrence_key',
          'occurrence_index',
          'occurrence_at',
        ]) {
          if (before?[key] != data[key]) _invalid();
        }
      }
    }
    final tags = data['tags'];
    if (tags is! List || tags.length > 100) _invalid();
    data['tags'] = tags.map((e) => _text(e, 100)).toSet().toList();
    final rules = data['remind_rules'];
    if (rules is! List || rules.length > 50) _invalid();
    final ids = <String>{};
    data['remind_rules'] = rules.map((rule) {
      if (rule is! Map<String, Object?> ||
          rule.keys.any(
            (k) => !{'id', 'offset_minutes', 'absolute_at'}.contains(k),
          )) {
        _invalid();
      }
      final id = _text(rule['id'], 128);
      validateWorkspaceId(id);
      if (!ids.add(id)) _invalid();
      final offset = rule['offset_minutes'];
      final absolute = rule['absolute_at'];
      if ((offset == null) == (absolute == null) ||
          (offset != null && offset is! int)) {
        _invalid();
      }
      return <String, Object?>{
        'id': id,
        'offset_minutes': offset,
        'absolute_at': _date(absolute),
      };
    }).toList();
  }
  return freezeWorkspaceJson(data);
}

/// Validate the final transaction state, including references created in the batch.
void validateWorkspaceGraph(Iterable<WorkspaceEntity> entities) {
  final all = entities.toList();
  validateBusinessGraph(all);
  final active = all.where((e) => !e.isDeleted).toList();
  final series = {
    for (final e in active.where((e) => e.kind == WorkspaceEntityKind.series))
      e.id: e,
  };
  final occurrenceKeys = <String>{}, occurrenceIndexes = <String>{};
  for (final e in all.where((e) => e.kind == WorkspaceEntityKind.todo)) {
    final id = e.data['series_id'];
    if (id == null) continue;
    if (!occurrenceKeys.add('$id/${e.data['occurrence_key']}') ||
        !occurrenceIndexes.add('$id/${e.data['occurrence_index']}')) {
      _invalid();
    }
    if (!e.isDeleted) {
      final owner = series[id];
      if (owner == null) _invalid();
      if (e.data['repeat_rule'] != owner.data['rule'] ||
          e.data['repeat_timezone'] != owner.data['timezone']) {
        _invalid();
      }
      if ((owner.data['excluded_indices']! as List).contains(
        e.data['occurrence_index'],
      )) {
        _invalid();
      }
      final stop = owner.data['stop_before'] as int?;
      if (stop != null &&
          (e.data['occurrence_index']! as int) >= stop &&
          {'pending', 'inProgress'}.contains(e.data['status'])) {
        _invalid();
      }
    }
  }
  for (final item in series.values) {
    final seen = <String>{item.id};
    var parent = item.data['parent_id'] as String?;
    while (parent != null) {
      if (!seen.add(parent) || !series.containsKey(parent)) _invalid();
      parent = series[parent]!.data['parent_id'] as String?;
    }
  }
  final categories = {
    for (final e in active.where((e) => e.kind == WorkspaceEntityKind.category))
      e.id: e,
  };
  for (final category in categories.values) {
    final parentId = category.data['parent_id'];
    if (parentId == null) continue;
    final parent = categories[parentId];
    if (parent == null ||
        parent.id == category.id ||
        parent.data['parent_id'] != null ||
        (parent.data['archived'] == true &&
            category.data['archived'] != true)) {
      _invalid();
    }
  }
  for (final item in series.values) {
    final category = (item.data['template']! as Map)['category_id'];
    if (item.data['stop_before'] != 0 &&
        category != null &&
        !categories.containsKey(category)) {
      _invalid();
    }
  }
  for (final todo in active.where((e) => e.kind == WorkspaceEntityKind.todo)) {
    final categoryId = todo.data['category_id'];
    if (categoryId != null && !categories.containsKey(categoryId)) _invalid();
  }
}

const seriesDefaults = <String, Object?>{
  'rule': '',
  'timezone': '',
  'anchor_at': null,
  'template': <String, Object?>{},
  'stop_before': null,
  'cursor_at': null,
  'cursor_index': -1,
  'parent_id': null,
  'fork_index': null,
  'excluded_indices': <Object?>[],
};

Map<String, Object?> _applySeriesPatch(
  Map<String, Object?>? before,
  Map<String, Object?> patch,
  DateTime now,
) {
  if (patch.keys.any((key) => !seriesDefaults.containsKey(key))) _invalid();
  final data = <String, Object?>{...seriesDefaults, ...?before, ...patch};
  if (data['rule'] is! String ||
      RecurrenceRule.tryParse(data['rule']! as String) == null ||
      data['timezone'] is! String ||
      data['anchor_at'] == null ||
      data['template'] is! Map<String, Object?>) {
    _invalid();
  }
  try {
    RecurrenceTimeZones.location(data['timezone']! as String);
  } on FormatException {
    _invalid();
  }
  data['anchor_at'] = _date(data['anchor_at']);
  data['cursor_at'] = _date(data['cursor_at']);
  final excluded = data['excluded_indices'];
  if (excluded is! List ||
      excluded.length > 100000 ||
      excluded.any((v) => v is! int || v < 0 || v > 100000) ||
      excluded.toSet().length != excluded.length) {
    _invalid();
  }
  data['excluded_indices'] = excluded.cast<int>().toList()..sort();
  final cursor = data['cursor_index'];
  final stop = data['stop_before'];
  if (cursor is! int ||
      cursor < -1 ||
      cursor > 100000 ||
      ((cursor == -1) != (data['cursor_at'] == null)) ||
      (stop != null && (stop is! int || stop < 0 || stop > 100000))) {
    _invalid();
  }
  if ((data['parent_id'] == null) != (data['fork_index'] == null)) _invalid();
  if (data['parent_id'] != null) {
    if (data['parent_id'] is! String ||
        data['fork_index'] is! int ||
        (data['fork_index']! as int) < 0) {
      _invalid();
    }
    validateWorkspaceId(data['parent_id']! as String);
  }
  // A split creates a new series. Do not mutate an existing series' calendar
  // identity beneath its already materialized instances.
  if (before != null) {
    for (final key in [
      'rule',
      'timezone',
      'anchor_at',
      'parent_id',
      'fork_index',
    ]) {
      if (canonicalWorkspaceJson(before[key]) !=
          canonicalWorkspaceJson(data[key])) {
        _invalid();
      }
    }
  }
  final template = applyWorkspacePatch(
    WorkspaceEntityKind.todo,
    before?['template'] as Map<String, Object?>?,
    data['template']! as Map<String, Object?>,
    now,
  );
  if (template['series_id'] != null ||
      template['status'] != 'pending' ||
      template['completed_at'] != null ||
      template['repeat_rule'] != data['rule'] ||
      template['repeat_timezone'] != data['timezone'] ||
      template['due_at'] != null ||
      template['remind_at'] != null ||
      (template['remind_rules']! as List).any(
        (r) => (r as Map)['absolute_at'] != null,
      )) {
    _invalid();
  }
  data['template'] = template;
  return freezeWorkspaceJson(data);
}
