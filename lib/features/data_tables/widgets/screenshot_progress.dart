part of 'screenshot_flow_page.dart';

/// 图片占位（纯 UI 阶段无真实图片文件）。
class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({
    required this.label,
    required this.height,
    this.width,
    this.iconSize = 48,
  });

  final String label;
  final double height;
  final double? width;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(color: c.fill2, borderRadius: AppRadii.brXl),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.images, size: iconSize, color: c.labelQuaternary),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: c.labelSecondary),
          ),
        ],
      ),
    );
  }
}

/// 上传进度：2px brand 细条压在图片底部（§3.6 步骤 1）。
class _UploadProgressBar extends StatelessWidget {
  const _UploadProgressBar();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadii.xl),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOut,
        builder: (context, value, _) => SizedBox(
          height: 2,
          width: double.infinity,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(color: c.brand),
          ),
        ),
      ),
    );
  }
}

/// 三点脉冲（规范 §4.8 AI 思考中）。
class _DotsPulse extends StatefulWidget {
  const _DotsPulse();

  @override
  State<_DotsPulse> createState() => _DotsPulseState();
}

class _DotsPulseState extends State<_DotsPulse>
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
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              // 三角波错峰：每个点相位错开 1/3 周期。
              Opacity(
                opacity: () {
                  final phase = (_controller.value - i / 3) % 1.0;
                  final bump = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
                  return 0.25 + 0.75 * bump;
                }(),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: c.brand,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
