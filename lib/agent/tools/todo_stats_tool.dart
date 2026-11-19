import '../../domain/ai/agent_run.dart';
import '../../domain/ai/model_gateway.dart';
import '../../domain/workspace/workspace_commands.dart';
import '../../domain/workspace/workspace_validation.dart';
import '../agent_time.dart';
import '../agent_tool_registry.dart';

/// 待办的聚合统计。「我这周完成了多少」「还有多少逾期」如果靠翻页清点，
/// 既费轮次又容易数错；这里一次给出按本地日期划分的计数。
class TodoStatsTool implements AgentReadTool {
  const TodoStatsTool();

  static const _priorities = ['urgent', 'high', 'medium', 'low', 'none'];

  @override
  String get name => 'todo_stats';

  @override
  JsonObject get schema => agentToolSchema(
    name,
    'Aggregated todo counts: open/overdue/due today/due within 7 days, '
    'breakdown by priority and category, and completions inside a window '
    '(default: the last 7 local days). Use it for progress, workload and '
    'review questions instead of paging todo_list. Counts cover '
    'materialized records only; future repeating occurrences beyond the '
    'generated window are not included.',
    {
      'completed_from': {
        'type': 'string',
        'description':
            'Inclusive start of the completion window, ISO-8601 with offset.',
      },
      'completed_before': {
        'type': 'string',
        'description': 'Exclusive end of the completion window.',
      },
      'category_id': {
        'type': 'string',
        'description': 'Limit to this category and its direct children.',
      },
    },
  );

  static Never _invalid() => throw const AgentFailure(AgentFailureCode.invalid);

  static DateTime? _instant(JsonObject args, String key) {
    final value = AgentTime.toUtc(args[key]);
    if (value == null) return null;
    if (value is! String) _invalid();
    final parsed = DateTime.tryParse(value);
    if (parsed == null || !value.endsWith('Z')) _invalid();
    return parsed.toUtc();
  }

  static DateTime? _stored(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;

  @override
  Object? call(JsonObject args, AgentToolContext context) {
    requireToolKeys(args, const {
      'completed_from',
      'completed_before',
      'category_id',
    });
    final offset = context.localOffset;
    final now = context.now.toUtc();
    // 本地「今天」的起点，再换回 UTC 与库内时间比较。
    final localNow = now.add(offset);
    final dayStart = DateTime.utc(
      localNow.year,
      localNow.month,
      localNow.day,
    ).subtract(offset);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final weekEnd = dayStart.add(const Duration(days: 7));
    final from =
        _instant(args, 'completed_from') ??
        dayStart.subtract(const Duration(days: 6));
    final before = _instant(args, 'completed_before') ?? dayEnd;
    if (!from.isBefore(before)) _invalid();

    Set<String>? scope;
    final category = args['category_id'];
    if (category != null) {
      if (category is! String) _invalid();
      validateWorkspaceId(category);
      final found = context.snapshot.find(
        WorkspaceEntityKind.category,
        category,
      );
      if (found == null || found.isDeleted) {
        return {'error': 'category_not_found', 'category_id': category};
      }
      scope = {
        category,
        for (final child in context.snapshot.categories)
          if (child.data['parent_id'] == category) child.id,
      };
    }

    final totals = {
      for (final status in ['pending', 'inProgress', 'done', 'cancelled'])
        status: 0,
    };
    final byPriority = {for (final p in _priorities) p: 0};
    final byCategory = <String?, int>{};
    var open = 0, overdue = 0, dueToday = 0, dueWeek = 0, noDue = 0;
    var completed = 0, onTime = 0, late = 0;
    for (final todo in context.snapshot.todos) {
      final data = todo.data;
      final categoryId = data['category_id'] as String?;
      if (scope != null && !scope.contains(categoryId)) continue;
      final status = data['status']! as String;
      totals[status] = (totals[status] ?? 0) + 1;
      final due = _stored(data['due_at']);
      if (status == 'pending' || status == 'inProgress') {
        open++;
        final priority = data['priority']! as String;
        byPriority[priority] = (byPriority[priority] ?? 0) + 1;
        byCategory[categoryId] = (byCategory[categoryId] ?? 0) + 1;
        if (due == null) {
          noDue++;
        } else if (due.isBefore(now)) {
          overdue++;
        } else {
          if (due.isBefore(dayEnd)) dueToday++;
          if (due.isBefore(weekEnd)) dueWeek++;
        }
      } else if (status == 'done') {
        final at = _stored(data['completed_at']);
        if (at != null && !at.isBefore(from) && at.isBefore(before)) {
          completed++;
          if (due != null) {
            if (at.isAfter(due)) {
              late++;
            } else {
              onTime++;
            }
          }
        }
      }
    }
    final categories = byCategory.entries.toList()
      ..sort((a, b) {
        final count = b.value.compareTo(a.value);
        return count != 0 ? count : (a.key ?? '').compareTo(b.key ?? '');
      });
    return {
      'as_of_local': AgentTime.local(now, offset),
      'open': {
        'total': open,
        'in_progress': totals['inProgress'],
        'overdue': overdue,
        'due_rest_of_today': dueToday,
        'due_within_7_days': dueWeek,
        'no_due_date': noDue,
        'by_priority': {
          for (final entry in byPriority.entries)
            if (entry.value > 0) entry.key: entry.value,
        },
        'by_category': [
          for (final entry in categories.take(20))
            {
              'category_id': entry.key,
              'name': entry.key == null
                  ? '未分类'
                  : context.snapshot
                            .find(WorkspaceEntityKind.category, entry.key!)
                            ?.data['name'] ??
                        '未知分类',
              'open': entry.value,
            },
        ],
      },
      'completed': {
        'from_local': AgentTime.local(from, offset),
        'before_local': AgentTime.local(before, offset),
        'count': completed,
        'on_time': onTime,
        'late': late,
      },
      'totals_by_status': totals,
    };
  }
}
