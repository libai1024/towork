import '../../domain/models/models.dart';
import '../../domain/repositories/data_table_store.dart';
import '../seeds/data_table_seed.dart';
import 'data_table_validation.dart';
import 'repository_validation.dart';

class DataTableRepository extends DataTableStore {
  DataTableRepository({DataTableBundle? initial, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(
        _validateBundle(initial ?? seedDataTables((clock ?? DateTime.now)())),
      );

  final DateTime Function() _clock;

  int _seq = 100;
  String _nid(String prefix) {
    final ids = {
      ...state.tables.map((item) => item.id),
      ...state.types.map((item) => item.id),
      ...state.rows.map((item) => item.id),
      ...state.logs.map((item) => item.id),
      ...state.pendingBatches.map((item) => item.id),
      for (final batch in state.pendingBatches)
        ...batch.changes.map((item) => item.id),
    };
    String id;
    do {
      id = '${prefix}_gen_${_seq++}';
    } while (ids.contains(id));
    return id;
  }

  // 一次 AI 批次应用的撤销快照（Toast「撤销」用）。
  _AppliedUndo? _lastUndo;

  // -------------------------------------------------------------------------
  // 查询
  // -------------------------------------------------------------------------

  @override
  DataTableDef? tableById(String id) {
    for (final t in state.tables) {
      if (t.id == id) return t;
    }
    return null;
  }

  @override
  List<DataRow> rowsOf(String tableId) {
    final list = state.rows.where((r) => r.tableId == tableId).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  List<DataChangeLog> logsOfRow(String rowId) {
    // Appended order breaks equal-timestamp ties deterministically.
    final indexed =
        state.logs.indexed.where((entry) => entry.$2.rowId == rowId).toList()
          ..sort((a, b) {
            final time = b.$2.createdAt.compareTo(a.$2.createdAt);
            return time != 0 ? time : b.$1.compareTo(a.$1);
          });
    return List.unmodifiable(indexed.map((entry) => entry.$2));
  }

  @override
  List<PendingAiBatch> batchesOf(String tableId) =>
      state.pendingBatches.where((b) => b.tableId == tableId).toList();

  @override
  int pendingCountOf(String tableId) =>
      batchesOf(tableId).fold(0, (sum, b) => sum + b.changes.length);

  /// 目标时间点之后（不含）该行被改动的字段数，用于回滚确认文案。
  @override
  int changesAfter(String rowId, DateTime at) => state.logs
      .where((l) => l.rowId == rowId && l.createdAt.isAfter(at))
      .length;

  // -------------------------------------------------------------------------
  // 表的创建与管理
  // -------------------------------------------------------------------------

  @override
  DataTableType createType(String name) {
    final value = _requireTypeName(name);
    if (state.types.any(
      (type) => type.name.toLowerCase() == value.toLowerCase(),
    )) {
      throw const RepositoryException(RepositoryErrorCode.conflict, '该类型已存在');
    }
    final type = DataTableType(id: _nid('type'), name: value);
    state = state.copyWith(types: [...state.types, type]);
    return type;
  }

  @override
  void assignTableType(String tableId, String? typeId) {
    _requireTable(tableId);
    _requireType(typeId);
    state = state.copyWith(
      tables: [
        for (final table in state.tables)
          table.id == tableId ? table.copyWith(typeId: typeId) : table,
      ],
    );
  }

  @override
  DataTableDef createTable({
    required String name,
    String iconKey = 'table',
    String description = '',
    required List<DataColumnDef> columns,
    List<Map<String, String>> seedRows = const [],
    String? typeId,
  }) {
    requireText(name, '表名');
    validateDataTableColumns(columns);
    _requireType(typeId);
    final table = DataTableDef(
      id: _nid('dt'),
      name: name.trim(),
      iconKey: iconKey,
      description: description,
      columns: columns,
      createdAt: _clock(),
      typeId: typeId,
    );
    for (final values in seedRows) {
      validateDataRowValues(table, values);
    }
    final staged = DataTableRepository(
      initial: state.copyWith(tables: [...state.tables, table]),
      clock: _clock,
    ).._seq = _seq;
    try {
      for (final values in seedRows) {
        staged.addRow(table.id, values);
      }
      _seq = staged._seq;
      state = staged.snapshot;
    } finally {
      staged.dispose();
    }
    return table;
  }

  @override
  void renameTable(String id, String name) {
    _requireTable(id);
    final validName = requireText(name, '表名');
    state = state.copyWith(
      tables: [
        for (final t in state.tables)
          t.id == id ? t.copyWith(name: validName) : t,
      ],
    );
  }

  @override
  void archiveTable(String id) {
    _requireTable(id);
    state = state.copyWith(
      tables: [
        for (final t in state.tables)
          t.id == id ? t.copyWith(archived: true) : t,
      ],
    );
  }

  // -------------------------------------------------------------------------
  // 字段管理（演示内存模式；生产路径走 BusinessUiCommands 的工作区命令）
  // -------------------------------------------------------------------------

  DataColumnDef _requireField(DataTableDef table, String fieldKey) {
    for (final field in table.columns) {
      // Legacy demo columns carry no stable ID; their name is the only key.
      if (field.id == fieldKey ||
          (field.id == null && field.name == fieldKey)) {
        return field;
      }
    }
    throw const RepositoryException(RepositoryErrorCode.invalidInput, '字段不存在');
  }

  @override
  int fieldUsageCount(String tableId, String fieldKey) {
    final table = _requireTable(tableId);
    final field = _requireField(table, fieldKey);
    return state.rows
        .where(
          (r) =>
              r.tableId == tableId &&
              (r.values[field.name]?.isNotEmpty ?? false),
        )
        .length;
  }

  @override
  void renameField(String tableId, String fieldKey, String name) {
    final table = _requireTable(tableId);
    final field = _requireField(table, fieldKey);
    final validName = requireText(name, '字段名');
    final columns = [
      for (final f in table.columns)
        identical(f, field) ? f.copyWith(name: validName) : f,
    ];
    validateDataTableColumns(columns);
    state = state.copyWith(
      tables: [
        for (final t in state.tables)
          t.id == tableId
              ? t.copyWith(columns: columns, schemaVersion: t.schemaVersion + 1)
              : t,
      ],
      rows: [
        for (final r in state.rows)
          if (r.tableId != tableId || !r.values.containsKey(field.name))
            r
          else
            DataRow(
              id: r.id,
              tableId: r.tableId,
              version: r.version,
              values: {
                for (final entry in r.values.entries)
                  entry.key == field.name ? validName : entry.key: entry.value,
              },
              updatedAt: r.updatedAt,
              source: r.source,
            ),
      ],
    );
  }

  @override
  void addField(String tableId, DataColumnDef field, {String? backfillValue}) {
    final table = _requireTable(tableId);
    final column = DataColumnDef(
      name: field.name,
      type: field.type,
      isRequired: field.isRequired,
      enumOptions: field.enumOptions,
      unit: field.unit,
      id: field.id ?? _nid('field'),
      scale: field.scale,
    );
    final columns = [...table.columns, column];
    validateDataTableColumns(columns);
    final tableRows = state.rows.where((r) => r.tableId == tableId).toList();
    if (column.isRequired &&
        tableRows.isNotEmpty &&
        (backfillValue == null || backfillValue.isEmpty)) {
      throw const RepositoryException(
        RepositoryErrorCode.invalidInput,
        '必填字段需要为现有记录补一个值',
      );
    }
    final draft = table.copyWith(columns: columns);
    final rows = [
      for (final r in state.rows)
        if (r.tableId != tableId)
          r
        else
          () {
            final values = {...r.values};
            if (backfillValue != null && backfillValue.isNotEmpty) {
              values[column.name] = backfillValue;
            }
            // The same change backfills every row or fails without writing.
            validateDataRowValues(draft, values);
            return DataRow(
              id: r.id,
              tableId: r.tableId,
              version: r.version,
              values: values,
              updatedAt: r.updatedAt,
              source: r.source,
            );
          }(),
    ];
    state = state.copyWith(
      tables: [
        for (final t in state.tables)
          t.id == tableId
              ? t.copyWith(columns: columns, schemaVersion: t.schemaVersion + 1)
              : t,
      ],
      rows: rows,
    );
  }

  @override
  void removeField(String tableId, String fieldKey) {
    final table = _requireTable(tableId);
    final field = _requireField(table, fieldKey);
    if (table.columns.length == 1) {
      throw const RepositoryException(
        RepositoryErrorCode.invalidInput,
        '至少保留一个字段',
      );
    }
    final columns = [
      for (final f in table.columns)
        if (!identical(f, field)) f,
    ];
    validateDataTableColumns(columns);
    state = state.copyWith(
      tables: [
        for (final t in state.tables)
          t.id == tableId
              ? t.copyWith(columns: columns, schemaVersion: t.schemaVersion + 1)
              : t,
      ],
      rows: [
        for (final r in state.rows)
          if (r.tableId != tableId || !r.values.containsKey(field.name))
            r
          else
            r.copyWith(
              values: {
                for (final entry in r.values.entries)
                  if (entry.key != field.name) entry.key: entry.value,
              },
            ),
      ],
    );
  }

  @override
  void deleteTable(String tableId) {
    _requireTable(tableId);
    state = state.copyWith(
      tables: [
        for (final t in state.tables)
          if (t.id != tableId) t,
      ],
      rows: [
        for (final r in state.rows)
          if (r.tableId != tableId) r,
      ],
    );
  }

  @override
  void restoreTable(DataTableDef table, List<DataRow> rows) {
    if (state.tables.any((t) => t.id == table.id)) {
      throw const RepositoryException(
        RepositoryErrorCode.conflict,
        '同名标识的表已存在',
      );
    }
    state = state.copyWith(
      tables: [...state.tables, table],
      rows: [...state.rows, ...rows],
    );
  }

  // -------------------------------------------------------------------------
  // 行写入（一律留痕：每次写入生成 DataChangeLog）
  // -------------------------------------------------------------------------

  @override
  DataRow addRow(
    String tableId,
    Map<String, String> values, {
    DataChangeSource source = DataChangeSource.manual,
    String? reason,
    String? sourceLabel,
    String? id,
  }) {
    final table = _requireTable(tableId);
    validateDataRowValues(table, values);
    if (id != null && (_rowById(id) != null || id.isEmpty)) {
      throw const RepositoryException(
        RepositoryErrorCode.conflict,
        '数据行 ID 无效或已存在',
      );
    }
    final row = DataRow(
      id: id ?? _nid('dr'),
      tableId: tableId,
      values: Map.of(values),
      updatedAt: _clock(),
      source: source,
    );
    state = state.copyWith(
      rows: [...state.rows, row],
      logs: [
        ...state.logs,
        DataChangeLog(
          id: _nid('log'),
          tableId: tableId,
          rowId: row.id,
          field: '',
          oldValue: '',
          newValue: '',
          source: source,
          createdAt: row.updatedAt,
          action: DataChangeAction.create,
          reason: reason,
          sourceLabel: sourceLabel,
          afterValues: Map.of(values),
        ),
      ],
    );
    return row;
  }

  /// 原样插回一行（撤销删除用，不再写日志）。
  @override
  void insertRowRaw(DataRow row) {
    validateDataRowValues(_requireTable(row.tableId), row.values);
    if (_rowById(row.id) != null) {
      throw const RepositoryException(
        RepositoryErrorCode.conflict,
        '这条记录已存在，无法覆盖恢复',
      );
    }
    state = state.copyWith(
      rows: [...state.rows.where((r) => r.id != row.id), row],
    );
  }

  @override
  void deleteRow(
    String rowId, {
    DataChangeSource source = DataChangeSource.manual,
    String? reason,
    String? sourceLabel,
  }) {
    DataRow? target;
    for (final r in state.rows) {
      if (r.id == rowId) target = r;
    }
    if (target == null) return;
    state = state.copyWith(
      rows: state.rows.where((r) => r.id != rowId).toList(),
      logs: [
        ...state.logs,
        DataChangeLog(
          id: _nid('log'),
          tableId: target.tableId,
          rowId: rowId,
          field: '',
          oldValue: '',
          newValue: '',
          source: source,
          createdAt: _clock(),
          action: DataChangeAction.delete,
          reason: reason,
          sourceLabel: sourceLabel,
          beforeValues: Map.of(target.values),
        ),
      ],
    );
  }

  @override
  void updateCell(
    String rowId,
    String field,
    String newValue, {
    DataChangeSource source = DataChangeSource.manual,
    String? reason,
    String? sourceLabel,
  }) {
    final row = _rowById(rowId);
    if (row == null) {
      throw const RepositoryException(RepositoryErrorCode.notFound, '这条记录已删除');
    }
    final values = Map<String, String>.of(row.values)..[field] = newValue;
    validateDataRowValues(_requireTable(row.tableId), values);
    final oldValue = row.values[field] ?? '';
    if (oldValue == newValue) return;
    final now = _clock();
    state = state.copyWith(
      rows: [
        for (final r in state.rows)
          r.id == rowId
              ? r.copyWith(values: values, updatedAt: now, source: source)
              : r,
      ],
      logs: [
        ...state.logs,
        DataChangeLog(
          id: _nid('log'),
          tableId: row.tableId,
          rowId: rowId,
          field: field,
          oldValue: oldValue,
          newValue: newValue,
          source: source,
          createdAt: now,
          reason: reason,
          sourceLabel: sourceLabel,
        ),
      ],
    );
  }

  /// 多字段一次写入，生成一条带 before/after 快照的日志。
  @override
  void updateRowMulti(
    String rowId,
    Map<String, String> changes, {
    DataChangeSource source = DataChangeSource.manual,
    String? reason,
    String? sourceLabel,
  }) {
    final row = _rowById(rowId);
    if (row == null) {
      throw const RepositoryException(RepositoryErrorCode.notFound, '这条记录已删除');
    }
    if (changes.isEmpty) return;
    final values = {...row.values, ...changes};
    validateDataRowValues(_requireTable(row.tableId), values);
    if (changes.entries.every(
      (entry) => (row.values[entry.key] ?? '') == entry.value,
    )) {
      return;
    }
    final before = <String, String>{};
    for (final field in changes.keys) {
      before[field] = row.values[field] ?? '';
    }
    final now = _clock();
    state = state.copyWith(
      rows: [
        for (final r in state.rows)
          r.id == rowId
              ? r.copyWith(values: values, updatedAt: now, source: source)
              : r,
      ],
      logs: [
        ...state.logs,
        DataChangeLog(
          id: _nid('log'),
          tableId: row.tableId,
          rowId: rowId,
          field: '',
          oldValue: '',
          newValue: '',
          source: source,
          createdAt: now,
          reason: reason,
          sourceLabel: sourceLabel,
          beforeValues: before,
          afterValues: Map.of(changes),
        ),
      ],
    );
  }

  DataRow? _rowById(String rowId) {
    for (final r in state.rows) {
      if (r.id == rowId) return r;
    }
    return null;
  }

  /// 回滚到某条日志所代表的版本：把「那之后改过的字段」还原到当时的值，
  /// 回滚本身也作为一条新日志插入（不删历史）。
  @override
  void rollbackTo(String rowId, String logId) {
    final row = _rowById(rowId);
    if (row == null) return;
    final logs = logsOfRow(rowId); // 倒序
    DataChangeLog? target;
    for (final l in logs) {
      if (l.id == logId) target = l;
    }
    if (target == null || target.action == DataChangeAction.delete) return;

    // 目标版本各字段的值：从目标日志往回找每个字段最后被设定的值。
    final revert = <String, String>{};
    final targetIndex = logs.indexWhere((log) => log.id == logId);
    final newerLogs = logs.take(targetIndex).toList();
    for (final l in newerLogs.reversed) {
      if (l.beforeValues != null) {
        l.beforeValues!.forEach((field, v) {
          revert.putIfAbsent(field, () => v);
        });
      } else if (l.field.isNotEmpty) {
        revert.putIfAbsent(l.field, () => l.oldValue);
      }
    }
    // 目标日志自身 after 快照里的字段也以当时值为准（若之后未变则无需还原）。
    if (revert.isEmpty) return;
    final time = target.createdAt;
    updateRowMulti(
      rowId,
      revert,
      reason:
          '回滚至 ${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} 的版本',
    );
  }

  // -------------------------------------------------------------------------
  // AI 待确认批次（diff 确认弹窗）
  // -------------------------------------------------------------------------

  /// 追加一个待确认批次（截图分析/模拟推送共用入口）。
  @override
  PendingAiBatch pushPendingBatch({
    required String tableId,
    required String reason,
    required String sourceLabel,
    required List<PendingRowChange> changes,
  }) {
    _requireTable(tableId);
    requireUniqueIds(changes, (PendingRowChange change) => change.id);
    final batch = PendingAiBatch(
      id: _nid('pb'),
      tableId: tableId,
      reason: reason,
      sourceLabel: sourceLabel,
      createdAt: _clock(),
      changes: changes,
    );
    state = state.copyWith(pendingBatches: [...state.pendingBatches, batch]);
    return batch;
  }

  /// 模拟一条 AI 更新推送（演示用）：按表内容生成一批真实感变更。
  @override
  PendingAiBatch? simulateAiPush(String tableId) {
    if (batchesOf(tableId).isNotEmpty) return batchesOf(tableId).first;
    if (tableId == 'dt_stock') {
      final mt = _rowById('dr2');
      final byd = _rowById('dr3');
      if (mt == null || byd == null) return null;
      return pushPendingBatch(
        tableId: tableId,
        reason: '依据最新持仓截图同步：卖出比亚迪，加仓贵州茅台。',
        sourceLabel: '截图「持仓_0921.png」的分析',
        changes: [
          PendingRowChange(
            id: _nid('pc'),
            action: DataChangeAction.update,
            rowId: mt.id,
            rowLabel: mt.values['名称'] ?? '贵州茅台',
            fields: [
              PendingFieldChange(
                field: '持仓(股)',
                oldValue: mt.values['持仓(股)'],
                newValue: '500',
                confidence: 0.97,
              ),
              PendingFieldChange(
                field: '现价',
                oldValue: mt.values['现价'],
                newValue: '1680.50',
                confidence: 0.62,
              ),
            ],
          ),
          PendingRowChange(
            id: _nid('pc'),
            action: DataChangeAction.delete,
            rowId: byd.id,
            rowLabel: byd.values['名称'] ?? '比亚迪',
            fields: [
              for (final e in byd.values.entries)
                PendingFieldChange(field: e.key, oldValue: e.value),
            ],
          ),
        ],
      );
    }
    // Explicit mock values follow the actual schema, including every required
    // column. This generates a fixture; it never repairs supplied user values.
    final table = tableById(tableId);
    if (table == null || table.columns.isEmpty) return null;
    final now = _clock();
    String pad(int value) => value.toString().padLeft(2, '0');
    final date =
        '${now.year.toString().padLeft(4, '0')}-${pad(now.month)}-${pad(now.day)}';
    final values = {
      for (final column in table.columns)
        column.name: switch (column.fieldType) {
          DataFieldType.text => '新记录',
          DataFieldType.number => '1',
          DataFieldType.money => '0.00',
          DataFieldType.date => date,
          DataFieldType.datetime => '$date ${pad(now.hour)}:${pad(now.minute)}',
          DataFieldType.selection => column.enumOptions.first,
          DataFieldType.boolean => 'false',
        },
    };
    validateDataRowValues(table, values);
    return pushPendingBatch(
      tableId: tableId,
      reason: '根据你刚才的描述补了一条记录，确认一下。',
      sourceLabel: '对话「随手记一笔」',
      changes: [
        PendingRowChange(
          id: _nid('pc'),
          action: DataChangeAction.create,
          rowLabel: '新记录',
          createValues: values,
        ),
      ],
    );
  }

  /// 应用批次里勾选的变更，返回受影响的行 id（落库高亮用）。
  @override
  List<String> applyPendingBatch(String batchId, Set<String> changeIds) {
    final batch = state.pendingBatches
        .where((batch) => batch.id == batchId)
        .firstOrNull;
    if (batch == null) {
      throw const RepositoryException(
        RepositoryErrorCode.notFound,
        '这批 AI 变更已处理，请重新打开待确认记录',
      );
    }
    if (changeIds.isEmpty) return const [];
    if (!changeIds.every(
      (id) => batch.changes.any((change) => change.id == id),
    )) {
      throw const RepositoryException(
        RepositoryErrorCode.invalidInput,
        '选中的变更已不存在',
      );
    }
    final staged = DataTableRepository(initial: state, clock: _clock)
      .._seq = _seq;
    final beforeRows = <String, DataRow?>{};
    final affected = <String>{};
    try {
      for (final change in batch.changes.where(
        (change) => changeIds.contains(change.id),
      )) {
        if (change.action == DataChangeAction.create) {
          final row = staged.addRow(
            batch.tableId,
            change.createValues,
            source: DataChangeSource.ai,
            reason: batch.reason,
            sourceLabel: batch.sourceLabel,
          );
          beforeRows[row.id] = null;
          affected.add(row.id);
          continue;
        }
        final rowId = change.rowId;
        final row = rowId == null ? null : staged._rowById(rowId);
        if (row == null || row.tableId != batch.tableId) {
          throw const RepositoryException(
            RepositoryErrorCode.conflict,
            '记录已删除或不属于这张表，请重新确认',
          );
        }
        final fields = <String>{};
        for (final field in change.fields) {
          if (!fields.add(field.field)) {
            throw const RepositoryException(
              RepositoryErrorCode.invalidInput,
              '一个变更不能重复同一字段',
            );
          }
        }
        validateDataRowValues(staged._requireTable(batch.tableId), {
          for (final field in change.fields)
            field.field: field.newValue ?? field.oldValue ?? '',
        }, partial: true);
        if (change.action == DataChangeAction.delete &&
            row.values.keys.any((field) => !fields.contains(field))) {
          throw const RepositoryException(
            RepositoryErrorCode.conflict,
            '记录的删除快照不完整，请重新确认',
          );
        }
        for (final field in change.fields) {
          if ((row.values[field.field] ?? '') != (field.oldValue ?? '')) {
            throw const RepositoryException(
              RepositoryErrorCode.conflict,
              '记录已有更新，请重新确认 AI 变更',
            );
          }
        }
        beforeRows.putIfAbsent(row.id, () => _rowById(row.id));
        if (change.action == DataChangeAction.update) {
          staged.updateRowMulti(
            row.id,
            {
              for (final field in change.fields)
                if (field.newValue != null) field.field: field.newValue!,
            },
            source: DataChangeSource.ai,
            reason: batch.reason,
            sourceLabel: batch.sourceLabel,
          );
        } else {
          staged.deleteRow(
            row.id,
            source: DataChangeSource.ai,
            reason: batch.reason,
            sourceLabel: batch.sourceLabel,
          );
        }
        affected.add(row.id);
      }
      final remaining = batch.changes
          .where((change) => !changeIds.contains(change.id))
          .toList();
      final remainingBatch = remaining.isEmpty
          ? null
          : PendingAiBatch(
              id: batch.id,
              tableId: batch.tableId,
              reason: batch.reason,
              sourceLabel: batch.sourceLabel,
              createdAt: batch.createdAt,
              changes: remaining,
            );
      final next = staged.snapshot.copyWith(
        pendingBatches: [
          for (final item in state.pendingBatches)
            if (item.id != batchId) item else ?remainingBatch,
        ],
      );
      _lastUndo = _AppliedUndo(
        batch: batch,
        beforeRows: beforeRows,
        afterRows: {for (final id in affected) id: staged._rowById(id)},
        remainingBatch: remainingBatch,
      );
      _seq = staged._seq;
      state = next;
      return List.unmodifiable(affected);
    } finally {
      staged.dispose();
    }
  }

  /// Undo is rejected if another command changed the affected rows or remaining
  /// selection. Never overwrite newer manual edits with an old AI snapshot.
  @override
  void undoLastApply() {
    final undo = _lastUndo;
    if (undo == null) return;
    final currentBatch = state.pendingBatches
        .where((batch) => batch.id == undo.batch.id)
        .firstOrNull;
    if (!identical(currentBatch, undo.remainingBatch) ||
        undo.afterRows.entries.any(
          (entry) => !identical(_rowById(entry.key), entry.value),
        )) {
      throw const RepositoryException(
        RepositoryErrorCode.conflict,
        '记录已有后续修改，无法撤销这次 AI 变更',
      );
    }
    var rows = List<DataRow>.of(state.rows);
    final logs = List<DataChangeLog>.of(state.logs);
    for (final entry in undo.beforeRows.entries) {
      final before = entry.value;
      final after = undo.afterRows[entry.key];
      rows.removeWhere((row) => row.id == entry.key);
      if (before != null) {
        rows.add(
          before.copyWith(updatedAt: _clock(), source: DataChangeSource.manual),
        );
      }
      logs.add(
        DataChangeLog(
          id: _nid('log'),
          tableId: undo.batch.tableId,
          rowId: entry.key,
          field: '',
          oldValue: '',
          newValue: '',
          source: DataChangeSource.manual,
          createdAt: _clock(),
          action: before == null
              ? DataChangeAction.delete
              : after == null
              ? DataChangeAction.create
              : DataChangeAction.update,
          reason: '撤销 AI 批次',
          beforeValues: after?.values,
          afterValues: before?.values,
        ),
      );
    }
    state = state.copyWith(
      rows: rows,
      logs: logs,
      pendingBatches: [
        ...state.pendingBatches.where((batch) => batch.id != undo.batch.id),
        undo.batch,
      ],
    );
    _lastUndo = null;
  }

  @override
  void discardPendingBatch(String batchId) {
    state = state.copyWith(
      pendingBatches: state.pendingBatches
          .where((b) => b.id != batchId)
          .toList(),
    );
  }

  DataTableDef _requireTable(String id) {
    final table = tableById(id);
    if (table == null || table.archived) {
      throw const RepositoryException(
        RepositoryErrorCode.notFound,
        '数据表不存在或已归档',
      );
    }
    return table;
  }

  void _requireType(String? id) {
    if (id != null && !state.types.any((type) => type.id == id)) {
      throw const RepositoryException(
        RepositoryErrorCode.notFound,
        '数据类型不存在，请重新选择',
      );
    }
  }
}

class _AppliedUndo {
  _AppliedUndo({
    required this.batch,
    required Map<String, DataRow?> beforeRows,
    required Map<String, DataRow?> afterRows,
    required this.remainingBatch,
  }) : beforeRows = Map.unmodifiable(beforeRows),
       afterRows = Map.unmodifiable(afterRows);
  final PendingAiBatch batch;
  final Map<String, DataRow?> beforeRows;
  final Map<String, DataRow?> afterRows;
  final PendingAiBatch? remainingBatch;
}

DataTableBundle _validateBundle(DataTableBundle bundle) {
  requireUniqueIds(bundle.types, (DataTableType type) => type.id);
  final typeNames = <String>{};
  for (final type in bundle.types) {
    final name = _requireTypeName(type.name);
    if (name != type.name || !typeNames.add(name.toLowerCase())) {
      throw const RepositoryException(
        RepositoryErrorCode.invalidInput,
        '数据类型名称无效或重复',
      );
    }
  }
  requireUniqueIds(bundle.tables, (DataTableDef table) => table.id);
  requireUniqueIds(bundle.rows, (DataRow row) => row.id);
  requireUniqueIds(bundle.logs, (DataChangeLog log) => log.id);
  requireUniqueIds(bundle.pendingBatches, (PendingAiBatch batch) => batch.id);
  final tables = {for (final table in bundle.tables) table.id: table};
  for (final table in bundle.tables) {
    validateDataTableColumns(table.columns);
    if (table.typeId != null &&
        !bundle.types.any((type) => type.id == table.typeId)) {
      throw const RepositoryException(
        RepositoryErrorCode.invalidInput,
        '数据表所属类型不存在',
      );
    }
  }
  for (final row in bundle.rows) {
    final table = tables[row.tableId];
    if (table == null) {
      throw const RepositoryException(
        RepositoryErrorCode.invalidInput,
        '数据行所属表不存在',
      );
    }
    validateDataRowValues(table, row.values);
  }
  for (final batch in bundle.pendingBatches) {
    if (!tables.containsKey(batch.tableId)) {
      throw const RepositoryException(
        RepositoryErrorCode.invalidInput,
        'AI 批次所属表不存在',
      );
    }
    requireUniqueIds(batch.changes, (PendingRowChange change) => change.id);
  }
  return bundle;
}

String _requireTypeName(String name) {
  final value = requireText(name, '类型名称');
  if (value.runes.length > 24) {
    throw const RepositoryException(
      RepositoryErrorCode.invalidInput,
      '类型名称最多 24 个字',
    );
  }
  return value;
}
