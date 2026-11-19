import '../domain/ai/model_gateway.dart';
import '../domain/workspace/workspace_commands.dart';

/// One logical tool call can own many atomic mutations. Approval selects calls,
/// never individual implementation effects within a recurrence operation.
class AgentToolChanges {
  static bool isWrite(JsonObject call) =>
      call['mutation'] != null || call['mutations'] != null;

  static List<WorkspaceMutation> mutations(JsonObject call) {
    final single = call['mutation'];
    final many = call['mutations'];
    if (single != null && many != null) throw const FormatException();
    final raw = many == null ? [?single] : many as List;
    return raw.map((value) {
      final m = value as JsonObject;
      return WorkspaceMutation(
        actionId: m['action_id']! as String,
        kind: WorkspaceEntityKind.values.byName(m['kind']! as String),
        entityId: m['entity_id']! as String,
        mutation: WorkspaceMutationKind.values.byName(m['mutation']! as String),
        expectedVersion: m['expected_version'] as int?,
        patch: m['patch']! as JsonObject,
      );
    }).toList();
  }

  static WorkspaceEntity project(
    WorkspaceMutation mutation,
    WorkspaceSnapshot snapshot,
    DateTime now,
  ) {
    final before = snapshot.find(mutation.kind, mutation.entityId);
    final deleting = mutation.mutation == WorkspaceMutationKind.delete;
    return WorkspaceEntity(
      kind: mutation.kind,
      id: mutation.entityId,
      version: (before?.version ?? 0) + 1,
      data: deleting ? before!.data : mutation.patch,
      createdAt: before?.createdAt ?? now,
      updatedAt: now,
      deletedAt: deleting ? now : null,
    );
  }
}
