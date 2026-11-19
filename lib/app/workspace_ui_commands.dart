import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/workspace_model_codec.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/todo_repository.dart';
import '../domain/models/models.dart';
import '../domain/use_cases/category_actions.dart';
import '../domain/workspace/append_todo.dart';
import '../domain/workspace/workspace_validation.dart';
import '../domain/workspace/workspace_commands.dart';
import '../domain/workspace/workspace_plans.dart';
import 'local_workspace_session.dart';
import 'providers.dart';

class WorkspaceBusy implements Exception {}

/// The records displayed before a deletion confirmation. Changes to this scope
/// require a fresh preview, including newly attached tasks or child categories.
class CategoryDeletePreview {
  CategoryDeletePreview.capture(
    String id,
    CategoryStore categories,
    TodoReadStore todos, {
    WorkspaceSnapshot? workspace,
  }) : categoryId = id,
       fingerprint = _fingerprint(id, categories, todos, workspace),
       _plans = workspace == null
           ? null
           : {
               for (final mode in WorkspaceCategoryDeleteMode.values)
                 mode: WorkspacePlans.deleteCategory(
                   workspace,
                   id,
                   operationId: newWorkspaceId('category-delete'),
                   mode: mode,
                 ),
             };

  final String categoryId;
  final String fingerprint;
  final Map<WorkspaceCategoryDeleteMode, WorkspaceCommand>? _plans;
  WorkspaceCommand? command(CategoryDeletionPolicy policy) =>
      _plans?[policy == CategoryDeletionPolicy.deleteSubtree
          ? WorkspaceCategoryDeleteMode.deleteSubtree
          : WorkspaceCategoryDeleteMode.promoteChildren];
  int get seriesCount =>
      _plans?[WorkspaceCategoryDeleteMode.deleteSubtree]?.actions
          .where((a) => a.kind == WorkspaceEntityKind.series)
          .length ??
      0;
  int get detachedCount =>
      _plans?[WorkspaceCategoryDeleteMode.deleteSubtree]?.actions
          .where(
            (a) =>
                a.kind == WorkspaceEntityKind.todo &&
                a.mutation == WorkspaceMutationKind.update,
          )
          .length ??
      0;

  static String _fingerprint(
    String id,
    CategoryStore categories,
    TodoReadStore todos,
    WorkspaceSnapshot? workspace,
  ) {
    final ids = categories.subtreeIds(id);
    final series =
        workspace?.series
            .where(
              (e) => ids.contains((e.data['template']! as Map)['category_id']),
            )
            .toList() ??
        <WorkspaceEntity>[];
    final seriesIds = series.map((e) => e.id).toSet();
    return canonicalWorkspaceJson({
      'categories': {
        for (final item in categories.snapshot.where((c) => ids.contains(c.id)))
          item.id: {'version': item.version, ...categoryWorkspaceData(item)},
      },
      'todos': {
        for (final item in todos.snapshot.where(
          (t) => ids.contains(t.categoryId) || seriesIds.contains(t.seriesId),
        ))
          item.id: {'version': item.version, ...todoWorkspaceData(item)},
      },
      'series': {for (final e in series) e.id: e.toJson()},
    });
  }

  void validate(
    String id,
    CategoryStore categories,
    TodoReadStore todos, {
    WorkspaceSnapshot? workspace,
  }) {
    if (id != categoryId ||
        fingerprint != _fingerprint(id, categories, todos, workspace)) {
      throw WorkspaceFailure(
        WorkspaceFailureCode.versionConflict,
        entityId: id,
      );
    }
  }
}

class UiWorkspaceChange<T> {
  UiWorkspaceChange(this.value, this._undo);
  final T value;
  final Future<void> Function() _undo;
  bool _used = false;
  bool _running = false;
  Future<void> undo() async {
    if (_used || _running) return;
    _running = true;
    try {
      await _undo();
      _used = true;
    } finally {
      _running = false;
    }
  }
}

final workspaceUiCommandsProvider = Provider<WorkspaceUiCommands>(
  (ref) => WorkspaceUiCommands(
    ref.watch(todoListProvider.notifier),
    ref.watch(categoryListProvider.notifier),
    session: ref.watch(localWorkspaceSessionProvider),
  ),
);

/// Executes existing pure edit plans on isolated copies, then commits their diff
/// once. No in-memory notification is published before the receipt is durable.
class WorkspaceUiCommands {
  WorkspaceUiCommands(this.todos, this.categories, {this.session});
  final TodoReadStore todos;
  final CategoryStore categories;
  final LocalWorkspaceSession? session;
  bool _busy = false;

  Future<UiWorkspaceChange<T>> run<T>(
    T Function(TodoRepository, CategoryRepository) plan, {
    String? operationId,
  }) async {
    if (_busy) throw WorkspaceBusy();
    _busy = true;
    final oldTodos = todos.snapshot;
    final oldCategories = categories.snapshot;
    final id = operationId ?? newWorkspaceId('op');
    var todoIndex = 0;
    var categoryIndex = 0;
    final draftTodos = TodoRepository(
      initial: oldTodos,
      idFactory: () => '${id}_t_${todoIndex++}',
    );
    final draftCategories = CategoryRepository(
      initial: oldCategories,
      idFactory: () => '${id}_c_${categoryIndex++}',
    );
    try {
      final value = plan(draftTodos, draftCategories);
      final newTodos = draftTodos.snapshot;
      final newCategories = draftCategories.snapshot;
      final local = session;
      if (local != null) {
        final actions = <WorkspaceMutation>[];
        void diff<R>(
          WorkspaceEntityKind kind,
          List<R> before,
          List<R> after,
          String Function(R) entityId,
          int Function(R) version,
          Map<String, Object?> Function(R) data,
        ) {
          final old = {for (final e in before) entityId(e): e};
          final next = {for (final e in after) entityId(e): e};
          for (final key in {...old.keys, ...next.keys}) {
            final previous = old[key];
            final changed = next[key];
            if (previous != null && changed != null) {
              if (version(changed) != version(previous)) {
                throw WorkspaceFailure(
                  WorkspaceFailureCode.versionConflict,
                  entityId: key,
                );
              }
              if (canonicalWorkspaceJson(data(previous)) ==
                  canonicalWorkspaceJson(data(changed))) {
                continue;
              }
            }
            actions.add(
              WorkspaceMutation(
                actionId: 'a_${actions.length}',
                kind: kind,
                entityId: key,
                mutation: previous == null
                    ? WorkspaceMutationKind.create
                    : changed == null
                    ? WorkspaceMutationKind.delete
                    : WorkspaceMutationKind.update,
                expectedVersion: previous == null ? null : version(previous),
                patch: changed == null ? {} : data(changed),
              ),
            );
          }
        }

        diff(
          WorkspaceEntityKind.category,
          oldCategories,
          newCategories,
          (e) => e.id,
          (e) => e.version,
          categoryWorkspaceData,
        );
        diff(
          WorkspaceEntityKind.todo,
          oldTodos,
          newTodos,
          (e) => e.id,
          (e) => e.version,
          todoWorkspaceData,
        );
        if (actions.isEmpty) return UiWorkspaceChange(value, () async {});
        final receipt = await local.execute(
          WorkspaceCommand(operationId: id, actions: actions),
        );
        final undoId = newWorkspaceId('undo');
        return UiWorkspaceChange(
          value,
          () => local.undo(receipt.changesetId, undoId),
        );
      }
      // Isolated UI fixtures retain memory repositories. Production bootstrap
      // always supplies a session; no asynchronous disk work is hidden here.
      final todos = this.todos;
      if (todos is! TodoStore) {
        throw StateError('Expected an in-memory todo store');
      }
      categories.restoreAll(newCategories);
      try {
        todos.restoreAll(newTodos);
      } catch (_) {
        categories.restoreAll(oldCategories);
        rethrow;
      }
      return UiWorkspaceChange(value, () async {
        List<R> restore<R>(
          List<R> before,
          List<R> after,
          List<R> current,
          String Function(R) key,
        ) {
          final old = {for (final e in before) key(e): e};
          final applied = {for (final e in after) key(e): e};
          final now = {for (final e in current) key(e): e};
          for (final id in {...old.keys, ...applied.keys}) {
            if (identical(old[id], applied[id])) continue;
            if (!identical(now[id], applied[id])) {
              throw const WorkspaceFailure(
                WorkspaceFailureCode.versionConflict,
              );
            }
            if (old[id] == null) {
              now.remove(id);
            } else {
              now[id] = old[id] as R;
            }
          }
          final result = [
            for (final e in current)
              if (now.containsKey(key(e))) now[key(e)] as R,
          ];
          for (final (index, e) in before.indexed) {
            if (now.containsKey(key(e)) &&
                !result.any((item) => key(item) == key(e))) {
              result.insert(index.clamp(0, result.length), now[key(e)] as R);
            }
          }
          return result;
        }

        final nextCategories = restore(
          oldCategories,
          newCategories,
          categories.snapshot,
          (e) => e.id,
        );
        final nextTodos = restore(
          oldTodos,
          newTodos,
          todos.snapshot,
          (e) => e.id,
        );
        final saved = categories.snapshot;
        categories.restoreAll(nextCategories);
        try {
          todos.restoreAll(nextTodos);
        } catch (_) {
          categories.restoreAll(saved);
          rethrow;
        }
      });
    } finally {
      draftTodos.dispose();
      draftCategories.dispose();
      _busy = false;
    }
  }

  Future<Todo> createTodo({
    required String title,
    String? categoryId,
    DateTime? dueAt,
    TodoSource source = TodoSource.manual,
    String? sourceMessageId,
    String? operationId,
  }) async => (await appendTodo(
    title: title,
    categoryId: categoryId,
    dueAt: dueAt,
    source: source,
    sourceMessageId: sourceMessageId,
    operationId: operationId,
  )).value;

  Future<UiWorkspaceChange<Todo>> appendTodo({
    required String title,
    String? note,
    TodoPriority priority = TodoPriority.none,
    TodoStatus status = TodoStatus.pending,
    List<RemindRule> remindRules = const [],
    String? categoryId,
    DateTime? dueAt,
    TodoSource source = TodoSource.manual,
    String? sourceMessageId,
    String? operationId,
    DateTime Function()? clock,
  }) async {
    final id = operationId ?? newWorkspaceId('op');
    final action = AppendTodo(
      operationId: id,
      title: title,
      note: note,
      priority: priority,
      status: status,
      remindRules: remindRules,
      categoryId: categoryId,
      dueAt: dueAt,
      source: source,
      sourceMessageId: sourceMessageId,
    );
    final local = session;
    if (local == null) {
      // Widget fixtures share the production field rules, without a disk store.
      return run((t, c) {
        final now = (clock ?? DateTime.now)();
        final data = applyWorkspacePatch(action.kind, null, {
          ...action.patch,
          'sort_order': t.snapshot.length,
        }, now);
        final todo = workspaceTodo(
          WorkspaceEntity(
            kind: action.kind,
            id: action.entityId,
            version: 0,
            data: data,
            createdAt: now,
            updatedAt: now,
          ),
        );
        if (t.byId(todo.id) != null) {
          throw const WorkspaceFailure(WorkspaceFailureCode.versionConflict);
        }
        t.insertRaw(todo);
        return todo;
      }, operationId: id);
    }
    if (_busy) throw WorkspaceBusy();
    _busy = true;
    try {
      final receipt = await local.execute(
        WorkspaceCommand(operationId: id, actions: [action]),
      );
      final undoId = newWorkspaceId('undo');
      return UiWorkspaceChange(
        workspaceTodo(receipt.affected.single),
        () => local.undo(receipt.changesetId, undoId),
      );
    } finally {
      _busy = false;
    }
  }

  Future<void> updateTodo(Todo todo) async {
    await run((t, c) => t.updateTodo(todo));
  }

  Future<void> toggleTodo(String id) async {
    await run((t, c) => t.toggleDone(id));
  }

  Future<bool> moveCategory(String id, String? parentId, int index) async =>
      (await run((t, c) => c.moveCategory(id, parentId, index))).value;
  Future<bool> moveWithin(String id, int delta) async =>
      (await run((t, c) => c.moveWithinSiblings(id, delta))).value;

  Future<UiCategoryUndo> archiveCategory(String id, bool archived) async {
    final change = await run((t, c) {
      final result = CategoryActions(
        categories: c,
        todos: t,
      ).setArchived(id, archived);
      final name = result.categoryName;
      result.dispose();
      return name;
    });
    return UiCategoryUndo(change);
  }

  Future<UiCategoryUndo> deleteCategory(
    String id, {
    required CategoryDeletionPolicy policy,
    required CategoryDeletePreview preview,
  }) async {
    final local = session;
    if (local != null && preview.command(policy) != null) {
      if (_busy) throw WorkspaceBusy();
      _busy = true;
      try {
        preview.validate(id, categories, todos, workspace: local.snapshot);
        final name = categories.byId(id)!.name;
        final receipt = await local.execute(preview.command(policy)!);
        final undoId = newWorkspaceId('undo');
        return UiCategoryUndo(
          UiWorkspaceChange(
            name,
            () => local.undo(receipt.changesetId, undoId),
          ),
        );
      } finally {
        _busy = false;
      }
    }
    final change = await run((t, c) {
      preview.validate(id, c, t, workspace: local?.snapshot);
      final result = CategoryActions(
        categories: c,
        todos: t,
      ).delete(id, policy: policy);
      final name = result.categoryName;
      result.dispose();
      return name;
    });
    return UiCategoryUndo(change);
  }

  CategoryDeletePreview previewCategoryDelete(String id) =>
      CategoryDeletePreview.capture(
        id,
        categories,
        todos,
        workspace: session?.snapshot,
      );
}

class UiCategoryUndo {
  UiCategoryUndo(this.change);
  final UiWorkspaceChange<String> change;
  bool _disposed = false;
  String get categoryName => change.value;
  void dispose() => _disposed = true;
  Future<CategoryUndoResult> undo() async {
    if (_disposed) return CategoryUndoResult.unavailable;
    try {
      await change.undo();
      _disposed = true;
      return CategoryUndoResult.restored;
    } on WorkspaceFailure catch (error) {
      if (error.code == WorkspaceFailureCode.versionConflict ||
          error.code == WorkspaceFailureCode.validation) {
        return CategoryUndoResult.conflict;
      }
      rethrow;
    }
  }
}
