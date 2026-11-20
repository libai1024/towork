part of 'calendar_card.dart';

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
            label: context.strings.tasksBuild2(
              date.month,
              date.day,
              isToday ? context.strings.todayBuild : '',
              todos.length,
              hasOverdue ? context.strings.overdueItems : '',
            ),
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
