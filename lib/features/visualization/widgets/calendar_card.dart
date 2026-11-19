import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../app/providers.dart';
import '../../../core/workspace_actions.dart';
import '../../../domain/models/models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../viz_stats.dart';
import 'viz_card.dart';
import 'viz_day_sheet.dart';

/// D2 日历（05 文档 §3.3）：月视图，Todo 按截止日分布，
/// 点日期出当日明细，长按 Todo 条拖拽改期（Toast 可撤销）。
class CalendarCard extends ConsumerStatefulWidget {
  const CalendarCard({
    super.key,
    required this.todos,
    required this.categories,
  });

  /// 已按全局过滤条过滤后的 Todo。
  final List<Todo> todos;
  final List<Category> categories;

  @override
  ConsumerState<CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends ConsumerState<CalendarCard> {
  static const _basePage = 600; // PageView 中点，前后各约 50 年
  late final PageController _pageController = PageController(
    initialPage: _basePage,
  );
  late DateTime _displayedMonth = _monthOf(_basePage);

  DateTime get _today => dayOnly(DateTime.now());

  DateTime _monthOf(int page) {
    final now = DateTime.now();
    return DateTime(now.year, now.month + page - _basePage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Category? _categoryOf(String? id) {
    if (id == null) return null;
    for (final c in widget.categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Color _colorOf(String? id) =>
      _categoryOf(id)?.color ?? AppColors.of(context).fill4;

  List<Todo> _todosOn(DateTime day) {
    final list = widget.todos
        .where((t) => t.dueAt != null && sameDay(t.dueAt!, day))
        .toList();
    list.sort((a, b) {
      final aDone = a.status == TodoStatus.done;
      final bDone = b.status == TodoStatus.done;
      if (aDone != bDone) return aDone ? 1 : -1;
      return a.dueAt!.compareTo(b.dueAt!);
    });
    return list;
  }

  void _goToday() {
    _pageController.animateToPage(
      _basePage,
      duration: AppMotion.tabSwitch,
      curve: Curves.easeOut,
    );
  }

  void _openDay(DateTime day) {
    HapticFeedback.lightImpact();
    AppSheet.show<void>(
      context,
      child: VizDaySheet(
        title: '${day.month} 月 ${day.day} 日 周${weekdayLabel(day)}',
        filter: (t) => t.dueAt != null && sameDay(t.dueAt!, day),
      ),
    );
  }

  /// 拖拽改期（05 文档 §5.3）：保留原时:分，立即生效 + Toast 可撤销。
  Future<void> _reschedule(Todo todo, DateTime day) async {
    final repository = ref.read(todoListProvider.notifier);
    final current = repository.byId(todo.id);
    if (current == null) return;
    final old = current.dueAt;
    if (old == null || sameDay(old, day)) return;
    final newDue = DateTime(day.year, day.month, day.day, old.hour, old.minute);
    final change = await workspaceUi(
      context,
      () => ref
          .read(workspaceUiCommandsProvider)
          .run((t, c) => t.updateTodo(current.copyWith(dueAt: newDue))),
    );
    if (!mounted || change == null) return;
    HapticFeedback.mediumImpact();

    // 冲突轻提示：当天高优先级 ≥ 3 件时追加说明
    final highOnDay = widget.todos
        .where(
          (t) =>
              t.id != todo.id &&
              t.dueAt != null &&
              sameDay(t.dueAt!, day) &&
              t.priority == TodoPriority.high &&
              t.isActive,
        )
        .length;
    final suffix = highOnDay >= 3 ? ' 当天已有 $highOnDay 件高优先级' : '';
    AppToast.show(
      context,
      message: '已改到 ${day.month} 月 ${day.day} 日$suffix',
      actionLabel: '撤销',
      onAction: () => workspaceUi(context, change.undo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final monthHasTodos = widget.todos.any(
      (t) =>
          t.dueAt != null &&
          t.dueAt!.year == _displayedMonth.year &&
          t.dueAt!.month == _displayedMonth.month,
    );

    return VizCard(
      title: '${_displayedMonth.year} 年 ${_displayedMonth.month} 月',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppPressable(
            onTap: () => _pageController.previousPage(
              duration: AppMotion.tabSwitch,
              curve: Curves.easeOut,
            ),

            behavior: HitTestBehavior.translucent,
            semanticLabel: '上一月',
            child: Icon(
              LucideIcons.chevronLeft,
              size: 20,
              color: c.labelSecondary,
            ),
          ),
          AppPressable(
            onTap:
                _today.year == _displayedMonth.year &&
                    _today.month == _displayedMonth.month
                ? null
                : _goToday,

            behavior: HitTestBehavior.translucent,
            semanticLabel: '回到今天',
            child: Text(
              '今天',
              style: AppTextStyles.footnote.copyWith(color: c.brand),
            ),
          ),
          AppPressable(
            onTap: () => _pageController.nextPage(
              duration: AppMotion.tabSwitch,
              curve: Curves.easeOut,
            ),

            behavior: HitTestBehavior.translucent,
            semanticLabel: '下一月',
            child: Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: c.labelSecondary,
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          // 星期头
          Row(
            children: [
              for (final label in weekdayLabels)
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: AppTextStyles.caption.copyWith(
                        color: c.labelTertiary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: _gridHeight(context),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) =>
                  setState(() => _displayedMonth = _monthOf(page)),
              itemBuilder: (context, page) => _MonthGrid(
                month: _monthOf(page),
                today: _today,
                todosOn: _todosOn,
                colorOf: _colorOf,
                onTapDay: _openDay,
                onAccept: _reschedule,
              ),
            ),
          ),
          if (!monthHasTodos) ...[
            const SizedBox(height: 8),
            Text(
              '本月暂无待办',
              style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
            ),
          ],
        ],
      ),
    );
  }

  double _gridHeight(BuildContext context) {
    // 卡片内宽 = 屏宽 - 页面边距 16×2 - 卡片内边距 16×2
    final cellW = (MediaQuery.of(context).size.width - 64) / 7;
    return cellW * 1.26 * 6;
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.today,
    required this.todosOn,
    required this.colorOf,
    required this.onTapDay,
    required this.onAccept,
  });

  final DateTime month;
  final DateTime today;
  final List<Todo> Function(DateTime day) todosOn;
  final Color Function(String? categoryId) colorOf;
  final ValueChanged<DateTime> onTapDay;
  final void Function(Todo todo, DateTime day) onAccept;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final first = DateTime(month.year, month.month, 1);
    final start = mondayOf(first);
    final cellW = (MediaQuery.of(context).size.width - 64) / 7;
    final cellH = cellW * 1.26;
    final now = DateTime.now();

    return Column(
      children: [
        for (var row = 0; row < 6; row++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: _DayCell(
                    date: start.add(Duration(days: row * 7 + col)),
                    month: month,
                    today: today,
                    now: now,
                    height: cellH,
                    todos: todosOn(start.add(Duration(days: row * 7 + col))),
                    colors: c,
                    colorOf: colorOf,
                    onTap: onTapDay,
                    onAccept: onAccept,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.month,
    required this.today,
    required this.now,
    required this.height,
    required this.todos,
    required this.colors,
    required this.colorOf,
    required this.onTap,
    required this.onAccept,
  });

  final DateTime date;
  final DateTime month;
  final DateTime today;
  final DateTime now;
  final double height;
  final List<Todo> todos;
  final AppColors colors;
  final Color Function(String? categoryId) colorOf;
  final ValueChanged<DateTime> onTap;
  final void Function(Todo todo, DateTime day) onAccept;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final inMonth = date.month == month.month;
    final isToday = sameDay(date, today);
    final hasOverdue = todos.any(
      (t) => t.isOverdue(now) && !sameDay(date, today),
    );
    final visible = todos.take(2).toList();
    final overflow = todos.length - visible.length;

    final dateColor = isToday
        ? c.onBrand
        : hasOverdue
        ? c.overdueForeground
        : inMonth
        ? c.labelPrimary
        : c.labelQuaternary;

    return DragTarget<Todo>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => onAccept(details.data, date),
      builder: (context, candidates, _) {
        final highlight = candidates.isNotEmpty;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(date),
          child: Semantics(
            label:
                '${date.month} 月 ${date.day} 日，${isToday ? '今天，' : ''}${todos.length} 件待办${hasOverdue ? '，有逾期' : ''}',
            button: true,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: height,
              decoration: BoxDecoration(
                color: highlight ? c.brand25 : null,
                border: Border(
                  top: BorderSide(color: c.separator, width: 0.5),
                  left: BorderSide(
                    color: highlight ? c.brand : Colors.transparent,
                  ),
                  right: BorderSide(
                    color: highlight ? c.brand : Colors.transparent,
                  ),
                  bottom: BorderSide(
                    color: highlight ? c.brand : Colors.transparent,
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(3, 4, 3, 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: isToday
                        ? Container(
                            decoration: BoxDecoration(
                              color: c.brand,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${date.day}',
                              style: AppTextStyles.footnote.copyWith(
                                color: dateColor,
                                height: 1,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              '${date.day}',
                              style: AppTextStyles.footnote.copyWith(
                                color: dateColor,
                                height: 1,
                                fontWeight: inMonth
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 2),
                  for (final todo in visible)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: _TodoChip(
                        todo: todo,
                        color: colorOf(todo.categoryId),
                        colors: c,
                        width: double.infinity,
                      ),
                    ),
                  if (overflow > 0)
                    Text(
                      '+$overflow',
                      style: AppTextStyles.caption.copyWith(
                        color: c.labelTertiary,
                        height: 1,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 日历 Todo 条：小面积雾彩分类底 + 中性文字；
/// 长按 300ms 进入拖拽（浮起 1.05 倍 + 阴影），原位置留 40% 残影。
class _TodoChip extends StatelessWidget {
  const _TodoChip({
    required this.todo,
    required this.color,
    required this.colors,
    required this.width,
  });

  final Todo todo;
  final Color color;
  final AppColors colors;
  final double width;

  @override
  Widget build(BuildContext context) {
    final chip = _buildChip(colors);
    return LongPressDraggable<Todo>(
      data: todo,
      delay: const Duration(milliseconds: 300),
      onDragStarted: () => HapticFeedback.mediumImpact(),
      feedback: Transform.scale(
        scale: 1.05,
        child: Container(
          width: 120,
          decoration: BoxDecoration(
            borderRadius: AppRadii.brXs,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _buildChip(colors),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: chip),
      child: chip,
    );
  }

  Widget _buildChip(AppColors c) {
    final done = todo.status == TodoStatus.done;
    return Container(
      height: 14,
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: c.categorySurface(color),
        borderRadius: AppRadii.brXs,
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        todo.title,
        style: AppTextStyles.caption.copyWith(
          color: c.categoryForeground,
          height: 1,
          decoration: done ? TextDecoration.lineThrough : null,
          decorationColor: c.categoryForeground,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
