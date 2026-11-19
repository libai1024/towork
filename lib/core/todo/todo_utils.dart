import 'package:flutter/material.dart';

import '../../domain/models/models.dart';
import '../../domain/recurrence/recurrence_rule.dart';

/// 待办列表/详情的纯逻辑层（02-todo-list.md §3/§5、03-todo-detail.md §5）：
/// 快速过滤、分组、截止文案、RRULE 人话摘要。不持有状态，输入输出均为值。

enum TodoQuickFilter { all, today, week, overdue, noDue, done }

enum TodoGroupBy { category, due, priority }

extension TodoQuickFilterLabel on TodoQuickFilter {
  String get label => switch (this) {
    TodoQuickFilter.all => '全部',
    TodoQuickFilter.today => '今天',
    TodoQuickFilter.week => '本周',
    TodoQuickFilter.overdue => '逾期',
    TodoQuickFilter.noDue => '无截止',
    TodoQuickFilter.done => '已完成',
  };
}

extension TodoStatusLabel on TodoStatus {
  String get label => switch (this) {
    TodoStatus.pending => '待处理',
    TodoStatus.inProgress => '进行中',
    TodoStatus.done => '已完成',
    TodoStatus.cancelled => '已取消',
  };
}

extension TodoPriorityLabel on TodoPriority {
  String get label => switch (this) {
    TodoPriority.none => '无',
    TodoPriority.low => '低',
    TodoPriority.medium => '中',
    TodoPriority.high => '高',
    TodoPriority.urgent => '紧急',
  };
}

/// 截止徽标语义色阶（02 §3.4）。
enum DueTone { normal, today, overdue, done }

class TodoGroup {
  const TodoGroup({
    required this.key,
    required this.title,
    required this.todos,
    this.dotColor,
  });

  final String key;
  final String title;
  final List<Todo> todos;

  /// 按分类分组时的分类色点。
  final Color? dotColor;
}

DateTime dayOnly(DateTime t) => DateTime(t.year, t.month, t.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// 本周起点（周一）。
DateTime weekStart(DateTime now) =>
    dayOnly(now).subtract(Duration(days: now.weekday - 1));

/// 本周终点（周日）。
DateTime weekEnd(DateTime now) => weekStart(now).add(const Duration(days: 6));

bool _hasTime(DateTime t) => t.hour != 0 || t.minute != 0;

String twoDigits(int v) => v.toString().padLeft(2, '0');

String timeLabel(DateTime t) => '${twoDigits(t.hour)}:${twoDigits(t.minute)}';

/// 截止智能文案（03 §3.2 C 区）：今天 15:00 / 明天 15:00 / 9月25日 / 2027-01-05。
String dueSmartLabel(DateTime due, DateTime now) {
  final day = dayOnly(due);
  final today = dayOnly(now);
  final suffix = _hasTime(due) ? ' ${timeLabel(due)}' : '';
  if (day == today) return '今天$suffix';
  if (day == today.add(const Duration(days: 1))) return '明天$suffix';
  if (day == today.subtract(const Duration(days: 1))) return '昨天$suffix';
  if (due.year == now.year) return '${due.month}月${due.day}日$suffix';
  return '${due.year}-${twoDigits(due.month)}-${twoDigits(due.day)}';
}

/// 徽标语义色（02 §3.4）：逾期 red / 今天 orange / 已完成弱化 / 默认 fill。
DueTone dueToneOf(Todo todo, DateTime now) {
  if (!todo.isActive) return DueTone.done;
  if (todo.isOverdue(now)) return DueTone.overdue;
  if (todo.dueAt != null && isSameDay(todo.dueAt!, now)) return DueTone.today;
  return DueTone.normal;
}

/// 列表项右侧截止徽标文字（逾期带「已逾期」前缀，双通道不只靠颜色）。
String dueBadgeLabel(Todo todo, DateTime now) {
  final due = todo.dueAt;
  if (due == null) return '';
  if (todo.isOverdue(now)) {
    return '已逾期 ${dueSmartLabel(due, now)}';
  }
  return dueSmartLabel(due, now);
}

/// 详情页截止行下方的倒计时 caption。
String? countdownLabel(Todo todo, DateTime now) {
  final due = todo.dueAt;
  if (due == null || !todo.isActive) return null;
  final diff = due.difference(now);
  if (diff.isNegative) {
    final over = now.difference(due);
    if (over.inDays >= 1) return '已逾期 ${over.inDays} 天';
    if (over.inHours >= 1) return '已逾期 ${over.inHours} 小时';
    return '刚刚逾期';
  }
  if (diff.inDays >= 1) return '还剩 ${diff.inDays} 天';
  if (diff.inHours >= 1) return '还剩 ${diff.inHours} 小时';
  return '还剩 ${diff.inMinutes.clamp(1, 59)} 分钟';
}

/// 相对时间（溯源卡片、元信息）：今天 14:02 / 昨天 09:30 / 9月15日 / 2025-12-03。
String relativeTimeLabel(DateTime t, DateTime now) {
  final day = dayOnly(t);
  final today = dayOnly(now);
  if (day == today) return '今天 ${timeLabel(t)}';
  if (day == today.subtract(const Duration(days: 1))) {
    return '昨天 ${timeLabel(t)}';
  }
  if (t.year == now.year) return '${t.month}月${t.day}日';
  return '${t.year}-${twoDigits(t.month)}-${twoDigits(t.day)}';
}

/// 元信息区时间戳（yyyy-MM-dd HH:mm）。
String metaTimeLabel(DateTime t) =>
    '${t.year}-${twoDigits(t.month)}-${twoDigits(t.day)} ${timeLabel(t)}';

// ---------------------------------------------------------------------------
// 过滤与分组
// ---------------------------------------------------------------------------

/// 应用快速过滤 + 分类范围 + 搜索词。
List<Todo> filterTodos(
  List<Todo> todos,
  TodoQuickFilter filter,
  DateTime now, {
  Set<String>? categoryIds,
  String query = '',
  bool showCompleted = true,
}) {
  Iterable<Todo> r = todos;
  if (categoryIds != null) {
    r = r.where(
      (t) => t.categoryId != null && categoryIds.contains(t.categoryId),
    );
  }
  final q = query.trim();
  if (q.isNotEmpty) {
    r = r.where(
      (t) => t.title.contains(q) || (t.note != null && t.note!.contains(q)),
    );
  }
  final today = dayOnly(now);
  final monday = weekStart(now);
  final sunday = weekEnd(now);
  switch (filter) {
    case TodoQuickFilter.all:
      r = r.where((t) => showCompleted || t.isActive);
    case TodoQuickFilter.today:
      r = r.where(
        (t) => t.isActive && t.dueAt != null && isSameDay(t.dueAt!, today),
      );
    case TodoQuickFilter.week:
      r = r.where((t) {
        if (!t.isActive || t.dueAt == null) return false;
        final d = dayOnly(t.dueAt!);
        return !d.isBefore(monday) && !d.isAfter(sunday);
      });
    case TodoQuickFilter.overdue:
      r = r.where((t) => t.isOverdue(now));
    case TodoQuickFilter.noDue:
      r = r.where((t) => t.isActive && t.dueAt == null);
    case TodoQuickFilter.done:
      r = r.where(
        (t) => t.status == TodoStatus.done || t.status == TodoStatus.cancelled,
      );
  }
  return r.toList();
}

/// 过滤 Chip 计数（活跃口径，与 Chip 文字右侧小计数一致）。
int countForFilter(List<Todo> todos, TodoQuickFilter filter, DateTime now) =>
    filterTodos(todos, filter, now, showCompleted: false).length;

int _priorityRank(TodoPriority p) => switch (p) {
  TodoPriority.urgent => 0,
  TodoPriority.high => 1,
  TodoPriority.medium => 2,
  TodoPriority.low => 3,
  TodoPriority.none => 4,
};

List<Todo> _sortWithinGroup(List<Todo> todos, TodoQuickFilter filter) {
  final list = [...todos];
  if (filter == TodoQuickFilter.done) {
    list.sort(
      (a, b) => (b.completedAt ?? b.updatedAt ?? b.createdAt).compareTo(
        a.completedAt ?? a.updatedAt ?? a.createdAt,
      ),
    );
  } else {
    list.sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      if (byOrder != 0) return byOrder;
      return a.createdAt.compareTo(b.createdAt);
    });
  }
  return list;
}

/// 一级分类聚合：子分类的待办归到其父级分组。
Category? rootCategoryOf(Todo todo, List<Category> categories) {
  Category? byId(String? id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  final direct = byId(todo.categoryId);
  if (direct == null) return null;
  if (direct.parentId == null) return direct.archived ? null : direct;
  final parent = byId(direct.parentId);
  return (parent == null || parent.archived) ? null : parent;
}

/// 分组（02 §3.4）：分类按 sortOrder、未分类沉底；截止与优先级为固定序列。
List<TodoGroup> groupTodos(
  List<Todo> todos,
  TodoGroupBy by,
  List<Category> categories,
  DateTime now,
  TodoQuickFilter filter,
) {
  List<TodoGroup> fromBuckets(List<(String, String, List<Todo>, Color?)> defs) {
    final groups = <TodoGroup>[];
    for (final (key, title, items, color) in defs) {
      if (items.isEmpty) continue;
      groups.add(
        TodoGroup(
          key: key,
          title: title,
          todos: _sortWithinGroup(items, filter),
          dotColor: color,
        ),
      );
    }
    return groups;
  }

  switch (by) {
    case TodoGroupBy.category:
      final buckets = <String, List<Todo>>{};
      for (final t in todos) {
        final root = rootCategoryOf(t, categories);
        buckets.putIfAbsent(root?.id ?? '_none', () => []).add(t);
      }
      final defs = <(String, String, List<Todo>, Color?)>[];
      final roots =
          categories.where((e) => e.parentId == null && !e.archived).toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      for (final root in roots) {
        final items = buckets[root.id];
        if (items != null) defs.add((root.id, root.name, items, root.color));
      }
      final uncategorized = buckets['_none'];
      if (uncategorized != null) {
        defs.add(('_none', '未分类', uncategorized, null));
      }
      return fromBuckets(defs);
    case TodoGroupBy.due:
      final today = dayOnly(now);
      final tomorrow = today.add(const Duration(days: 1));
      final sunday = weekEnd(now);
      final overdue = <Todo>[];
      final todayL = <Todo>[];
      final tomorrowL = <Todo>[];
      final thisWeek = <Todo>[];
      final later = <Todo>[];
      final noDue = <Todo>[];
      for (final t in todos) {
        final due = t.dueAt;
        if (due == null) {
          noDue.add(t);
          continue;
        }
        final d = dayOnly(due);
        if (t.isActive && due.isBefore(now)) {
          overdue.add(t);
        } else if (d == today) {
          todayL.add(t);
        } else if (d == tomorrow) {
          tomorrowL.add(t);
        } else if (!d.isAfter(sunday)) {
          thisWeek.add(t);
        } else {
          later.add(t);
        }
      }
      return fromBuckets([
        ('overdue', '逾期', overdue, null),
        ('today', '今天', todayL, null),
        ('tomorrow', '明天', tomorrowL, null),
        ('week', '本周', thisWeek, null),
        ('later', '更晚', later, null),
        ('noDue', '无截止', noDue, null),
      ]);
    case TodoGroupBy.priority:
      final buckets = <TodoPriority, List<Todo>>{};
      for (final t in todos) {
        buckets.putIfAbsent(t.priority, () => []).add(t);
      }
      final ordered = [...buckets.keys]
        ..sort((a, b) => _priorityRank(a).compareTo(_priorityRank(b)));
      return fromBuckets([
        for (final p in ordered) ('p_${p.name}', p.label, buckets[p]!, null),
      ]);
  }
}

// ---------------------------------------------------------------------------
// RRULE 可视化编辑（03 §5.4）：人话 ⇄ RRULE 单向/反向映射
// ---------------------------------------------------------------------------

enum RepeatFreq { daily, weekly, monthly, yearly }

enum RepeatEnd { never, until, count }

class RepeatSpec {
  RepeatSpec({
    this.freq = RepeatFreq.weekly,
    this.interval = 1,
    Set<int>? weekdays,
    this.monthDay = 1,
    this.end = RepeatEnd.never,
    this.until,
    this.untilDateOnly = true,
    this.count = 5,
  }) : weekdays = weekdays ?? {DateTime.now().weekday};

  /// 1（周一）– 7（周日），仅 weekly。
  final Set<int> weekdays;
  RepeatFreq freq;
  int interval;
  int monthDay;
  RepeatEnd end;
  DateTime? until;
  bool untilDateOnly;
  int count;

  static const _byDayTokens = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

  String toRrule() {
    final freqToken = switch (freq) {
      RepeatFreq.daily => 'DAILY',
      RepeatFreq.weekly => 'WEEKLY',
      RepeatFreq.monthly => 'MONTHLY',
      RepeatFreq.yearly => 'YEARLY',
    };
    final parts = <String>['FREQ=$freqToken'];
    if (interval > 1) parts.add('INTERVAL=$interval');
    if (freq == RepeatFreq.weekly && weekdays.isNotEmpty) {
      final days = weekdays.toList()..sort();
      parts.add('BYDAY=${days.map((d) => _byDayTokens[d - 1]).join(',')}');
    }
    if (freq == RepeatFreq.monthly) parts.add('BYMONTHDAY=$monthDay');
    switch (end) {
      case RepeatEnd.never:
        break;
      case RepeatEnd.until:
        final u = until;
        if (u != null) {
          parts.add(
            'UNTIL=${u.year.toString().padLeft(4, '0')}${twoDigits(u.month)}${twoDigits(u.day)}${untilDateOnly ? '' : 'T235959'}',
          );
        }
      case RepeatEnd.count:
        parts.add('COUNT=$count');
    }
    return parts.join(';');
  }

  /// RRULE → 控件反向映射；无法映射返回 null（降级为只读）。
  static RepeatSpec? fromRrule(String rrule) {
    final parsed = RecurrenceRule.tryParse(rrule);
    if (parsed == null ||
        (parsed.count ?? 1) > 99 ||
        (parsed.frequency == RecurrenceFrequency.monthly &&
            parsed.monthDay == null)) {
      return null;
    }
    final until = parsed.until;
    // The visual editor can express end dates, not arbitrary UTC instants or
    // partial end days. Keep these valid engine rules read-only in this editor.
    if (until != null &&
        (parsed.untilIsUtc ||
            (!parsed.untilIsDate &&
                (until.hour != 23 ||
                    until.minute != 59 ||
                    until.second != 59)))) {
      return null;
    }
    final spec = RepeatSpec(
      freq: RepeatFreq.values.byName(parsed.frequency.name),
      interval: parsed.interval,
      weekdays: parsed.weekdays.toSet(),
      monthDay: parsed.monthDay ?? 1,
      count: parsed.count ?? 5,
      untilDateOnly: parsed.untilIsDate,
      end: parsed.count != null
          ? RepeatEnd.count
          : until != null
          ? RepeatEnd.until
          : RepeatEnd.never,
      until: until == null
          ? null
          : DateTime(until.year, until.month, until.day),
    );
    return spec;
  }

  /// 星期 chip 文案（周一=1 … 周日=7）。
  static const weekdayNames = ['一', '二', '三', '四', '五', '六', '日'];

  /// 人话摘要（编辑器底部主校验手段）。
  String summary() {
    final unit = switch (freq) {
      RepeatFreq.daily => '天',
      RepeatFreq.weekly => '周',
      RepeatFreq.monthly => '月',
      RepeatFreq.yearly => '年',
    };
    var head = interval == 1 ? '每$unit' : '每 $interval $unit';
    if (freq == RepeatFreq.weekly && weekdays.isNotEmpty) {
      final days = weekdays.toList()..sort();
      head += '（${days.map((d) => '周${weekdayNames[d - 1]}').join('、')}）';
    }
    if (freq == RepeatFreq.monthly) head += ' $monthDay 日';
    final tail = switch (end) {
      RepeatEnd.never => '永不结束',
      RepeatEnd.count => '共 $count 次',
      RepeatEnd.until =>
        until == null
            ? '永不结束'
            : '${until!.year} 年 ${until!.month} 月 ${until!.day} 日结束',
    };
    return '$head，$tail';
  }
}

/// 重复字段行的人话值（无规则 → 不重复）。
String repeatLabelOf(String? rrule) {
  if (rrule == null || rrule.isEmpty) return '不重复';
  final spec = RepeatSpec.fromRrule(rrule);
  return spec?.summary() ?? '自定义规则';
}

/// 提醒规则文案（03 §5.3）。
String remindRuleLabel(RemindRule rule) {
  final offset = rule.offsetMinutes;
  if (offset != null) {
    if (offset == 0) return '截止时';
    if (offset < 60) return '截止前 $offset 分钟';
    if (offset < 60 * 24) {
      final h = offset ~/ 60;
      final m = offset % 60;
      return m == 0 ? '截止前 $h 小时' : '截止前 $h 小时 $m 分钟';
    }
    final d = offset ~/ (60 * 24);
    final rest = offset % (60 * 24);
    if (rest == 0) return '截止前 $d 天';
    return '截止前 $d 天 ${rest ~/ 60} 小时';
  }
  final at = rule.absoluteAt;
  if (at != null) return '${at.month}月${at.day}日 ${timeLabel(at)}（自定义）';
  return '提醒';
}

/// 提醒字段行的值：第一条 + 「 +N」。
String remindSummaryOf(List<RemindRule> rules) {
  if (rules.isEmpty) return '关闭';
  final first = remindRuleLabel(rules.first);
  return rules.length == 1 ? first : '$first +${rules.length - 1}';
}
