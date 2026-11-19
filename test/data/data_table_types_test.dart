import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/providers.dart' show dataTableProvider;
import 'package:towork/data/repositories/data_table_repository.dart';
import 'package:towork/domain/models/data_table.dart';
import 'package:towork/domain/repositories/data_table_store.dart';
import 'package:towork/features/data_tables/application/data_table_library.dart';

final now = DateTime(2026, 9, 23, 12);

DataTableRepository emptyRepo() => DataTableRepository(
  clock: () => now,
  initial: DataTableBundle(tables: [], rows: [], logs: []),
);

DataTableDef createTable(
  DataTableRepository repo,
  String name, {
  String? typeId,
}) => repo.createTable(
  name: name,
  typeId: typeId,
  columns: [DataColumnDef(name: '名称', type: 'text', isRequired: true)],
);

void main() {
  test('types survive table staging, row writes and AI apply/undo', () {
    final repo = emptyRepo();
    addTearDown(repo.dispose);
    final type = repo.createType('  工作  ');
    final table = createTable(repo, '接收记录', typeId: type.id);
    expect(type.name, '工作');
    expect(repo.tableById(table.id)!.typeId, type.id);
    final batch = repo.pushPendingBatch(
      tableId: table.id,
      reason: '接收清单',
      sourceLabel: '会话',
      changes: [
        PendingRowChange(
          id: 'new',
          action: DataChangeAction.create,
          rowLabel: '新一批',
          createValues: {'名称': '新一批'},
        ),
      ],
    );
    repo.applyPendingBatch(batch.id, {'new'});
    final secondType = repo.createType('生活');
    repo.undoLastApply();
    expect(repo.snapshot.types.map((item) => item.id), [
      type.id,
      secondType.id,
    ]);
    expect(repo.tableById(table.id)!.typeId, type.id);
    expect(repo.rowsOf(table.id), isEmpty);
    expect(repo.batchesOf(table.id), hasLength(1));
    expect(() => repo.snapshot.types.clear(), throwsUnsupportedError);
  });

  test('type names and foreign keys are validated without partial writes', () {
    final repo = emptyRepo();
    addTearDown(repo.dispose);
    repo.createType('Work');
    final before = repo.snapshot;
    for (final name in [' ', ' work ', '长' * 25]) {
      expect(() => repo.createType(name), throwsA(isA<RepositoryException>()));
      expect(repo.snapshot, same(before));
    }
    expect(
      () => createTable(repo, '记录', typeId: 'missing'),
      throwsA(isA<RepositoryException>()),
    );
    expect(repo.snapshot, same(before));
    final table = createTable(repo, '记录');
    expect(
      () => repo.assignTableType(table.id, 'missing'),
      throwsA(isA<RepositoryException>()),
    );
    expect(repo.tableById(table.id)!.typeId, isNull);
  });

  test('reassignment and explicit clearing update immutable table records', () {
    final repo = emptyRepo();
    addTearDown(repo.dispose);
    final work = repo.createType('工作');
    final life = repo.createType('生活');
    final original = createTable(repo, '记录', typeId: work.id);
    repo.assignTableType(original.id, life.id);
    expect(original.typeId, work.id);
    expect(repo.tableById(original.id)!.typeId, life.id);
    repo.assignTableType(original.id, null);
    expect(repo.tableById(original.id)!.typeId, isNull);
    repo.renameTable(original.id, '新名称');
    expect(repo.tableById(original.id)!.typeId, isNull);
  });

  test(
    'invalid bundles reject dangling type references and duplicate names',
    () {
      final table = DataTableDef(
        id: 't',
        name: '表',
        typeId: 'missing',
        createdAt: now,
        columns: [DataColumnDef(name: '名称', type: 'text')],
      );
      expect(
        () => DataTableRepository(
          initial: DataTableBundle(tables: [table], rows: [], logs: []),
        ),
        throwsA(isA<RepositoryException>()),
      );
      expect(
        () => DataTableRepository(
          initial: DataTableBundle(
            tables: [],
            rows: [],
            logs: [],
            types: const [
              DataTableType(id: 'a', name: 'Work'),
              DataTableType(id: 'b', name: 'work'),
            ],
          ),
        ),
        throwsA(isA<RepositoryException>()),
      );
    },
  );

  test(
    'live scope counts exclude archived tables and follow reassignment/search',
    () {
      final repo = emptyRepo();
      final container = ProviderContainer(
        overrides: [dataTableProvider.overrideWith((ref) => repo)],
      );
      addTearDown(container.dispose);
      final work = repo.createType('工作');
      final life = repo.createType('生活');
      final spare = repo.createType('项目');
      final archive = createTable(repo, '档案记录', typeId: work.id);
      createTable(repo, '家庭记录', typeId: life.id);
      final hidden = createTable(repo, '旧记录', typeId: work.id);
      repo.archiveTable(hidden.id);
      createTable(repo, '临时记录');
      final filter = container.read(dataTableLibraryFilterProvider.notifier);
      filter.selectType(work.id);
      var library = container.read(dataTableLibraryProvider);
      expect(library.tables.map((summary) => summary.table.id), [archive.id]);
      expect(library.types.first.count, 3);
      expect(library.types.firstWhere((type) => type.id == work.id).count, 1);
      expect(library.types.firstWhere((type) => type.id == spare.id).count, 0);
      repo.assignTableType(archive.id, life.id);
      library = container.read(dataTableLibraryProvider);
      expect(library.tables, isEmpty);
      expect(library.types.firstWhere((type) => type.id == life.id).count, 2);
      filter.selectType(life.id);
      filter.search('档案');
      library = container.read(dataTableLibraryProvider);
      expect(library.tables.single.table.id, archive.id);
      expect(library.types.first.count, 1);
      filter.selectType(spare.id);
      expect(container.read(dataTableLibraryProvider).newTableTypeId, spare.id);
    },
  );
}
