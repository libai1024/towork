import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'app_pressable.dart';

/// Shared month picker with accessible touch targets and quiet theme tokens.
class AppDayCalendar extends StatefulWidget {
  const AppDayCalendar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.now,
    this.weekOnly = false,
    this.dayCounts = const {},
    this.headerTrailing,
    this.onPageChanged,
  });

  final DateTime? now;
  final bool weekOnly;
  final Map<DateTime, int> dayCounts;
  final Widget? headerTrailing;

  /// Date to focus after changing the displayed month or week. Optional so
  /// ordinary date pickers do not commit a date while browsing months.
  final ValueChanged<DateTime>? onPageChanged;

  final DateTime? selected;
  final ValueChanged<DateTime> onSelected;

  @override
  State<AppDayCalendar> createState() => AppDayCalendarState();
}

class AppDayCalendarState extends State<AppDayCalendar> {
  late DateTime _month;
  late DateTime _focusDay;
  final _horizontalScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    final base = widget.selected ?? widget.now ?? DateTime.now();
    _month = DateTime(base.year, base.month);
    _focusDay = DateUtils.dateOnly(base);
  }

  @override
  void dispose() {
    _horizontalScroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AppDayCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DateUtils.isSameDay(oldWidget.selected, widget.selected) &&
        widget.selected != null) {
      _focusDay = DateUtils.dateOnly(widget.selected!);
      _month = DateTime(_focusDay.year, _focusDay.month);
    }
  }

  void _shiftMonth(int delta) {
    final month = DateTime(_month.year, _month.month + delta);
    final day = widget.weekOnly
        ? DateTime(_focusDay.year, _focusDay.month, _focusDay.day + delta * 7)
        : DateTime(
            month.year,
            month.month,
            math.min(
              _focusDay.day,
              DateTime(month.year, month.month + 1, 0).day,
            ),
          );
    setState(() {
      _focusDay = day;
      _month = DateTime(day.year, day.month);
    });
    widget.onPageChanged?.call(day);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final today = DateUtils.dateOnly(widget.now ?? DateTime.now());
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday;
    final cells = <DateTime?>[
      if (widget.weekOnly)
        for (var i = 0; i < 7; i++)
          DateTime(
            _focusDay.year,
            _focusDay.month,
            _focusDay.day - (_focusDay.weekday - 1) + i,
          )
      else ...[
        for (var i = 1; i < firstWeekday; i++) null,
        for (var d = 1; d <= daysInMonth; d++)
          DateTime(_month.year, _month.month, d),
      ],
    ];
    // On narrow phones the editor has less than 7 × 44 px available. Keep a
    // complete seven-column calendar scrollable instead of shrinking hit areas.
    final metrics = TextPainter(
      text: TextSpan(text: '88', style: AppTextStyles.footnote),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final cellExtent = math.max(
      44.0,
      math.max(metrics.width, metrics.height) + 12,
    );
    metrics.dispose();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${_month.year} 年 ${_month.month} 月',
                style:
                    (widget.headerTrailing == null
                            ? AppTextStyles.subhead
                            : AppTextStyles.body)
                        .copyWith(
                          color: c.labelPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ?widget.headerTrailing,
            AppPressable(
              onTap: () => _shiftMonth(-1),
              semanticLabel: widget.weekOnly ? '上一周' : '上个月',
              child: Icon(
                LucideIcons.chevronLeft,
                size: 20,
                color: c.labelSecondary,
              ),
            ),
            AppPressable(
              onTap: () => _shiftMonth(1),
              semanticLabel: widget.weekOnly ? '下一周' : '下个月',
              child: Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: c.labelSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = math.max(constraints.maxWidth, cellExtent * 7);
            return Scrollbar(
              controller: _horizontalScroll,
              thumbVisibility: width > constraints.maxWidth,
              child: SingleChildScrollView(
                controller: _horizontalScroll,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 6),
                child: SizedBox(
                  width: width,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          for (final w in ['一', '二', '三', '四', '五', '六', '日'])
                            Expanded(
                              child: Center(
                                child: Text(
                                  w,
                                  style: AppTextStyles.caption.copyWith(
                                    color: c.labelTertiary,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      GridView(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisExtent: cellExtent,
                        ),
                        children: [
                          for (final day in cells)
                            if (day == null)
                              const SizedBox.shrink()
                            else
                              _CalendarCell(
                                extent: cellExtent,
                                day: day,
                                isToday: day == today,
                                count: widget.dayCounts[day],
                                selected:
                                    widget.selected != null &&
                                    DateUtils.isSameDay(day, widget.selected!),
                                onTap: () => widget.onSelected(day),
                              ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.extent,
    required this.day,
    required this.isToday,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final int? count;
  final DateTime day;
  final double extent;
  final bool isToday;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final diameter = extent - 4;
    return Semantics(
      selected: selected,
      child: AppPressable(
        semanticLabel:
            '${day.year}年${day.month}月${day.day}日${count == null ? '' : '，$count项待办'}',
        onTap: onTap,
        child: Center(
          child: Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              color: selected ? c.brand : Colors.transparent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${day.day}',
                  style: AppTextStyles.footnote.copyWith(
                    color: selected ? c.onBrand : c.labelPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if ((count ?? 0) > 0 || (isToday && !selected))
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: selected ? c.onBrand : c.labelSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
