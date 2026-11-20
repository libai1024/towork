part of 'chat_drawer.dart';

extension _ChatDrawerCategories on _ChatDrawerState {
  Widget _row(
    AppColors c, {
    IconData? icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
    bool muted = false,
    String? trailing,
  }) => AppPressable(
    semanticLabel: label,
    borderRadius: BorderRadius.circular(14),
    onTap: onTap,
    child: Container(
      constraints: BoxConstraints(minHeight: widget.desktop ? 44 : 48),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? c.fill1 : null,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: c.labelSecondary),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: muted ? c.labelTertiary : c.labelPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null)
            Text(
              trailing,
              style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
            ),
        ],
      ),
    ),
  );

  String _group(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = today
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;
    return days <= 0
        ? context.strings.today
        : days == 1
        ? context.strings.yesterdayGroup
        : days < 7
        ? context.strings.lastDays
        : context.strings.earlier;
  }
}
