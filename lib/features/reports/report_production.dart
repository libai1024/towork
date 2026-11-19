import 'dart:convert';

import 'package:drift/drift.dart' show QueryRow;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/local_database_provider.dart';
import '../../domain/recurrence/recurrence_schedule.dart';
import '../../domain/reports/report_documents.dart';

/// 报告周期使用的时区。项目内暂无全局「用户时区」设置（重复规则的时区也是
/// 每条待办单独选择、默认 Asia/Shanghai），因此报告统一按 Asia/Shanghai
/// 计算周期边界，并在列表脚注与详情头注明；`DateTime.now().timeZoneName`
/// 在不同平台返回值不稳定，不作为依据。
const String kProductionReportTimezone = 'Asia/Shanghai';

/// 生产模式的报告列表（新→旧）。读取走 [localDatabaseProvider] 的同一连接，
/// 解码口径与 SqliteReportStore 一致；行映射放在 provider 闭包内以推断
/// AppDatabase 类型（架构规则禁止 features 直接 import data 层）。
final productionReportListProvider = FutureProvider<List<ReportDocument>>((
  ref,
) async {
  final db = await ref.watch(localDatabaseProvider.future);
  final rows = await db
      .customSelect(
        'SELECT id, kind, start_at, end_at, timezone, snapshot, status, '
        'summary, template_id, created_at, updated_at FROM local_reports '
        'ORDER BY start_at DESC, id DESC',
      )
      .get();
  return [for (final row in rows) _decodeReportRow(row)];
});

/// 生产模式的单份报告；依赖列表 provider，列表失效时自动刷新。
final productionReportProvider = FutureProvider.family<ReportDocument?, String>(
  (ref, id) async {
    final reports = await ref.watch(productionReportListProvider.future);
    for (final report in reports) {
      if (report.id == id) return report;
    }
    return null;
  },
);

ReportDocument _decodeReportRow(QueryRow row) {
  final snapshot = (jsonDecode(row.read<String>('snapshot')) as Map)
      .cast<String, Object?>();
  return ReportDocument(
    id: row.read<String>('id'),
    kind: ReportPeriodKind.values.byName(row.read<String>('kind')),
    startAt: row.read<int>('start_at'),
    endAt: row.read<int>('end_at'),
    timezone: row.read<String>('timezone'),
    status: ReportDocumentStatus.values.byName(row.read<String>('status')),
    summary: row.readNullable<String>('summary'),
    templateId: row.readNullable<String>('template_id'),
    snapshotId: reportSnapshotId(snapshot),
    metrics: ReportMetrics.fromJson(
      (snapshot['metrics']! as Map).cast<String, Object?>(),
    ),
    createdAt: row.read<int>('created_at'),
    updatedAt: row.read<int>('updated_at'),
  );
}

// ---------------------------------------------------------------------------
// 周期与状态文案（全部按报告自身 timezone 的墙上时间换算）
// ---------------------------------------------------------------------------

String _two(int v) => v.toString().padLeft(2, '0');

DateTime _civilAt(ReportDocument report, int micros) =>
    RecurrenceTimeZones.civil(
      DateTime.fromMicrosecondsSinceEpoch(micros, isUtc: true),
      report.timezone,
    );

/// 周起始日的「当月第几周」：以包含当月 1 日的那个周一周期为第 1 周。
int _weekOfMonth(DateTime monday) {
  final firstOfMonth = DateTime.utc(monday.year, monday.month, 1);
  return ((monday.day + firstOfMonth.weekday - 2) ~/ 7) + 1;
}

/// 「09/21–09/27」；endAt 为排他边界，展示时回退 1 微秒取末日。
String productionRangeLabel(ReportDocument report) {
  final start = _civilAt(report, report.startAt);
  final lastDay = _civilAt(report, report.endAt - 1);
  return '${_two(start.month)}/${_two(start.day)}'
      '–${_two(lastDay.month)}/${_two(lastDay.day)}';
}

/// 周期标签：「9月第4周（09/21–09/27）」或「2026年9月」。
String productionPeriodLabel(ReportDocument report) {
  final start = _civilAt(report, report.startAt);
  return switch (report.kind) {
    ReportPeriodKind.weekly =>
      '${start.month}月第${_weekOfMonth(start)}周（${productionRangeLabel(report)}）',
    ReportPeriodKind.monthly => '${start.year}年${start.month}月',
    ReportPeriodKind.custom => productionRangeLabel(report),
  };
}

/// AppBar 标题：「9月第4周周报」「2026年9月月报」。
String productionNavTitle(ReportDocument report) {
  final start = _civilAt(report, report.startAt);
  return switch (report.kind) {
    ReportPeriodKind.weekly => '${start.month}月第${_weekOfMonth(start)}周周报',
    ReportPeriodKind.monthly => '${start.year}年${start.month}月月报',
    ReportPeriodKind.custom => '自定义报告',
  };
}

/// 状态 chip 文案：待总结 / 已总结 / 失败。
String productionStatusChip(ReportDocument report) => switch (report.status) {
  ReportDocumentStatus.snapshotReady => '待总结',
  ReportDocumentStatus.summaryReady => '已总结',
  ReportDocumentStatus.failed => '失败',
};

/// 完成率整数百分比；分母为 0 时显示「—」。
String productionCompletionLabel(ReportDocument report) {
  final value = report.metrics.completion.value;
  return value == null ? '—' : '${value.round()}%';
}

/// 完成率的分子/分母，如「2/4」。
String productionCompletionFraction(ReportDocument report) =>
    '${report.metrics.completion.numerator}'
    '/${report.metrics.completion.denominator}';
