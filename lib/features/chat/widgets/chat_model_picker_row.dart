import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/app_pressable.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Dense menu rows grow with wrapped text and retain a separate selected state.
class ChatModelPickerRow extends StatelessWidget {
  const ChatModelPickerRow({
    super.key,
    required this.label,
    required this.onTap,
    this.leading,
    this.selected = false,
    this.next = false,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onTap;
  final Widget? leading;
  final bool selected, next;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = onTap == null ? c.labelTertiary : c.labelPrimary;
    return Semantics(
      selected: selected,
      child: AppPressable(
        minSize: 36,
        compact: true,
        onTap: onTap,
        semanticLabel: semanticLabel ?? label,
        borderRadius: BorderRadius.circular(10),
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 6)],
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.modelLabel.copyWith(color: color),
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 6),
                  Icon(LucideIcons.check, size: 14, color: color),
                ],
                if (next) ...[
                  const SizedBox(width: 6),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 14,
                    color: c.labelSecondary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
