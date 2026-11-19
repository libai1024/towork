import 'dart:ui' show Color;

enum ReportType { weekly, monthly, custom }

enum ReportStatus { generating, ready, failed }

enum ReportSource { scheduled, manual }

/// 报告生成时勾选的分类快照（分类日后改名/删除不影响历史报告展示）。
class ReportCategoryRef {
  const ReportCategoryRef({
    required this.id,
    required this.name,
    required this.color,
  });

  final String id;
  final String name;
  final Color color;
}

/// 大数字卡片结构化数据（06-reports.md §8.2）。
/// delta 可空：无上期数据时前端显示中性行。
class ReportStats {
  const ReportStats({
    this.completionRate,
    this.doneCount,
    this.createdCount,
    this.overdueCount,
    this.dataRowCount,
    this.dataRowUnit,
    this.completionRateDelta,
    this.doneCountDelta,
    this.dataRowNote,
  });

  /// 完成率，0–100。
  final double? completionRate;
  final int? doneCount;
  final int? createdCount;
  final int? overdueCount;
  final int? dataRowCount;
  final String? dataRowUnit;

  /// 较上期的完成率变化（百分点）。
  final double? completionRateDelta;

  /// 较上期的完成数变化。
  final int? doneCountDelta;

  /// 数据条目补充说明（如「接收 3 批」）。
  final String? dataRowNote;
}

class Report {
  Report({
    required this.id,
    required this.type,
    required this.title,
    required this.periodLabel,
    required this.summary,
    required this.createdAt,
    required this.periodStart,
    required this.periodEnd,
    this.status = ReportStatus.ready,
    this.failureReason,
    this.isRead = false,
    this.source = ReportSource.scheduled,
    List<ReportCategoryRef> categorySnapshot = const [],
    this.contentMarkdown = '',
    this.stats = const ReportStats(),
    this.readingMinutes = 3,
    List<String> incompleteSections = const [],
    this.model,
    this.generatedAt,
    this.deletedAt,
  }) : categorySnapshot = List<ReportCategoryRef>.unmodifiable(
         categorySnapshot,
       ),
       incompleteSections = List<String>.unmodifiable(incompleteSections);

  final String id;
  final ReportType type;

  /// AI 生成的报告标题。
  final String title;

  /// 展示用周期名（「第 38 周」「2026 年 8 月」）。
  final String periodLabel;

  /// 一句话摘要。
  final String summary;
  final DateTime createdAt;

  /// 覆盖周期（分组与展示）。
  final DateTime periodStart;
  final DateTime periodEnd;

  final ReportStatus status;

  /// network / quota_5h / quota_week / quota_month。
  final String? failureReason;
  final bool isRead;
  final ReportSource source;
  final List<ReportCategoryRef> categorySnapshot;

  /// 正文（固定章节模板 Markdown）。
  final String contentMarkdown;
  final ReportStats stats;
  final int readingMinutes;

  /// 部分失败：受影响分类名（渲染黄色横幅）。
  final List<String> incompleteSections;

  /// 生成模型（如 k3）。
  final String? model;

  /// 生成完成时间（卡片右上角日期）。
  final DateTime? generatedAt;

  /// 软删除标记（撤销即清除）。
  final DateTime? deletedAt;

  static const Object _unset = Object();

  Report copyWith({
    String? title,
    String? summary,
    ReportStatus? status,
    Object? failureReason = _unset,
    bool? isRead,
    String? contentMarkdown,
    ReportStats? stats,
    int? readingMinutes,
    List<String>? incompleteSections,
    List<ReportCategoryRef>? categorySnapshot,
    Object? model = _unset,
    Object? generatedAt = _unset,
    Object? deletedAt = _unset,
  }) {
    return Report(
      id: id,
      type: type,
      title: title ?? this.title,
      periodLabel: periodLabel,
      summary: summary ?? this.summary,
      createdAt: createdAt,
      periodStart: periodStart,
      periodEnd: periodEnd,
      status: status ?? this.status,
      failureReason: identical(failureReason, _unset)
          ? this.failureReason
          : failureReason as String?,
      isRead: isRead ?? this.isRead,
      source: source,
      categorySnapshot: categorySnapshot ?? this.categorySnapshot,
      contentMarkdown: contentMarkdown ?? this.contentMarkdown,
      stats: stats ?? this.stats,
      readingMinutes: readingMinutes ?? this.readingMinutes,
      incompleteSections: incompleteSections ?? this.incompleteSections,
      model: identical(model, _unset) ? this.model : model as String?,
      generatedAt: identical(generatedAt, _unset)
          ? this.generatedAt
          : generatedAt as DateTime?,
      deletedAt: identical(deletedAt, _unset)
          ? this.deletedAt
          : deletedAt as DateTime?,
    );
  }
}

/// ISO 8601 周数（「第 N 周」标签用，避免客户端历法歧义）。
int isoWeekNumber(DateTime date) {
  // Work with calendar dates in UTC so DST cannot change a day count. The
  // week's Thursday determines its ISO week-year, including January/December.
  final day = DateTime.utc(date.year, date.month, date.day);
  final thursday = day.add(Duration(days: DateTime.thursday - day.weekday));
  final firstDay = DateTime.utc(thursday.year);
  return thursday.difference(firstDay).inDays ~/ 7 + 1;
}
