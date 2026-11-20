import 'package:towork/l10n/strings.dart';

import '../../domain/models/models.dart';

/// 日程可视化派生统计（05-visualization.md §8）。
/// 纯函数：输入 mock 仓库的原始列表，输出各图表可直接消费的结构。

DateTime dayOnly(DateTime t) => DateTime(t.year, t.month, t.day);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// 所在周的周一（周起点，规范与设计稿均为周一在上）。
DateTime mondayOf(DateTime day) {
  final d = dayOnly(day);
  return d.subtract(Duration(days: d.weekday - DateTime.monday));
}

/// 热力图统计口径。
enum HeatMetric {
  completed('完成 Todo 数', '件', ['0', '1', '2–3', '4–6', '7+']),
  created('新增 Todo 数', '件', ['0', '1', '2–3', '4–6', '7+']),
  dataRows('新增数据条数', '条', ['0', '1–2', '3–5', '6–9', '10+']);

  const HeatMetric(this._label, this._unit, this.thresholdLabels);

  final String _label;
  String get label => localizedBuiltin(_label);
  final String _unit;
  String get unit => localizedBuiltin(_unit);

  /// 5 档色阶对应的数值区间文字（图例与无障碍朗读用）。
  final List<String> thresholdLabels;
}

/// 勾选的一级分类展开为「自身 + 全部子分类」id 集合。
Set<String> expandCategoryIds(
  Set<String> selectedRoots,
  List<Category> categories,
) {
  final ids = <String>{};
  for (final rootId in selectedRoots) {
    ids.add(rootId);
    for (final cat in categories) {
      if (cat.parentId == rootId) ids.add(cat.id);
    }
  }
  return ids;
}

/// 全局分类过滤：空集合 = 全部；否则只保留勾选分类树内的 Todo。
List<Todo> filterTodosByRoots(
  List<Todo> todos,
  Set<String> selectedRoots,
  List<Category> categories,
) {
  if (selectedRoots.isEmpty) return todos;
  final ids = expandCategoryIds(selectedRoots, categories);
  return todos
      .where((t) => t.categoryId != null && ids.contains(t.categoryId))
      .toList();
}

/// 向上找到一级分类 id；未分类返回 null。
String? rootIdOf(String? categoryId, List<Category> categories) {
  if (categoryId == null) return null;
  Category? current;
  for (final c in categories) {
    if (c.id == categoryId) {
      current = c;
      break;
    }
  }
  var guard = 0;
  while (current?.parentId != null && guard++ < 8) {
    final parentId = current!.parentId;
    Category? parent;
    for (final c in categories) {
      if (c.id == parentId) {
        parent = c;
        break;
      }
    }
    current = parent;
  }
  return current?.id;
}

/// 热力图日粒度计数：key 为当日零点。
Map<DateTime, int> heatmapCounts({
  required List<Todo> todos,
  required HeatMetric metric,
  required List<DataRow> dataRows,
}) {
  final map = <DateTime, int>{};
  void bump(DateTime? t) {
    if (t == null) return;
    final d = dayOnly(t);
    map[d] = (map[d] ?? 0) + 1;
  }

  switch (metric) {
    case HeatMetric.completed:
      for (final t in todos) {
        bump(t.completedAt);
      }
    case HeatMetric.created:
      for (final t in todos) {
        bump(t.createdAt);
      }
    case HeatMetric.dataRows:
      for (final r in dataRows) {
        bump(r.updatedAt);
      }
  }
  return map;
}

/// 5 档色阶（05 文档 §3.2）：0 / 1 / 2–3 / 4–6 / 7+，
/// 数据条数口径缩放为 0 / 1–2 / 3–5 / 6–9 / 10+。
int heatLevel(int count, HeatMetric metric) {
  if (count <= 0) return 0;
  final steps = metric == HeatMetric.dataRows
      ? const [1, 3, 6, 10]
      : const [1, 2, 4, 7];
  var level = 0;
  for (final s in steps) {
    if (count >= s) level++;
  }
  return level;
}

/// 分类分布饼图/柱状图的一片（按一级分类聚合）。
class CategorySlice {
  const CategorySlice({
    required this.rootId,
    required this.category,
    required this.total,
    required this.done,
  });

  /// 一级分类 id；null = 未分类。
  final String? rootId;

  /// 一级分类实体；未分类为 null（UI 层用 fill4 兜底色）。
  final Category? category;
  final int total;
  final int done;

  double get rate => total == 0 ? 0 : done / total;
}

/// 分类分布：统计近 [days] 天内创建的 Todo，按一级分类聚合，数量降序。
List<CategorySlice> distributionSlices(
  List<Todo> todos,
  List<Category> categories, {
  int days = 90,
}) {
  final cutoff = dayOnly(DateTime.now()).subtract(Duration(days: days));
  final byRoot = <String?, _Agg>{};
  for (final t in todos) {
    if (t.createdAt.isBefore(cutoff)) continue;
    final agg = byRoot.putIfAbsent(
      rootIdOf(t.categoryId, categories),
      _Agg.new,
    );
    agg.total++;
    if (t.status == TodoStatus.done) agg.done++;
  }
  Category? byId(String? id) {
    if (id == null) return null;
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  final slices = [
    for (final e in byRoot.entries)
      CategorySlice(
        rootId: e.key,
        category: byId(e.key),
        total: e.value.total,
        done: e.value.done,
      ),
  ]..sort((a, b) => b.total.compareTo(a.total));
  return slices;
}

class _Agg {
  int total = 0;
  int done = 0;
}

/// 趋势图一周的数据点。
class WeekPoint {
  const WeekPoint({
    required this.monday,
    required this.created,
    required this.completed,
  });

  final DateTime monday;
  final int created;
  final int completed;

  int get weekNumber => isoWeekNumber(monday);
}

/// 近 [weeks] 周（含本周）的创建 vs 完成序列，按时间升序。
List<WeekPoint> weeklyTrend(List<Todo> todos, int weeks) {
  final thisMonday = mondayOf(DateTime.now());
  return [
    for (var i = weeks - 1; i >= 0; i--)
      _countInWeek(todos, thisMonday.subtract(Duration(days: 7 * i))),
  ];
}

/// 上一个等长周期的合计（环比结论行用）。
WeekPoint previousPeriodTotals(List<Todo> todos, int weeks) {
  final end = mondayOf(DateTime.now());
  final start = end.subtract(Duration(days: 7 * weeks));
  var created = 0, completed = 0;
  for (final t in todos) {
    if (!t.createdAt.isBefore(start) && t.createdAt.isBefore(end)) created++;
    final c = t.completedAt;
    if (c != null && !c.isBefore(start) && c.isBefore(end)) completed++;
  }
  return WeekPoint(monday: start, created: created, completed: completed);
}

WeekPoint _countInWeek(List<Todo> todos, DateTime monday) {
  final end = monday.add(const Duration(days: 7));
  var created = 0, completed = 0;
  for (final t in todos) {
    if (!t.createdAt.isBefore(monday) && t.createdAt.isBefore(end)) created++;
    final c = t.completedAt;
    if (c != null && !c.isBefore(monday) && c.isBefore(end)) completed++;
  }
  return WeekPoint(monday: monday, created: created, completed: completed);
}

/// 数据跨度（最早创建日到今天的天数），趋势图 <14 天降级。
int dataSpanDays(List<Todo> todos) {
  DateTime? earliest;
  for (final t in todos) {
    if (earliest == null || t.createdAt.isBefore(earliest)) {
      earliest = t.createdAt;
    }
  }
  if (earliest == null) return 0;
  return dayOnly(DateTime.now()).difference(dayOnly(earliest)).inDays;
}

List<String> get weekdayLabels => [
  strings.mon,
  strings.tue,
  strings.wed,
  strings.thu,
  strings.fri,
  strings.sat,
  strings.weekdaySunday,
];

String weekdayLabel(DateTime day) => weekdayLabels[day.weekday - 1];
