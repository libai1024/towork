import 'package:towork/l10n/strings.dart';

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/membership_plan.dart';
import '../../core/widgets/work_mark.dart';
import '../../theme/app_text_styles.dart';
import '../../core/membership/membership_mark.dart';

class MembershipSuccess extends StatefulWidget {
  const MembershipSuccess({super.key, required this.plan});
  final MembershipPlan plan;
  @override
  State<MembershipSuccess> createState() => _MembershipSuccessState();
}

class _MembershipSuccessState extends State<MembershipSuccess>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  bool started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context)) {
      controller.value = 1;
      started = true;
    } else if (!started) {
      started = true;
      controller.forward();
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const cream = Color(0xfffff5df);
    final plan = widget.plan;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xff141412),
      ),
      child: Scaffold(
        key: const ValueKey('membership-success'),
        backgroundColor: const Color(0xff151513),
        body: Stack(
          fit: StackFit.expand,
          children: [
            ExcludeSemantics(
              child: Image.asset(
                plan.family.asset(plan.tier, 'jpg'),
                fit: BoxFit.cover,
                opacity: const AlwaysStoppedAnimation(.42),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x70141210),
                    Color(0x50141210),
                    Color(0xfa141210),
                  ],
                ),
              ),
            ),
            RepaintBoundary(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _MembershipLights(controller, plan.family),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 10, 0),
                    child: Row(
                      children: [
                        const Spacer(),
                        IconButton(
                          tooltip: context.strings.dismissSuccessAnimation,
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, size: 20, color: cream),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, bounds) => SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: bounds.maxHeight,
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 16,
                              ),
                              child: _SuccessDetails(
                                plan: plan,
                                progress: controller,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
                    child: SizedBox(
                      width: 420,
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: cream,
                          foregroundColor: const Color(0xff24221e),
                          textStyle: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(context.strings.complete),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessDetails extends StatelessWidget {
  const _SuccessDetails({required this.plan, required this.progress});
  final MembershipPlan plan;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    const cream = Color(0xfffff5df);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MembershipSignature(plan: plan, progress: progress),
        const SizedBox(height: 20),
        _Reveal(
          progress: progress,
          start: .30,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ToWork',
                style: AppTextStyles.subhead.copyWith(color: cream),
              ),
              const SizedBox(height: 4),
              Text(
                plan.name,
                textAlign: TextAlign.center,
                style: AppTextStyles.display.copyWith(
                  fontSize: 36,
                  height: 1.2,
                  color: cream,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.strings.membership(plan.name),
                style: AppTextStyles.subhead.copyWith(color: cream),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _Reveal(
          progress: progress,
          start: .46,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                liveRegion: true,
                child: Text(
                  context.strings.planChanged,
                  style: AppTextStyles.footnote.copyWith(
                    color: cream.withValues(alpha: .75),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.strings.creditsPerMonth(plan.credits),
                style: AppTextStyles.title3.copyWith(color: cream),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The brand arrives first; the tier joins it without replacing the W mark.
class _MembershipSignature extends StatelessWidget {
  const _MembershipSignature({required this.plan, required this.progress});
  final MembershipPlan plan;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    const cream = Color(0xfffff5df);
    const ink = Color(0xff171715);
    return SizedBox(
      width: 208,
      height: 150,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 8,
            left: 40,
            child: _Reveal(
              progress: progress,
              start: .06,
              child: AnimatedBuilder(
                animation: progress,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(31),
                    border: Border.all(color: cream.withValues(alpha: .25)),
                    boxShadow: [
                      BoxShadow(
                        color: cream.withValues(alpha: .13),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(1),
                    child: WorkMark(
                      key: ValueKey('membership-brand-logo'),
                      size: 108,
                      foregroundColor: cream,
                      backgroundColor: ink,
                    ),
                  ),
                ),
                builder: (_, child) {
                  final join = Curves.easeOutCubic.transform(
                    ((progress.value - .18) / .26).clamp(0, 1),
                  );
                  return Transform.translate(
                    offset: Offset(-18 * join, -5 * join),
                    child: child,
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 70,
            left: 110,
            child: _Reveal(
              progress: progress,
              start: .23,
              child: Semantics(
                label: context.strings.membershipBadge(plan.name),
                image: true,
                child: Container(
                  key: const ValueKey('membership-tier-logo'),
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cream,
                    shape: BoxShape.circle,
                    border: Border.all(color: ink, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .2),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: MembershipMark(plan: plan),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Reveal extends StatelessWidget {
  const _Reveal({
    required this.progress,
    required this.start,
    required this.child,
  });
  final Animation<double> progress;
  final double start;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: progress,
    child: child,
    builder: (_, child) {
      final reveal = Curves.easeOutCubic.transform(
        ((progress.value - start) / .28).clamp(0, 1),
      );
      return Opacity(
        opacity: reveal,
        child: Transform.translate(
          offset: Offset(0, 22 * (1 - reveal)),
          child: Transform.scale(scale: .94 + reveal * .06, child: child),
        ),
      );
    },
  );
}

/// A finite screen-wide field of light. The same timeline drives every stroke.
class _MembershipLights extends CustomPainter {
  _MembershipLights(this.progress, this.family) : super(repaint: progress);
  final Animation<double> progress;
  final MembershipFamily family;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0 || t >= 1) return;
    final glow = math.sin(t * math.pi);
    final center = Offset(size.width * .5, size.height * .4);
    final color = family == MembershipFamily.music
        ? const Color(0xffe4b67c)
        : const Color(0xffbee2e1);
    final spread = size.longestSide * (.08 + t * .72);
    final halo = Paint()
      ..shader = ui.Gradient.radial(center, spread, [
        color.withValues(alpha: .12 * glow),
        color.withValues(alpha: 0),
      ]);
    canvas.drawCircle(center, spread, halo);
    final line = Paint()..style = PaintingStyle.stroke;
    for (var i = 0; i < 12; i++) {
      final f = i / 11;
      line
        ..strokeWidth = .65 + f * .45
        ..color = color.withValues(alpha: glow * (.1 + .21 * f));
      final path = Path();
      if (family == MembershipFamily.music) {
        final x = size.width * (f * 1.5 - .25);
        path.moveTo(x - 70 * t, size.height);
        path.cubicTo(
          size.width * (1 - f),
          size.height * (.66 - t * .18),
          size.width * f,
          size.height * .35,
          x + 130 * t,
          -10,
        );
      } else {
        final rise = size.height * (1.15 - t * .7) + i * 14;
        path.moveTo(-20, rise + 45);
        path.lineTo(size.width * .29, rise - 30 - f * 30);
        path.lineTo(size.width * .43, rise + 5);
        path.lineTo(size.width * .69, rise - size.height * .25);
        path.lineTo(size.width + 20, rise + 10);
      }
      canvas.drawPath(path, line);
    }
    for (var i = 0; i < 34; i++) {
      final angle = i * 2.39996;
      final radius = (20 + i * 4) + t * size.longestSide * .48;
      final p =
          center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      final opacity = glow * (.25 + (i % 5) * .12);
      final dot = Paint()..color = color.withValues(alpha: opacity);
      canvas.drawCircle(p, i % 3 == 0 ? 1.7 : .85, dot);
      if (family == MembershipFamily.alpine && i % 7 == 0) {
        canvas.drawLine(
          p - const Offset(0, 5),
          p + const Offset(0, 5),
          dot..strokeWidth = .6,
        );
        canvas.drawLine(p - const Offset(4, 0), p + const Offset(4, 0), dot);
      }
    }
    for (var i = 0; i < 3; i++) {
      final ring = (t * 1.4 - i * .18).clamp(0.0, 1.0);
      if (ring <= 0 || ring >= 1) continue;
      canvas.drawCircle(
        center,
        48 + ring * size.shortestSide * .85,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .9
          ..color = color.withValues(alpha: (1 - ring) * .28),
      );
    }
  }

  @override
  bool shouldRepaint(_MembershipLights oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.family != family;
}
