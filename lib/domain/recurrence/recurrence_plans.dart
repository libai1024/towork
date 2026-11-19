import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../workspace/workspace_commands.dart';
import '../workspace/workspace_validation.dart';
import 'recurrence_rule.dart';
import 'recurrence_schedule.dart';

enum RecurrenceScope { current, currentAndFuture }

/// Pure plans are prepared from the displayed snapshot. Keep the returned
/// command intact when retrying; the shared store owns CAS, atomicity and undo.
class RecurrencePlans {
  RecurrencePlans(this.snapshot, {required this.now});
  final WorkspaceSnapshot snapshot;
  final DateTime now;

  static String seriesIdFor(String operationId) =>
      'series_${sha256.convert(utf8.encode(operationId))}';
  static String _key(RecurrenceOccurrence occurrence) =>
      occurrence.nominal.toIso8601String().replaceFirst(RegExp(r'Z$'), '');
  static const _identity = {
    'series_id': null,
    'occurrence_key': null,
    'occurrence_index': null,
    'occurrence_at': null,
  };
  static const _editable = {
    'title',
    'note',
    'priority',
    'due_at',
    'remind_at',
    'remind_rules',
    'category_id',
    'tags',
    'sort_order',
    'repeat_rule',
    'repeat_timezone',
  };

  WorkspaceEntity _todo(String id) => _entity(WorkspaceEntityKind.todo, id);
  WorkspaceEntity _entity(WorkspaceEntityKind kind, String id) {
    final item = snapshot.find(kind, id);
    if (item == null || item.isDeleted) {
      throw WorkspaceFailure(WorkspaceFailureCode.notFound, entityId: id);
    }
    return item;
  }

  Never _invalid() =>
      throw const WorkspaceFailure(WorkspaceFailureCode.validation);

  Map<String, Object?> _template(
    Map<String, Object?> data,
    String rule,
    String zone,
  ) => {
    ...data, ..._identity, 'status': 'pending', 'completed_at': null,
    'due_at': null,
    'remind_at': null,
    'repeat_rule': rule,
    'repeat_timezone': zone,
    // Absolute reminders refer to one instant; only relative reminders recur.
    'remind_rules': [
      for (final raw in data['remind_rules']! as List)
        if ((raw as Map)['offset_minutes'] != null) raw,
    ],
  };

  RecurrenceSchedule _schedule(Map<String, Object?> series) {
    try {
      return RecurrenceSchedule(
        rule: RecurrenceRule.parse(series['rule']! as String),
        anchor: DateTime.parse(series['anchor_at']! as String),
        timezone: series['timezone']! as String,
      );
    } on FormatException {
      _invalid();
    }
  }

  WorkspaceCommand start(
    String todoId, {
    required String rule,
    required String timezone,
    required String operationId,
    required DateTime through,
    int limit = 64,
  }) {
    final todo = _todo(todoId);
    if (todo.data['series_id'] != null || todo.data['due_at'] == null) {
      _invalid();
    }
    final draft = _RecurrenceDraft(snapshot, now);
    final seriesId = seriesIdFor(operationId);
    final data = <String, Object?>{
      ...seriesDefaults,
      'rule': rule,
      'timezone': timezone,
      'anchor_at': todo.data['due_at'],
      'template': _template(todo.data, rule, timezone),
    };
    final first = _schedule(data).occurrences(limit: 1);
    if (first.isEmpty) _invalid();
    data['cursor_at'] = first.single.dueAt.toIso8601String();
    data['cursor_index'] = 0;
    draft.create(WorkspaceEntityKind.series, seriesId, data);
    draft.patch(todo, {
      'repeat_rule': rule,
      'repeat_timezone': timezone,
      ..._instance(seriesId, first.single),
    });
    _generate(draft, seriesId, through, limit);
    return draft.command(operationId)!;
  }

  Map<String, Object?> _instance(
    String seriesId,
    RecurrenceOccurrence occurrence,
  ) => {
    'series_id': seriesId,
    'occurrence_key': _key(occurrence),
    'occurrence_index': occurrence.index,
    'occurrence_at': occurrence.dueAt.toIso8601String(),
  };

  /// At most [limit] new slots per transaction. Call again from a fresh snapshot
  /// until no plan is returned; the cursor is advanced in the same transaction.
  WorkspaceCommand? materialize(
    String seriesId, {
    required DateTime through,
    required String operationId,
    int limit = 64,
  }) {
    _entity(WorkspaceEntityKind.series, seriesId);
    final draft = _RecurrenceDraft(snapshot, now);
    _generate(draft, seriesId, through, limit);
    return draft.command(operationId, source: 'system');
  }

  void _generate(
    _RecurrenceDraft draft,
    String id,
    DateTime through,
    int limit,
  ) {
    if (limit < 1 || limit > 400) _invalid();
    final series = draft.get(WorkspaceEntityKind.series, id);
    final cursor = series.data['cursor_index']! as int;
    final stop = series.data['stop_before'] as int?;
    if (stop != null && cursor >= stop - 1) return;
    final dates = _schedule(series.data).occurrences(
      after: series.data['cursor_at'] == null
          ? null
          : DateTime.parse(series.data['cursor_at']! as String),
      before: through,
      limit: limit,
    );
    final known = {
      for (final e in draft.entities.values.where(
        (e) => e.kind == WorkspaceEntityKind.todo && e.data['series_id'] == id,
      ))
        e.data['occurrence_key']: e,
    };
    RecurrenceOccurrence? last;
    for (final occurrence in dates) {
      if (stop != null && occurrence.index >= stop) break;
      final previous = known[_key(occurrence)];
      // Tombstones are durable single-instance exceptions, not missing slots.
      if ((series.data['excluded_indices']! as List).contains(
        occurrence.index,
      )) {
        last = occurrence;
        continue;
      }
      if (previous == null) {
        draft.create(WorkspaceEntityKind.todo, occurrence.stableId(id), {
          ...(series.data['template']! as Map<String, Object?>),
          ..._instance(id, occurrence),
          'due_at': occurrence.dueAt.toIso8601String(),
        });
      } else if (previous.data['occurrence_index'] != occurrence.index) {
        _invalid();
      }
      last = occurrence;
    }
    if (last != null) {
      draft.patch(series, {
        'cursor_at': last.dueAt.toIso8601String(),
        'cursor_index': last.index,
      });
    }
  }

  WorkspaceCommand complete(
    String todoId, {
    required String operationId,
    bool completed = true,
  }) {
    final draft = _RecurrenceDraft(snapshot, now);
    draft.patch(_todo(todoId), {'status': completed ? 'done' : 'pending'});
    // Idempotent completion callers still receive a versioned receipt.
    return draft.command(operationId, keepNoop: true)!;
  }

  WorkspaceCommand edit(
    String todoId,
    Map<String, Object?> patch, {
    required RecurrenceScope scope,
    required String operationId,
    required DateTime through,
    int limit = 64,
  }) {
    if (patch.isEmpty || patch.keys.any((key) => !_editable.contains(key))) {
      _invalid();
    }
    final todo = _todo(todoId);
    final id = todo.data['series_id'] as String?;
    if (id == null) _invalid();
    final draft = _RecurrenceDraft(snapshot, now);
    if (scope == RecurrenceScope.current) {
      for (final key in ['repeat_rule', 'repeat_timezone']) {
        if (patch.containsKey(key) && patch[key] != todo.data[key]) _invalid();
      }
      draft.patch(todo, patch);
      return draft.command(operationId, keepNoop: true)!;
    }
    final oldSeries = _entity(WorkspaceEntityKind.series, id);
    final split = todo.data['occurrence_index']! as int;
    final previousStop = oldSeries.data['stop_before'] as int?;
    if (previousStop != null && split >= previousStop) _invalid();
    final excluded = _truncate(draft, oldSeries, split, except: todo.id);
    if (patch.containsKey('repeat_rule') && patch['repeat_rule'] == null) {
      draft.patch(todo, {
        ...patch,
        ..._identity,
        'repeat_rule': null,
        'repeat_timezone': null,
      });
      return draft.command(operationId)!;
    }
    final oldRule = oldSeries.data['rule']! as String;
    var rule = patch['repeat_rule'] as String? ?? oldRule;
    // An explicitly changed COUNT starts at the selected occurrence. Otherwise
    // continue the original total, even when some instances were missed/deleted.
    if (!patch.containsKey('repeat_rule') || rule == oldRule) {
      final end = _effectiveEnd(oldSeries);
      final parts = oldRule
          .split(';')
          .where((p) => !p.startsWith('COUNT=') && !p.startsWith('UNTIL='))
          .toList();
      if (end.count != null) {
        if (end.count! <= split) _invalid();
        parts.add('COUNT=${end.count! - split}');
      } else if (end.until != null) {
        parts.add(end.until!);
      }
      rule = parts.join(';');
    }
    final zone = patch.containsKey('repeat_timezone')
        ? patch['repeat_timezone']
        : oldSeries.data['timezone'];
    final anchor = patch.containsKey('due_at')
        ? patch['due_at']
        : todo.data['occurrence_at'];
    if (zone is! String || anchor is! String) _invalid();
    final seriesId = seriesIdFor(operationId);
    final template = applyWorkspacePatch(
      WorkspaceEntityKind.todo,
      oldSeries.data['template']! as Map<String, Object?>,
      {...patch, 'repeat_rule': rule, 'repeat_timezone': zone},
      now,
    );
    final data = <String, Object?>{
      ...seriesDefaults,
      'rule': rule,
      'timezone': zone,
      'anchor_at': anchor,
      'template': _template(template, rule, zone),
      'parent_id': oldSeries.id,
      'fork_index': split,
      'excluded_indices': excluded.toList()..sort(),
    };
    final first = _schedule(data).occurrences(limit: 1);
    if (first.isEmpty) _invalid();
    data['cursor_at'] = first.single.dueAt.toIso8601String();
    data['cursor_index'] = 0;
    draft.create(WorkspaceEntityKind.series, seriesId, data);
    draft.patch(todo, {
      ...patch,
      'repeat_rule': rule,
      'repeat_timezone': zone,
      ..._instance(seriesId, first.single),
    });
    _generate(draft, seriesId, through, limit);
    return draft.command(operationId)!;
  }

  WorkspaceCommand delete(
    String todoId, {
    required RecurrenceScope scope,
    required String operationId,
  }) {
    final todo = _todo(todoId);
    final draft = _RecurrenceDraft(snapshot, now);
    if (scope == RecurrenceScope.currentAndFuture) {
      final id = todo.data['series_id'];
      if (id is! String) _invalid();
      final owner = _entity(WorkspaceEntityKind.series, id);
      final index = todo.data['occurrence_index']! as int;
      final stop = owner.data['stop_before'] as int?;
      if (stop != null && index >= stop) _invalid();
      _truncate(draft, owner, index, except: todo.id);
    }
    draft.delete(todo);
    return draft.command(operationId)!;
  }

  /// Resolve the effective ordinal end through previous splits. A later segment
  /// may have changed COUNT or ended early; editing an earlier segment must not
  /// silently restart a future that the user already removed.
  ({int? count, String? until}) _effectiveEnd(WorkspaceEntity series) {
    final stop = series.data['stop_before'] as int?;
    if (stop == null) {
      final rule = series.data['rule']! as String;
      final until = rule.split(';').where((p) => p.startsWith('UNTIL='));
      return (
        count: RecurrenceRule.parse(rule).count,
        until: until.isEmpty ? null : until.single,
      );
    }
    final next = snapshot.series
        .where(
          (s) =>
              s.data['parent_id'] == series.id &&
              s.data['fork_index'] == stop &&
              s.data['stop_before'] != 0,
        )
        .toList();
    if (next.length > 1) _invalid();
    if (next.isEmpty) return (count: stop, until: null);
    final tail = _effectiveEnd(next.single);
    return (
      count: tail.count == null ? null : stop + tail.count!,
      until: tail.until,
    );
  }

  /// A later edit from an older segment also closes its successor segments;
  /// otherwise editing before an earlier split would leave duplicate futures.
  Set<int> _truncate(
    _RecurrenceDraft draft,
    WorkspaceEntity series,
    int index, {
    required String except,
  }) {
    final cutoffs = <String, int>{series.id: index};
    final offsets = <String, int>{series.id: 0};
    var changed = true;
    while (changed) {
      changed = false;
      for (final child in snapshot.series) {
        final parentCut = cutoffs[child.data['parent_id']];
        if (!cutoffs.containsKey(child.id) &&
            parentCut != null &&
            (child.data['fork_index']! as int) >= parentCut) {
          cutoffs[child.id] = 0;
          offsets[child.id] =
              offsets[child.data['parent_id']]! +
              (child.data['fork_index']! as int);
          changed = true;
        }
      }
    }
    final excluded = <int>{};
    for (final entry in cutoffs.entries) {
      final item = draft.get(WorkspaceEntityKind.series, entry.key);
      final oldStop = item.data['stop_before'] as int?;
      final localExcluded = (item.data['excluded_indices']! as List)
          .cast<int>()
          .toSet();
      // Tombstones inside the old valid range are explicit single deletions.
      // Tombstones outside it came from an earlier split and must not cancel
      // its successor a second time. Persist the distinction before truncating.
      for (final record in snapshot.entities.values) {
        if (record.kind == WorkspaceEntityKind.todo &&
            record.isDeleted &&
            record.data['series_id'] == item.id) {
          final n = record.data['occurrence_index']! as int;
          if (oldStop == null || n < oldStop) localExcluded.add(n);
        }
      }
      for (final n in localExcluded) {
        final relative = offsets[entry.key]! + n - index;
        if (relative > 0) excluded.add(relative);
      }
      draft.patch(item, {
        'stop_before': oldStop == null || entry.value < oldStop
            ? entry.value
            : oldStop,
        'excluded_indices': localExcluded.toList()..sort(),
      });
    }
    for (final item in snapshot.todos) {
      final cutoff = cutoffs[item.data['series_id']];
      if (cutoff != null &&
          item.id != except &&
          (item.data['occurrence_index']! as int) >= cutoff &&
          {'done', 'cancelled'}.contains(item.data['status'])) {
        final relative =
            offsets[item.data['series_id']]! +
            (item.data['occurrence_index']! as int) -
            index;
        if (relative > 0) excluded.add(relative);
      }
      if (cutoff != null &&
          item.id != except &&
          (item.data['occurrence_index']! as int) >= cutoff &&
          {'pending', 'inProgress'}.contains(item.data['status'])) {
        draft.delete(item);
      }
    }
    return excluded;
  }
}

class _RecurrenceDraft {
  _RecurrenceDraft(this.original, this.now) : entities = {...original.entities};
  final WorkspaceSnapshot original;
  final DateTime now;
  final Map<String, WorkspaceEntity> entities;
  final Set<String> changed = {};

  WorkspaceEntity get(WorkspaceEntityKind kind, String id) =>
      entities['${kind.name}:$id']!;
  void create(WorkspaceEntityKind kind, String id, Map<String, Object?> data) {
    validateWorkspaceId(id);
    if (entities.containsKey('${kind.name}:$id')) {
      throw WorkspaceFailure(
        WorkspaceFailureCode.versionConflict,
        entityId: id,
      );
    }
    _put(kind, id, applyWorkspacePatch(kind, null, data, now));
  }

  void patch(WorkspaceEntity entity, Map<String, Object?> patch) {
    final current = get(entity.kind, entity.id);
    _put(
      entity.kind,
      entity.id,
      applyWorkspacePatch(entity.kind, current.data, patch, now),
    );
  }

  void delete(WorkspaceEntity entity) =>
      _put(entity.kind, entity.id, entity.data, deleted: true);
  void _put(
    WorkspaceEntityKind kind,
    String id,
    Map<String, Object?> data, {
    bool deleted = false,
  }) {
    final old = original.find(kind, id);
    final item = WorkspaceEntity(
      kind: kind,
      id: id,
      version: (old?.version ?? 0) + 1,
      data: data,
      createdAt: old?.createdAt ?? now,
      updatedAt: now,
      deletedAt: deleted ? now : null,
    );
    entities[item.key] = item;
    changed.add(item.key);
  }

  WorkspaceCommand? command(
    String id, {
    String source = 'manual',
    bool keepNoop = false,
  }) {
    validateWorkspaceId(id);
    validateWorkspaceGraph(entities.values);
    final actions = <WorkspaceMutation>[];
    for (final key in changed) {
      final old = original.entities[key], next = entities[key]!;
      if (!keepNoop &&
          old != null &&
          old.isDeleted == next.isDeleted &&
          canonicalWorkspaceJson(old.data) ==
              canonicalWorkspaceJson(next.data)) {
        continue;
      }
      actions.add(
        WorkspaceMutation(
          actionId: sha256.convert(utf8.encode(key)).toString(),
          kind: next.kind,
          entityId: next.id,
          expectedVersion: old?.version,
          mutation: old == null
              ? WorkspaceMutationKind.create
              : next.isDeleted
              ? WorkspaceMutationKind.delete
              : WorkspaceMutationKind.update,
          patch: next.isDeleted ? {} : next.data,
        ),
      );
    }
    if (actions.length > 500) {
      throw const WorkspaceFailure(WorkspaceFailureCode.validation);
    }
    return actions.isEmpty
        ? null
        : WorkspaceCommand(operationId: id, source: source, actions: actions);
  }
}
