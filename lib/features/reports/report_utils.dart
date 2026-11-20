import 'package:towork/l10n/strings.dart';

import '../../domain/models/models.dart';

String _two(int v) => v.toString().padLeft(2, '0');

/// 「9.14」
String md(DateTime d) => '${d.month}.${d.day}';

/// 「09.21」
String mmdd(DateTime d) => '${_two(d.month)}.${_two(d.day)}';

/// 「09.21 08:00」
String mmddHm(DateTime d) =>
    '${_two(d.month)}.${_two(d.day)} ${_two(d.hour)}:${_two(d.minute)}';

/// 「9.14 – 9.20」
String rangeLabel(DateTime start, DateTime end) => '${md(start)} – ${md(end)}';

/// 列表分组头：「2026 年 9 月」（按周期结束所在月份）。
String monthGroupLabel(DateTime d) =>
    strings.formattedValueBuild2(d.year, d.month);

/// 类型徽标文案：周报 / 月报 / 自定义。
String reportTypeLabel(ReportType type) => switch (type) {
  ReportType.weekly => strings.weeklyReport,
  ReportType.monthly => strings.monthlyReport,
  ReportType.custom => strings.custom,
};

/// AppBar 标题：类型 + 周期序号（「第 38 周周报」「2026 年 8 月月报」）。
String reportNavTitle(Report report) => switch (report.type) {
  ReportType.weekly => strings.weeklyReportReportnavtitle(report.periodLabel),
  ReportType.monthly => strings.monthlyReportReportnavtitle(report.periodLabel),
  ReportType.custom => strings.customReport,
};

/// 详情页头部第一行：「周报 9.14 – 9.20」。
String reportHeaderLine(Report report) =>
    '${reportTypeLabel(report.type)} ${rangeLabel(report.periodStart, report.periodEnd)}';

/// 大数字卡片对比行措辞：「较上周 / 较上月 / 较上期」。
String compareLabel(Report report) => switch (report.type) {
  ReportType.weekly => strings.vsLastWeek,
  ReportType.monthly => strings.vsLastMonth,
  ReportType.custom => strings.vsLastPeriod,
};

/// 失败原因的可读文案。
String failureText(String? reason) => switch (reason) {
  'quota_5h' => strings.hourQuotaExhaustedResetsAtTheEnd,
  'quota_week' ||
  'quota_month' => strings.quotaExhaustedForThisPeriodResetsNext,
  _ => strings.reportGenerationFailed,
};
