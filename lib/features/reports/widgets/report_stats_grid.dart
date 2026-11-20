import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../domain/models/models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// 大数字卡片区（06-reports.md §3.3）：2×2 网格，间距 8。
/// 涨跌由箭头与数字表达，只有逾期数量的提醒使用警示色。
/// 固定四卡：完成率 / 完成（副行新增）/ 逾期 / 核心数据新增条目。
class ReportStatsGrid extends StatelessWidget {
  const ReportStatsGrid({
    super.key,
    required this.stats,
    required this.compareText,
  });

  final ReportStats stats;

  /// 「较上周 / 较上月 / 较上期」。
  final String compareText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _completionCard(context)),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: _doneCard(context)),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _overdueCard(context)),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: _dataCard(context)),
          ],
        ),
      ],
    );
  }

  Widget _completionCard(BuildContext context) {
    final c = AppColors.of(context);
    final rate = stats.completionRate;
    final delta = stats.completionRateDelta;
    final Widget deltaRow;
    if (delta == null) {
      deltaRow = _deltaRow(
        context,
        LucideIcons.minus,
        context.strings.noPreviousComparison,
        c.labelTertiary,
      );
    } else if (delta >= 0) {
      deltaRow = _deltaRow(
        context,
        LucideIcons.trendingUp,
        '$compareText +${_fmt(delta)}pt',
        c.labelSecondary,
      );
    } else {
      deltaRow = _deltaRow(
        context,
        LucideIcons.trendingDown,
        '$compareText ${_fmt(delta)}pt',
        c.labelPrimary,
      );
    }
    return _card(
      context,
      value: rate == null ? null : _fmt(rate),
      unit: '%',
      label: context.strings.completionRateBuildpie,
      delta: deltaRow,
    );
  }

  Widget _doneCard(BuildContext context) {
    final c = AppColors.of(context);
    final created = stats.createdCount;
    return _card(
      context,
      value: stats.doneCount?.toString(),
      label: context.strings.complete,
      delta: created == null
          ? _deltaRow(context, LucideIcons.minus, '–', c.labelTertiary)
          : _deltaRow(
              context,
              LucideIcons.trendingUp,
              context.strings.addedDonecard(created),
              c.labelTertiary,
            ),
    );
  }

  Widget _overdueCard(BuildContext context) {
    final c = AppColors.of(context);
    final overdue = stats.overdueCount;
    return _card(
      context,
      value: overdue?.toString(),
      label: context.strings.overdueBuild,
      delta: overdue == null
          ? _deltaRow(context, LucideIcons.minus, '–', c.labelTertiary)
          : overdue > 0
          ? _deltaRow(
              context,
              LucideIcons.trendingDown,
              context.strings.needsAttention,
              c.overdueForeground,
            )
          : _deltaRow(
              context,
              LucideIcons.minus,
              context.strings.noneOverdue,
              c.labelTertiary,
            ),
    );
  }

  Widget _dataCard(BuildContext context) {
    final c = AppColors.of(context);
    final note = stats.dataRowNote;
    return _card(
      context,
      value: stats.dataRowCount?.toString(),
      unit: stats.dataRowUnit,
      label: context.strings.newData,
      delta: _deltaRow(
        context,
        LucideIcons.minus,
        note ?? '–',
        c.labelTertiary,
      ),
    );
  }

  /// 数字展示：整数去小数点，保留一位小数的实际值。
  String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : '$v';

  Widget _card(
    BuildContext context, {
    required String? value,
    String? unit,
    required String label,
    required Widget delta,
  }) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: c.bgPrimary,
        borderRadius: AppRadii.brLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value ?? '–',
                  style: AppTextStyles.title1.copyWith(
                    color: value == null ? c.labelQuaternary : c.labelPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (value != null && unit != null)
                Text(
                  unit,
                  style: AppTextStyles.body.copyWith(
                    color: c.labelPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: c.labelSecondary),
          ),
          const SizedBox(height: 6),
          delta,
        ],
      ),
    );
  }

  Widget _deltaRow(
    BuildContext context,
    IconData icon,
    String text,
    Color color,
  ) {
    return Semantics(
      label: text,
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
