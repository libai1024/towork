import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/report_snapshot_builder.dart';
import 'package:towork/data/local/report_store.dart';
import 'package:towork/domain/reports/report_documents.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';

WorkspaceEntity _todo(
  String id, {
  String status = 'pending',
  DateTime? completedAt,
  DateTime? dueAt,
  String? categoryId,
  DateTime? createdAt,
  String? seriesId,
}) => WorkspaceEntity(
  kind: WorkspaceEntityKind.todo,
  id: id,
  version: 1,
  data: {
    'title': id,
    'note': null,
    'status': status,
    'priority': 'none',
    'due_at': dueAt?.toUtc().toIso8601String(),
    'remind_at': null,
    'remind_rules': <Object?>[],
    'repeat_rule': null,
    'repeat_timezone': null,
    'series_id': seriesId,
    'occurrence_key': null,
    'occurrence_index': null,
    'occurrence_at': null,
    'category_id': categoryId,
    'source': 'manual',
    'source_message_id': null,
    'tags': <Object?>[],
    'sort_order': 0,
    'completed_at': completedAt?.toUtc().toIso8601String(),
  },
  createdAt: createdAt ?? DateTime.utc(2026, 9, 20),
  updatedAt: DateTime.utc(2026, 9, 20),
);

void main() {
  // 周：2026-09-14 00:00 UTC → 09-21 00:00 UTC（Asia/Shanghai 日历周由调用方换算）。
  final start = DateTime.utc(2026, 9, 14).microsecondsSinceEpoch;
  final end = DateTime.utc(2026, 9, 21).microsecondsSinceEpoch;
  final prevStart = DateTime.utc(2026, 9, 7).microsecondsSinceEpoch;

  test('frozen metrics: window counts, cancel excluded, denominator exact', () {
    final todos = [
      // 周内创建、周内完成。
      _todo(
        'done_in',
        status: 'done',
        completedAt: DateTime.utc(2026, 9, 16),
        createdAt: DateTime.utc(2026, 9, 15),
        categoryId: 'cat_work',
      ),
      // 重复实例：同样按实例计入完成。
      _todo(
        'repeat_instance',
        status: 'done',
        completedAt: DateTime.utc(2026, 9, 17),
        createdAt: DateTime.utc(2026, 9, 14),
        seriesId: 'series_1',
        categoryId: 'cat_work',
      ),
      // 上周完成：不计入本周 completed，也不在分母。
      _todo(
        'done_before',
        status: 'done',
        completedAt: DateTime.utc(2026, 9, 10),
        createdAt: DateTime.utc(2026, 9, 8),
      ),
      // 周内创建、期末仍未完成 → 分母 +1。
      _todo('open_new', createdAt: DateTime.utc(2026, 9, 18)),
      // 周前创建、期末未完成且已逾期 → 分母 +1、逾期 +1。
      _todo(
        'overdue_old',
        createdAt: DateTime.utc(2026, 9, 10),
        dueAt: DateTime.utc(2026, 9, 12),
      ),
      // 周内取消：不计完成；取消也不占分母。
      _todo(
        'cancelled',
        status: 'cancelled',
        createdAt: DateTime.utc(2026, 9, 15),
      ),
      // 下周创建：不进任何本周口径。
      _todo('future', createdAt: DateTime.utc(2026, 9, 22)),
    ];
    final snapshot = WorkspaceSnapshot([
      ...todos,
      WorkspaceEntity(
        kind: WorkspaceEntityKind.category,
        id: 'cat_work',
        version: 1,
        data: const {
          'name': '工作',
          'color_value': 0xff3366cc,
          'icon_key': 'briefcase',
          'parent_id': null,
          'sort_order': 0,
          'archived': false,
        },
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
    ]);

    final metrics = ReportSnapshotBuilder.build(
      snapshot: snapshot,
      nickname: '小王',
      startAt: start,
      endAt: end,
      previousStartAt: prevStart,
      categoryIds: ['cat_work'],
      dataRowsTotal: 42,
      dataRowsCreated: 3,
    );

    expect(
      metrics.created,
      4,
      reason: '周内创建 4 条（done_in/repeat/open_new/cancelled）',
    );
    expect(metrics.completed, 2);
    expect(metrics.cancelledInWindow, 1);
    expect(metrics.openAtEnd, 2, reason: 'open_new + overdue_old');
    expect(metrics.overdueAtEnd, 1);
    expect(metrics.completion.numerator, 2);
    expect(metrics.completion.denominator, 4);
    expect(metrics.completion.value, 50.0);
    expect(metrics.completion.label, contains('取消不计完成'));
    expect(metrics.previousCompleted, 1, reason: '上周完成 done_before');
    final work = metrics.byCategory.singleWhere((c) => c.id == 'cat_work');
    expect(work.name, '工作');
    expect(work.created, 2);
    expect(work.completed, 2);
    final uncategorized = metrics.byCategory.singleWhere((c) => c.id.isEmpty);
    expect(uncategorized.created, 2, reason: 'open_new + cancelled');
    expect(uncategorized.completed, 0);
    expect(metrics.dataRowsTotal, 42);
    expect(metrics.nickname, '小王');
  });

  test('store persists immutable snapshots; summary updates status', () async {
    final dir = await Directory.systemTemp.createTemp('towork-reports-');
    var db = AppDatabase.background(File('${dir.path}/db.sqlite'));
    final store = SqliteReportStore(db);
    final metrics = ReportSnapshotBuilder.build(
      snapshot: WorkspaceSnapshot([
        WorkspaceEntity(
          kind: WorkspaceEntityKind.category,
          id: 'c1',
          version: 1,
          data: const {
            'name': '旧名',
            'color_value': 0xff112233,
            'icon_key': 'folder',
            'parent_id': null,
            'sort_order': 0,
            'archived': false,
          },
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      ]),
      nickname: '旧昵称',
      startAt: start,
      endAt: end,
      previousStartAt: prevStart,
      categoryIds: ['c1'],
    );
    final snapshotJson = {
      'schema_version': 1,
      'period': {
        'start': DateTime.fromMicrosecondsSinceEpoch(
          start,
          isUtc: true,
        ).toIso8601String(),
        'end_exclusive': DateTime.fromMicrosecondsSinceEpoch(
          end,
          isUtc: true,
        ).toIso8601String(),
        'timezone': 'Asia/Shanghai',
      },
      'metrics': metrics.toJson(),
    };
    final doc = ReportDocument(
      id: 'report_w38',
      kind: ReportPeriodKind.weekly,
      startAt: start,
      endAt: end,
      timezone: 'Asia/Shanghai',
      metrics: metrics,
      status: ReportDocumentStatus.snapshotReady,
      snapshotId: reportSnapshotId(snapshotJson),
      createdAt: 0,
      updatedAt: 0,
    );
    final saved = await store.create(doc);
    expect(saved.status, ReportDocumentStatus.snapshotReady);
    expect(saved.snapshotId, doc.snapshotId);

    final summarized = await store.saveSummary(
      'report_w38',
      summary: '本周完成了两项工作。',
      templateId: 'weekly-simple',
    );
    expect(summarized.status, ReportDocumentStatus.summaryReady);
    expect(summarized.summary, contains('两项'));
    expect(summarized.templateId, 'weekly-simple');

    await db.close();
    db = AppDatabase.background(File('${dir.path}/db.sqlite'));
    final reopened = await SqliteReportStore(db).read('report_w38');
    // 归档快照不随分类/昵称后续改名重写。
    expect(reopened!.metrics.byCategory.single.name, '旧名');
    expect(reopened.metrics.nickname, '旧昵称');
    expect(reopened.snapshotId, doc.snapshotId);
    expect(reopened.summary, contains('两项'));

    final failed = await SqliteReportStore(db).markFailed('report_w38');
    expect(failed.status, ReportDocumentStatus.failed);
    expect(failed.snapshotId, doc.snapshotId, reason: '失败不重写快照');
    // FC5：总结失败可以重生成——failed 文档允许再次保存总结。
    final retried = await SqliteReportStore(db)
        .saveSummary('report_w38', summary: '重生成总结');
    expect(retried.status, ReportDocumentStatus.summaryReady);
    await expectLater(
      SqliteReportStore(db).read('missing'),
      completion(isNull),
    );
    await db.close();
    await dir.delete(recursive: true);
  });

  test('v11 upgrade creates report tables; foreign table rolls back', () async {
    final dir = await Directory.systemTemp.createTemp('towork-reports-mig-');
    final migrationFile = File('${dir.path}/migration.sqlite');
    var raw = sqlite3.sqlite3.open(migrationFile.path);
    raw.execute(File('test/fixtures/local/schema_v11.sql').readAsStringSync());
    raw.execute('PRAGMA user_version = 11');
    raw.execute(
      "INSERT INTO local_profiles VALUES(1,'old-user','保留姓名',1,1700000000)",
    );
    raw.close();
    var db = AppDatabase.background(migrationFile);
    expect(await SqliteReportStore(db).list(), isEmpty);
    expect(
      (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
        'user_version',
      ),
      13,
    );
    expect((await db.loadOrCreateProfile()).nickname, '保留姓名');
    await db.close();

    final foreign = File('${dir.path}/foreign.sqlite');
    raw = sqlite3.sqlite3.open(foreign.path);
    raw.execute(File('test/fixtures/local/schema_v11.sql').readAsStringSync());
    raw.execute('PRAGMA user_version = 11');
    raw.execute('CREATE TABLE local_reports(alien TEXT)');
    raw.close();
    db = AppDatabase.background(foreign);
    await expectLater(db.select(db.localReports).get(), throwsA(anything));
    await db.close();
    raw = sqlite3.sqlite3.open(foreign.path);
    expect(raw.select('PRAGMA user_version').single['user_version'], 11);
    raw.close();
    await dir.delete(recursive: true);
  });
}
