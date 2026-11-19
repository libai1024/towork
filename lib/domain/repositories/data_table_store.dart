import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'data_table_bundle.dart';
export 'data_table_bundle.dart';
export 'repository_error.dart';

abstract class DataTableStore extends StateNotifier<DataTableBundle> {
  DataTableStore(super.state);
  DataTableBundle get snapshot => state;
  DataTableDef? tableById(String id);
  List<DataRow> rowsOf(String tableId);
  List<DataChangeLog> logsOfRow(String rowId);
  List<PendingAiBatch> batchesOf(String tableId);
  int pendingCountOf(String tableId);
  int changesAfter(String rowId, DateTime at);
  DataTableType createType(String name);
  void assignTableType(String tableId, String? typeId);
  DataTableDef createTable({
    required String name,
    String iconKey = 'table',
    String description = '',
    required List<DataColumnDef> columns,
    List<Map<String, String>> seedRows = const [],
    String? typeId,
  });
  void renameTable(String id, String name);
  void archiveTable(String id);

  /// Removes a table and all its rows in one change. Production undo uses the
  /// workspace changeset; demo mode restores via [restoreTable].
  void deleteTable(String tableId);

  /// Demo-mode inverse of [deleteTable]; production undo never calls this.
  void restoreTable(DataTableDef table, List<DataRow> rows);

  /// Rows that currently store a value for the field; used for impact preview.
  int fieldUsageCount(String tableId, String fieldKey);

  /// Renames a field, keeping its stable ID and every stored value.
  /// [fieldKey] is the field ID, or the field name for legacy demo tables.
  void renameField(String tableId, String fieldKey, String name);

  /// Adds a field. A required field needs [backfillValue] when rows exist,
  /// applied to every row in the same atomic change.
  void addField(String tableId, DataColumnDef field, {String? backfillValue});

  /// Removes a field and, in the same atomic change, its values from every row.
  void removeField(String tableId, String fieldKey);
  DataRow addRow(
    String tableId,
    Map<String, String> values, {
    DataChangeSource source = DataChangeSource.manual,
    String? reason,
    String? sourceLabel,
    String? id,
  });
  void insertRowRaw(DataRow row);
  void deleteRow(
    String rowId, {
    DataChangeSource source = DataChangeSource.manual,
    String? reason,
    String? sourceLabel,
  });
  void updateCell(
    String rowId,
    String field,
    String newValue, {
    DataChangeSource source = DataChangeSource.manual,
    String? reason,
    String? sourceLabel,
  });
  void updateRowMulti(
    String rowId,
    Map<String, String> changes, {
    DataChangeSource source = DataChangeSource.manual,
    String? reason,
    String? sourceLabel,
  });
  void rollbackTo(String rowId, String logId);
  PendingAiBatch pushPendingBatch({
    required String tableId,
    required String reason,
    required String sourceLabel,
    required List<PendingRowChange> changes,
  });
  PendingAiBatch? simulateAiPush(String tableId);
  List<String> applyPendingBatch(String batchId, Set<String> changeIds);
  void undoLastApply();
  void discardPendingBatch(String batchId);
}
