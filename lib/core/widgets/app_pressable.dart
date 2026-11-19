import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Shared pointer, touch and keyboard interaction with visible focus.
class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.minSize = 44,
    this.compact = false,
    this.behavior = HitTestBehavior.opaque,
    this.borderRadius,
    this.semanticLabel,
  });
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double minSize;

  /// Dense menu rows opt into their own minimum, with content-led height.
  final bool compact;
  final HitTestBehavior behavior;
  final BorderRadius? borderRadius;
  final String? semanticLabel;
  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false, _hover = false, _focus = false;
  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    final targetSize = enabled && !widget.compact && widget.minSize < 44
        ? 44.0
        : widget.minSize;
    final c = AppColors.of(context);
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        onShowFocusHighlight: (v) => setState(() => _focus = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: widget.behavior,
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedOpacity(
            opacity: _pressed ? AppMotion.pressOpacity : 1,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : AppMotion.press,
            child: Container(
              constraints: BoxConstraints(
                minWidth: targetSize,
                minHeight: targetSize,
              ),
              foregroundDecoration: BoxDecoration(
                color: _hover ? c.labelPrimary.withValues(alpha: .06) : null,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
                border: _focus ? Border.all(color: c.labelPrimary) : null,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
