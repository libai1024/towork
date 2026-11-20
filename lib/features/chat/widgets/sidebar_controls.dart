import 'package:towork/l10n/strings.dart';

import 'dart:ui' as ui show Gradient;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/glass_surface.dart';
import '../../../core/membership/membership_badge.dart';
import '../../../core/widgets/work_mark.dart';
import '../../../domain/models/settings.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// The sidebar uses the same local glass as the conversation header.
double _tint(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? .54 : .68;

class SidebarHeader extends StatelessWidget {
  const SidebarHeader({
    super.key,
    required this.user,
    required this.desktop,
    required this.height,
    required this.onProfile,
    required this.onTier,
    required this.onNew,
    this.onCollapse,
  });

  final UserProfile user;
  final bool desktop;
  final double height;
  final VoidCallback onProfile, onTier, onNew;
  final VoidCallback? onCollapse;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final tint = _tint(context);
    return Row(
      children: [
        if (desktop) ...[
          const WorkMark(size: 29),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'ToWork',
              style: AppTextStyles.subhead.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: context.strings.collapseSidebar,
            onPressed: onCollapse,
            icon: Icon(
              LucideIcons.panelLeftClose,
              size: 18,
              color: c.labelSecondary,
            ),
          ),
        ] else
          Expanded(
            child: LayoutBuilder(
              builder: (context, bounds) => Align(
                alignment: Alignment.centerLeft,
                child: GlassSurface(
                  key: const ValueKey('sidebar-profile'),
                  radius: height / 2,
                  opacity: tint,
                  blur: 18,
                  elevated: false,
                  child: SizedBox(
                    height: height,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6, right: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: AppPressable(
                              semanticLabel: context.strings.avatar,
                              onTap: onProfile,
                              borderRadius: BorderRadius.circular(height / 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppAvatar(
                                    nickname: user.displayName(
                                      context.strings.defaultNickname,
                                    ),
                                    size: 30,
                                  ),
                                  const SizedBox(width: 7),
                                  Flexible(
                                    child: Text(
                                      user.displayName(
                                        context.strings.defaultNickname,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.body.copyWith(
                                        color: c.labelPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: bounds.maxWidth * .56,
                            ),
                            // Let the badge size itself to its caption inside its
                            // existing 44-point hit target.
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                MembershipBadge(tier: user.tier, onTap: onTier),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(width: 8),
        GlassIconButton(
          key: const ValueKey('sidebar-new-conversation'),
          icon: LucideIcons.messageCirclePlus,
          label: context.strings.newChatBuild,
          size: 44,
          iconSize: 20,
          opacity: tint,
          blur: 18,
          elevated: false,
          onTap: onNew,
        ),
      ],
    );
  }
}

class SidebarSearchBar extends StatelessWidget {
  const SidebarSearchBar({
    super.key,
    required this.desktop,
    required this.height,
    required this.onSearch,
    required this.onToggleTheme,
  });
  final bool desktop;
  final double height;
  final VoidCallback onSearch, onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final tint = _tint(context);
    return Row(
      children: [
        Expanded(
          child: GlassSurface(
            key: const ValueKey('sidebar-search'),
            radius: height / 2,
            opacity: tint,
            blur: 18,
            child: AppPressable(
              semanticLabel: context.strings.search,
              onTap: onSearch,
              borderRadius: BorderRadius.circular(height / 2),
              child: SizedBox(
                height: height,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.search,
                        size: 17,
                        color: c.labelSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.strings.search,
                          style: AppTextStyles.footnote.copyWith(
                            color: c.labelSecondary,
                          ),
                        ),
                      ),
                      if (desktop)
                        Text(
                          '⌘ K',
                          style: AppTextStyles.caption.copyWith(
                            color: c.labelTertiary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (!desktop) ...[
          const SizedBox(width: 8),
          GlassIconButton(
            icon: Theme.of(context).brightness == Brightness.dark
                ? LucideIcons.sun
                : LucideIcons.moon,
            label: context.strings.toggleLightOrDarkTheme,
            iconSize: 19,
            opacity: tint,
            blur: 18,
            onTap: onToggleTheme,
          ),
        ],
      ],
    );
  }
}

/// Softens only the ends of the scrolling list, before the glass is painted.
class SidebarEdgeFade extends CustomPainter {
  const SidebarEdgeFade({
    required this.color,
    required this.extent,
    required this.showTop,
  });
  final Color color;
  final double extent;
  final bool showTop;

  @override
  void paint(Canvas canvas, Size size) {
    final depth = extent.clamp(0.0, size.height / 2);
    if (depth <= 0) return;
    final colors = [
      color,
      color.withValues(alpha: .90),
      color.withValues(alpha: .45),
      color.withValues(alpha: 0),
    ];
    final paint = Paint();
    void fade(double start, double end) {
      paint.shader = ui.Gradient.linear(
        Offset(0, start),
        Offset(0, end),
        colors,
        const [0, .20, .60, 1],
      );
      canvas.drawRect(
        Rect.fromLTRB(
          0,
          start < end ? start : end,
          size.width,
          start < end ? end : start,
        ),
        paint,
      );
    }

    if (showTop) fade(0, depth);
    fade(size.height, size.height - depth);
  }

  @override
  bool shouldRepaint(SidebarEdgeFade old) =>
      old.color != color || old.extent != extent || old.showTop != showTop;
}
