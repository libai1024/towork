import '../models/models.dart';
import '../repositories/category_store.dart';
import '../repositories/repository_error.dart';
import '../repositories/todo_store.dart';

enum CategoryDeletionPolicy { keepTodosAndChildren, deleteSubtree }

enum CategoryUndoResult { restored, conflict, unavailable }

/// Synchronous in-memory commands spanning category and task repositories.
///
/// Call after confirmation: each command reads its own current tree and tasks.
/// A future remote implementation needs a server-side transaction/version
/// boundary; these synchronous compensations are not a database transaction.
class CategoryActions {
  CategoryActions({required this.categories, required this.todos});

  final CategoryStore categories;
  final TodoStore todos;

  CategoryUndo setArchived(String id, bool archived) {
    final beforeCategories = categories.snapshot;
    final category = _requireCategory(id);
    final ids = categories.subtreeIds(id);
    if (!archived && category.parentId != null) ids.add(category.parentId!);
    final afterCategories = [
      for (final item in beforeCategories)
        ids.contains(item.id) && item.archived != archived
            ? item.copyWith(archived: archived)
            : item,
    ];
    return _apply(
      category.name,
      beforeCategories,
      afterCategories,
      todos.snapshot,
      todos.snapshot,
    );
  }

  CategoryUndo delete(
    String id, {
    CategoryDeletionPolicy policy = CategoryDeletionPolicy.keepTodosAndChildren,
  }) {
    final category = _requireCategory(id);
    final beforeCategories = categories.snapshot;
    final beforeTodos = todos.snapshot;
    final List<Category> afterCategories;
    final List<Todo> afterTodos;
    if (policy == CategoryDeletionPolicy.deleteSubtree) {
      final ids = categories.subtreeIds(id);
      afterCategories = [
        for (final item in beforeCategories)
          if (!ids.contains(item.id)) item,
      ];
      afterTodos = [
        for (final item in beforeTodos)
          if (!ids.contains(item.categoryId)) item,
      ];
    } else {
      final children =
          beforeCategories.where((item) => item.parentId == id).toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      var nextOrder =
          beforeCategories
              .where((item) => item.parentId == null && !item.archived)
              .fold(
                -1,
                (max, item) => item.sortOrder > max ? item.sortOrder : max,
              ) +
          1;
      final promoted = {
        for (final child in children)
          child.id: child.copyWith(parentId: null, sortOrder: nextOrder++),
      };
      afterCategories = [
        for (final item in beforeCategories)
          if (item.id != id) promoted[item.id] ?? item,
      ];
      afterTodos = [
        for (final item in beforeTodos)
          item.categoryId == id ? item.copyWith(categoryId: null) : item,
      ];
    }
    return _apply(
      category.name,
      beforeCategories,
      afterCategories,
      beforeTodos,
      afterTodos,
    );
  }

  Category _requireCategory(String id) {
    final category = categories.byId(id);
    if (category == null) {
      throw const RepositoryException(RepositoryErrorCode.notFound, '分类已不存在');
    }
    return category;
  }

  CategoryUndo _apply(
    String name,
    List<Category> beforeCategories,
    List<Category> afterCategories,
    List<Todo> beforeTodos,
    List<Todo> afterTodos,
  ) {
    _commit(
      categories,
      todos,
      beforeCategories: beforeCategories,
      afterCategories: afterCategories,
      beforeTodos: beforeTodos,
      afterTodos: afterTodos,
      categoriesFirst: false,
    );
    return CategoryUndo._(
      _changes(beforeCategories, afterCategories, (item) => item.id),
      _changes(beforeTodos, afterTodos, (item) => item.id),
      categoryName: name,
      categories: categories,
      todos: todos,
    );
  }
}

/// One-use, scoped compensation. Dispose when its UI undo window closes.
///
/// Immutable object identity acts as a compare-and-swap token. Observing the
/// affected IDs also detects delete/recreate/delete (ABA) during the undo window.
/// Unrelated records never become part of the compensation.
class CategoryUndo {
  CategoryUndo._(
    this._categoryChanges,
    this._todoChanges, {
    required this.categoryName,
    required CategoryStore categories,
    required TodoStore todos,
  }) : _categories = categories,
       _todos = todos {
    if (_categoryChanges.isNotEmpty) {
      _removeCategoryListener = categories.addListener(
        (_) => _checkConflict(),
        fireImmediately: false,
      );
    }
    if (_todoChanges.isNotEmpty) {
      _removeTodoListener = todos.addListener(
        (_) => _checkConflict(),
        fireImmediately: false,
      );
    }
  }

  final String categoryName;
  final CategoryStore _categories;
  final TodoStore _todos;
  final Map<String, _Change<Category>> _categoryChanges;
  final Map<String, _Change<Todo>> _todoChanges;
  void Function()? _removeCategoryListener;
  void Function()? _removeTodoListener;
  bool _closed = false;
  bool _conflicted = false;

  void _checkConflict() {
    if (_closed || _conflicted) return;
    if (!_categories.mounted ||
        !_todos.mounted ||
        !_matches(_categories.snapshot, _categoryChanges, (item) => item.id) ||
        !_matches(_todos.snapshot, _todoChanges, (item) => item.id)) {
      _conflicted = true;
      // StateNotifier is iterating its listener list here. Release only when
      // the undo window closes, never mutate that list inside notification.
    }
  }

  CategoryUndoResult undo() {
    if (_closed || !_categories.mounted || !_todos.mounted) {
      dispose();
      return CategoryUndoResult.unavailable;
    }
    _checkConflict();
    if (_conflicted) {
      dispose();
      return CategoryUndoResult.conflict;
    }
    final beforeCategories = _categories.snapshot;
    final beforeTodos = _todos.snapshot;
    final afterCategories = _compensate(
      beforeCategories,
      _categoryChanges,
      (item) => item.id,
    );
    final afterTodos = _compensate(
      beforeTodos,
      _todoChanges,
      (item) => item.id,
    );
    final categoryIds = afterCategories.map((item) => item.id).toSet();
    // A later child attached to a promoted category or an archived/deleted
    // parent can make the old placement invalid even if affected IDs match.
    if (!_validTree(afterCategories) ||
        _todoChanges.values.any(
          (change) =>
              change.before?.categoryId != null &&
              !categoryIds.contains(change.before!.categoryId),
        )) {
      dispose();
      return CategoryUndoResult.conflict;
    }
    dispose();
    _commit(
      _categories,
      _todos,
      beforeCategories: beforeCategories,
      afterCategories: afterCategories,
      beforeTodos: beforeTodos,
      afterTodos: afterTodos,
      categoriesFirst: true,
    );
    return CategoryUndoResult.restored;
  }

  void _releaseListeners() {
    _removeCategoryListener?.call();
    _removeTodoListener?.call();
    _removeCategoryListener = null;
    _removeTodoListener = null;
  }

  void dispose() {
    if (_closed) return;
    _closed = true;
    _releaseListeners();
  }
}

class _Change<T> {
  const _Change(this.before, this.after, this.index);
  final T? before;
  final T? after;
  final int index;
}

Map<String, _Change<T>> _changes<T>(
  List<T> before,
  List<T> after,
  String Function(T) id,
) {
  final old = {for (final item in before) id(item): item};
  final next = {for (final item in after) id(item): item};
  return {
    for (final key in {...old.keys, ...next.keys})
      if (!identical(old[key], next[key]))
        key: _Change(
          old[key],
          next[key],
          before.indexWhere((item) => id(item) == key),
        ),
  };
}

bool _matches<T>(
  List<T> current,
  Map<String, _Change<T>> changes,
  String Function(T) id,
) {
  final byId = {for (final item in current) id(item): item};
  return changes.entries.every(
    (entry) => identical(byId[entry.key], entry.value.after),
  );
}

List<T> _compensate<T>(
  List<T> current,
  Map<String, _Change<T>> changes,
  String Function(T) id,
) {
  if (changes.isEmpty) return current;
  final result = <T>[];
  final present = current.map(id).toSet();
  for (final item in current) {
    final change = changes[id(item)];
    if (change == null) {
      result.add(item);
    } else if (change.before != null) {
      result.add(change.before as T);
    }
  }
  final missing =
      changes.entries
          .where(
            (entry) =>
                !present.contains(entry.key) && entry.value.before != null,
          )
          .toList()
        ..sort((a, b) => a.value.index.compareTo(b.value.index));
  for (final entry in missing) {
    result.insert(
      entry.value.index.clamp(0, result.length),
      entry.value.before as T,
    );
  }
  return result;
}

bool _validTree(List<Category> categories) {
  final byId = {for (final item in categories) item.id: item};
  if (byId.length != categories.length) return false;
  for (final item in categories) {
    if (item.parentId == null) continue;
    final parent = byId[item.parentId];
    if (parent == null ||
        parent.id == item.id ||
        parent.parentId != null ||
        (parent.archived && !item.archived)) {
      return false;
    }
  }
  return true;
}

bool _sameItems<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var index = 0; index < a.length; index++) {
    if (!identical(a[index], b[index])) return false;
  }
  return true;
}

void _commit(
  CategoryStore categories,
  TodoStore todos, {
  required List<Category> beforeCategories,
  required List<Category> afterCategories,
  required List<Todo> beforeTodos,
  required List<Todo> afterTodos,
  required bool categoriesFirst,
}) {
  final categoriesChanged = !_sameItems(beforeCategories, afterCategories);
  final todosChanged = !_sameItems(beforeTodos, afterTodos);
  if (categoriesFirst) {
    if (categoriesChanged) categories.restoreAll(afterCategories);
    try {
      if (todosChanged) todos.restoreAll(afterTodos);
    } catch (_) {
      if (categoriesChanged) categories.restoreAll(beforeCategories);
      rethrow;
    }
  } else {
    if (todosChanged) todos.restoreAll(afterTodos);
    try {
      if (categoriesChanged) categories.restoreAll(afterCategories);
    } catch (_) {
      if (todosChanged) todos.restoreAll(beforeTodos);
      rethrow;
    }
  }
}
