import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/reports/report_documents.dart';
import '../../domain/workspace/workspace_commands.dart';
import 'app_database.dart';

class SqliteReportStore implements ReportDocumentStore {
  SqliteReportStore(this._db);
  final AppDatabase _db;

  static Never _fail() =>
      throw const WorkspaceFailure(WorkspaceFailureCode.storageUnavailable);

  ReportDocument _document(LocalReport row) {
    final snapshot = (jsonDecode(row.snapshot) as Map).cast<String, Object?>();
    return ReportDocument(
      id: row.id,
      kind: ReportPeriodKind.values.byName(row.kind),
      startAt: row.startAt,
      endAt: row.endAt,
      timezone: row.timezone,
      status: ReportDocumentStatus.values.byName(row.status),
      summary: row.summary,
      templateId: row.templateId,
      snapshotId: reportSnapshotId(snapshot),
      metrics: ReportMetrics.fromJson(
        (snapshot['metrics']! as Map).cast<String, Object?>(),
      ),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  @override
  Future<ReportDocument> create(ReportDocument document) =>
      _db.transaction(() async {
        final now = DateTime.now().toUtc().microsecondsSinceEpoch;
        await _db
            .into(_db.localReports)
            .insert(
              LocalReportsCompanion.insert(
                id: document.id,
                kind: document.kind.name,
                startAt: document.startAt,
                endAt: document.endAt,
                timezone: document.timezone,
                snapshot: jsonEncode(document.snapshotJson()),
                status: document.status.name,
                summary: Value(document.summary),
                templateId: Value(document.templateId),
                createdAt: document.createdAt == 0 ? now : document.createdAt,
                updatedAt: now,
              ),
            )
            .catchError((Object _) => _fail());
        final row = await (_db.select(
          _db.localReports,
        )..where((r) => r.id.equals(document.id))).getSingle();
        return _document(row);
      });

  @override
  Future<ReportDocument?> read(String id) async {
    final row = await (_db.select(
      _db.localReports,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    return row == null ? null : _document(row);
  }

  @override
  Future<List<ReportDocument>> list({bool newestFirst = true}) async {
    final query = _db.select(_db.localReports)
      ..orderBy([
        newestFirst
            ? (r) => OrderingTerm.desc(r.startAt)
            : (r) => OrderingTerm.asc(r.startAt),
      ]);
    final rows = await query.get();
    return [for (final row in rows) _document(row)];
  }

  @override
  Future<ReportDocument> saveSummary(
    String id, {
    required String summary,
    String? templateId,
  }) => _db.transaction(() async {
    final row = await (_db.select(
      _db.localReports,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    if (row == null) {
      throw const WorkspaceFailure(WorkspaceFailureCode.notFound);
    }
    // A failed summary may regenerate (FC5); the frozen snapshot never moves.
    await (_db.update(_db.localReports)..where((r) => r.id.equals(id))).write(
      LocalReportsCompanion(
        summary: Value(summary),
        templateId: Value(templateId ?? row.templateId),
        status: Value(ReportDocumentStatus.summaryReady.name),
        updatedAt: Value(DateTime.now().toUtc().microsecondsSinceEpoch),
      ),
    );
    return _document(
      (await (_db.select(
        _db.localReports,
      )..where((r) => r.id.equals(id))).getSingle()),
    );
  });

  @override
  Future<ReportDocument> markFailed(String id) => _db.transaction(() async {
    final updated =
        await (_db.update(
          _db.localReports,
        )..where((r) => r.id.equals(id))).write(
          LocalReportsCompanion(
            status: Value(ReportDocumentStatus.failed.name),
            updatedAt: Value(DateTime.now().toUtc().microsecondsSinceEpoch),
          ),
        );
    if (updated != 1) {
      throw const WorkspaceFailure(WorkspaceFailureCode.notFound);
    }
    return _document(
      (await (_db.select(
        _db.localReports,
      )..where((r) => r.id.equals(id))).getSingle()),
    );
  });
}
