import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/domain/reports/report_documents.dart';
import 'package:towork/features/reports/report_export.dart';
import 'package:towork/features/reports/widgets/report_poster.dart';
import 'package:towork/theme/app_theme.dart';

ReportDocument _document({String? summary}) {
  final metrics = ReportMetrics(
    created: 4,
    completed: 2,
    cancelledInWindow: 1,
    openAtEnd: 2,
    overdueAtEnd: 1,
    completion: const ReportRate(
      numerator: 2,
      denominator: 4,
      label: '完成数 ÷（周期内完成 + 期末仍未完成且未取消）',
    ),
    byCategory: const [
      ReportCategoryMetric(
        id: 'c1',
        name: '工作',
        colorValue: 0xff3366cc,
        created: 2,
        completed: 2,
      ),
    ],
    previousCompleted: 1,
    dataRowsTotal: 42,
    dataRowsCreated: 3,
    nickname: '小王',
  );
  return ReportDocument(
    id: 'report_weekly_test',
    kind: ReportPeriodKind.weekly,
    startAt: DateTime.utc(2026, 9, 21).microsecondsSinceEpoch,
    endAt: DateTime.utc(2026, 9, 28).microsecondsSinceEpoch,
    timezone: 'Asia/Shanghai',
    metrics: metrics,
    status: summary == null
        ? ReportDocumentStatus.snapshotReady
        : ReportDocumentStatus.summaryReady,
    summary: summary,
    snapshotId: 'a' * 64,
    createdAt: 0,
    updatedAt: 0,
  );
}

void main() {
  test('markdown quotes frozen numbers and the summary verbatim', () {
    final markdown = reportMarkdown(_document(summary: '进展：完成两项。'));
    expect(markdown, contains('# 周报 2026-09-21 ~ 2026-09-27'));
    expect(markdown, contains('- 用户：小王'));
    expect(markdown, contains('- 完成：2'));
    expect(markdown, contains('50.0%'));
    expect(markdown, contains('（2/4）'));
    expect(markdown, contains('| 工作 | 2 | 2 |'));
    expect(markdown, contains('进展：完成两项。'));
    expect(markdown, contains('快照：${'a' * 64}'));
    expect(reportMarkdown(_document()), contains('（总结尚未生成）'));
  });

  testWidgets('poster renders snapshot numbers and snapshot id', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: ListView(children: [ReportPoster(report: _document())]),
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('report-poster')), findsOneWidget);
    expect(find.text('周报 09/21–09/27'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    expect(find.textContaining('50%'), findsOneWidget);
    expect(find.byType(RepaintBoundary), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
