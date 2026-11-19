import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'app_pressable.dart';
import 'glass_surface.dart';

/// Inset, continuous-corner sheets on phones; compact dialogs on desktop.
class AppSheet {
  AppSheet._();

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    Widget? titleLeading,
    bool isScrollControlled = true,
    bool dismissible = true,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final transition = reduceMotion
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: Duration(milliseconds: 260),
            reverseDuration: Duration(milliseconds: 220),
          );
    // 遮罩走 scrim token（黑色基底），沿用既有的明暗两档透明度。
    final barrier = AppColors.of(context).scrim
        .withValues(alpha: dark ? .36 : .18);
    if (MediaQuery.sizeOf(context).width >= 900) {
      return showDialog<T>(
        context: context,
        useRootNavigator: false,
        barrierDismissible: dismissible,
        barrierColor: barrier,
        animationStyle: transition,
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(24),
          insetAnimationDuration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 180),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 560,
              maxHeight: MediaQuery.sizeOf(dialogContext).height * .85,
            ),
            child: _SheetSurface(
              title: title,
              titleLeading: titleLeading,
              child: child,
            ),
          ),
        ),
      );
    }
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: false,
      useSafeArea: true,
      isDismissible: dismissible,
      enableDrag: dismissible,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      barrierColor: barrier,
      elevation: 0,
      showDragHandle: false,
      sheetAnimationStyle: transition,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (sheetContext) {
        final media = MediaQuery.of(sheetContext);
        return Padding(
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: math.max(
                  0,
                  media.size.height -
                      media.viewInsets.bottom -
                      media.viewPadding.top -
                      media.viewPadding.bottom -
                      24,
                ),
              ),
              child: _SheetSurface(
                title: title,
                titleLeading: titleLeading,
                mobile: true,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SheetSurface extends StatelessWidget {
  const _SheetSurface({
    required this.child,
    this.title,
    this.titleLeading,
    this.mobile = false,
  });
  final Widget child;
  final String? title;
  final Widget? titleLeading;
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GlassSurface(
      radius: 24,
      blur: 8,
      opacity: .97,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mobile)
            Center(
              child: Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                decoration: BoxDecoration(
                  color: c.fill3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          if (title != null)
            Padding(
              padding: EdgeInsets.fromLTRB(16, mobile ? 0 : 8, 8, 4),
              child: Row(
                children: [
                  if (titleLeading != null) ...[
                    titleLeading!,
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title!,
                        style: AppTextStyles.title3.copyWith(
                          color: c.labelPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: '关闭',
                    excludeFromSemantics: true,
                    child: AppPressable(
                      semanticLabel: '关闭',
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => Navigator.of(context).pop(),
                      child: Center(
                        widthFactor: 1,
                        heightFactor: 1,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: c.fill2,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.x,
                            size: 17,
                            color: c.labelSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(height: mobile ? 6 : 12),
          Flexible(child: child),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
