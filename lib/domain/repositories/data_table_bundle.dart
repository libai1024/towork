import '../models/models.dart';

class DataTableBundle {
  DataTableBundle({
    required List<DataTableDef> tables,
    required List<DataRow> rows,
    required List<DataChangeLog> logs,
    List<PendingAiBatch> pendingBatches = const [],
    List<DataTableType> types = const [],
    this.historyLoading = false,
    this.historyError = false,
  }) : tables = List.unmodifiable(tables),
       rows = List.unmodifiable(rows),
       logs = List.unmodifiable(logs),
       pendingBatches = List.unmodifiable(pendingBatches),
       types = List.unmodifiable(types);

  final List<DataTableDef> tables;
  final List<DataRow> rows;
  final List<DataChangeLog> logs;

  /// AI 待确认批次（diff 确认弹窗的数据源）。
  final List<PendingAiBatch> pendingBatches;
  final List<DataTableType> types;
  final bool historyLoading;
  final bool historyError;

  DataTableBundle copyWith({
    List<DataTableDef>? tables,
    List<DataRow>? rows,
    List<DataChangeLog>? logs,
    List<PendingAiBatch>? pendingBatches,
    List<DataTableType>? types,
    bool? historyLoading,
    bool? historyError,
  }) {
    return DataTableBundle(
      tables: tables ?? this.tables,
      rows: rows ?? this.rows,
      logs: logs ?? this.logs,
      pendingBatches: pendingBatches ?? this.pendingBatches,
      types: types ?? this.types,
      historyLoading: historyLoading ?? this.historyLoading,
      historyError: historyError ?? this.historyError,
    );
  }
}
