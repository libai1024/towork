import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../workspace_clock.dart';
import '../../domain/models/models.dart';
import 'todo_view_model.dart';

typedef DailyQuery = ({DateTime? day, String? categoryId});

/// A projection of current task records by due date, not a historical snapshot.
final dailyOverviewProvider = Provider.autoDispose
    .family<DailyOverview, DailyQuery>((ref, query) {
      // Reuse the deadline-aware invalidation of the shared todo projection.
      final base = ref.watch(todoOverviewProvider(const TodoQuery()));
      final categories = ref.watch(categoryListProvider.notifier);
      final scope = categories.byId(query.categoryId) == null
          ? null
          : categories.subtreeIds(query.categoryId!);
      return DailyOverview.from(
        todos: ref.watch(todoListProvider),
        day: query.day ?? ref.watch(workspaceClockProvider).now,
        now: base.now,
        categoryIds: scope,
      );
    });

class DailyOverview {
  DailyOverview._(
    this.day,
    this.now,
    List<Todo> overdue,
    List<Todo> pending,
    List<Todo> completed,
  ) : overdue = List.unmodifiable(overdue),
      pending = List.unmodifiable(pending),
      completed = List.unmodifiable(completed);

  factory DailyOverview.from({
    required Iterable<Todo> todos,
    required DateTime day,
    required DateTime now,
    Set<String>? categoryIds,
  }) {
    final date = DateTime(day.year, day.month, day.day);
    final end = DateTime(day.year, day.month, day.day + 1);
    final today = DateTime(now.year, now.month, now.day);
    final overdue = <Todo>[], pending = <Todo>[], completed = <Todo>[];
    for (final todo in todos) {
      if (categoryIds != null && !categoryIds.contains(todo.categoryId)) {
        continue;
      }
      final due = todo.dueAt?.toLocal();
      if (due == null || todo.status == TodoStatus.cancelled) continue;
      if (!due.isBefore(date) && due.isBefore(end)) {
        if (todo.isActive) pending.add(todo);
        if (todo.status == TodoStatus.done) completed.add(todo);
      } else if (date == today && due.isBefore(date) && todo.isActive) {
        overdue.add(todo);
      }
    }
    int order(Todo a, Todo b) {
      final due = a.dueAt!.compareTo(b.dueAt!);
      return due == 0 ? a.sortOrder.compareTo(b.sortOrder) : due;
    }

    overdue.sort(order);
    pending.sort(order);
    completed.sort(order);
    return DailyOverview._(date, now, overdue, pending, completed);
  }

  final DateTime day, now;
  final List<Todo> overdue, pending, completed;
  int get total => pending.length + completed.length;
  double get progress => total == 0 ? 0 : completed.length / total;
  bool get isToday => day == DateTime(now.year, now.month, now.day);
}
