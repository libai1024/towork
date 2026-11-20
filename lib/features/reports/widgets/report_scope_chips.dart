part of 'generate_report_sheet.dart';

/// 周期快捷 Chip（单选）：选中 fill2 + labelPrimary，未选 fill1 + labelSecondary。
class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppPressable(
      onTap: onTap,

      behavior: HitTestBehavior.translucent,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: AppMotion.tabSwitch,
        curve: Curves.easeOut,
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? c.fill2 : c.fill1,
          borderRadius: AppRadii.brFull,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.footnote.copyWith(
            color: selected ? c.labelPrimary : c.labelSecondary,
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// 自定义日期按钮：fill1 底 r-md 高 40，body + chevron-down 16。
class _DateButton extends StatelessWidget {
  const _DateButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppPressable(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      semanticLabel: context.strings.chooseDateBuild3(label),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: c.fill1, borderRadius: AppRadii.brMd),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(color: c.labelPrimary),
              ),
            ),
            Icon(LucideIcons.chevronDown, size: 16, color: c.labelSecondary),
          ],
        ),
      ),
    );
  }
}

/// 分类多选 Chip：高 32 r-full；选中 = brand 1px 描边 + brand 字 + check 12。
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppPressable(
      onTap: onTap,

      behavior: HitTestBehavior.translucent,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: AppMotion.tabSwitch,
        curve: Curves.easeOut,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.transparent : c.fill1,
          borderRadius: AppRadii.brFull,
          border: selected ? Border.all(color: c.brand, width: 1) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(LucideIcons.check, size: 12, color: c.brand),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTextStyles.footnote.copyWith(
                color: selected ? c.brand : c.labelSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
