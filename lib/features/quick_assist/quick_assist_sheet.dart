import 'package:towork/l10n/strings.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// 快捷面板的容器：一张浮在屏幕底部的卡片，默认占半屏。
///
/// 顶部一行可以拖动：上拖展开到接近全屏，下拖收回半屏，半屏时再下拖
/// 则关闭。卡片从屏幕底部滑入，卡片外保持透明，点一下也会关闭。
/// 键盘弹出时卡片整体上移，离场时仍滑到屏幕底部。
///
/// 关闭由宿主决定：这里只通过 [onDismiss] 表达「用户想关」，宿主收尾后
/// 调用 [QuickAssistSheetState.dismiss] 播放离场动画。
class QuickAssistSheet extends StatefulWidget {
  const QuickAssistSheet({
    super.key,
    this.contentKey,
    required this.header,
    required this.body,
    required this.onDismiss,
  });

  /// 顶部一行，同时是拖动把手。
  final Widget header;
  final Widget body;

  /// 用户点了卡片外、按了返回键，或把卡片拖了下去。
  final VoidCallback onDismiss;

  /// 半屏时卡片高度占窗口的比例。
  final GlobalKey? contentKey;

  static const halfFraction = .56;

  @override
  State<QuickAssistSheet> createState() => QuickAssistSheetState();
}

class QuickAssistSheetState extends State<QuickAssistSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
    reverseDuration: const Duration(milliseconds: 240),
  );
  late final CurvedAnimation _motion = CurvedAnimation(
    parent: _entrance,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  bool _started = false;
  bool _expanded = false;
  bool _dragging = false;
  bool _leaving = false;

  /// 手指相对按下位置的位移，向下为正。
  double _drag = 0;

  bool get expanded => _expanded;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = _leaving ? 0 : 1;
    }
    if (_started) return;
    _started = true;
    // 先绘制卡片在屏幕外的起始帧，再开始移动。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_leaving) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _motion.dispose();
    _entrance.dispose();
    super.dispose();
  }

  /// 离场后重新滑上来。面板收在后台时又被唤起会用到。
  void show() {
    _leaving = false;
    setState(() {
      _dragging = false;
      _drag = 0;
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else {
      _entrance.forward(from: _entrance.isCompleted ? 0 : null);
    }
  }

  /// 播放离场动画。重复关闭、重新唤起或销毁时返回 false。
  Future<bool> dismiss() async {
    if (_leaving) return false;
    _leaving = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 0;
    } else {
      try {
        await _entrance.reverse().orCancel;
      } on TickerCanceled {
        return false;
      }
    }
    return mounted && _leaving;
  }

  void _toggleHeight() {
    if (_leaving) return;
    setState(() {
      _expanded = !_expanded;
      _drag = 0;
    });
  }

  void _dragEnd(DragEndDetails details) {
    // 快速一甩以方向为准，否则看拖了多远。
    final velocity = details.primaryVelocity ?? 0;
    final down = velocity > 700 || (velocity > -700 && _drag > 90);
    final up = velocity < -700 || (velocity < 700 && _drag < -60);
    if (!_expanded && down) {
      // 半屏时下拖是关闭。保留已经拖下去的位移，离场动画接着往下走。
      setState(() => _dragging = false);
      widget.onDismiss();
      return;
    }
    setState(() {
      _dragging = false;
      _drag = 0;
      if (_expanded && down) _expanded = false;
      if (!_expanded && up) _expanded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final media = MediaQuery.of(context);
    final reduceMotion = media.disableAnimations;
    final outline = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(32),
      side: BorderSide(color: c.separator, width: .8),
    );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onDismiss();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final keyboard = media.viewInsets.bottom;
          // 键盘收起时让出手势条；键盘弹出时紧贴键盘上沿。
          final bottom = keyboard + math.max(8.0, media.padding.bottom + 8);
          final top = media.viewPadding.top + 8;
          final available = math.max(0.0, constraints.maxHeight - bottom - top);
          final half = math.min(
            available,
            math.max(
              380.0,
              constraints.maxHeight * QuickAssistSheet.halfFraction,
            ),
          );
          double height;
          var shift = 0.0;
          if (_expanded) {
            height = (available - math.max(0.0, _drag)).clamp(half, available);
          } else if (_drag <= 0) {
            height = (half - _drag).clamp(half, available);
          } else {
            height = half;
            shift = _drag;
          }
          return Stack(
            children: [
              Positioned.fill(
                child: Semantics(
                  label: context.strings.closeQuickAsk,
                  button: true,
                  excludeSemantics: true,
                  child: GestureDetector(
                    key: const ValueKey('quick-assist-outside'),
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onDismiss,
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: bottom,
                child: AnimatedBuilder(
                  animation: _motion,
                  builder: (context, child) => Transform.translate(
                    // 包含键盘、安全区和阴影，确保整张卡片从屏幕外进出。
                    offset: Offset(
                      0,
                      (height + bottom + 40) * (1 - _motion.value),
                    ),
                    child: child,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: AnimatedContainer(
                        key: const ValueKey('quick-assist-card'),
                        duration: _dragging || reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        height: height,
                        transform: Matrix4.translationValues(0, shift, 0),
                        decoration: ShapeDecoration(
                          shape: outline,
                          shadows: [
                            BoxShadow(
                              color: c.scrim.withValues(alpha: .22),
                              blurRadius: 36,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Material(
                          color: c.bgGround,
                          shape: outline,
                          clipBehavior: Clip.antiAlias,
                          child: Semantics(
                            key: widget.contentKey,
                            scopesRoute: true,
                            namesRoute: true,
                            explicitChildNodes: true,
                            label: context.strings.quickAsk,
                            child: Column(
                              children: [
                                GestureDetector(
                                  key: const ValueKey('quick-assist-handle'),
                                  behavior: HitTestBehavior.translucent,
                                  excludeFromSemantics: true,
                                  onTap: _toggleHeight,
                                  onVerticalDragStart: (_) =>
                                      setState(() => _dragging = true),
                                  onVerticalDragUpdate: (details) =>
                                      setState(() => _drag += details.delta.dy),
                                  onVerticalDragEnd: _dragEnd,
                                  onVerticalDragCancel: () => setState(() {
                                    _dragging = false;
                                    _drag = 0;
                                  }),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Semantics(
                                        button: true,
                                        label: _expanded
                                            ? context.strings.collapseQuickAsk
                                            : context.strings.expandQuickAsk,
                                        onTap: _toggleHeight,
                                        child: Container(
                                          width: 32,
                                          height: 4,
                                          margin: const EdgeInsets.only(top: 8),
                                          decoration: BoxDecoration(
                                            color: c.fill3,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                      ),
                                      widget.header,
                                    ],
                                  ),
                                ),
                                Expanded(child: widget.body),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
