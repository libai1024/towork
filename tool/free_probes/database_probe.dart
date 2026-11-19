import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'database_probe.g.dart';

/// Isolated feasibility schema. Never opens the production user database.
class ProbeItems extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ProbeReceipts extends Table {
  TextColumn get operationId => text()();
  TextColumn get canonicalRequest => text()();
  TextColumn get committedResult => text()();

  @override
  Set<Column<Object>> get primaryKey => {operationId};
}

class ProbeMutation {
  const ProbeMutation(this.id, this.title, {this.expectedVersion});
  final String id;
  final String title;
  final int? expectedVersion;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'expected_version': expectedVersion,
  };
}

class ProbeConflict implements Exception {
  const ProbeConflict(this.kind);
  final String kind;
}

@DriftDatabase(tables: [ProbeItems, ProbeReceipts])
class ProbeDatabase extends _$ProbeDatabase {
  ProbeDatabase(super.executor, {this.migrationCheckpoint});

  /// Fault injection for the isolated prototype, never a production setting.
  final Future<void> Function()? migrationCheckpoint;

  factory ProbeDatabase.background(File file) =>
      ProbeDatabase(NativeDatabase.createInBackground(file));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from != 1 || to != 2) {
        throw StateError('Unsupported probe schema migration');
      }
      await transaction(() async {
        await m.addColumn(probeItems, probeItems.version);
        await migrationCheckpoint?.call();
        await m.createTable(probeReceipts);
      });
    },
  );

  Future<List<ProbeItem>> readItems() =>
      (select(probeItems)..orderBy([(row) => OrderingTerm.asc(row.id)])).get();

  /// The reply and changes share a transaction; a retry returns stored results.
  Future<String> applyBatch(
    String operationId,
    List<ProbeMutation> input,
  ) async {
    final mutations = List<ProbeMutation>.unmodifiable(input);
    if (operationId.isEmpty || mutations.isEmpty || mutations.length > 100) {
      throw ArgumentError('Invalid probe batch');
    }
    final ids = <String>{};
    for (final mutation in mutations) {
      if (mutation.id.isEmpty ||
          mutation.title.trim().isEmpty ||
          !ids.add(mutation.id) ||
          (mutation.expectedVersion != null && mutation.expectedVersion! < 1)) {
        throw ArgumentError('Invalid probe mutation');
      }
    }
    final canonical = jsonEncode(mutations.map((e) => e.toJson()).toList());
    return transaction(() async {
      final receipt = await (select(
        probeReceipts,
      )..where((row) => row.operationId.equals(operationId))).getSingleOrNull();
      if (receipt != null) {
        if (receipt.canonicalRequest != canonical) {
          throw const ProbeConflict('idempotency_mismatch');
        }
        return receipt.committedResult;
      }
      final result = <Map<String, Object?>>[];
      for (final mutation in mutations) {
        final current = await (select(
          probeItems,
        )..where((row) => row.id.equals(mutation.id))).getSingleOrNull();
        if (current?.version != mutation.expectedVersion) {
          throw const ProbeConflict('version_conflict');
        }
        final next = (current?.version ?? 0) + 1;
        if (current == null) {
          await into(probeItems).insert(
            ProbeItemsCompanion.insert(
              id: mutation.id,
              title: mutation.title,
              version: Value(next),
            ),
          );
        } else {
          final changed =
              await (update(probeItems)..where(
                    (row) =>
                        row.id.equals(mutation.id) &
                        row.version.equals(mutation.expectedVersion!),
                  ))
                  .write(
                    ProbeItemsCompanion(
                      title: Value(mutation.title),
                      version: Value(next),
                    ),
                  );
          if (changed != 1) throw const ProbeConflict('version_conflict');
        }
        result.add({
          'id': mutation.id,
          'version': next,
          'title': mutation.title,
        });
      }
      final committed = jsonEncode(result);
      await into(probeReceipts).insert(
        ProbeReceiptsCompanion.insert(
          operationId: operationId,
          canonicalRequest: canonical,
          committedResult: committed,
        ),
      );
      return committed;
    });
  }
}

Future<void> main() async {
  final directory = await Directory.systemTemp.createTemp('towork-db-probe-');
  final file = File('${directory.path}/probe.sqlite');
  var db = ProbeDatabase.background(file);
  try {
    final result = await db.applyBatch('create', const [
      ProbeMutation('one', '事务与重启验证'),
      ProbeMutation('two', '完整批次'),
    ]);
    await db.close();
    db = ProbeDatabase.background(file);
    final replay = await db.applyBatch('create', const [
      ProbeMutation('one', '事务与重启验证'),
      ProbeMutation('two', '完整批次'),
    ]);
    if (result != replay || (await db.readItems()).length != 2) {
      throw StateError('Probe failed');
    }
    stdout.writeln(
      jsonEncode({
        'probe': 'background_sqlite',
        'status': 'passed',
        'rows_after_reopen': 2,
        'receipt_replayed': true,
      }),
    );
  } finally {
    await db.close();
    await directory.delete(recursive: true);
  }
}
