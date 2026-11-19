import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/models/models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_text_styles.dart';
import '../viz_stats.dart';
import 'viz_card.dart';

/// D4 创建 vs 完成趋势（05 文档 §3.5）：brand 实线 = 创建，green = 完成，
/// 近 4/8/12 周可切，底部环比结论行；数据跨度 <2 周时降级为文字摘要。
class TrendCard extends StatefulWidget {
  const TrendCard({super.key, required this.todos});

  /// 已按全局过滤条过滤后的 Todo。
  final List<Todo> todos;

  @override
  State<TrendCard> createState() => _TrendCardState();
}

class _TrendCardState extends State<TrendCard> {
  int _weeks = 8;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final points = weeklyTrend(widget.todos, _weeks);
    final degraded = dataSpanDays(widget.todos) < 14;

    return VizCard(
      title: '创建 vs 完成',
      trailing: VizMiniSegmented<int>(
        options: const [4, 8, 12],
        selected: _weeks,
        labelOf: (w) => '$w 周',
        semanticLabel: '切换统计周期',
        onChanged: (w) {
          HapticFeedback.lightImpact();
          setState(() => _weeks = w);
        },
      ),
      child: degraded ? _buildDegraded(c, points.last) : _buildChart(c, points),
    );
  }

  Widget _buildDegraded(AppColors c, WeekPoint thisWeek) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Text(
              '趋势要等数据攒够两周才看得出来，先到的是惊喜。',
              style: AppTextStyles.body.copyWith(color: c.labelTertiary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '本周创建 ${thisWeek.created} 件，完成 ${thisWeek.completed} 件',
              style: AppTextStyles.body.copyWith(color: c.labelSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(AppColors c, List<WeekPoint> points) {
    var peak = 0;
    var createdSum = 0, completedSum = 0;
    for (final p in points) {
      createdSum += p.created;
      completedSum += p.completed;
      if (p.created > peak) peak = p.created;
      if (p.completed > peak) peak = p.completed;
    }
    final maxY = peak == 0 ? 4.0 : peak.toDouble();
    final yInterval = (maxY / 2).ceilToDouble();

    final prev = previousPeriodTotals(widget.todos, _weeks);
    final rate = createdSum == 0 ? 0.0 : completedSum / createdSum;
    final prevRate = prev.created == 0 ? 0.0 : prev.completed / prev.created;
    final deltaPct = ((rate - prevRate) * 100).round();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (points.length - 1).toDouble(),
              minY: 0,
              maxY: maxY,
              borderData: FlBorderData(show: false),
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yInterval,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: c.separator,
                  strokeWidth: 0.5,
                  dashArray: [4, 4],
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: yInterval,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.round()}',
                      style: AppTextStyles.caption.copyWith(
                        color: c.labelQuaternary,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 20,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final i = value.round();
                      if (value != i.toDouble() ||
                          i < 0 ||
                          i >= points.length) {
                        return const SizedBox.shrink();
                      }
                      // 12 周时隔点标注，避免拥挤
                      if (_weeks > 8 && i % 2 != 0) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'W${points[i].weekNumber}',
                          style: AppTextStyles.caption.copyWith(
                            color: c.labelTertiary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => c.bgTertiary,
                  tooltipBorder: BorderSide(color: c.separator, width: 0.5),
                  tooltipRoundedRadius: AppRadii.md,
                  tooltipPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  fitInsideHorizontally: true,
                  getTooltipItems: (spots) => [
                    for (var i = 0; i < spots.length; i++)
                      i == 0
                          ? LineTooltipItem(
                              _tooltipText(points, spots.first.x.round()),
                              AppTextStyles.footnote.copyWith(
                                color: c.labelPrimary,
                              ),
                            )
                          : null,
                  ],
                ),
              ),
              lineBarsData: [
                _line(c, [for (final p in points) p.created], c.brand),
                _line(c, [
                  for (final p in points) p.completed,
                ], c.labelSecondary),
              ],
            ),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          ),
        ),
        const SizedBox(height: 8),
        // 线图例
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _lineLegend(c, c.brand, '创建'),
            const SizedBox(width: 16),
            _lineLegend(c, c.labelSecondary, '完成'),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '近 $_weeks 周创建 $createdSum 件，完成 $completedSum 件',
            style: AppTextStyles.caption.copyWith(color: c.labelSecondary),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              style: AppTextStyles.caption.copyWith(color: c.labelSecondary),
              children: [
                TextSpan(text: '完成率 ${(rate * 100).round()}%，比上一周期 '),
                if (deltaPct == 0)
                  TextSpan(
                    text: '持平',
                    style: TextStyle(color: c.labelTertiary),
                  )
                else
                  TextSpan(
                    text: '${deltaPct > 0 ? '↑' : '↓'} ${deltaPct.abs()}%',
                    style: TextStyle(
                      color: deltaPct > 0 ? c.labelSecondary : c.labelPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _tooltipText(List<WeekPoint> points, int index) {
    if (index < 0 || index >= points.length) return '';
    final p = points[index];
    return '第 ${p.weekNumber} 周：创建 ${p.created} 完成 ${p.completed}';
  }

  Widget _lineLegend(AppColors c, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 2,
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppRadii.brFull,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
        ),
      ],
    );
  }

  LineChartBarData _line(AppColors c, List<int> ys, Color color) {
    return LineChartBarData(
      spots: [
        for (var i = 0; i < ys.length; i++)
          FlSpot(i.toDouble(), ys[i].toDouble()),
      ],
      isCurved: true,
      preventCurveOverShooting: true,
      color: color,
      barWidth: 2,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 3,
          color: color,
          strokeWidth: 0,
          strokeColor: color,
        ),
      ),
      belowBarData: BarAreaData(show: false),
    );
  }
}
