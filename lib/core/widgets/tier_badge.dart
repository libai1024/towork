import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_text_styles.dart';
import 'app_pressable.dart';

/// 订阅等级徽标（规范 §7.1）：等级胶囊，最小高 18，水平 padding 7，
/// caption 600。默认反色，可由会员档位提供底色、前景和徽标。
class TierBadge extends StatelessWidget {
  const TierBadge({
    super.key,
    required this.tier,
    this.onTap,
    this.background,
    this.foreground,
    this.leading,
  });

  /// 档位名，如 "Prelude"。
  final String tier;
  final VoidCallback? onTap;
  final Color? background, foreground;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    final badge = Container(
      constraints: const BoxConstraints(minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: background ?? c.brand,
        borderRadius: AppRadii.brFull,
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 3)],
          Flexible(
            child: Text(
              tier,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                height: 14 / 11,
                color: foreground ?? c.onBrand,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return IntrinsicWidth(child: badge);
    return AppPressable(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      semanticLabel: '订阅等级 $tier',
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: IntrinsicWidth(child: badge),
      ),
    );
  }
}
