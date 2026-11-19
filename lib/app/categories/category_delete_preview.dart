import '../../data/local/workspace_model_codec.dart';
import '../../domain/repositories/category_store.dart';
import '../../domain/repositories/todo_store.dart';
import '../../domain/use_cases/category_actions.dart';
import '../../domain/workspace/workspace_commands.dart';
import '../../domain/workspace/workspace_plans.dart';

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
