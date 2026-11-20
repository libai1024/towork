import 'package:towork/l10n/strings.dart';

import '../../../app/routes.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_text_styles.dart';
import '../viz_stats.dart';
import 'viz_card.dart';

/// D3 分类分布（05 文档 §3.4）：环形图 ⇄ 柱状图切换，
/// 配色 = 分类色；图例行点击 = 过滤条单选该分类。
class DistributionCard extends StatefulWidget {
  const DistributionCard({
    super.key,
    required this.slices,
    required this.onIsolate,
  });

  /// 近 90 天按一级分类聚合的结果（已按全局过滤条过滤、数量降序）。
  final List<CategorySlice> slices;

  /// 图例行点击：单选该一级分类（null = 未分类，不可过滤）。
  final ValueChanged<String?> onIsolate;

  @override
  State<DistributionCard> createState() => _DistributionCardState();
}

class _DistributionCardState extends State<DistributionCard> {
  var _mode = _ChartMode.pie;
  int? _touchedIndex;

  int get _total => widget.slices.fold(0, (sum, s) => sum + s.total);
  int get _done => widget.slices.fold(0, (sum, s) => sum + s.done);

  Color _sliceColor(AppColors c, CategorySlice s) => s.category == null
      ? c.labelSecondary
      : c.categoryAccent(s.category!.color);

  String _sliceName(CategorySlice s) =>
      s.category?.name ?? context.strings.uncategorized;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return VizCard(
      title: context.strings.byCategory,
      trailing: VizMiniSegmented<_ChartMode>(
        options: _ChartMode.values,
        selected: _mode,
        labelOf: (m) => m == _ChartMode.pie
            ? context.strings.pieChart
            : context.strings.barChart,
        iconOf: (m) =>
            m == _ChartMode.pie ? LucideIcons.chartPie : LucideIcons.chartBar,
        semanticLabel: context.strings.switchChart,
        onChanged: (m) {
          HapticFeedback.lightImpact();
          setState(() {
            _mode = m;
            _touchedIndex = null;
          });
        },
      ),
      // 勾选范围内 Todo < 3 件时不画图（05 文档 §6.2）
      child: _total < 3
          ? _buildDegraded(c)
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(
                key: ValueKey(_mode),
                child: _mode == _ChartMode.pie ? _buildPie(c) : _buildBar(c),
              ),
            ),
    );
  }

  Widget _buildDegraded(AppColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Text(
              context.strings.addCategoriesToYourTasksToSee,
              style: AppTextStyles.body.copyWith(color: c.labelTertiary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: context.strings.organizeCategories,
              type: AppButtonType.ghost,
              onPressed: () => context.push(AppRoutes.categories),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPie(AppColors c) {
    final touched =
        _touchedIndex != null && _touchedIndex! < widget.slices.length
        ? widget.slices[_touchedIndex!]
        : null;
    final centerNumber = touched != null
        ? '${touched.total}'
        : '${(_done / _total * 100).round()}%';
    final centerLabel = touched != null
        ? context.strings.completeBuildpie(
            _sliceName(touched),
            (touched.rate * 100).round(),
          )
        : context.strings.completionRateBuildpie;

    return Column(
      children: [
        SizedBox(
          height: 176,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 56,
                  startDegreeOffset: -90,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      if (event is! FlTapUpEvent) return;
                      final index =
                          response?.touchedSection?.touchedSectionIndex;
                      if (index == null || index < 0) return;
                      HapticFeedback.lightImpact();
                      setState(() {
                        _touchedIndex = _touchedIndex == index ? null : index;
                      });
                    },
                  ),
                  sections: [
                    for (var i = 0; i < widget.slices.length; i++)
                      PieChartSectionData(
                        value: widget.slices[i].total.toDouble(),
                        color: _sliceColor(c, widget.slices[i]),
                        radius: _touchedIndex == i ? 30 : 24,
                        showTitle: false,
                      ),
                  ],
                ),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
              ),
              IgnorePointer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      centerNumber,
                      style: AppTextStyles.title1.copyWith(
                        color: c.labelPrimary,
                      ),
                    ),
                    Text(
                      centerLabel,
                      style: AppTextStyles.caption.copyWith(
                        color: c.labelTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 图例列表：点击 = 过滤条单选该分类
        for (final slice in widget.slices)
          AppPressable(
            onTap: slice.rootId == null
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    widget.onIsolate(slice.rootId);
                  },

            behavior: HitTestBehavior.opaque,
            semanticLabel: context.strings.itemsComplete(
              _sliceName(slice),
              slice.total,
              (slice.rate * 100).round(),
            ),
            child: SizedBox(
              height: 36,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _sliceColor(c, slice),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _sliceName(slice),
                      style: AppTextStyles.body.copyWith(color: c.labelPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    context.strings.itemsCompleteBuildpie(
                      slice.total,
                      (slice.rate * 100).round(),
                    ),
                    style: AppTextStyles.footnote.copyWith(
                      color: c.labelSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBar(AppColors c) {
    final maxTotal = widget.slices.fold(0, (m, s) => s.total > m ? s.total : m);
    final interval = (maxTotal / 2).ceilToDouble().clamp(1, 1 << 20);

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxTotal.toDouble(),
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(enabled: false),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval.toDouble(),
            getDrawingHorizontalLine: (value) =>
                FlLine(color: c.separator, strokeWidth: 0.5, dashArray: [4, 4]),
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
                reservedSize: 26,
                interval: interval.toDouble(),
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
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if (value != i.toDouble() ||
                      i < 0 ||
                      i >= widget.slices.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _sliceName(widget.slices[i]),
                      style: AppTextStyles.caption.copyWith(
                        color: c.labelTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < widget.slices.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: widget.slices[i].total.toDouble(),
                    width: 20,
                    color: _sliceColor(c, widget.slices[i]),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadii.xs),
                    ),
                    // 实色段 = 已完成，40% 透明段 = 未完成（一条同时表达总量与完成率）
                    rodStackItems: [
                      BarChartRodStackItem(
                        0,
                        widget.slices[i].done.toDouble(),
                        _sliceColor(c, widget.slices[i]),
                      ),
                      BarChartRodStackItem(
                        widget.slices[i].done.toDouble(),
                        widget.slices[i].total.toDouble(),
                        _sliceColor(c, widget.slices[i]).withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      ),
    );
  }
}

enum _ChartMode { pie, bar }
