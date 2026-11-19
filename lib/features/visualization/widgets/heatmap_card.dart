import 'dart:math' as math;

import 'package:flutter/material.dart' hide DataRow;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../app/providers.dart';
import '../../../domain/models/models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../viz_stats.dart';
import 'viz_card.dart';
import 'viz_day_sheet.dart';

/// D1 坚持强度热力图（05 文档 §3.2）：52 列 × 7 行 GitHub 风格，
/// 格子 10pt 间距 2，5 档 brand 透明度色阶，横滑看全年，点按出详情。
class HeatmapCard extends ConsumerStatefulWidget {
  const HeatmapCard({super.key, required this.todos, required this.dataRows});

  /// 已按全局过滤条过滤后的 Todo。
  final List<Todo> todos;
  final List<DataRow> dataRows;

  @override
  ConsumerState<HeatmapCard> createState() => _HeatmapCardState();
}

class _HeatmapCardState extends ConsumerState<HeatmapCard>
    with SingleTickerProviderStateMixin {
  HeatMetric _metric = HeatMetric.completed;
  (int, int)? _selected;
  final _scrollController = ScrollController();
  var _scrolledToEnd = false;

  late final AnimationController _pulse =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 160),
        reverseDuration: AppMotion.exit,
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _pulse.reverse();
      });

  DateTime get _today => dayOnly(DateTime.now());

  /// 52 列：本周在最后一列，起点 = 51 周前的周一。
  DateTime get _start =>
      mondayOf(_today).subtract(const Duration(days: 7 * 51));

  @override
  void dispose() {
    _pulse.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _ensureScrolledToEnd() {
    if (_scrolledToEnd) return;
    _scrolledToEnd = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Map<DateTime, int> get _counts => heatmapCounts(
    todos: widget.todos,
    metric: _metric,
    dataRows: widget.dataRows,
  );

  int _totalInWindow(Map<DateTime, int> counts) {
    var total = 0;
    counts.forEach((day, count) {
      if (!day.isBefore(_start) && !day.isAfter(_today)) total += count;
    });
    return total;
  }

  int _activeDays(Map<DateTime, int> counts) => counts.entries
      .where((e) => !e.key.isBefore(_start) && !e.key.isAfter(_today))
      .length;

  void _onTapCell(TapUpDetails details) {
    final p = details.localPosition;
    final col = ((p.dx - _HeatmapPainter.padLeft) / _HeatmapPainter.pitch)
        .floor();
    final row = ((p.dy - _HeatmapPainter.padTop) / _HeatmapPainter.pitch)
        .floor();
    if (col < 0 || col >= _HeatmapPainter.columns || row < 0 || row >= 7) {
      return;
    }
    final date = _start.add(Duration(days: col * 7 + row));
    if (date.isAfter(_today)) return;
    HapticFeedback.lightImpact();
    setState(() => _selected = (col, row));
    _pulse.forward(from: 0);
    _openDetail(date);
  }

  void _openDetail(DateTime date) {
    final title = '${date.month} 月 ${date.day} 日 周${weekdayLabel(date)}';
    if (_metric == HeatMetric.dataRows) {
      AppSheet.show<void>(
        context,
        child: _DataRowsSheet(day: date, title: title),
      );
      return;
    }
    AppSheet.show<void>(
      context,
      child: VizDaySheet(
        title: title,
        filter: _metric == HeatMetric.completed
            ? (t) => t.completedAt != null && sameDay(t.completedAt!, date)
            : (t) => sameDay(t.createdAt, date),
      ),
    );
  }

  void _openMetricSheet() {
    final c = AppColors.of(context);
    AppSheet.show<void>(
      context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '统计口径',
              style: AppTextStyles.subhead.copyWith(
                color: c.labelPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            for (final m in HeatMetric.values)
              SizedBox(
                height: 48,
                child: AppPressable(
                  onTap: () {
                    setState(() {
                      _metric = m;
                      _selected = null;
                    });
                    Navigator.of(context).pop();
                  },
                  behavior: HitTestBehavior.opaque,
                  semanticLabel: '口径：${m.label}',
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.label,
                              style: AppTextStyles.body.copyWith(
                                color: c.labelPrimary,
                              ),
                            ),
                            Text(
                              '色阶：${m.thresholdLabels.join(' / ')}',
                              style: AppTextStyles.caption.copyWith(
                                color: c.labelTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (m == _metric)
                        Icon(LucideIcons.check, size: 18, color: c.brand),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    _ensureScrolledToEnd();
    final counts = _counts;
    final total = _totalInWindow(counts);
    final activeDays = _activeDays(counts);

    return VizCard(
      title: '坚持强度',
      hint: activeDays < 7 ? '已记录 $activeDays 天' : null,
      trailing: AppPressable(
        onTap: _openMetricSheet,

        behavior: HitTestBehavior.translucent,
        semanticLabel: '切换统计口径，当前：${_metric.label}',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '口径：${_metric == HeatMetric.dataRows ? '数据' : (_metric == HeatMetric.completed ? '完成' : '新增')}',
              style: AppTextStyles.footnote.copyWith(color: c.brand),
            ),
            Icon(LucideIcons.chevronDown, size: 16, color: c.brand),
          ],
        ),
      ),
      child: Column(
        children: [
          Semantics(
            label:
                '坚持强度热力图，统计口径：${_metric.label}。过去一年共 $total ${_metric.unit}。',
            child: SizedBox(
              height: _HeatmapPainter.canvasSize.height,
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: _onTapCell,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_pulse, _scrollController]),
                      builder: (context, _) => CustomPaint(
                        size: _HeatmapPainter.canvasSize,
                        painter: _HeatmapPainter(
                          colors: c,
                          counts: counts,
                          metric: _metric,
                          start: _start,
                          today: _today,
                          labelStyle: AppTextStyles.caption.copyWith(
                            color: c.labelTertiary,
                          ),
                          selected: _selected,
                          pulse: Curves.easeOut.transform(_pulse.value),
                          viewportLeft: _scrollController.hasClients
                              ? _scrollController.offset
                              : 0,
                          viewportWidth: constraints.maxWidth,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '少',
                style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
              ),
              const SizedBox(width: 6),
              Semantics(
                label: '色阶：${_metric.thresholdLabels.join('，')}',
                child: Row(
                  children: [
                    for (var level = 0; level < 5; level++)
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(right: 3),
                        decoration: BoxDecoration(
                          color: _levelColor(c, level),
                          borderRadius: BorderRadius.circular(AppRadii.xs),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 3),
              Text(
                '多',
                style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
              ),
              const Spacer(),
              Text(
                '全年 $total ${_metric.unit}',
                style: AppTextStyles.caption.copyWith(color: c.labelSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
          text: TextSpan(text: '${monday.month}月', style: labelStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        final left = math.max(monthLeft, viewportLeft);
        if (left + label.width <= math.min(monthRight, visibleRight)) {
          label.paint(canvas, Offset(left, 0));
        }
      }
    }
    // 行标签：一 / 三 / 五 / 日
    const rowLabels = {0: '一', 2: '三', 4: '五', 6: '日'};
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

/// 口径 = 新增数据条数时的当日明细（数据表行）。
class _DataRowsSheet extends ConsumerWidget {
  const _DataRowsSheet({required this.day, required this.title});

  final DateTime day;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final bundle = ref.watch(dataTableProvider);
    final rows = bundle.rows.where((r) => sameDay(r.updatedAt, day)).toList()
      ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    String tableName(String id) {
      for (final t in bundle.tables) {
        if (t.id == id) return t.name;
      }
      return '数据表';
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title 新增数据 ${rows.length} 条',
              style: AppTextStyles.subhead.copyWith(
                color: c.labelPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: rows.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          '这一天很安静，什么也没有发生。',
                          style: AppTextStyles.body.copyWith(
                            color: c.labelTertiary,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: rows.length,
                      separatorBuilder: (_, _) => Divider(color: c.separator),
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        final title = row.values.values.length > 1
                            ? row.values.values.elementAt(1)
                            : row.id;
                        final hm =
                            '${row.updatedAt.hour.toString().padLeft(2, '0')}:${row.updatedAt.minute.toString().padLeft(2, '0')}';
                        return SizedBox(
                          height: 48,
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.table,
                                size: 16,
                                color: c.labelTertiary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: AppTextStyles.body.copyWith(
                                        color: c.labelPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${tableName(row.tableId)} $hm',
                                      style: AppTextStyles.footnote.copyWith(
                                        color: c.labelTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
