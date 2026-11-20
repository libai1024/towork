part of 'heatmap_card.dart';

Color _levelColor(AppColors c, int level) => switch (level) {
  0 => c.fill1,
  1 => c.brand.withValues(alpha: 0.2),
  2 => c.brand.withValues(alpha: 0.4),
  3 => c.brand.withValues(alpha: 0.65),
  _ => c.brand,
};

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter({
    required this.colors,
    required this.counts,
    required this.metric,
    required this.start,
    required this.today,
    required this.labelStyle,
    required this.viewportLeft,
    required this.viewportWidth,
    this.selected,
    this.pulse = 0,
  });

  final AppColors colors;
  final Map<DateTime, int> counts;
  final HeatMetric metric;
  final DateTime start;
  final DateTime today;
  final TextStyle labelStyle;
  final double viewportLeft;
  final double viewportWidth;
  final (int, int)? selected;

  /// 选中格回弹插值 0→1。
  final double pulse;

  static const double cell = 10;
  static const double gap = 2;
  static const double pitch = cell + gap;
  static const double padLeft = 20;
  static const double padTop = 16;
  static const int columns = 52;
  static const int rows = 7;

  static Size get canvasSize =>
      Size(padLeft + columns * pitch - gap, padTop + rows * pitch - gap);

  @override
  void paint(Canvas canvas, Size size) {
    // 横滑时将首个可见月份的标签留在视口内，避免显示半个「月」。
    final visibleRight = viewportLeft + viewportWidth;
    for (var col = 0; col < columns; col++) {
      final monday = start.add(Duration(days: col * 7));
      final prev = col == 0 ? null : start.add(Duration(days: (col - 1) * 7));
      if (prev == null || monday.month != prev.month) {
        var endColumn = col + 1;
        while (endColumn < columns &&
            start.add(Duration(days: endColumn * 7)).month == monday.month) {
          endColumn++;
        }
        final monthLeft = padLeft + col * pitch;
        final monthRight = padLeft + endColumn * pitch;
        if (monthRight <= viewportLeft || monthLeft >= visibleRight) continue;
        final label = TextPainter(
          text: TextSpan(
            text: strings.monthPaint(monday.month),
            style: labelStyle,
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final left = math.max(monthLeft, viewportLeft);
        if (left + label.width <= math.min(monthRight, visibleRight)) {
          label.paint(canvas, Offset(left, 0));
        }
      }
    }
    // 行标签：一 / 三 / 五 / 日
    final rowLabels = {
      0: strings.mon,
      2: strings.wed,
      4: strings.fri,
      6: strings.weekdaySunday,
    };
    for (final e in rowLabels.entries) {
      _text(canvas, e.value, Offset(0, padTop + e.key * pitch - 1));
    }

    // 格子
    final fillPaint = Paint();
    (int, int)? selectedToDraw;
    for (var col = 0; col < columns; col++) {
      for (var row = 0; row < rows; row++) {
        final date = start.add(Duration(days: col * 7 + row));
        final rect = Rect.fromLTWH(
          padLeft + col * pitch,
          padTop + row * pitch,
          cell,
          cell,
        );
        final future = date.isAfter(today);
        final count = future ? 0 : (counts[date] ?? 0);
        fillPaint.color = future
            ? colors.fill1.withValues(alpha: 0.5)
            : _levelColor(colors, heatLevel(count, metric));
        if (selected == (col, row)) {
          selectedToDraw = (col, row);
          continue;
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(AppRadii.xs)),
          fillPaint,
        );
      }
    }
    // 选中格最后绘制：1.15 倍回弹 + 0.5px labelPrimary 描边
    if (selectedToDraw != null) {
      final (col, row) = selectedToDraw;
      final date = start.add(Duration(days: col * 7 + row));
      final count = counts[date] ?? 0;
      final base = Rect.fromLTWH(
        padLeft + col * pitch,
        padTop + row * pitch,
        cell,
        cell,
      );
      final scale = 1 + 0.15 * pulse;
      final rect = Rect.fromCenter(
        center: base.center,
        width: cell * scale,
        height: cell * scale,
      );
      final rrect = RRect.fromRectAndRadius(
        rect,
        const Radius.circular(AppRadii.xs),
      );
      canvas.drawRRect(
        rrect,
        Paint()..color = _levelColor(colors, heatLevel(count, metric)),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = colors.labelPrimary,
      );
    }
  }

  void _text(Canvas canvas, String text, Offset offset) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_HeatmapPainter old) =>
      old.counts != counts ||
      old.metric != metric ||
      old.selected != selected ||
      old.pulse != pulse ||
      old.viewportLeft != viewportLeft ||
      old.viewportWidth != viewportWidth ||
      old.colors != colors;
}
