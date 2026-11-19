import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// ToWork's Quiet Precision monogram; geometry matches tool/generate_brand.swift.
class WorkMark extends StatelessWidget {
  const WorkMark({
    super.key,
    this.size = 32,
    this.foregroundColor,
    this.backgroundColor,
  });
  final double size;
  final Color? foregroundColor, backgroundColor;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      label: 'ToWork',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? c.labelPrimary,
          borderRadius: BorderRadius.circular(size * .28),
        ),
        child: CustomPaint(
          painter: _MarkPainter(foregroundColor ?? c.bgPrimary),
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = size.width * .075
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * .22, size.height * .35)
        ..lineTo(size.width * .34, size.height * .68)
        ..lineTo(size.width * .49, size.height * .44)
        ..lineTo(size.width * .62, size.height * .68)
        ..lineTo(size.width * .79, size.height * .30),
      p,
    );
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => color != oldDelegate.color;
}
