import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'app_pressable.dart';

/// Content filters use understated tint, separate from floating glass chrome.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.selected = false,
    this.height = 32,
    this.color,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool selected;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final bg = selected
        ? c.brand
        : color != null
        ? c.categorySurface(color!)
        : c.fill1;
    final fg = selected ? c.onBrand : c.labelSecondary;
    final corners = BorderRadius.circular(999);
    final visualHeight = math.max(32.0, height);
    return Semantics(
      selected: selected,
      child: AppPressable(
        onTap: onTap,
        minSize: onTap == null ? visualHeight : 44,
        borderRadius: corners,
        behavior: HitTestBehavior.translucent,
        semanticLabel: label,
        child: Center(
          heightFactor: 1,
          widthFactor: 1,
          child: Container(
            constraints: BoxConstraints(minHeight: visualHeight),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: ShapeDecoration(
              color: bg,
              shape: RoundedSuperellipseBorder(borderRadius: corners),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: fg),
                  const SizedBox(width: 5),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: AppTextStyles.footnote.copyWith(
                      color: fg,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
