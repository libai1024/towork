import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_text_styles.dart';

/// 报告类型徽标：高 20，r-xs，fill1 底 + caption labelSecondary。
class ReportTypeBadge extends StatelessWidget {
  const ReportTypeBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(color: c.fill1, borderRadius: AppRadii.brXs),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: c.labelSecondary),
      ),
    );
  }
}

/// 来源徽标保持中性，颜色不用于区分 AI 与人工。
class AiBadge extends StatelessWidget {
  const AiBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: c.fill1, borderRadius: AppRadii.brFull),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.sparkles, size: 10, color: c.labelSecondary),
          const SizedBox(width: 3),
          Text(
            'AI',
            style: AppTextStyles.caption.copyWith(
              color: c.labelSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 三点脉冲（规范 §4.8）：3 个 4×4 fill3 圆点依次缩放，周期 900ms。
class PulsingDots extends StatefulWidget {
  const PulsingDots({super.key});

  @override
  State<PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<PulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

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
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_controller.value - i * 0.2) % 1.0;
            final scale =
                0.6 + 0.4 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2);
            return Container(
              margin: const EdgeInsets.only(right: 4),
              width: 4,
              height: 4,
              decoration: BoxDecoration(color: c.fill3, shape: BoxShape.circle),
              transform: Matrix4.diagonal3Values(scale, scale, 1),
              transformAlignment: Alignment.center,
            );
          }),
        );
      },
    );
  }
}
