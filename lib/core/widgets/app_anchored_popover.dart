import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// A compact menu anchored to its trigger, constrained to the usable viewport.
///
/// [anchorContext] must belong to the trigger rather than the whole page.
/// Pass [anchorKey] when a responsive layout reparents or replaces the trigger.
class AppAnchoredPopover {
  AppAnchoredPopover._();

  static Future<T?> show<T>(
    BuildContext anchorContext, {
    required WidgetBuilder builder,
    double maxWidth = 300,
    GlobalKey? anchorKey,
    Color? barrierColor,
  }) {
    final navigator = Navigator.of(anchorContext);
    final overlay = navigator.overlay!.context.findRenderObject()! as RenderBox;
    final trigger = anchorContext.findRenderObject()! as RenderBox;
    var lastAnchor =
        trigger.localToGlobal(Offset.zero, ancestor: overlay) & trigger.size;
    Rect resolveAnchor() {
      final currentContext = anchorKey?.currentContext ?? anchorContext;
      if (!currentContext.mounted) return lastAnchor;
      final currentTrigger = currentContext.findRenderObject();
      final currentOverlay = navigator.overlay?.context.findRenderObject();
      if (currentTrigger is RenderBox &&
          currentTrigger.attached &&
          currentTrigger.hasSize &&
          currentOverlay is RenderBox &&
          currentOverlay.attached) {
        lastAnchor =
            currentTrigger.localToGlobal(
              Offset.zero,
              ancestor: currentOverlay,
            ) &
            currentTrigger.size;
      }
      return lastAnchor;
    }

    final dark = Theme.of(anchorContext).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(anchorContext);
    // 遮罩走 scrim token（黑色基底），沿用既有的明暗两档透明度。
    final barrier = AppColors.of(anchorContext).scrim
        .withValues(alpha: dark ? .36 : .18);

    return showDialog<T>(
      context: anchorContext,
      useRootNavigator: false,
      useSafeArea: false,
      barrierColor: barrierColor ?? barrier,
      animationStyle: reduceMotion
          ? AnimationStyle.noAnimation
          : const AnimationStyle(
              duration: Duration(milliseconds: 220),
              reverseDuration: Duration(milliseconds: 180),
            ),
      builder: (context) => _AnchoredPopover(
        initialAnchor: lastAnchor,
        resolveAnchor: resolveAnchor,
        maxWidth: maxWidth,
        builder: builder,
      ),
    );
  }
}

class _AnchoredPopover extends StatefulWidget {
  const _AnchoredPopover({
    required this.initialAnchor,
    required this.resolveAnchor,
    required this.maxWidth,
    required this.builder,
  });
  final Rect initialAnchor;
  final Rect Function() resolveAnchor;
  final double maxWidth;
  final WidgetBuilder builder;

  @override
  State<_AnchoredPopover> createState() => _AnchoredPopoverState();
}

class _AnchoredPopoverState extends State<_AnchoredPopover> {
  late Rect _anchor = widget.initialAnchor;
  bool _refreshScheduled = false;

  void _refreshAfterLayout() {
    if (_refreshScheduled) return;
    _refreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshScheduled = false;
      if (!mounted) return;
      // A responsive page can reparent the trigger during this frame. Reading
      // its transform here also avoids inspecting another box during layout.
      final anchor = widget.resolveAnchor();
      if (anchor != _anchor) setState(() => _anchor = anchor);
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // LayoutBuilder also covers nested navigator bounds changing when a
        // desktop sidebar changes width without changing the window metrics.
        _refreshAfterLayout();
        return CustomSingleChildLayout(
          delegate: _PopoverLayout(
            anchor: _anchor,
            maxWidth: widget.maxWidth,
            safeInsets: EdgeInsets.fromLTRB(
              media.padding.left + 12,
              media.padding.top + 8,
              media.padding.right + 12,
              math.max(media.padding.bottom, media.viewInsets.bottom) + 12,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: SingleChildScrollView(child: widget.builder(context)),
          ),
        );
      },
    );
  }
}

class _PopoverLayout extends SingleChildLayoutDelegate {
  const _PopoverLayout({
    required this.anchor,
    required this.safeInsets,
    required this.maxWidth,
  });

  final Rect anchor;
  final EdgeInsets safeInsets;
  final double maxWidth;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final width = math.min(
      maxWidth,
      math.max(0.0, constraints.maxWidth - safeInsets.horizontal),
    );
    return BoxConstraints(
      minWidth: width,
      maxWidth: width,
      maxHeight: math.max(0.0, constraints.maxHeight - safeInsets.vertical),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final right = math.max(
      safeInsets.left,
      size.width - safeInsets.right - childSize.width,
    );
    final bottom = math.max(
      safeInsets.top,
      size.height - safeInsets.bottom - childSize.height,
    );
    final below = anchor.bottom + 8;
    final above = anchor.top - childSize.height - 8;
    final top = below <= bottom
        ? below
        : above >= safeInsets.top
        ? above
        : bottom;
    return Offset(
      anchor.left.clamp(safeInsets.left, right),
      top.clamp(safeInsets.top, bottom),
    );
  }

  @override
  bool shouldRelayout(_PopoverLayout oldDelegate) =>
      anchor != oldDelegate.anchor ||
      safeInsets != oldDelegate.safeInsets ||
      maxWidth != oldDelegate.maxWidth;
}
