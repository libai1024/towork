import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'workspace_commands.dart';

enum WorkspaceCategoryDeleteMode { promoteChildren, deleteSubtree }

/// Plans use the displayed snapshot, not a refreshed version that could silently
/// overwrite a user's concurrent edit. The command store validates the final graph.
class WorkspacePlans {
  static String _actionId(WorkspaceEntity entity) =>
      sha256.convert(utf8.encode(entity.key)).toString();
  static WorkspaceEntity _category(WorkspaceSnapshot snapshot, String id) {
    final entity = snapshot.find(WorkspaceEntityKind.category, id);
    if (entity == null || entity.isDeleted) {
      throw WorkspaceFailure(WorkspaceFailureCode.notFound, entityId: id);
    }
    return entity;
  }

  static WorkspaceMutation update(
    WorkspaceEntity entity,
    Map<String, Object?> patch,
  ) => WorkspaceMutation(
    actionId: _actionId(entity),
    kind: entity.kind,
    entityId: entity.id,
    mutation: WorkspaceMutationKind.update,
    expectedVersion: entity.version,
    patch: patch,
  );

  static WorkspaceMutation delete(WorkspaceEntity entity) => WorkspaceMutation(
    actionId: _actionId(entity),
    kind: entity.kind,
    entityId: entity.id,
    mutation: WorkspaceMutationKind.delete,
    expectedVersion: entity.version,
  );

  static WorkspaceCommand deleteCategory(
    WorkspaceSnapshot snapshot,
    String id, {
    required String operationId,
    required WorkspaceCategoryDeleteMode mode,
  }) {
    final root = _category(snapshot, id);
    final children =
        snapshot.categories.where((e) => e.data['parent_id'] == id).toList()
          ..sort(_order);
    final actions = <WorkspaceMutation>[delete(root)];
    if (mode == WorkspaceCategoryDeleteMode.deleteSubtree) {
      final ids = {id, ...children.map((e) => e.id)};
      actions.addAll(children.map(delete));
      actions.addAll(
        snapshot.todos
            .where((e) => ids.contains(e.data['category_id']))
            .map(delete),
      );
    } else {
      var order =
          snapshot.categories
              .where((e) => e.data['parent_id'] == null)
              .fold(
                -1,
                (max, e) => (e.data['sort_order']! as int) > max
                    ? e.data['sort_order']! as int
                    : max,
              ) +
          1;
      for (final child in children) {
        actions.add(update(child, {'parent_id': null, 'sort_order': order++}));
      }
      for (final todo in snapshot.todos.where(
        (e) => e.data['category_id'] == id,
      )) {
        actions.add(update(todo, {'category_id': null}));
      }
    }
    final removedIds = {
      id,
      if (mode == WorkspaceCategoryDeleteMode.deleteSubtree)
        ...children.map((e) => e.id),
    };
    // Templates are independent of current instances: even an empty category
    // can own a series whose instances were individually moved or deleted.
    final owners = snapshot.series.where(
      (e) => removedIds.contains((e.data['template']! as Map)['category_id']),
    );
    for (final owner in owners) {
      actions.add(
        update(owner, {
          'template': {
            ...(owner.data['template']! as Map<String, Object?>),
            'category_id': null,
          },
          if (mode == WorkspaceCategoryDeleteMode.deleteSubtree)
            'stop_before': 0,
        }),
      );
      if (mode != WorkspaceCategoryDeleteMode.deleteSubtree) continue;
      // Explicitly moved instances belong to their new category. Preserve them
      // as standalone tasks, including completed facts, rather than deleting
      // them or leaving an uncompletable task attached to a stopped series.
      for (final todo in snapshot.todos.where(
        (e) =>
            e.data['series_id'] == owner.id &&
            !removedIds.contains(e.data['category_id']),
      )) {
        actions.add(
          update(todo, {
            'series_id': null,
            'occurrence_key': null,
            'occurrence_index': null,
            'occurrence_at': null,
            'repeat_rule': null,
            'repeat_timezone': null,
          }),
        );
      }
    }
    return WorkspaceCommand(operationId: operationId, actions: actions);
  }

  static WorkspaceCommand archiveCategory(
    WorkspaceSnapshot snapshot,
    String id, {
    required String operationId,
    required bool archived,
  }) {
    final root = _category(snapshot, id);
    final ids = {
      id,
      ...snapshot.categories
          .where((e) => e.data['parent_id'] == id)
          .map((e) => e.id),
    };
    if (!archived && root.data['parent_id'] != null) {
      ids.add(root.data['parent_id']! as String);
    }
    return WorkspaceCommand(
      operationId: operationId,
      actions: [
        for (final category in snapshot.categories)
          if (ids.contains(category.id))
            update(category, {'archived': archived}),
      ],
    );
  }

  static int _order(WorkspaceEntity a, WorkspaceEntity b) {
    final result = (a.data['sort_order']! as int).compareTo(
      b.data['sort_order']! as int,
    );
    return result == 0 ? a.id.compareTo(b.id) : result;
  }
}
