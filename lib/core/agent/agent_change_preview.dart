import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../domain/ai/model_gateway.dart';
import '../../domain/workspace/workspace_commands.dart';
import '../../theme/app_text_styles.dart';
import '../todo/todo_utils.dart';
import 'agent_table_preview.dart';

/// 审批卡里一组提醒规则的读法：「准时、提前 30 分钟、11-15 14:30」。
String reminderRulesLabel(Object? value) {
  if (value is! List || value.isEmpty) return strings.noneLabel;
  return value
      .map((rule) {
        if (rule is! Map) return strings.reminder;
        final offset = rule['offset_minutes'];
        if (offset is int) {
          if (offset == 0) return strings.atTheDueTime;
          if (offset % 1440 == 0) return strings.daysBefore(offset ~/ 1440);
          if (offset % 60 == 0) return strings.hoursBefore(offset ~/ 60);
          return strings.minutesBefore(offset);
        }
        final at = rule['absolute_at'];
        final date = at is String ? DateTime.tryParse(at) : null;
        return date == null
            ? strings.reminder
            : DateFormat('MM-dd HH:mm').format(date.toLocal());
      })
      .join('、');
}

class AgentChangePreview extends ConsumerWidget {
  const AgentChangePreview({super.key, required this.change});
  final JsonObject change;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (change['table_intent'] != null) {
      return AgentTablePreview(change: change);
    }
    final categories = {
      for (final c in ref.watch(categoryListProvider)) c.id: c.name,
    };
    final before = ((change['before'] as Map?)?['data'] as Map?) ?? {};
    final after = (change['after'] as Map?) ?? {};
    final operation = switch (change['operation']) {
      'create' => context.strings.add,
      'edit' => context.strings.edit,
      'complete' => context.strings.complete,
      'delete' => context.strings.deleteLabel,
      _ => context.strings.change,
    };
    final table = change['business_table'];
    if (table is JsonObject) {
      final oldValues = (before['values'] as Map?) ?? {};
      final newValues = (after['values'] as Map?) ?? {};
      String cell(Map<Object?, Object?> values, String id) =>
          !values.containsKey(id)
          ? context.strings.notSet
          : values[id] == null
          ? context.strings.cleared
          : values[id] == true
          ? context.strings.yes
          : values[id] == false
          ? context.strings.no
          : values[id].toString();
      final rowId = (change['mutation']! as Map)['entity_id'];
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$operation ${table['name']}', style: AppTextStyles.subhead),
            Text(
              context.strings.record(rowId.toString()),
              style: AppTextStyles.caption,
            ),
            if ((change['uncertain_field_ids'] as List?)?.isNotEmpty == true)
              Text(
                context.strings.someFieldsAreUncertainCheckThemAgainst,
                style: AppTextStyles.footnote,
              ),
            for (final field in (table['fields']! as List).cast<JsonObject>())
              if (cell(oldValues, field['id']! as String) !=
                  cell(newValues, field['id']! as String))
                SelectableText(
                  '${field['name']}${field['unit'] == null ? '' : '（${field['unit']}）'}：${cell(oldValues, field['id']! as String)} → ${cell(newValues, field['id']! as String)}',
                  style: AppTextStyles.footnote,
                ),
          ],
        ),
      );
    }
    final labels = {
      'title': context.strings.title,
      'note': context.strings.notes,
      'status': context.strings.status,
      'priority': context.strings.priority,
      'due_at': context.strings.due,
      'remind_rules': context.strings.reminder,
      'category_id': context.strings.category,
      'steps': context.strings.steps,
      'tags': context.strings.tags,
      'completed_at': context.strings.completedAt,
      'repeat_rule': context.strings.recurrence,
      'repeat_timezone': context.strings.recurrenceTimeZone,
    };
    String show(Object? value, String key) {
      if (key == 'steps') {
        return (value as List? ?? const []).indexed
            .map((pair) {
              final step = pair.$2 as Map;
              return '${pair.$1 + 1}. ${step['title']}${step['done'] == true ? ' ✓' : ''}';
            })
            .join('\n');
      }
      if (key == 'repeat_rule') return repeatLabelOf(value as String?);
      if (key == 'remind_rules') return reminderRulesLabel(value);
      if (key == 'category_id' && value != null) {
        return categories[value] ?? context.strings.unavailableCategory;
      }
      if ((key == 'due_at' || key == 'completed_at') && value is String) {
        final date = DateTime.tryParse(value);
        if (date != null) {
          return DateFormat('yyyy-MM-dd HH:mm').format(date.toLocal());
        }
      }
      if (value == null || value == '') return context.strings.noneLabel;
      if (value is List) {
        return value.isEmpty ? context.strings.noneLabel : value.join('、');
      }
      return switch (value) {
        'done' => context.strings.completed,
        'pending' => context.strings.task,
        'inProgress' => context.strings.inProgress,
        'none' => context.strings.noneLabel,
        'high' => context.strings.high,
        'medium' => context.strings.medium,
        'low' => context.strings.low,
        'urgent' => context.strings.urgent,
        'cancelled' => context.strings.canceled,
        _ => '$value',
      };
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$operation ${after['title'] ?? before['title'] ?? context.strings.task}',
            style: AppTextStyles.subhead,
          ),
          if (change['effects'] is List) ...[
            const SizedBox(height: 4),
            Text(
              '${change['scope'] == 'current' ? context.strings.thisOccurrence : context.strings.thisAndFutureOccurrences} '
              '${context.strings.taskChanges((change['effects']! as List).where((e) => (e as Map)['kind'] == 'todo').length)}',
              style: AppTextStyles.footnote,
            ),
            Text(
              change['scope'] == 'current'
                  ? context.strings.onlyTheSelectedOccurrenceWillChangeOther
                  : change['operation'] == 'delete' ||
                        after['repeat_rule'] == null
                  ? context.strings.stopsFutureOccurrencesInThisRangeAnd
                  : context.strings.acceptOrRejectTheSeriesChangesTogether,
              style: AppTextStyles.footnote,
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                context.strings.viewAllChanges,
                style: AppTextStyles.footnote,
              ),
              children: [
                for (final effect
                    in (change['effects']! as List).cast<JsonObject>())
                  if (effect['kind'] == 'todo')
                    AgentChangePreview(change: effect)
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${context.strings.seriesTemplate}'
                        '${effect['operation'] == 'create' ? context.strings.newLabel : context.strings.update} '
                        '${repeatLabelOf(((effect['after'] as Map?) ?? (effect['before'] as Map?)?['data'])?['rule'] as String?)} '
                        '${context.strings.timeZone('${(effect['after'] as Map?)?['timezone']}')}'
                        '${(effect['after'] as Map?)?['stop_before'] == null ? context.strings.keepRepeating : context.strings.endBoundarySet}',
                        style: AppTextStyles.footnote,
                      ),
                    ),
              ],
            ),
          ],
          for (final entry in labels.entries)
            if (change['operation'] == 'delete'
                ? before[entry.key] != null
                : canonicalWorkspaceJson(before[entry.key]) !=
                      canonicalWorkspaceJson(after[entry.key]))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SelectableText(
                  change['operation'] == 'delete'
                      ? '${entry.value}：${show(before[entry.key], entry.key)}'
                      : '${entry.value}：${show(before[entry.key], entry.key)} → ${show(after[entry.key], entry.key)}',
                  style: AppTextStyles.footnote,
                ),
              ),
        ],
      ),
    );
  }
}
