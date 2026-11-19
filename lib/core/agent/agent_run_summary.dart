import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../widgets/app_pressable.dart';
import '../widgets/reply_copy_button.dart';

/// One terminal action row, after all of the reply's text and result cards.
class AgentRunSummary extends StatelessWidget {
  const AgentRunSummary({
    super.key,
    required this.label,
    required this.icon,
    this.note,
    this.replyText,
    this.onUndo,
    this.processing = false,
    this.compactActions = false,
    this.undoEnabled = true,
  });

  final String label;
  final IconData icon;
  final String? note, replyText;
  final VoidCallback? onUndo;
  final bool processing, compactActions, undoEnabled;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (replyText != null) ReplyCopyButton(text: replyText!),
            if (label.isNotEmpty) ...[
              if (processing && !MediaQuery.disableAnimationsOf(context))
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: c.labelSecondary,
                  ),
                )
              else
                Icon(
                  processing ? LucideIcons.ellipsis : icon,
                  size: 14,
                  color: c.labelSecondary,
                ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.footnote.copyWith(
                    color: c.labelSecondary,
                  ),
                ),
              ),
            ],
            if (onUndo != null)
              if (compactActions)
                Tooltip(
                  message: '撤销本次全部修改',
                  excludeFromSemantics: true,
                  child: AppPressable(
                    semanticLabel: '撤销本次全部修改',
                    minSize: 48,
                    onTap: undoEnabled ? onUndo : null,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        LucideIcons.undo2,
                        size: 17,
                        color: c.labelSecondary,
                      ),
                    ),
                  ),
                )
              else
                TextButton(
                  onPressed: undoEnabled ? onUndo : null,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: c.labelSecondary,
                    textStyle: AppTextStyles.footnote,
                  ),
                  child: const Text('撤销'),
                ),
          ],
        ),
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              note!,
              style: AppTextStyles.caption.copyWith(color: c.labelSecondary),
            ),
          ),
      ],
    );
  }
}
