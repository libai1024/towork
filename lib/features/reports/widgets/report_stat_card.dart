part of 'production_report_detail_view.dart';

/// 详情页大数字卡（bgPrimary + r-lg）。
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    this.sub,
    this.emphasized = false,
  });

  final String value;
  final String label;
  final String? sub;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
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
          Text(
            value,
            style: AppTextStyles.title1.copyWith(
              color: emphasized ? c.overdueForeground : c.labelPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: c.labelSecondary),
          ),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(
              sub!,
              style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
