import 'dart:convert';
import 'dart:math';

enum WorkspaceEntityKind {
  todo,
  category,
  series,
  dataTable,
  dataRow,
  tableType,
}

enum WorkspaceMutationKind { create, update, delete }

enum WorkspaceFailureCode {
  validation,
  notFound,
  versionConflict,
  idempotencyMismatch,
  storageUnavailable,
}

/// Safe for UI/logs: never contains user text or raw SQLite exceptions.
class WorkspaceFailure implements Exception {
  const WorkspaceFailure(this.code, {this.entityId});
  final WorkspaceFailureCode code;
  final String? entityId;
  @override
  String toString() => 'WorkspaceFailure(${code.name})';
}

String newWorkspaceId(String prefix) {
  final random = Random.secure();
  return '${prefix}_${List.generate(24, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
}

Map<String, Object?> freezeWorkspaceJson(Map<String, Object?> value) {
  Object? freeze(Object? item) => switch (item) {
    Map<String, Object?> map => Map<String, Object?>.unmodifiable(
      map.map((key, child) => MapEntry(key, freeze(child))),
    ),
    List<Object?> list => List<Object?>.unmodifiable(list.map(freeze)),
    null || String() || bool() || int() => item,
    double number when number.isFinite => number,
    _ => throw const WorkspaceFailure(WorkspaceFailureCode.validation),
  };
  return freeze(value)! as Map<String, Object?>;
}

String canonicalWorkspaceJson(Object? value) {
  Object? sort(Object? item) {
    if (item is Map<String, Object?>) {
      final keys = item.keys.toList()..sort();
      return {for (final key in keys) key: sort(item[key])};
    }
    if (item is List<Object?>) return item.map(sort).toList();
    return item;
  }

  return jsonEncode(sort(value));
}

class WorkspaceEntity {
  WorkspaceEntity({
    required this.kind,
    required this.id,
    required this.version,
    required Map<String, Object?> data,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  }) : data = freezeWorkspaceJson(data);
  final WorkspaceEntityKind kind;
  final String id;
  final int version;
  final Map<String, Object?> data;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  bool get isDeleted => deletedAt != null;
  String get key => '${kind.name}:$id';
  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'id': id,
    'version': version,
    'data': data,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'deleted_at': deletedAt?.toUtc().toIso8601String(),
  };
  factory WorkspaceEntity.fromJson(Map<String, Object?> json) =>
      WorkspaceEntity(
        kind: WorkspaceEntityKind.values.byName(json['kind']! as String),
        id: json['id']! as String,
        version: json['version']! as int,
        data: (json['data']! as Map).cast<String, Object?>(),
        createdAt: DateTime.parse(json['created_at']! as String).toUtc(),
        updatedAt: DateTime.parse(json['updated_at']! as String).toUtc(),
        deletedAt: json['deleted_at'] == null
            ? null
            : DateTime.parse(json['deleted_at']! as String).toUtc(),
      );
}

class WorkspaceMutation {
  WorkspaceMutation({
    required this.actionId,
    required this.kind,
    required this.entityId,
    required this.mutation,
    this.expectedVersion,
    Map<String, Object?> patch = const {},
  }) : patch = freezeWorkspaceJson(patch);
  final String actionId;
  final WorkspaceEntityKind kind;
  final String entityId;
  final WorkspaceMutationKind mutation;
  final int? expectedVersion;
  final Map<String, Object?> patch;
  String get key => '${kind.name}:$entityId';
  Map<String, Object?> patchFor(WorkspaceSnapshot current) => patch;
  Map<String, Object?> toJson() => {
    'action_id': actionId,
    'kind': kind.name,
    'entity_id': entityId,
    'mutation': mutation.name,
    'expected_version': expectedVersion,
    'patch': patch,
  };
}

/// A caller generates an operation ID once and reuses it when retrying.
/// Agent callers must pass the independent permission gate before this boundary.
class WorkspaceCommand {
  WorkspaceCommand({
    required this.operationId,
    required List<WorkspaceMutation> actions,
    this.source = 'manual',
  }) : actions = List.unmodifiable(actions);
  final String operationId;
  final String source;
  final List<WorkspaceMutation> actions;
  Map<String, Object?> toJson() => {
    'schema_version': 1,
    'operation_id': operationId,
    'source': source,
    'actions': actions.map((a) => a.toJson()).toList(),
  };
}

class WorkspaceReceipt {
  WorkspaceReceipt({
    required this.operationId,
    required this.committedAt,
    required List<WorkspaceEntity> affected,
    List<String> undoOf = const [],
  }) : affected = List.unmodifiable(affected),
       undoOf = List.unmodifiable(undoOf);
  final String operationId;
  final DateTime committedAt;
  final List<WorkspaceEntity> affected;
  final List<String> undoOf;
  // One changeset per atomic operation; the persisted operation ID names both.
  String get changesetId => operationId;
  Map<String, Object?> toJson() => {
    'operation_id': operationId,
    'committed_at': committedAt.toUtc().toIso8601String(),
    'affected': affected.map((e) => e.toJson()).toList(),
    if (undoOf.isNotEmpty) 'undo_of': undoOf,
  };
  factory WorkspaceReceipt.fromJson(Map<String, Object?> json) =>
      WorkspaceReceipt(
        operationId: json['operation_id']! as String,
        undoOf: (json['undo_of'] as List?)?.cast<String>() ?? const [],
        committedAt: DateTime.parse(json['committed_at']! as String).toUtc(),
        affected: (json['affected']! as List)
            .map(
              (e) =>
                  WorkspaceEntity.fromJson((e as Map).cast<String, Object?>()),
            )
            .toList(),
      );
}

class WorkspaceSnapshot {
  WorkspaceSnapshot(Iterable<WorkspaceEntity> entities)
    : entities = Map.unmodifiable({
        for (final entity in entities) entity.key: entity,
      });
  final Map<String, WorkspaceEntity> entities;
  Iterable<WorkspaceEntity> get todos => entities.values.where(
    (e) => e.kind == WorkspaceEntityKind.todo && !e.isDeleted,
  );
  Iterable<WorkspaceEntity> get categories => entities.values.where(
    (e) => e.kind == WorkspaceEntityKind.category && !e.isDeleted,
  );
  Iterable<WorkspaceEntity> get series => entities.values.where(
    (e) => e.kind == WorkspaceEntityKind.series && !e.isDeleted,
  );
  Iterable<WorkspaceEntity> get dataTables => entities.values.where(
    (e) => e.kind == WorkspaceEntityKind.dataTable && !e.isDeleted,
  );
  Iterable<WorkspaceEntity> get dataRows => entities.values.where(
    (e) => e.kind == WorkspaceEntityKind.dataRow && !e.isDeleted,
  );
  Iterable<WorkspaceEntity> get tableTypes => entities.values.where(
    (e) => e.kind == WorkspaceEntityKind.tableType && !e.isDeleted,
  );
  WorkspaceEntity? find(WorkspaceEntityKind kind, String id) =>
      entities['${kind.name}:$id'];
}

abstract interface class WorkspaceCommandStore {
  Future<WorkspaceSnapshot> load();
  Stream<WorkspaceSnapshot> watch();
  Future<WorkspaceReceipt> execute(WorkspaceCommand command);
  Future<WorkspaceReceipt> undo(
    String changesetId, {
    required String operationId,
  });
}
