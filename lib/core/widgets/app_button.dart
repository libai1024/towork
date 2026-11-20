import 'package:towork/l10n/strings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'app_pressable.dart';

enum AppButtonType { primary, secondary, ghost, destructive, chip }

/// Shared capsule action with a 44-point minimum target and a loading state.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.icon,
    this.expand = false,
    this.enabled = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final IconData? icon;
  final bool expand;
  final bool enabled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final available = enabled && onPressed != null;
    final active = available && !loading;
    final (Color bg, Color fg) = switch (type) {
      AppButtonType.primary => (
        available ? c.brand : c.fill2,
        available ? c.onBrand : c.labelTertiary,
      ),
      AppButtonType.secondary => (
        c.brand.withValues(alpha: .1),
        available ? c.brand : c.labelTertiary,
      ),
      AppButtonType.ghost => (
        Colors.transparent,
        available ? c.brand : c.labelTertiary,
      ),
      AppButtonType.destructive => (
        c.fill1,
        available ? c.labelPrimary : c.labelTertiary,
      ),
      AppButtonType.chip => (
        c.fill2,
        available ? c.labelPrimary : c.labelTertiary,
      ),
    };
    final compact = type == AppButtonType.chip;
    final radius = BorderRadius.circular(999);
    return Semantics(
      liveRegion: loading,
      value: loading ? context.strings.processing : null,
      child: AppPressable(
        onTap: active ? onPressed : null,
        semanticLabel: label,
        borderRadius: radius,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: 8,
          ),
          decoration: ShapeDecoration(
            color: bg,
            shape: RoundedSuperellipseBorder(borderRadius: radius),
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading || icon != null) ...[
                if (loading)
                  CupertinoActivityIndicator(radius: 8, color: fg)
                else
                  Icon(icon, size: compact ? 16 : 18, color: fg),
                const SizedBox(width: 7),
              ],
              Flexible(
                child: Text(
                  label,
                  style: (compact ? AppTextStyles.footnote : AppTextStyles.body)
                      .copyWith(color: fg, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
