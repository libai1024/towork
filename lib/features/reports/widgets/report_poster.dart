import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/reports/report_documents.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_text_styles.dart';

/// 报告海报（FC5 render 产物）：数字全部来自冻结快照；无总结时显示待生成提示。
/// 被 RepaintBoundary 包裹后按 3x 像素比导出 PNG。
class ReportPoster extends ConsumerWidget {
  const ReportPoster({super.key, required this.report});
  final ReportDocument report;

  String get _periodLabel {
    final start = DateTime.fromMicrosecondsSinceEpoch(
      report.startAt,
      isUtc: true,
    ).toLocal();
    final end = DateTime.fromMicrosecondsSinceEpoch(
      report.endAt,
      isUtc: true,
    ).toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    final last = end.subtract(const Duration(days: 1));
    return report.kind == ReportPeriodKind.monthly
        ? strings.formattedValueProductionperiodlabel(start.year, start.month)
        : '${strings.weeklyReportPeriodlabel(two(start.month), two(start.day))}'
              '${two(last.month)}/${two(last.day)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final metrics = report.metrics;
    final rate = metrics.completion.value;
    return Container(
      key: const ValueKey('report-poster'),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.bgPrimary,
        borderRadius: AppRadii.brXl,
        border: Border.all(color: c.separator, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _periodLabel,
                  style: AppTextStyles.title3.copyWith(color: c.labelPrimary),
                ),
              ),
              Text(
                report.kind == ReportPeriodKind.monthly
                    ? context.strings.monthlyReport
                    : context.strings.weeklyReport,
                style: AppTextStyles.caption.copyWith(color: c.brand),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            context.strings.sToworkReport(metrics.nickname),
            style: AppTextStyles.footnote.copyWith(color: c.labelTertiary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _big(c, context.strings.complete, '${metrics.completed}'),
              _big(
                c,
                context.strings.completionRateBuildpie,
                rate == null ? '—' : '${rate.toStringAsFixed(0)}%',
              ),
              _big(c, context.strings.add, '${metrics.created}'),
              _big(c, context.strings.overdueBuild, '${metrics.overdueAtEnd}'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.strings.methodThisPeriod(
              metrics.completion.label,
              metrics.completion.numerator,
              metrics.completion.denominator,
            ),
            style: AppTextStyles.caption.copyWith(color: c.labelQuaternary),
          ),
          const SizedBox(height: 14),
          if (metrics.byCategory.isNotEmpty) ...[
            Text(
              context.strings.completedByCategory,
              style: AppTextStyles.subhead,
            ),
            const SizedBox(height: 8),
            for (final category in metrics.byCategory.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Color(category.colorValue),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        category.name,
                        style: AppTextStyles.footnote.copyWith(
                          color: c.labelSecondary,
                        ),
                      ),
                    ),
                    Text(
                      context.strings.completedAdded(
                        category.completed,
                        category.created,
                      ),
                      style: AppTextStyles.footnote.copyWith(
                        color: c.labelTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
          Text(context.strings.summaryBuild, style: AppTextStyles.subhead),
          const SizedBox(height: 6),
          Text(
            report.summary ?? context.strings.noSummaryYetOpenTheReportTo,
            style: AppTextStyles.body.copyWith(color: c.labelSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            'ToWork',
            style: AppTextStyles.caption.copyWith(color: c.labelQuaternary),
          ),
        ],
      ),
    );
  }

  Widget _big(AppColors c, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.title2.copyWith(color: c.labelPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
          ),
        ],
      ),
    );
  }
}
