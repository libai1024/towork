import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'app_pressable.dart';

/// Floating navigation and controls, not the material for content beneath them.
///
/// Flutter exposes no reduce-transparency flag. Accessible navigation and high
/// contrast therefore use a solid surface, preserving legibility without blur.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.radius = 32,
    this.padding = EdgeInsets.zero,
    this.blur = 12,
    this.opacity,
    this.elevated = true,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double blur;
  final double? opacity;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = AppColors.of(context);
    final media = MediaQuery.of(context);
    final opaque = media.highContrast || media.accessibleNavigation;
    final corners = BorderRadius.circular(radius);
    final outline = RoundedSuperellipseBorder(borderRadius: corners);
    final tint = dark ? c.bgTertiary : c.bgPrimary;
    final surface = DecoratedBox(
      decoration: ShapeDecoration(
        color: tint.withValues(
          alpha: opaque ? 1 : opacity ?? (dark ? .88 : .92),
        ),
        shape: outline,
      ),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: ShapeDecoration(
          shape: outline.copyWith(
            side: BorderSide(
              color: opaque
                  ? c.labelSecondary
                  : Colors.white.withValues(alpha: dark ? .13 : .9),
              width: opaque ? 1 : .8,
            ),
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: outline,
        shadows: elevated && !opaque
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? .2 : .055),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? .08 : .025),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ]
            : const [],
      ),
      child: ClipRSuperellipse(
        borderRadius: corners,
        // Switching accessibility modes must keep the editor and its draft mounted.
        child: BackdropFilter(
          enabled: !opaque && blur != 0,
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: surface,
        ),
      ),
    );
  }
}

/// A circular floating action with a minimum 44-point target.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 44,
    this.iconSize = 22,
    this.color,
    this.elevated = true,
    this.opacity,
    this.blur = 12,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final Color? color;
  final bool elevated;
  final double? opacity;
  final double blur;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: GlassSurface(
      radius: 999,
      elevated: elevated,
      opacity: opacity,
      blur: blur,
      child: AppPressable(
        semanticLabel: label,
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: SizedBox.square(
          dimension: math.max(44, size),
          child: Icon(
            icon,
            size: iconSize,
            color: color ?? AppColors.of(context).labelPrimary,
          ),
        ),
      ),
    ),
  );
}
