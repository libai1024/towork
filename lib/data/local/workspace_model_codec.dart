import 'dart:ui' show Color;

import '../../domain/models/models.dart';
import '../../domain/ai/provider_catalog.dart';
import '../../domain/workspace/workspace_commands.dart';

Map<String, Object?> todoWorkspaceData(Todo todo) => {
  'title': todo.title,
  'note': todo.note,
  'status': todo.status.name,
  'priority': todo.priority.name,
  'due_at': todo.dueAt?.toUtc().toIso8601String(),
  'remind_at': todo.remindAt?.toUtc().toIso8601String(),
  'remind_rules': [
    for (final r in todo.remindRules)
      {
        'id': r.id,
        'offset_minutes': r.offsetMinutes,
        'absolute_at': r.absoluteAt?.toUtc().toIso8601String(),
      },
  ],
  'repeat_rule': todo.repeatRule,
  'repeat_timezone': todo.repeatTimezone,
  'series_id': todo.seriesId,
  'occurrence_key': todo.occurrenceKey,
  'occurrence_index': todo.occurrenceIndex,
  'occurrence_at': todo.occurrenceAt?.toUtc().toIso8601String(),
  'category_id': todo.categoryId,
  'source': todo.source.name,
  'source_message_id': todo.sourceMessageId,
  if (todo.sourceProvider != null)
    'source_provider': todo.sourceProvider!.wireId,
  if (todo.sourceModel != null) 'source_model': todo.sourceModel,
  'steps': [for (final step in todo.steps) step.toJson()],
  'tags': todo.tags,
  'sort_order': todo.sortOrder,
  'completed_at': todo.completedAt?.toUtc().toIso8601String(),
};
Map<String, Object?> categoryWorkspaceData(Category category) => {
  'name': category.name,
  'color_value': category.color.toARGB32(),
  'icon_key': category.iconKey,
  'parent_id': category.parentId,
  'sort_order': category.sortOrder,
  'archived': category.archived,
};
DateTime? _date(Object? value) =>
    value == null ? null : DateTime.parse(value as String).toLocal();
Todo workspaceTodo(WorkspaceEntity e) => Todo(
  id: e.id,
  version: e.version,
  title: e.data['title']! as String,
  note: e.data['note'] as String?,
  steps: TodoStep.decode(e.data['steps'] ?? const []),
  status: TodoStatus.values.byName(e.data['status']! as String),
  priority: TodoPriority.values.byName(e.data['priority']! as String),
  dueAt: _date(e.data['due_at']),
  remindAt: _date(e.data['remind_at']),
  remindRules: [
    if ((e.data['remind_rules']! as List).isEmpty &&
        e.data['remind_at'] != null)
      RemindRule(id: 'legacy', absoluteAt: _date(e.data['remind_at'])),
    for (final raw in e.data['remind_rules']! as List)
      RemindRule(
        id: (raw as Map)['id'] as String,
        offsetMinutes: raw['offset_minutes'] as int?,
        absoluteAt: _date(raw['absolute_at']),
      ),
  ],
  repeatRule: e.data['repeat_rule'] as String?,
  repeatTimezone: e.data['repeat_timezone'] as String?,
  seriesId: e.data['series_id'] as String?,
  occurrenceKey: e.data['occurrence_key'] as String?,
  occurrenceIndex: e.data['occurrence_index'] as int?,
  occurrenceAt: _date(e.data['occurrence_at']),
  categoryId: e.data['category_id'] as String?,
  source: TodoSource.values.byName(e.data['source']! as String),
  sourceMessageId: e.data['source_message_id'] as String?,
  sourceModel: e.data['source_model'] as String?,
  sourceProvider: e.data['source_provider'] == null
      ? null
      : ProviderKind.values.firstWhere(
          (p) => p.wireId == e.data['source_provider'],
          orElse: () => ProviderKind.custom,
        ),
  tags: (e.data['tags']! as List).cast<String>(),
  sortOrder: e.data['sort_order']! as int,
  createdAt: e.createdAt.toLocal(),
  updatedAt: e.updatedAt.toLocal(),
  completedAt: _date(e.data['completed_at']),
);
Category workspaceCategory(WorkspaceEntity e) => Category(
  id: e.id,
  version: e.version,
  name: e.data['name']! as String,
  color: Color(e.data['color_value']! as int),
  iconKey: e.data['icon_key']! as String,
  parentId: e.data['parent_id'] as String?,
  sortOrder: e.data['sort_order']! as int,
  archived: e.data['archived']! as bool,
);
