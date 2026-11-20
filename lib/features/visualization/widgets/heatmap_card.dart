import 'package:towork/l10n/strings.dart';

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

part 'heatmap_painter.dart';

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
    final title = context.strings.formattedValueOpenday(
      date.month,
      date.day,
      weekdayLabel(date),
    );
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
              context.strings.metric,
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
                  semanticLabel: context.strings.method(m.label),
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
                              context.strings.scale(
                                m.thresholdLabels.join(' / '),
                              ),
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
      title: context.strings.activity,
      hint: activeDays < 7 ? context.strings.daysRecorded(activeDays) : null,
      trailing: AppPressable(
        onTap: _openMetricSheet,

        behavior: HitTestBehavior.translucent,
        semanticLabel: context.strings.changeMetricCurrently(_metric.label),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.strings.method(
                _metric == HeatMetric.dataRows
                    ? context.strings.data
                    : (_metric == HeatMetric.completed
                          ? context.strings.complete
                          : context.strings.add),
              ),
              style: AppTextStyles.footnote.copyWith(color: c.brand),
            ),
            Icon(LucideIcons.chevronDown, size: 16, color: c.brand),
          ],
        ),
      ),
      child: Column(
        children: [
          Semantics(
            label: context.strings.activityHeatmapForPastYear(
              _metric.label,
              total,
              _metric.unit,
            ),
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
                context.strings.less,
                style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
              ),
              const SizedBox(width: 6),
              Semantics(
                label: context.strings.scale(_metric.thresholdLabels.join('，')),
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
                context.strings.moreBuild,
                style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
              ),
              const Spacer(),
              Text(
                context.strings.yearBuild(total, _metric.unit),
                style: AppTextStyles.caption.copyWith(color: c.labelSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
      return context.strings.tablesTablename;
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
              context.strings.rowsAdded(title, rows.length),
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
                          context.strings.noActivityThisDay,
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
