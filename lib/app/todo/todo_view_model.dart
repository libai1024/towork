import 'dart:async';
import 'dart:ui' show Color;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../workspace_clock.dart';
import '../../domain/models/models.dart';
import '../../core/todo/todo_utils.dart';

class CategoryTodoScope {
  const CategoryTodoScope(this.category, this.activeCount);
  final Category category;
  final int activeCount;
}

/// Direct subcategories form the compact index; descendants never leak in from
/// another root. Counts continue to describe active records when search changes.
final categoryTodoScopesProvider = Provider.autoDispose
    .family<List<CategoryTodoScope>, String>((ref, rootId) {
      final categories = ref.watch(categoryListProvider);
      final todos = ref.watch(todoListProvider);
      final children =
          categories
              .where(
                (category) => category.parentId == rootId && !category.archived,
              )
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return List.unmodifiable([
        for (final category in children)
          CategoryTodoScope(
            category,
            todos
                .where(
                  (todo) => todo.isActive && todo.categoryId == category.id,
                )
                .length,
          ),
      ]);
    });

final todoViewModelProvider = Provider<TodoQueries>(
  (ref) => TodoQueries(
    todos: ref.watch(todoListProvider.notifier),
    categories: ref.watch(categoryListProvider.notifier),
    clock: ref.watch(workspaceNowProvider),
  ),
);

/// Invalidates derived presentation data when its sources or wall time change.
/// The repositories remain the only owners of task and category data.
final todoOverviewProvider = Provider.autoDispose
    .family<TodoOverview, TodoQuery>((ref, query) {
      final todos = ref.watch(todoListProvider);
      ref.watch(categoryListProvider);
      final clock = ref.watch(workspaceClockProvider);
      final overview = ref.watch(todoViewModelProvider).overview(query);
      // A deadline can fall between minute ticks. Counts cover all tasks, so
      // watch the earliest active deadline even outside the visible filter.
      DateTime? nextDeadline;
      if (clock.isActive) {
        for (final todo in todos) {
          final due = todo.dueAt;
          if (!todo.isActive || due == null || due.isBefore(overview.now)) {
            continue;
          }
          if (nextDeadline == null || due.isBefore(nextDeadline)) {
            nextDeadline = due;
          }
        }
      }
      if (nextDeadline != null) {
        final timer = Timer(
          nextDeadline.difference(overview.now) +
              const Duration(microseconds: 1),
          ref.invalidateSelf,
        );
        ref.onDispose(timer.cancel);
      }
      return overview;
    });

class TodoQuery {
  const TodoQuery({
    this.filter = TodoQuickFilter.all,
    this.groupBy = TodoGroupBy.category,
    this.categoryId,
    this.search = '',
    this.showCompleted = true,
  });

  final TodoQuickFilter filter;
  final TodoGroupBy groupBy;
  final String? categoryId;
  final String search;
  final bool showCompleted;

  @override
  bool operator ==(Object other) =>
      other is TodoQuery &&
      other.filter == filter &&
      other.groupBy == groupBy &&
      other.categoryId == categoryId &&
      other.search == search &&
      other.showCompleted == showCompleted;

  @override
  int get hashCode =>
      Object.hash(filter, groupBy, categoryId, search, showCompleted);
}

class TodoBoardColumn {
  TodoBoardColumn(this.status, Iterable<Todo> items)
    : todos = List<Todo>.unmodifiable(items);
  final TodoStatus status;
  final List<Todo> todos;
  String get title => status.label;
}

class TodoOverview {
  TodoOverview({
    required this.now,
    required Iterable<Todo> visible,
    required Iterable<TodoGroup> groups,
    required Iterable<TodoBoardColumn> columns,
    required Map<TodoQuickFilter, int> counts,
  }) : visible = List<Todo>.unmodifiable(visible),
       groups = List<TodoGroup>.unmodifiable(
         groups.map(
           (group) => TodoGroup(
             key: group.key,
             title: group.title,
             dotColor: group.dotColor,
             todos: List<Todo>.unmodifiable(group.todos),
           ),
         ),
       ),
       columns = List<TodoBoardColumn>.unmodifiable(columns),
       counts = Map<TodoQuickFilter, int>.unmodifiable(counts);

  final DateTime now;
  final List<Todo> visible;
  final List<TodoGroup> groups;
  final List<TodoBoardColumn> columns;
  final Map<TodoQuickFilter, int> counts;
}

/// An operation receipt supplies a one-use undo without retaining BuildContext.
class TodoMutation {
  factory TodoMutation({required int count, FutureOr<void> Function()? undo}) =>
      TodoMutation._(count, undo);
  TodoMutation._(this.count, this._undo);
  final int count;
  FutureOr<void> Function()? _undo;
  FutureOr<void> undo() {
    final action = _undo;
    _undo = null;
    return action?.call();
  }
}

class TodoQueries {
  TodoQueries({
    required TodoReadStore todos,
    required this._categories,
    DateTime Function()? clock,
  }) : _reader = todos,
       _clock = clock ?? DateTime.now;

  final TodoReadStore _reader;
  final CategoryStore _categories;
  final DateTime Function() _clock;

  TodoOverview overview(TodoQuery query) {
    final now = _clock();
    final categoryIds = query.categoryId == null
        ? null
        : _categories.subtreeIds(query.categoryId!);
    final scopedTodos = categoryIds == null
        ? _reader.snapshot
        : _reader.snapshot
              .where((todo) => categoryIds.contains(todo.categoryId))
              .toList(growable: false);
    final visible = filterTodos(
      scopedTodos,
      query.filter,
      now,
      query: query.search,
      showCompleted: query.showCompleted,
    );
    List<Todo> column(TodoStatus status) {
      final items = visible
          .where(
            (todo) => status == TodoStatus.done
                ? todo.status == TodoStatus.done ||
                      todo.status == TodoStatus.cancelled
                : todo.status == status,
          )
          .toList();
      items.sort(
        status == TodoStatus.done
            ? (a, b) => (b.completedAt ?? b.updatedAt ?? b.createdAt).compareTo(
                a.completedAt ?? a.updatedAt ?? a.createdAt,
              )
            : (a, b) => a.sortOrder.compareTo(b.sortOrder),
      );
      return items;
    }

    return TodoOverview(
      now: now,
      visible: visible,
      groups: groupTodos(
        visible,
        query.groupBy,
        _categories.snapshot,
        now,
        query.filter,
      ),
      columns: [
        for (final status in [
          TodoStatus.inProgress,
          TodoStatus.pending,
          TodoStatus.done,
        ])
          TodoBoardColumn(status, column(status)),
      ],
      counts: {
        for (final filter in TodoQuickFilter.values)
          filter: countForFilter(scopedTodos, filter, now),
      },
    );
  }

  (String?, Color?) categoryDisplay(Todo todo) {
    final direct = _categories.byId(todo.categoryId);
    if (direct == null) return (null, null);
    final parent = _categories.byId(direct.parentId);
    return (
      parent == null ? direct.name : '${parent.name}/${direct.name}',
      direct.color,
    );
  }
}

/// Mutable edit plans run on isolated drafts before the workspace commits.
class TodoViewModel extends TodoQueries {
  TodoViewModel({
    required TodoStore todos,
    required super.categories,
    super.clock,
  }) : _todos = todos,
       super(todos: todos);

  final TodoStore _todos;

  List<Todo> _targets(Iterable<String> ids) =>
      ids.toSet().map(_todos.byId).whereType<Todo>().toList(growable: false);

  TodoMutation toggleDone(String id) {
    final before = _todos.byId(id);
    if (before == null) return TodoMutation(count: 0);
    _todos.toggleDone(id);
    return _statusReceipt([before]);
  }

  TodoMutation complete(Iterable<String> ids) {
    final before = _targets(ids).where((todo) => todo.isActive).toList();
    final now = _clock();
    for (final todo in before) {
      _todos.updateTodo(
        todo.copyWith(status: TodoStatus.done, completedAt: now),
      );
    }
    return _statusReceipt(before);
  }

  TodoMutation _statusReceipt(List<Todo> before) {
    final applied = {for (final todo in before) todo.id: _todos.byId(todo.id)!};
    return TodoMutation(
      count: before.length,
      undo: () {
        for (final previous in before) {
          final current = _todos.byId(previous.id);
          final expected = applied[previous.id]!;
          // Preserve edits made after this command. Do not recreate a deleted
          // task or overwrite a later status transition when undo is requested.
          if (current == null ||
              current.status != expected.status ||
              current.completedAt != expected.completedAt) {
            continue;
          }
          _todos.updateTodo(
            current.copyWith(
              status: previous.status,
              completedAt: previous.completedAt,
            ),
          );
        }
      },
    );
  }

  int setCategory(Iterable<String> ids, String? categoryId) {
    final targets = _targets(ids);
    for (final todo in targets) {
      _todos.updateTodo(todo.copyWith(categoryId: categoryId));
    }
    return targets.length;
  }

  int setDue(Iterable<String> ids, DateTime? dueAt) {
    final targets = _targets(ids);
    for (final todo in targets) {
      _todos.updateTodo(todo.copyWith(dueAt: dueAt));
    }
    return targets.length;
  }

  TodoMutation delete(Iterable<String> ids) {
    final selected = ids.toSet();
    final snapshots = <(int, Todo)>[
      for (final (index, todo) in _todos.snapshot.indexed)
        if (selected.contains(todo.id)) (index, todo),
    ];
    for (final (_, todo) in snapshots) {
      _todos.removeById(todo.id);
    }
    return TodoMutation(
      count: snapshots.length,
      undo: () {
        for (final (index, todo) in snapshots) {
          _todos.insertAt(index, todo);
        }
      },
    );
  }
}
