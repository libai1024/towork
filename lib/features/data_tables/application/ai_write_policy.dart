import '../../../domain/models/models.dart';
import '../../../domain/ai/permission_policy.dart';
import '../../../domain/repositories/data_table_store.dart';

/// The confirmed REQUIREMENTS F6.3 matrix, shared by push and screenshot flows.
/// Authorization applies to whole row changes, never to a guessed subset of
/// their fields. The repository still validates and atomically applies writes.
Set<String> automaticAiChangeIds(
  AiWritePermission permission,
  Iterable<PendingRowChange> changes,
) => Set.unmodifiable({
  for (final change in changes)
    if (evaluatePermission(permission, switch (change.action) {
          DataChangeAction.create => AgentOperation.create,
          DataChangeAction.update => AgentOperation.edit,
          DataChangeAction.delete => AgentOperation.delete,
        }) ==
        PermissionDecision.execute)
      change.id,
});

class AiWriteResult {
  AiWriteResult({
    List<String> affectedRowIds = const [],
    List<PendingRowChange> appliedChanges = const [],
    this.pendingBatch,
  }) : affectedRowIds = List.unmodifiable(affectedRowIds),
       appliedChanges = List.unmodifiable(appliedChanges);

  final List<String> affectedRowIds;
  final List<PendingRowChange> appliedChanges;
  final PendingAiBatch? pendingBatch;

  bool get hasWrites => appliedChanges.isNotEmpty;
  bool get containsDeletion =>
      appliedChanges.any((change) => change.action == DataChangeAction.delete);
  bool get createsOnly =>
      hasWrites &&
      appliedChanges.every(
        (change) => change.action == DataChangeAction.create,
      );
}

/// One instance per injected repository. Reviewed, failed, or undone batches
/// must not silently run again when the user revisits a page or changes modes.
class AiWritePolicy {
  AiWritePolicy(this._store);
  final DataTableStore _store;
  final Set<String> _requiresReview = {};

  void requireReview(String batchId) => _requiresReview.add(batchId);

  AiWriteResult receive(String batchId, AiWritePermission permission) {
    final batch = _store.snapshot.pendingBatches
        .where((batch) => batch.id == batchId)
        .firstOrNull;
    if (batch == null) {
      throw const RepositoryException(
        RepositoryErrorCode.notFound,
        '这批 AI 变更已处理，请重新打开待确认记录',
      );
    }
    final ids = _requiresReview.contains(batchId)
        ? <String>{}
        : automaticAiChangeIds(permission, batch.changes);
    if (ids.isEmpty) return AiWriteResult(pendingBatch: batch);
    // Mark before applying: a conflict/validation failure remains a reviewable
    // proposal, not an automatic retry loop. Undo restores the same batch ID.
    requireReview(batchId);
    final affected = _store.applyPendingBatch(batchId, ids);
    return AiWriteResult(
      affectedRowIds: affected,
      appliedChanges: batch.changes
          .where((change) => ids.contains(change.id))
          .toList(),
      pendingBatch: _store.snapshot.pendingBatches
          .where((batch) => batch.id == batchId)
          .firstOrNull,
    );
  }
}
