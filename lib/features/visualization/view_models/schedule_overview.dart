import '../../../domain/models/models.dart';
import '../viz_stats.dart';

/// Date-scoped projection of shared tasks. Undated and cancelled records do not
/// occupy calendar days; category and text filters apply to marks and agenda.
class ScheduleOverview {
  ScheduleOverview._({
    required this.day,
    required this.now,
    required this.pending,
    required this.completed,
    required this.dayCounts,
  });

  factory ScheduleOverview.from({
    required List<Todo> todos,
    required List<Category> categories,
    required DateTime day,
    required DateTime now,
    Set<String> selectedRoots = const {},
    String search = '',
  }) {
    final query = search.trim().toLowerCase();
    final categoryById = {for (final c in categories) c.id: c};
    final scoped = filterTodosByRoots(todos, selectedRoots, categories);
    final counts = <DateTime, int>{};
    final pending = <Todo>[];
    final completed = <Todo>[];
    for (final todo in scoped) {
      if (todo.dueAt == null || todo.status == TodoStatus.cancelled) continue;
      final category = categoryById[todo.categoryId];
      final root = categoryById[category?.parentId];
      if (query.isNotEmpty &&
          !'${todo.title} ${category?.name ?? ''} ${root?.name ?? ''}'
              .toLowerCase()
              .contains(query)) {
        continue;
      }
      final date = dayOnly(todo.dueAt!.toLocal());
      counts.update(date, (value) => value + 1, ifAbsent: () => 1);
      if (!sameDay(date, day)) continue;
      if (todo.isActive) pending.add(todo);
      if (todo.status == TodoStatus.done) completed.add(todo);
    }
    int order(Todo a, Todo b) {
      final result = a.dueAt!.compareTo(b.dueAt!);
      return result == 0 ? a.sortOrder.compareTo(b.sortOrder) : result;
    }

    pending.sort(order);
    completed.sort(order);
    return ScheduleOverview._(
      day: dayOnly(day),
      now: now,
      pending: List.unmodifiable(pending),
      completed: List.unmodifiable(completed),
      dayCounts: Map.unmodifiable(counts),
    );
  }

  final DateTime day;
  final DateTime now;
  final List<Todo> pending;
  final List<Todo> completed;
  final Map<DateTime, int> dayCounts;
  int get total => pending.length + completed.length;
}
