import '../domain/ai/agent_run.dart';
import '../domain/workspace/workspace_validation.dart';
import '../domain/ai/model_gateway.dart';
import '../domain/workspace/workspace_commands.dart';

/// One logical tool call can own many atomic mutations. Approval selects calls,
/// never individual implementation effects within a recurrence operation.
class AgentToolChanges {
  static JsonObject refreshTodo(
    JsonObject call,
    WorkspaceSnapshot snapshot,
    DateTime now,
  ) {
    final raw = call['mutation'];
    if (raw is! JsonObject || call['intent_patch'] is! JsonObject) {
      throw const AgentFailure(AgentFailureCode.invalid);
    }
    final kind = WorkspaceEntityKind.values.byName(raw['kind']! as String);
    final mutation = WorkspaceMutationKind.values.byName(
      raw['mutation']! as String,
    );
    final entityId = raw['entity_id']! as String;
    final before = snapshot.find(kind, entityId);
    if (mutation == WorkspaceMutationKind.create
        ? before != null
        : before == null || before.isDeleted) {
      throw WorkspaceFailure(
        WorkspaceFailureCode.versionConflict,
        entityId: entityId,
      );
    }
    // A stale full step list may overwrite another editor's work. Ask the
    // model for a new read and proposal instead of replaying that list.
    if ((call['intent_patch']! as JsonObject).containsKey('steps') &&
        before?.version != raw['expected_version']) {
      throw WorkspaceFailure(
        WorkspaceFailureCode.versionConflict,
        entityId: entityId,
      );
    }
    final deleting = mutation == WorkspaceMutationKind.delete;
    final after = deleting
        ? before!.data
        : applyWorkspacePatch(
            kind,
            before?.data,
            call['intent_patch']! as JsonObject,
            now,
          );
    return {
      ...call,
      'before': before?.toJson(),
      'after': deleting ? null : after,
      'mutation': {
        ...raw,
        'expected_version': before?.version,
        'patch': deleting
            ? <String, Object?>{}
            : {
                ...after,
                if ((call['intent_patch']! as JsonObject).containsKey('steps'))
                  'steps': (call['intent_patch']! as JsonObject)['steps'],
              },
      },
    };
  }

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
