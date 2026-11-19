import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../workspace/workspace_commands.dart';
import '../workspace/workspace_validation.dart';

class RecurrenceDraft {
  RecurrenceDraft(this.original, this.now) : entities = {...original.entities};
  final WorkspaceSnapshot original;
  final DateTime now;
  final Map<String, WorkspaceEntity> entities;
  final Set<String> changed = {};

  WorkspaceEntity get(WorkspaceEntityKind kind, String id) =>
      entities['${kind.name}:$id']!;
  void create(WorkspaceEntityKind kind, String id, Map<String, Object?> data) {
    validateWorkspaceId(id);
    if (entities.containsKey('${kind.name}:$id')) {
      throw WorkspaceFailure(
        WorkspaceFailureCode.versionConflict,
        entityId: id,
      );
    }
    _put(kind, id, applyWorkspacePatch(kind, null, data, now));
  }

  void patch(WorkspaceEntity entity, Map<String, Object?> patch) {
    final current = get(entity.kind, entity.id);
    _put(
      entity.kind,
      entity.id,
      applyWorkspacePatch(entity.kind, current.data, patch, now),
    );
  }

  void delete(WorkspaceEntity entity) =>
      _put(entity.kind, entity.id, entity.data, deleted: true);
  void _put(
    WorkspaceEntityKind kind,
    String id,
    Map<String, Object?> data, {
    bool deleted = false,
  }) {
    final old = original.find(kind, id);
    final item = WorkspaceEntity(
      kind: kind,
      id: id,
      version: (old?.version ?? 0) + 1,
      data: data,
      createdAt: old?.createdAt ?? now,
      updatedAt: now,
      deletedAt: deleted ? now : null,
    );
    entities[item.key] = item;
    changed.add(item.key);
  }

  WorkspaceCommand? command(
    String id, {
    String source = 'manual',
    bool keepNoop = false,
  }) {
    validateWorkspaceId(id);
    validateWorkspaceGraph(entities.values);
    final actions = <WorkspaceMutation>[];
    for (final key in changed) {
      final old = original.entities[key], next = entities[key]!;
      if (!keepNoop &&
          old != null &&
          old.isDeleted == next.isDeleted &&
          canonicalWorkspaceJson(old.data) ==
              canonicalWorkspaceJson(next.data)) {
        continue;
      }
      actions.add(
        WorkspaceMutation(
          actionId: sha256.convert(utf8.encode(key)).toString(),
          kind: next.kind,
          entityId: next.id,
          expectedVersion: old?.version,
          mutation: old == null
              ? WorkspaceMutationKind.create
              : next.isDeleted
              ? WorkspaceMutationKind.delete
              : WorkspaceMutationKind.update,
          patch: next.isDeleted
              ? {}
              : {
                  ...next.data,
                  if (old?.data.containsKey('steps') == true &&
                      !next.data.containsKey('steps'))
                    'steps': const [],
                },
        ),
      );
    }
    if (actions.length > 500) {
      throw const WorkspaceFailure(WorkspaceFailureCode.validation);
    }
    return actions.isEmpty
        ? null
        : WorkspaceCommand(operationId: id, source: source, actions: actions);
  }
}
