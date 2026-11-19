import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/business_model_codec.dart';
import '../domain/models/data_table.dart';
import '../domain/workspace/workspace_commands.dart';
import 'local_workspace_session.dart';
import 'providers.dart';
import 'workspace_ui_commands.dart';

final businessUiCommandsProvider = Provider<BusinessUiCommands>(
  (ref) => BusinessUiCommands(
    ref.watch(dataTableProvider.notifier),
    session: ref.watch(localWorkspaceSessionProvider),
  ),
);

class BusinessUiCommands {
  BusinessUiCommands(this.store, {this.session});
  final DataTableStore store;
  final LocalWorkspaceSession? session;
  bool _busy = false;
  Future<T> _guard<T>(Future<T> Function() action) async {
    if (_busy) throw WorkspaceBusy();
    _busy = true;
    try {
      return await action();
    } finally {
      _busy = false;
    }
  }

  WorkspaceMutation _action(
    WorkspaceEntityKind kind,
    String id,
    Map<String, Object?> patch, {
    int? version,
    bool delete = false,
  }) => WorkspaceMutation(
    actionId: '${kind.name}_$id',
    kind: kind,
    entityId: id,
    expectedVersion: version,
    mutation: delete
        ? WorkspaceMutationKind.delete
        : version == null
        ? WorkspaceMutationKind.create
        : WorkspaceMutationKind.update,
    patch: patch,
  );
  Future<WorkspaceReceipt> _commit(List<WorkspaceMutation> actions) =>
      session!.execute(
        WorkspaceCommand(
          operationId: newWorkspaceId('business'),
          actions: actions,
        ),
      );
  void _tableCurrent(DataTableDef table) {
    final actual = session!.snapshot.find(
      WorkspaceEntityKind.dataTable,
      table.id,
    );
    if (actual == null || actual.isDeleted || actual.version != table.version) {
      throw const WorkspaceFailure(WorkspaceFailureCode.versionConflict);
    }
  }

  Future<DataTableType> createType(String name) => _guard(() async {
    if (session == null) return store.createType(name);
    final receipt = await _commit([
      _action(WorkspaceEntityKind.tableType, newWorkspaceId('type'), {
        'name': name,
      }),
    ]);
    final e = receipt.affected.single;
    return DataTableType(
      id: e.id,
      name: e.data['name']! as String,
      version: e.version,
    );
  });

  Future<DataTableDef> createTable({
    required String name,
    required List<DataColumnDef> columns,
    String description = '',
    String iconKey = 'table',
    String? typeId,
    List<Map<String, String>> seedRows = const [],
  }) => _guard(() async {
    if (session == null) {
      return store.createTable(
        name: name,
        columns: columns,
        description: description,
        iconKey: iconKey,
        typeId: typeId,
        seedRows: seedRows,
      );
    }
    final id = newWorkspaceId('table');
    final localColumns = [
      for (final f in columns)
        DataColumnDef(
          id: newWorkspaceId('field'),
          name: f.name,
          type: f.type,
          isRequired: f.isRequired,
          enumOptions: f.enumOptions,
          unit: f.unit,
          scale: f.scale,
        ),
    ];
    final draft = DataTableDef(
      id: id,
      name: name,
      columns: localColumns,
      createdAt: DateTime.now(),
    );
    final receipt = await _commit([
      _action(WorkspaceEntityKind.dataTable, id, {
        'name': name,
        'description': description,
        'icon_key': iconKey,
        'type_id': typeId,
        'fields': [
          for (final f in localColumns)
            {
              'id': f.id,
              'name': f.name,
              'type': f.fieldType.name,
              'required': f.isRequired,
              'options': f.enumOptions,
              'unit': f.unit,
              if (f.fieldType == DataFieldType.money) 'scale': f.scale,
            },
        ],
      }),
      for (final values in seedRows)
        _action(WorkspaceEntityKind.dataRow, newWorkspaceId('row'), {
          'table_id': id,
          'values': businessInputValues(draft, values),
        }),
    ]);
    return businessTable(receipt.affected.first);
  });

  Future<void> renameTable(DataTableDef table, String name) => _changeTable(
    table,
    {'name': name},
    () => store.renameTable(table.id, name),
  );
  Future<void> assignType(DataTableDef table, String? typeId) => _changeTable(
    table,
    {'type_id': typeId},
    () => store.assignTableType(table.id, typeId),
  );
  Future<void> archiveTable(DataTableDef table) => _changeTable(table, {
    'archived': true,
  }, () => store.archiveTable(table.id));

  int fieldUsageCount(DataTableDef table, String fieldKey) =>
      store.fieldUsageCount(table.id, fieldKey);

  /// Production rows store values keyed by field ID; a field edit changes the
  /// table entity and, when needed, row values in one atomic command.
  Map<String, Object?> _fieldEntry(DataColumnDef field, {String? id}) => {
    'id': id ?? field.id,
    'name': field.name,
    'type': field.fieldType.name,
    'required': field.isRequired,
    'options': field.enumOptions,
    'unit': field.unit,
    if (field.fieldType == DataFieldType.money) 'scale': field.scale,
  };

  Future<UiWorkspaceChange<void>> renameField(
    DataTableDef table,
    String fieldKey,
    String name,
  ) => _guard(() async {
    final oldName = table.columns
        .firstWhere((f) => (f.id ?? f.name) == fieldKey)
        .name;
    if (session == null) {
      store.renameField(table.id, fieldKey, name);
      return UiWorkspaceChange(
        null,
        () async => store.renameField(table.id, fieldKey, oldName),
      );
    }
    _tableCurrent(table);
    final entity = _tableEntity(table);
    final fields = (entity.data['fields']! as List)
        .cast<Map<String, Object?>>()
        .map((f) => f['id'] == fieldKey ? {...f, 'name': name.trim()} : f)
        .toList();
    final receipt = await _commit([
      _action(WorkspaceEntityKind.dataTable, table.id, {
        'fields': fields,
        'schema_version': (entity.data['schema_version']! as int) + 1,
      }, version: entity.version),
    ]);
    return _undoable(receipt);
  });

  Future<UiWorkspaceChange<void>> addField(
    DataTableDef table,
    DataColumnDef field, {
    String? backfillValue,
  }) => _guard(() async {
    if (session == null) {
      store.addField(table.id, field, backfillValue: backfillValue);
      return UiWorkspaceChange(null, () async {
        final added = store
            .tableById(table.id)!
            .columns
            .firstWhere((c) => c.name == field.name);
        store.removeField(table.id, added.id ?? added.name);
      });
    }
    _tableCurrent(table);
    final entity = _tableEntity(table);
    final id = newWorkspaceId('field');
    final entry = _fieldEntry(field, id: id);
    final fields = [
      ...(entity.data['fields']! as List).cast<Map<String, Object?>>(),
      entry,
    ];
    final rows = session!.snapshot.entities.values
        .where(
          (e) =>
              e.kind == WorkspaceEntityKind.dataRow &&
              !e.isDeleted &&
              e.data['table_id'] == table.id,
        )
        .toList();
    // A required field must not leave existing rows invalid; the same atomic
    // command backfills every row with the user-provided value.
    if (field.isRequired &&
        rows.isNotEmpty &&
        (backfillValue == null || backfillValue.isEmpty)) {
      throw const WorkspaceFailure(WorkspaceFailureCode.validation);
    }
    final appliesBackfill = backfillValue != null && backfillValue.isNotEmpty;
    // [businessInputValues] parses the UI string into the canonical cell form
    // (bool/datetime/decimal) against the post-change schema.
    final backfill = !appliesBackfill
        ? const <String, Object?>{}
        : businessInputValues(
            table.copyWith(
              columns: [
                ...table.columns,
                DataColumnDef(
                  name: field.name,
                  type: field.type,
                  isRequired: field.isRequired,
                  enumOptions: field.enumOptions,
                  unit: field.unit,
                  id: id,
                  scale: field.scale,
                ),
              ],
            ),
            {field.name: backfillValue},
          );
    final receipt = await _commit([
      _action(WorkspaceEntityKind.dataTable, table.id, {
        'fields': fields,
        'schema_version': (entity.data['schema_version']! as int) + 1,
      }, version: entity.version),
      for (final row in rows)
        _action(WorkspaceEntityKind.dataRow, row.id, {
          'values': {
            ...row.data['values']! as Map<String, Object?>,
            ...backfill,
          },
        }, version: row.version),
    ]);
    return _undoable(receipt);
  });

  Future<UiWorkspaceChange<void>> removeField(
    DataTableDef table,
    String fieldKey,
  ) => _guard(() async {
    final removed = table.columns.firstWhere(
      (f) => (f.id ?? f.name) == fieldKey,
    );
    if (session == null) {
      final saved = [
        for (final row in store.rowsOf(table.id))
          if (row.values[removed.name]?.isNotEmpty ?? false)
            (row.id, row.values[removed.name]!),
      ];
      store.removeField(table.id, fieldKey);
      return UiWorkspaceChange(null, () async {
        store.addField(table.id, removed);
        for (final (rowId, value) in saved) {
          store.updateCell(rowId, removed.name, value);
        }
      });
    }
    _tableCurrent(table);
    final entity = _tableEntity(table);
    final original = entity.data['fields']! as List;
    final fields = original
        .cast<Map<String, Object?>>()
        .where((f) => f['id'] != fieldKey)
        .toList();
    if (fields.length == original.length) {
      throw const WorkspaceFailure(WorkspaceFailureCode.validation);
    }
    final affected = session!.snapshot.entities.values
        .where(
          (e) =>
              e.kind == WorkspaceEntityKind.dataRow &&
              !e.isDeleted &&
              e.data['table_id'] == table.id &&
              (e.data['values']! as Map).containsKey(fieldKey),
        )
        .toList();
    // FC1 bounds one command at 500 actions; refuse a doomed batch up front
    // with a specific message instead of the generic limit failure.
    if (affected.length + 1 > 500) {
      throw const WorkspaceFailure(WorkspaceFailureCode.validation);
    }
    final receipt = await _commit([
      _action(WorkspaceEntityKind.dataTable, table.id, {
        'fields': fields,
        'schema_version': (entity.data['schema_version']! as int) + 1,
      }, version: entity.version),
      // Cell removal rides the same transaction; partial deletes cannot pass.
      for (final row in affected)
        _action(WorkspaceEntityKind.dataRow, row.id, {
          'values': {
            for (final entry
                in (row.data['values']! as Map<String, Object?>).entries)
              if (entry.key != fieldKey) entry.key: entry.value,
          },
        }, version: row.version),
    ]);
    return _undoable(receipt);
  });

  UiWorkspaceChange<void> _undoable(WorkspaceReceipt receipt) =>
      UiWorkspaceChange(
        null,
        () => session!.undo(receipt.changesetId, newWorkspaceId('undo')),
      );

  WorkspaceEntity _tableEntity(DataTableDef table) {
    final entity = session!.snapshot.find(
      WorkspaceEntityKind.dataTable,
      table.id,
    );
    if (entity == null || entity.isDeleted) {
      throw const WorkspaceFailure(WorkspaceFailureCode.versionConflict);
    }
    return entity;
  }

  Future<UiWorkspaceChange<void>> deleteTable(DataTableDef table) =>
      _guard(() async {
        if (session == null) {
          final saved = store.tableById(table.id);
          if (saved == null) {
            throw const WorkspaceFailure(WorkspaceFailureCode.versionConflict);
          }
          final rows = store.rowsOf(table.id);
          store.deleteTable(table.id);
          return UiWorkspaceChange(
            null,
            () async => store.restoreTable(saved, rows),
          );
        }
        _tableCurrent(table);
        final rows = session!.snapshot.entities.values
            .where(
              (e) =>
                  e.kind == WorkspaceEntityKind.dataRow &&
                  !e.isDeleted &&
                  e.data['table_id'] == table.id,
            )
            .toList();
        // Same FC1 action bound as field removal; refuse oversized batches up
        // front with a readable failure.
        if (rows.length + 1 > 500) {
          throw const WorkspaceFailure(WorkspaceFailureCode.validation);
        }
        final receipt = await _commit([
          _action(
            WorkspaceEntityKind.dataTable,
            table.id,
            {},
            version: table.version,
            delete: true,
          ),
          // Rows and table leave in one transaction; the graph check rejects
          // any orphaned row, so a partial delete can never commit.
          for (final row in rows)
            _action(
              WorkspaceEntityKind.dataRow,
              row.id,
              {},
              version: row.version,
              delete: true,
            ),
        ]);
        return _undoable(receipt);
      });

  Future<void> _changeTable(
    DataTableDef table,
    Map<String, Object?> patch,
    void Function() fallback,
  ) => _guard(() async {
    if (session == null) {
      fallback();
      return;
    }
    await _commit([
      _action(
        WorkspaceEntityKind.dataTable,
        table.id,
        patch,
        version: table.version,
      ),
    ]);
  });

  DataRow _row(WorkspaceEntity e, DataTableDef table) => DataRow(
    id: e.id,
    tableId: table.id,
    version: e.version,
    values: businessDisplayValues(
      table,
      e.data['values']! as Map<String, Object?>,
    ),
    updatedAt: e.updatedAt.toLocal(),
    source: e.data['source'] == 'ai'
        ? DataChangeSource.ai
        : DataChangeSource.manual,
  );
  Future<DataRow> addRow(DataTableDef table, Map<String, String> values) =>
      _guard(() async {
        if (session == null) return store.addRow(table.id, values);
        _tableCurrent(table);
        final receipt = await _commit([
          _action(WorkspaceEntityKind.dataRow, newWorkspaceId('row'), {
            'table_id': table.id,
            'values': businessInputValues(table, values),
          }),
        ]);
        return _row(receipt.affected.single, table);
      });
  Future<void> updateCell(
    DataTableDef table,
    DataRow row,
    String field,
    String value,
  ) => _guard(() async {
    if (session == null) {
      store.updateCell(row.id, field, value);
      return;
    }
    _tableCurrent(table);
    // Keep exact persisted values for untouched cells, including missing vs null.
    final current = session!.snapshot.find(WorkspaceEntityKind.dataRow, row.id);
    if (current == null ||
        current.isDeleted ||
        current.version != row.version) {
      throw const WorkspaceFailure(WorkspaceFailureCode.versionConflict);
    }
    final values = {
      ...current.data['values']! as Map<String, Object?>,
      ...businessInputValues(table, {field: value}),
    };
    await _commit([
      _action(WorkspaceEntityKind.dataRow, row.id, {
        'values': values,
      }, version: row.version),
    ]);
  });
  Future<UiWorkspaceChange<void>> deleteRow(DataRow row) => _guard(() async {
    if (session == null) {
      store.deleteRow(row.id);
      return UiWorkspaceChange(null, () async => store.insertRowRaw(row));
    }
    final receipt = await _commit([
      _action(
        WorkspaceEntityKind.dataRow,
        row.id,
        {},
        version: row.version,
        delete: true,
      ),
    ]);
    final undoId = newWorkspaceId('undo');
    return UiWorkspaceChange(
      null,
      () => session!.undo(receipt.changesetId, undoId),
    );
  });
  Future<void> restoreRow(DataRow row, DataChangeLog log) => _guard(() async {
    if (session == null) {
      store.rollbackTo(row.id, log.id);
      return;
    }
    if (log.rowId != row.id || log.persistedValues == null) {
      throw const WorkspaceFailure(WorkspaceFailureCode.validation);
    }
    await _commit([
      _action(WorkspaceEntityKind.dataRow, row.id, {
        'values': log.persistedValues,
      }, version: row.version),
    ]);
  });
}
