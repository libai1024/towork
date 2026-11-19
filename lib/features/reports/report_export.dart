import 'dart:io';

import 'package:flutter/widgets.dart';

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../domain/reports/report_documents.dart';

/// Deterministic Markdown of a report. Numbers come from the frozen snapshot;
/// the summary paragraph is quoted verbatim when present.
String reportMarkdown(ReportDocument report) {
  final metrics = report.metrics;
  final start = DateTime.fromMicrosecondsSinceEpoch(
    report.startAt,
    isUtc: true,
  ).toLocal();
  final endExclusive = DateTime.fromMicrosecondsSinceEpoch(
    report.endAt,
    isUtc: true,
  ).toLocal();
  final endLast = endExclusive.subtract(const Duration(days: 1));
  String two(int n) => n.toString().padLeft(2, '0');
  final period =
      '${start.year}-${two(start.month)}-${two(start.day)} ~ '
      '${endLast.year}-${two(endLast.month)}-${two(endLast.day)}';
  final rate = metrics.completion.value;
  final buffer = StringBuffer()
    ..writeln(
      '# ${report.kind == ReportPeriodKind.monthly ? '月报' : '周报'} $period',
    )
    ..writeln()
    ..writeln('- 用户：${metrics.nickname}')
    ..writeln('- 新增：${metrics.created}')
    ..writeln('- 完成：${metrics.completed}')
    ..writeln(
      '- 完成率：${rate == null ? '—' : '${rate.toStringAsFixed(1)}%'}'
      '（${metrics.completion.numerator}/${metrics.completion.denominator}）',
    )
    ..writeln('- 期末未完成：${metrics.openAtEnd}，其中逾期：${metrics.overdueAtEnd}')
    ..writeln(
      '- 业务表记录：${metrics.dataRowsTotal} 条，周期内新增 ${metrics.dataRowsCreated} 条',
    );
  if (metrics.previousCompleted != null) {
    buffer.writeln('- 上期完成：${metrics.previousCompleted}');
  }
  buffer
    ..writeln()
    ..writeln('## 分类')
    ..writeln()
    ..writeln('| 分类 | 新增 | 完成 |')
    ..writeln('|---|---|---|');
  for (final category in metrics.byCategory) {
    buffer.writeln(
      '| ${category.name} | ${category.created} | ${category.completed} |',
    );
  }
  buffer
    ..writeln()
    ..writeln('## 总结')
    ..writeln()
    ..writeln(report.summary ?? '（总结尚未生成）')
    ..writeln()
    ..writeln('---')
    ..writeln('口径：${metrics.completion.label}')
    ..writeln('快照：${report.snapshotId}');
  return buffer.toString();
}

/// Captures the poster boundary as PNG bytes at 3x pixel ratio. Returns the
/// written file; the caller decides how to surface the path.
Future<File> exportReportPosterPng(
  GlobalKey boundaryKey,
  ReportDocument report,
  Directory directory,
) async {
  final boundary =
      boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null || boundary.debugNeedsPaint) {
    throw PlatformException(code: 'poster_not_ready');
  }
  final image = await boundary.toImage(pixelRatio: 3);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  if (data == null) {
    throw PlatformException(code: 'poster_encode_failed');
  }
  final file = File(
    '${directory.path}/report_${report.id}_${DateTime.now().millisecondsSinceEpoch}.png',
  );
  await file.writeAsBytes(data.buffer.asUint8List());
  return file;
}
