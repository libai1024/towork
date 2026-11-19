import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';

/// 骨架屏（规范 §4.8）：fill1 呼吸动画块。
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = AppRadii.sm,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              c.fill1.withValues(alpha: 0.6 + 0.4 * _controller.value),
              Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}
