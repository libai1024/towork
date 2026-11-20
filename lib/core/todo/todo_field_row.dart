import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../widgets/app_pressable.dart';

class TodoFieldRow extends StatefulWidget {
  const TodoFieldRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.inset = 16,
    this.caption,
    this.captionColor,
    this.expanded = false,
    this.onTap,
    this.editor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final double inset;
  final String? caption;
  final Color? captionColor;
  final bool expanded;
  final VoidCallback? onTap;
  final Widget? editor;

  @override
  State<TodoFieldRow> createState() => _TodoFieldRowState();
}

class _TodoFieldRowState extends State<TodoFieldRow> {
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Column(
      children: [
        AppPressable(
          onTap: widget.onTap,
          semanticLabel: context.strings.doubleTapToEdit(
            widget.label,
            widget.value,
          ),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: EdgeInsets.symmetric(
              horizontal: widget.inset,
              vertical: 6,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stacked =
                    constraints.maxWidth < 300 ||
                    MediaQuery.textScalerOf(context).scale(14) > 20;
                return Row(
                  children: [
                    Icon(widget.icon, size: 20, color: c.labelSecondary),
                    const SizedBox(width: 12),
                    if (!stacked) ...[
                      Text(
                        widget.label,
                        style: AppTextStyles.body.copyWith(
                          color: c.labelSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: stacked
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.end,
                        children: [
                          if (stacked)
                            Text(
                              widget.label,
                              style: AppTextStyles.footnote.copyWith(
                                color: c.labelSecondary,
                              ),
                            ),
                          Text(
                            widget.value,
                            style: AppTextStyles.body.copyWith(
                              color: widget.valueColor ?? c.labelPrimary,
                            ),
                            textAlign: stacked
                                ? TextAlign.start
                                : TextAlign.end,
                          ),
                          if (widget.caption != null)
                            Text(
                              widget.caption!,
                              style: AppTextStyles.caption.copyWith(
                                color: widget.captionColor ?? c.labelTertiary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      widget.expanded
                          ? LucideIcons.chevronDown
                          : LucideIcons.chevronRight,
                      size: 16,
                      color: c.labelTertiary,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        if (widget.editor != null)
          AnimatedSize(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: widget.expanded ? widget.editor! : const SizedBox.shrink(),
          ),
        Padding(
          padding: EdgeInsets.only(left: widget.inset + 32),
          child: Divider(height: 0.5, color: c.separator),
        ),
      ],
    );
  }
}
