part of 'report_detail_page.dart';

/// 部分失败横幅（§6.4）：受影响分类的数据没赶上，给「重新生成」出口。
class _IncompleteBanner extends StatelessWidget {
  const _IncompleteBanner({
    required this.categoryNames,
    required this.onRegenerate,
  });

  final List<String> categoryNames;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final names = categoryNames.map((e) => '「$e」').join('、');
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(color: c.fill1, borderRadius: AppRadii.brMd),
      child: Row(
        children: [
          Icon(LucideIcons.triangleAlert, size: 16, color: c.labelPrimary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              context.strings.dataForWasntAvailableInTimeThis(names),
              style: AppTextStyles.footnote.copyWith(color: c.labelPrimary),
            ),
          ),
          AppPressable(
            onTap: onRegenerate,

            behavior: HitTestBehavior.translucent,
            semanticLabel: context.strings.regenerateConfirmregenerate,
            child: Text(
              context.strings.regenerateConfirmregenerate,
              style: AppTextStyles.caption.copyWith(color: c.brand),
            ),
          ),
        ],
      ),
    );
  }
}
