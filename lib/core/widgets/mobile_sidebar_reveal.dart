import 'package:towork/l10n/strings.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// A stationary sidebar revealed by sliding the full-width page to the right.
/// Owns only presentation, gestures and a local back-stack entry.
class MobileSidebarReveal extends StatefulWidget {
  const MobileSidebarReveal({
    super.key,
    required this.sidebar,
    this.endSidebar,
    required this.child,
  });

  final Widget sidebar;
  final Widget? endSidebar;
  final Widget child;

  @override
  State<MobileSidebarReveal> createState() => MobileSidebarRevealState();
}

class MobileSidebarRevealState extends State<MobileSidebarReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    lowerBound: -1,
    value: 0,
    duration: const Duration(milliseconds: 300),
  );
  LocalHistoryEntry? _history;
  bool _sidebarMounted = false;
  bool _endSidebarMounted = false;
  double _dragSide = 1;
  double _width = 0;
  bool _disposing = false;
  double _revealWidth = 0;
  bool _dragStartedOpen = false;
  bool _dragging = false;

  void _prepareOpening({bool end = false}) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (end && !_endSidebarMounted) {
      setState(() => _endSidebarMounted = true);
    } else if (!end && !_sidebarMounted) {
      setState(() => _sidebarMounted = true);
    }
    final route = ModalRoute.of(context);
    if (_history == null && route != null) {
      _history = LocalHistoryEntry(
        onRemove: () {
          _history = null;
          if (!_disposing && mounted) _settle(0);
        },
      );
      route.addLocalHistoryEntry(_history!);
    }
  }

  void open() {
    _prepareOpening();
    _settle(1);
  }

  void openEnd() {
    if (widget.endSidebar == null) return;
    _prepareOpening(end: true);
    _settle(-1);
  }

  void close() {
    final entry = _history;
    if (entry != null) {
      entry.remove();
    } else {
      _settle(0);
    }
  }

  void _settle(double target) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.value = target;
    } else {
      _animation.animateTo(target, curve: Curves.easeOutCubic);
    }
  }

  void _dragStart(DragStartDetails details) {
    _dragging = true;
    _dragStartedOpen = _animation.value.abs() > .5;
    _dragSide = _animation.value == 0
        ? (widget.endSidebar != null && details.globalPosition.dx > _width / 2
              ? -1
              : 1)
        : _animation.value.sign;
    _animation.stop();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _dragUpdate(DragUpdateDetails details) {
    if (_revealWidth <= 0) return;
    final next = (_animation.value + details.delta.dx / _revealWidth).clamp(
      _dragSide < 0 ? -1.0 : 0.0,
      _dragSide < 0 ? 0.0 : 1.0,
    );
    if (next != 0) _prepareOpening(end: next < 0);
    _animation.value = next;
  }

  void _dragEnd(DragEndDetails details) {
    _dragging = false;
    final velocity = details.primaryVelocity ?? 0;
    final shouldOpen = velocity.abs() > 450
        ? velocity * _dragSide > 0
        : _animation.value.abs() > .5;
    shouldOpen ? (_dragSide < 0 ? openEnd() : open()) : close();
  }

  void _dragCancel() {
    // Losing the arena to a tap, long press or vertical scroll is not a swipe.
    if (!_dragging) return;
    _dragging = false;
    _dragStartedOpen ? (_dragSide < 0 ? openEnd() : open()) : close();
  }

  @override
  void dispose() {
    _disposing = true;
    _history?.remove();
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        _width = constraints.maxWidth;
        _revealWidth = math
            .min(
              380.0,
              math.min(constraints.maxWidth * .85, constraints.maxWidth - 48),
            )
            .clamp(0.0, double.infinity);
        return ClipRect(
          child: ColoredBox(
            color: c.bgSecondary,
            child: AnimatedBuilder(
              animation: _animation,
              child: RepaintBoundary(child: widget.child),
              builder: (context, page) {
                final progress = _animation.value.abs();
                final revealed = progress > 0;
                final corners = BorderRadius.circular(36 * progress);
                final outline = RoundedSuperellipseBorder(
                  borderRadius: corners,
                  side: BorderSide(
                    color: c.labelPrimary.withValues(alpha: .1 * progress),
                    width: .65,
                  ),
                );
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_sidebarMounted)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: _revealWidth,
                        child: Offstage(
                          offstage: _animation.value <= 0,
                          child: GestureDetector(
                            onHorizontalDragStart: _dragStart,
                            onHorizontalDragUpdate: _dragUpdate,
                            onHorizontalDragEnd: _dragEnd,
                            onHorizontalDragCancel: _dragCancel,
                            child: widget.sidebar,
                          ),
                        ),
                      ),
                    if (_endSidebarMounted && widget.endSidebar != null)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        width: _revealWidth,
                        child: Offstage(
                          offstage: _animation.value >= 0,
                          child: GestureDetector(
                            onHorizontalDragStart: _dragStart,
                            onHorizontalDragUpdate: _dragUpdate,
                            onHorizontalDragEnd: _dragEnd,
                            onHorizontalDragCancel: _dragCancel,
                            child: widget.endSidebar!,
                          ),
                        ),
                      ),
                    Transform.translate(
                      offset: Offset(_revealWidth * _animation.value, 0),
                      child: DecoratedBox(
                        decoration: ShapeDecoration(
                          shape: outline,
                          shadows: revealed
                              ? [
                                  BoxShadow(
                                    color: c.labelPrimary.withValues(
                                      alpha: .07 * progress,
                                    ),
                                    blurRadius: 28,
                                    offset: const Offset(-8, 0),
                                  ),
                                ]
                              : const [],
                        ),
                        child: ClipRSuperellipse(
                          key: const ValueKey('mobile-reveal-surface'),
                          borderRadius: corners,
                          child: DecoratedBox(
                            position: DecorationPosition.foreground,
                            decoration: ShapeDecoration(shape: outline),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ExcludeFocus(
                                  excluding: revealed,
                                  child: ExcludeSemantics(
                                    excluding: revealed,
                                    child: IgnorePointer(
                                      ignoring: revealed,
                                      child: page,
                                    ),
                                  ),
                                ),
                                if (revealed)
                                  Semantics(
                                    label: context.strings.collapseSidebar,
                                    button: true,
                                    onTap: close,
                                    child: GestureDetector(
                                      key: const ValueKey(
                                        'mobile-sidebar-dismiss',
                                      ),
                                      behavior: HitTestBehavior.opaque,
                                      excludeFromSemantics: true,
                                      onTap: close,
                                      onHorizontalDragStart: _dragStart,
                                      onHorizontalDragUpdate: _dragUpdate,
                                      onHorizontalDragEnd: _dragEnd,
                                      onHorizontalDragCancel: _dragCancel,
                                      child: ColoredBox(
                                        color: c.bgGround.withValues(
                                          alpha: .48 * progress,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (widget.endSidebar != null)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        width: constraints.maxWidth * .25,
                        child: IgnorePointer(
                          ignoring: revealed,
                          child: GestureDetector(
                            key: const ValueKey('mobile-overview-edge'),
                            behavior: HitTestBehavior.translucent,
                            excludeFromSemantics: true,
                            onHorizontalDragStart: _dragStart,
                            onHorizontalDragUpdate: _dragUpdate,
                            onHorizontalDragEnd: _dragEnd,
                            onHorizontalDragCancel: _dragCancel,
                          ),
                        ),
                      ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      // Match the physical side of the screen, independent of
                      // the width of the revealed sidebar. Translucent hit
                      // testing lets taps and vertical scrolling reach content.
                      width: constraints.maxWidth * .25,
                      child: IgnorePointer(
                        ignoring: revealed,
                        child: GestureDetector(
                          key: const ValueKey('mobile-sidebar-edge'),
                          behavior: HitTestBehavior.translucent,
                          excludeFromSemantics: true,
                          onHorizontalDragStart: _dragStart,
                          onHorizontalDragUpdate: _dragUpdate,
                          onHorizontalDragEnd: _dragEnd,
                          onHorizontalDragCancel: _dragCancel,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
