import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../core/widgets/app_pressable.dart';

/// 选项行（批量/改期/菜单 Sheet 用）。
class TodoOptionMenuRow extends StatelessWidget {
  const TodoOptionMenuRow({
    super.key,
    this.icon,
    this.dotColor,
    required this.label,
    this.selected = false,
    this.indent = 0,
    this.onTap,
  });

  final IconData? icon;
  final Color? dotColor;
  final String label;
  final bool selected;
  final double indent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppPressable(
      onTap: onTap,

      behavior: HitTestBehavior.opaque,
      semanticLabel: label,
      child: Container(
        height: 48,
        padding: EdgeInsets.only(left: 16 + indent, right: 16),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: c.labelSecondary),
              const SizedBox(width: 12),
            ],
            if (dotColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(color: c.labelPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (selected) Icon(LucideIcons.check, size: 16, color: c.brand),
          ],
        ),
      ),
    );
  }
}
