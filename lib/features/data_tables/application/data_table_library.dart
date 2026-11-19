import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart' show dataTableProvider;
import '../../../domain/models/data_table.dart';
import '../../../domain/repositories/data_table_bundle.dart';

const allDataTableTypes = 'all';
const unassignedDataTableType = 'unassigned';

class DataTableLibraryFilter {
  const DataTableLibraryFilter({
    this.typeId = allDataTableTypes,
    this.query = '',
  });

  final String typeId;
  final String query;
}

class DataTableLibraryController extends StateNotifier<DataTableLibraryFilter> {
  DataTableLibraryController() : super(const DataTableLibraryFilter());

  void selectType(String id) =>
      state = DataTableLibraryFilter(typeId: id, query: state.query);

  void search(String value) => state = DataTableLibraryFilter(
    typeId: state.typeId,
    query: value.trim().toLowerCase(),
  );
}

class DataTableTypeCount {
  const DataTableTypeCount({
    required this.id,
    required this.name,
    required this.count,
  });

  final String id;
  final String name;
  final int count;
}

class DataTableSummary {
  const DataTableSummary({
    required this.table,
    required this.rowCount,
    required this.pendingCount,
    required this.updatedAt,
  });

  final DataTableDef table;
  final int rowCount;
  final int pendingCount;
  final DateTime updatedAt;
}

/// A projection of the repository snapshot; filtering never mutates source data.
class DataTableLibrarySnapshot {
  DataTableLibrarySnapshot._({
    required this.selectedTypeId,
    required List<DataTableTypeCount> types,
    required List<DataTableSummary> tables,
  }) : types = List.unmodifiable(types),
       tables = List.unmodifiable(tables);

  factory DataTableLibrarySnapshot.from(
    DataTableBundle bundle,
    DataTableLibraryFilter filter,
  ) {
    final selected =
        filter.typeId == unassignedDataTableType ||
            bundle.types.any((type) => type.id == filter.typeId)
        ? filter.typeId
        : allDataTableTypes;
    final matching = bundle.tables
        .where(
          (table) =>
              !table.archived &&
              table.name.toLowerCase().contains(filter.query),
        )
        .toList();
    final unassigned = matching.where((table) => table.typeId == null).length;
    final rowsByTable = <String, List<DataRow>>{};
    for (final row in bundle.rows) {
      rowsByTable.putIfAbsent(row.tableId, () => []).add(row);
    }
    final pendingByTable = <String, int>{};
    for (final batch in bundle.pendingBatches) {
      pendingByTable.update(
        batch.tableId,
        (count) => count + batch.changes.length,
        ifAbsent: () => batch.changes.length,
      );
    }
    final tables =
        <DataTableSummary>[
          for (final table in matching)
            if (selected == allDataTableTypes ||
                (selected == unassignedDataTableType && table.typeId == null) ||
                table.typeId == selected)
              DataTableSummary(
                table: table,
                rowCount: rowsByTable[table.id]?.length ?? 0,
                pendingCount: pendingByTable[table.id] ?? 0,
                updatedAt: (rowsByTable[table.id] ?? const <DataRow>[]).fold(
                  table.createdAt,
                  (latest, row) =>
                      row.updatedAt.isAfter(latest) ? row.updatedAt : latest,
                ),
              ),
        ]..sort((a, b) {
          final recent = b.updatedAt.compareTo(a.updatedAt);
          return recent != 0 ? recent : a.table.id.compareTo(b.table.id);
        });
    return DataTableLibrarySnapshot._(
      selectedTypeId: selected,
      types: [
        DataTableTypeCount(
          id: allDataTableTypes,
          name: '全部',
          count: matching.length,
        ),
        for (final type in bundle.types)
          DataTableTypeCount(
            id: type.id,
            name: type.name,
            count: matching.where((table) => table.typeId == type.id).length,
          ),
        if (unassigned > 0 || selected == unassignedDataTableType)
          DataTableTypeCount(
            id: unassignedDataTableType,
            name: '未分类',
            count: unassigned,
          ),
      ],
      tables: tables,
    );
  }

  final String selectedTypeId;
  final List<DataTableTypeCount> types;
  final List<DataTableSummary> tables;

  String? get newTableTypeId =>
      selectedTypeId == allDataTableTypes ||
          selectedTypeId == unassignedDataTableType
      ? null
      : selectedTypeId;
}

final dataTableLibraryFilterProvider =
    StateNotifierProvider<DataTableLibraryController, DataTableLibraryFilter>(
      (ref) => DataTableLibraryController(),
    );

final dataTableLibraryProvider = Provider<DataTableLibrarySnapshot>((ref) {
  return DataTableLibrarySnapshot.from(
    ref.watch(dataTableProvider),
    ref.watch(dataTableLibraryFilterProvider),
  );
});
