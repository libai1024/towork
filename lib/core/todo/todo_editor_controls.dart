import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_text_styles.dart';
import '../widgets/app_pressable.dart';

/// 编辑器容器（字段行下方内联展开区）。
class TodoEditorBox extends StatelessWidget {
  const TodoEditorBox({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: c.fill1, borderRadius: AppRadii.brXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class TodoOptionRow extends StatelessWidget {
  const TodoOptionRow({
    super.key,
    this.icon,
    this.iconColor,
    this.dotColor,
    required this.label,
    this.selected = false,
    this.enabled = true,
    this.indent = 0,
    this.onTap,
  });

  final IconData? icon;
  final Color? iconColor;
  final Color? dotColor;
  final String label;
  final bool selected;
  final bool enabled;
  final double indent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fg = !enabled ? c.labelQuaternary : c.labelPrimary;
    return AppPressable(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      semanticLabel: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: EdgeInsets.fromLTRB(16 + indent, 8, 16, 8),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: iconColor ?? fg),
              const SizedBox(width: 12),
            ],
            if (dotColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: c.categorySurface(dotColor!),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(label, style: AppTextStyles.body.copyWith(color: fg)),
            ),
            if (selected) Icon(LucideIcons.check, size: 16, color: c.brand),
          ],
        ),
      ),
    );
  }
}

class TodoEditorStepper extends StatelessWidget {
  const TodoEditorStepper({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final String label;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    Widget btn(IconData icon, VoidCallback? onTap, String action) =>
        AppPressable(
          onTap: onTap,
          semanticLabel: '$action$label',
          behavior: HitTestBehavior.translucent,
          child: Icon(icon, size: 16, color: c.labelSecondary),
        );
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        color: c.bgPrimary,
        borderRadius: AppRadii.brMd,
        border: Border.all(color: c.separator, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(
            LucideIcons.minus,
            value > min ? () => onChanged(value - 1) : null,
            context.strings.decrease,
          ),
          SizedBox(
            width: 44,
            child: Center(
              child: Text(
                '$value',
                style: AppTextStyles.body.copyWith(
                  color: c.labelPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          btn(
            LucideIcons.plus,
            value < max ? () => onChanged(value + 1) : null,
            context.strings.increase,
          ),
        ],
      ),
    );
  }
}
