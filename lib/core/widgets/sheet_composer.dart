import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'app_inline_input.dart';
import 'app_pressable.dart';

/// Short editors keep the draft and its commit action in the same surface.
class SheetComposer extends StatelessWidget {
  const SheetComposer({
    super.key,
    required this.title,
    required this.hint,
    required this.controller,
    required this.action,
    required this.onCommit,
    this.actionLabel,
    this.fieldKey,
    this.fields,
    this.tools = const [],
    this.error,
    this.saving = false,
    this.autofocus = true,
    this.multiline = false,
    this.maxLength,
    this.maxLines = 3,
    this.onChanged,
    this.onNext,
  });

  final String title, hint, action;
  final String? actionLabel, error;
  final TextEditingController controller;
  final Key? fieldKey;
  final Widget? fields;
  final VoidCallback onCommit;
  final VoidCallback? onNext;
  final ValueChanged<String>? onChanged;
  final bool saving, autofocus, multiline;
  final int? maxLength;
  final int maxLines;
  final List<Widget> tools;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final canCommit =
        controller.text.trim().isNotEmpty && error == null && !saving;
    final submitLabel = actionLabel ?? action;
    return PopScope(
      canPop: !saving,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  tooltip: '关闭',
                  onPressed: saving ? null : () => Navigator.pop(context),
                  icon: Icon(LucideIcons.x, size: 18, color: c.labelSecondary),
                  constraints: const BoxConstraints.tightFor(
                    width: 44,
                    height: 44,
                  ),
                ),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.subhead.copyWith(
                        color: c.labelPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Tooltip(
                  message: submitLabel,
                  excludeFromSemantics: true,
                  child: AppPressable(
                    semanticLabel: saving ? '保存中' : submitLabel,
                    onTap: canCommit ? onCommit : null,
                    borderRadius: BorderRadius.circular(24),
                    child: Center(
                      widthFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: canCommit || saving ? c.brand : c.fill2,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          child: saving
                              ? Semantics(
                                  liveRegion: true,
                                  label: '保存中',
                                  child: CupertinoActivityIndicator(
                                    radius: 8,
                                    color: c.onBrand,
                                  ),
                                )
                              : ExcludeSemantics(
                                  child: Text(
                                    action,
                                    style: AppTextStyles.footnote.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: canCommit
                                          ? c.onBrand
                                          : c.labelTertiary,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    key: fieldKey,
                    controller: controller,
                    enabled: !saving,
                    autofocus: autofocus,
                    minLines: multiline ? 2 : 1,
                    maxLines: maxLines,
                    maxLength: maxLength,
                    textInputAction: multiline
                        ? TextInputAction.newline
                        : (onNext == null
                              ? TextInputAction.done
                              : TextInputAction.next),
                    onSubmitted: multiline
                        ? null
                        : (_) {
                            if (onNext != null) {
                              onNext!();
                            } else if (!saving &&
                                controller.text.trim().isNotEmpty) {
                              onCommit();
                            }
                          },
                    onChanged: onChanged,
                    style: AppTextStyles.chatInput.copyWith(
                      color: c.labelPrimary,
                    ),
                    cursorColor: c.brand,
                    decoration: appInlineInput(
                      hintText: hint,
                      hintStyle: AppTextStyles.chatInput.copyWith(
                        color: c.labelSecondary,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      constraints: const BoxConstraints(minHeight: 44),
                    ).copyWith(counterText: '', errorText: error),
                  ),
                  if (fields != null)
                    IgnorePointer(ignoring: saving, child: fields!),
                  if (tools.isNotEmpty) ...[
                    Divider(height: 1, thickness: .6, color: c.separator),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: IgnorePointer(
                        ignoring: saving,
                        child: Wrap(spacing: 6, children: tools),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the current value in the toolbar. The hit area extends beyond the pill.
class SheetChoice extends StatelessWidget {
  const SheetChoice({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onOpen,
  });

  final IconData icon;
  final String label, value;
  final ValueChanged<BuildContext> onOpen;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: AppPressable(
        semanticLabel: '$label，$value',
        onTap: () => onOpen(context),
        borderRadius: BorderRadius.circular(18),
        child: Align(
          widthFactor: 1,
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.fill1,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(9, 5, 7, 5),
              child: ExcludeSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 15, color: c.labelSecondary),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.footnote.copyWith(
                          color: c.labelPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      LucideIcons.chevronDown,
                      size: 12,
                      color: c.labelSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
