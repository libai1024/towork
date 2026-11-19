import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../domain/data_tables/business_validation.dart';
import '../../domain/workspace/workspace_commands.dart';
import '../../domain/workspace/workspace_validation.dart';
import 'app_database.dart';

enum WorkspaceCommitCheckpoint { entitiesWritten, receiptWritten }

/// The database is application-owned. All mutation entry points share this store;
/// awaiting a receipt means data, audit and idempotency key have committed.
class SqliteWorkspaceCommandStore implements WorkspaceCommandStore {
  SqliteWorkspaceCommandStore(
    this.db, {
    DateTime Function()? clock,
    this.checkpoint,
  }) : _clock = clock ?? DateTime.now;
  final AppDatabase db;
  final DateTime Function() _clock;

  /// Synchronous fault injection only. Never perform IO/model calls in a transaction.
  final void Function(WorkspaceCommitCheckpoint)? checkpoint;

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on WorkspaceFailure {
      rethrow;
    } catch (_) {
      throw const WorkspaceFailure(WorkspaceFailureCode.storageUnavailable);
    }
  }

  // A single SELECT gives one consistent SQLite snapshot without acquiring a
  // write lock, so existing records remain readable on read-only storage.
  Selectable<QueryRow> _snapshotQuery() => db.customSelect(
    "SELECT 'todo' AS kind, id, version, payload, created_at, updated_at, deleted_at FROM work_todos "
    "UNION ALL SELECT 'category' AS kind, id, version, payload, created_at, updated_at, deleted_at FROM work_categories "
    "UNION ALL SELECT 'series' AS kind, id, version, payload, created_at, updated_at, deleted_at FROM work_todo_series "
    "UNION ALL SELECT 'dataTable' AS kind, id, version, payload, created_at, updated_at, deleted_at FROM work_data_tables "
    "UNION ALL SELECT 'dataRow' AS kind, id, version, payload, created_at, updated_at, deleted_at FROM work_data_rows "
    "UNION ALL SELECT 'tableType' AS kind, id, version, payload, created_at, updated_at, deleted_at FROM work_table_types",
    readsFrom: {
      db.workTodos,
      db.workCategories,
      db.workTodoSeries,
      db.workDataTables,
      db.workDataRows,
      db.workTableTypes,
    },
  );

  WorkspaceSnapshot _decode(List<QueryRow> rows) => WorkspaceSnapshot([
    for (final row in rows)
      WorkspaceEntity(
        kind: WorkspaceEntityKind.values.byName(row.read<String>('kind')),
        id: row.read<String>('id'),
        version: row.read<int>('version'),
        data: (jsonDecode(row.read<String>('payload')) as Map)
            .cast<String, Object?>(),
        createdAt: DateTime.fromMicrosecondsSinceEpoch(
          row.read<int>('created_at'),
          isUtc: true,
        ),
        updatedAt: DateTime.fromMicrosecondsSinceEpoch(
          row.read<int>('updated_at'),
          isUtc: true,
        ),
        deletedAt: row.readNullable<int>('deleted_at') == null
            ? null
            : DateTime.fromMicrosecondsSinceEpoch(
                row.read<int>('deleted_at'),
                isUtc: true,
              ),
      ),
  ]);

  Future<WorkspaceSnapshot> _read() async =>
      _decode(await _snapshotQuery().get());

  @override
  Future<WorkspaceSnapshot> load() => _guard(_read);

  /// Table and type entities only. Bounded read paths that page rows directly
  /// in SQL use this instead of materializing every row in Dart.
  Future<WorkspaceSnapshot> loadTables() => _guard(
    () async => _decode(
      await db
          .customSelect(
            "SELECT 'dataTable' AS kind, id, version, payload, created_at, updated_at, deleted_at FROM work_data_tables "
            "UNION ALL SELECT 'tableType' AS kind, id, version, payload, created_at, updated_at, deleted_at FROM work_table_types",
            readsFrom: {db.workDataTables, db.workTableTypes},
          )
          .get(),
    ),
  );

  @override
  Stream<WorkspaceSnapshot> watch() =>
      _snapshotQuery().watch().map(_decode).handleError((Object error) {
        if (error is WorkspaceFailure) throw error;
        throw const WorkspaceFailure(WorkspaceFailureCode.storageUnavailable);
      });

  String _digest(Map<String, Object?> input) =>
      sha256.convert(utf8.encode(canonicalWorkspaceJson(input))).toString();

  Future<WorkspaceReceipt?> _existing(String operationId, String digest) async {
    final row = await (db.select(
      db.workspaceOperations,
    )..where((r) => r.operationId.equals(operationId))).getSingleOrNull();
    if (row == null) return null;
    if (row.requestDigest != digest) {
      throw const WorkspaceFailure(WorkspaceFailureCode.idempotencyMismatch);
    }
    return WorkspaceReceipt.fromJson(
      (jsonDecode(row.receipt) as Map).cast<String, Object?>(),
    );
  }

  @override
  Future<WorkspaceReceipt> execute(WorkspaceCommand command) async {
    validateWorkspaceId(command.operationId);
    if (!{'manual', 'agent', 'system'}.contains(command.source) ||
        command.actions.isEmpty ||
        command.actions.length > 500) {
      throw const WorkspaceFailure(WorkspaceFailureCode.validation);
    }
    final ids = <String>{};
    final keys = <String>{};
    for (final action in command.actions) {
      validateWorkspaceId(action.actionId);
      validateWorkspaceId(action.entityId);
      if (!ids.add(action.actionId) ||
          !keys.add(action.key) ||
          (action.mutation == WorkspaceMutationKind.create
              ? action.expectedVersion != null
              : (action.expectedVersion == null ||
                    action.expectedVersion! < 1)) ||
          (action.mutation == WorkspaceMutationKind.delete &&
              action.patch.isNotEmpty)) {
        throw const WorkspaceFailure(WorkspaceFailureCode.validation);
      }
    }
    final digest = _digest(command.toJson());
    return _guard(
      () => db.transaction(() async {
        final existing = await _existing(command.operationId, digest);
        if (existing != null) return existing;
        final current = await _read();
        final next = {...current.entities};
        final before = <WorkspaceEntity?>[];
        final affected = <WorkspaceEntity>[];
        final now = _clock().toUtc();
        for (final action in command.actions) {
          final old = current.entities[action.key];
          if (action.mutation == WorkspaceMutationKind.create) {
            // Tombstones reserve the ID, preventing delete/recreate ABA conflicts.
            if (old != null) {
              throw WorkspaceFailure(
                WorkspaceFailureCode.versionConflict,
                entityId: action.entityId,
              );
            }
          } else {
            if (old == null || old.isDeleted) {
              throw WorkspaceFailure(
                WorkspaceFailureCode.notFound,
                entityId: action.entityId,
              );
            }
            if (old.version != action.expectedVersion) {
              throw WorkspaceFailure(
                WorkspaceFailureCode.versionConflict,
                entityId: action.entityId,
              );
            }
          }
          final deleting = action.mutation == WorkspaceMutationKind.delete;
          final changed = WorkspaceEntity(
            kind: action.kind,
            id: action.entityId,
            version: (old?.version ?? 0) + 1,
            data: deleting
                ? old!.data
                : applyWorkspacePatch(
                    action.kind,
                    old?.data,
                    action.patchFor(current),
                    now,
                  ),
            createdAt: old?.createdAt ?? now,
            updatedAt: now,
            deletedAt: deleting ? now : null,
          );
          before.add(old);
          affected.add(changed);
          next[changed.key] = changed;
        }
        // Resolve values after all actions so row/table order does not matter.
        for (var i = 0; i < affected.length; i++) {
          final row = affected[i];
          if (row.kind != WorkspaceEntityKind.dataRow || row.isDeleted) {
            continue;
          }
          final table = next['dataTable:${row.data['table_id']}'];
          if (table == null || table.isDeleted) {
            throw const WorkspaceFailure(WorkspaceFailureCode.validation);
          }
          final normalized = WorkspaceEntity(
            kind: row.kind,
            id: row.id,
            version: row.version,
            data: {
              ...row.data,
              'values': normalizeBusinessValues(
                table.data,
                row.data['values']! as Map<String, Object?>,
              ),
            },
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
          );
          affected[i] = normalized;
          next[row.key] = normalized;
        }
        validateWorkspaceGraph(next.values);
        return _commit(
          command.operationId,
          digest,
          command.source,
          now,
          before,
          affected,
        );
      }),
    );
  }

  @override
  Future<WorkspaceReceipt> undo(
    String changesetId, {
    required String operationId,
  }) async {
    validateWorkspaceId(changesetId);
    validateWorkspaceId(operationId);
    final digest = _digest({
      'schema_version': 1,
      'operation_id': operationId,
      'undo_of': changesetId,
    });
    return _guard(
      () => db.transaction(() async {
        final existing = await _existing(operationId, digest);
        if (existing != null) return existing;
        final original = await (db.select(
          db.workspaceOperations,
        )..where((r) => r.operationId.equals(changesetId))).getSingleOrNull();
        if (original == null) {
          throw const WorkspaceFailure(WorkspaceFailureCode.notFound);
        }
        final changes = jsonDecode(original.changes) as List;
        final current = await _read();
        final next = {...current.entities};
        final before = <WorkspaceEntity?>[];
        final affected = <WorkspaceEntity>[];
        final now = _clock().toUtc();
        for (final raw in changes) {
          final change = (raw as Map).cast<String, Object?>();
          final was = change['before'] == null
              ? null
              : WorkspaceEntity.fromJson(
                  (change['before'] as Map).cast<String, Object?>(),
                );
          final after = WorkspaceEntity.fromJson(
            (change['after'] as Map).cast<String, Object?>(),
          );
          final actual = current.entities[after.key];
          if (actual == null || actual.version != after.version) {
            throw WorkspaceFailure(
              WorkspaceFailureCode.versionConflict,
              entityId: after.id,
            );
          }
          final changed = WorkspaceEntity(
            kind: after.kind,
            id: after.id,
            version: actual.version + 1,
            data: was?.data ?? actual.data,
            createdAt: actual.createdAt,
            updatedAt: now,
            deletedAt: was == null || was.isDeleted ? now : null,
          );
          before.add(actual);
          affected.add(changed);
          next[changed.key] = changed;
        }
        validateWorkspaceGraph(next.values);
        return _commit(
          operationId,
          digest,
          'manual',
          now,
          before,
          affected,
          undoOf: changesetId,
        );
      }),
    );
  }

  /// Collapses a causally contiguous group into one compensating transaction.
  /// An intervening edit, even later overwritten by the Agent, is a conflict.
  Future<WorkspaceReceipt> undoMany(
    List<String> changesetIds, {
    required String operationId,
  }) async {
    final ids = List<String>.unmodifiable(changesetIds);
    if (ids.isEmpty || ids.length > 256 || ids.toSet().length != ids.length) {
      throw const WorkspaceFailure(WorkspaceFailureCode.validation);
    }
    validateWorkspaceId(operationId);
    for (final id in ids) {
      validateWorkspaceId(id);
    }
    final digest = _digest({
      'schema_version': 1,
      'operation_id': operationId,
      'undo_many': ids,
    });
    return _guard(
      () => db.transaction(() async {
        final existing = await _existing(operationId, digest);
        if (existing != null) return existing;
        final earliest = <String, WorkspaceEntity?>{};
        final latest = <String, WorkspaceEntity>{};
        for (final id in ids) {
          final original = await (db.select(
            db.workspaceOperations,
          )..where((r) => r.operationId.equals(id))).getSingleOrNull();
          if (original == null) {
            throw const WorkspaceFailure(WorkspaceFailureCode.notFound);
          }
          for (final raw in jsonDecode(original.changes) as List) {
            final change = (raw as Map).cast<String, Object?>();
            final before = change['before'] == null
                ? null
                : WorkspaceEntity.fromJson(
                    (change['before'] as Map).cast<String, Object?>(),
                  );
            final after = WorkspaceEntity.fromJson(
              (change['after'] as Map).cast<String, Object?>(),
            );
            if (latest.containsKey(after.key)) {
              if (canonicalWorkspaceJson(latest[after.key]!.toJson()) !=
                  canonicalWorkspaceJson(before?.toJson())) {
                throw WorkspaceFailure(
                  WorkspaceFailureCode.versionConflict,
                  entityId: after.id,
                );
              }
            } else {
              earliest[after.key] = before;
            }
            latest[after.key] = after;
          }
        }
        final current = await _read();
        final next = {...current.entities};
        final before = <WorkspaceEntity?>[], affected = <WorkspaceEntity>[];
        final now = _clock().toUtc();
        for (final entry in latest.entries) {
          final actual = current.entities[entry.key];
          if (canonicalWorkspaceJson(actual?.toJson()) !=
              canonicalWorkspaceJson(entry.value.toJson())) {
            throw WorkspaceFailure(
              WorkspaceFailureCode.versionConflict,
              entityId: entry.value.id,
            );
          }
          final was = earliest[entry.key];
          final restored = WorkspaceEntity(
            kind: actual!.kind,
            id: actual.id,
            version: actual.version + 1,
            data: was?.data ?? actual.data,
            createdAt: actual.createdAt,
            updatedAt: now,
            deletedAt: was == null || was.isDeleted ? now : null,
          );
          before.add(actual);
          affected.add(restored);
          next[entry.key] = restored;
        }
        validateWorkspaceGraph(next.values);
        return _commit(
          operationId,
          digest,
          'manual',
          now,
          before,
          affected,
          undoOfMany: ids,
        );
      }),
    );
  }

  Future<WorkspaceReceipt> _commit(
    String operationId,
    String digest,
    String source,
    DateTime now,
    List<WorkspaceEntity?> before,
    List<WorkspaceEntity> affected, {
    String? undoOf,
    List<String>? undoOfMany,
  }) async {
    for (final entity in affected) {
      final payload = canonicalWorkspaceJson(entity.data);
      if (entity.kind == WorkspaceEntityKind.todo) {
        await db
            .into(db.workTodos)
            .insertOnConflictUpdate(
              WorkTodosCompanion.insert(
                id: entity.id,
                version: entity.version,
                categoryId: Value(entity.data['category_id'] as String?),
                seriesId: Value(entity.data['series_id'] as String?),
                occurrenceKey: Value(entity.data['occurrence_key'] as String?),
                occurrenceIndex: Value(entity.data['occurrence_index'] as int?),
                status: entity.data['status']! as String,
                dueAt: Value(
                  entity.data['due_at'] == null
                      ? null
                      : DateTime.parse(entity.data['due_at']! as String),
                ),
                sortOrder: entity.data['sort_order']! as int,
                payload: payload,
                createdAt: entity.createdAt.microsecondsSinceEpoch,
                updatedAt: entity.updatedAt.microsecondsSinceEpoch,
                deletedAt: Value(entity.deletedAt?.microsecondsSinceEpoch),
              ),
            );
      } else if (entity.kind == WorkspaceEntityKind.series) {
        await db
            .into(db.workTodoSeries)
            .insertOnConflictUpdate(
              WorkTodoSeriesCompanion.insert(
                id: entity.id,
                version: entity.version,
                payload: payload,
                createdAt: entity.createdAt.microsecondsSinceEpoch,
                updatedAt: entity.updatedAt.microsecondsSinceEpoch,
                deletedAt: Value(entity.deletedAt?.microsecondsSinceEpoch),
              ),
            );
      } else if (entity.kind == WorkspaceEntityKind.category) {
        await db
            .into(db.workCategories)
            .insertOnConflictUpdate(
              WorkCategoriesCompanion.insert(
                id: entity.id,
                version: entity.version,
                parentId: Value(entity.data['parent_id'] as String?),
                archived: entity.data['archived']! as bool,
                sortOrder: entity.data['sort_order']! as int,
                payload: payload,
                createdAt: entity.createdAt.microsecondsSinceEpoch,
                updatedAt: entity.updatedAt.microsecondsSinceEpoch,
                deletedAt: Value(entity.deletedAt?.microsecondsSinceEpoch),
              ),
            );
      } else if (entity.kind == WorkspaceEntityKind.dataTable) {
        await db
            .into(db.workDataTables)
            .insertOnConflictUpdate(
              WorkDataTablesCompanion.insert(
                id: entity.id,
                version: entity.version,
                typeId: Value(entity.data['type_id'] as String?),
                archived: entity.data['archived']! as bool,
                schemaRevision: entity.data['schema_version']! as int,
                payload: payload,
                createdAt: entity.createdAt.microsecondsSinceEpoch,
                updatedAt: entity.updatedAt.microsecondsSinceEpoch,
                deletedAt: Value(entity.deletedAt?.microsecondsSinceEpoch),
              ),
            );
      } else if (entity.kind == WorkspaceEntityKind.dataRow) {
        await db
            .into(db.workDataRows)
            .insertOnConflictUpdate(
              WorkDataRowsCompanion.insert(
                id: entity.id,
                version: entity.version,
                tableId: entity.data['table_id']! as String,
                payload: payload,
                createdAt: entity.createdAt.microsecondsSinceEpoch,
                updatedAt: entity.updatedAt.microsecondsSinceEpoch,
                deletedAt: Value(entity.deletedAt?.microsecondsSinceEpoch),
              ),
            );
      } else if (entity.kind == WorkspaceEntityKind.tableType) {
        await db
            .into(db.workTableTypes)
            .insertOnConflictUpdate(
              WorkTableTypesCompanion.insert(
                id: entity.id,
                version: entity.version,
                payload: payload,
                createdAt: entity.createdAt.microsecondsSinceEpoch,
                updatedAt: entity.updatedAt.microsecondsSinceEpoch,
                deletedAt: Value(entity.deletedAt?.microsecondsSinceEpoch),
              ),
            );
      }
    }
    checkpoint?.call(WorkspaceCommitCheckpoint.entitiesWritten);
    final receipt = WorkspaceReceipt(
      operationId: operationId,
      committedAt: now,
      affected: affected,
      undoOf: undoOfMany ?? [?undoOf],
    );
    await db
        .into(db.workspaceOperations)
        .insert(
          WorkspaceOperationsCompanion.insert(
            operationId: operationId,
            requestDigest: digest,
            source: source,
            undoOf: Value(undoOf),
            receipt: canonicalWorkspaceJson(receipt.toJson()),
            changes: canonicalWorkspaceJson([
              for (var i = 0; i < affected.length; i++)
                {'before': before[i]?.toJson(), 'after': affected[i].toJson()},
            ]),
            committedAt: now.microsecondsSinceEpoch,
          ),
        );
    checkpoint?.call(WorkspaceCommitCheckpoint.receiptWritten);
    return receipt;
  }
}
