import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_text_styles.dart';
import '../../../core/widgets/app_pressable.dart';

/// 图表卡片容器。
class VizCard extends StatelessWidget {
  const VizCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.hint,
  });

  final String title;
  final Widget child;

  /// 卡头右侧局部控制（口径切换 / 图形切换 / 周期分段）。
  final Widget? trailing;

  /// 降级轻提示（footnote labelTertiary），插在卡头与图表之间。
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.bgPrimary,
          borderRadius: AppRadii.brXl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.subhead.copyWith(
                      color: c.labelPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            if (hint != null) ...[
              const SizedBox(height: 6),
              Text(
                hint!,
                style: AppTextStyles.footnote.copyWith(color: c.labelTertiary),
              ),
            ],
            const SizedBox(height: 6),
            child,
          ],
        ),
      ),
    );
  }
}

/// 卡头分段保留 44 点热区，视觉胶囊仍保持紧凑。
class VizMiniSegmented<T> extends StatelessWidget {
  const VizMiniSegmented({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.iconOf,
    this.semanticLabel,
  });

  final List<T> options;
  final T selected;
  final String Function(T option) labelOf;
  final IconData? Function(T option)? iconOf;
  final ValueChanged<T> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: semanticLabel,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: c.fill1,
          borderRadius: AppRadii.brFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in options)
              AppPressable(
                onTap: () => onChanged(option),

                behavior: HitTestBehavior.opaque,
                semanticLabel: labelOf(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  constraints: const BoxConstraints(minHeight: 28),
                  padding: EdgeInsets.symmetric(
                    horizontal: iconOf != null ? 8 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: option == selected
                        ? (dark ? c.fill3 : c.bgPrimary)
                        : null,
                    borderRadius: AppRadii.brFull,
                    border: option == selected
                        ? Border.all(color: c.separator, width: 0.5)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: iconOf != null
                      ? Icon(
                          iconOf!(option),
                          size: 16,
                          color: option == selected
                              ? c.labelPrimary
                              : c.labelTertiary,
                        )
                      : Text(
                          labelOf(option),
                          style: AppTextStyles.caption.copyWith(
                            color: option == selected
                                ? c.labelPrimary
                                : c.labelTertiary,
                            fontWeight: FontWeight.w500,
                            height: 1,
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
