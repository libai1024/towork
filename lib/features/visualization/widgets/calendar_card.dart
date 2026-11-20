import 'package:towork/l10n/strings.dart';
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

part 'calendar_grid.dart';

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
        title: context.strings.formattedValueOpenday(
          day.month,
          day.day,
          weekdayLabel(day),
        ),
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
      () => ref.read(workspaceUiCommandsProvider).editTodoFields([
        current.id,
      ], TodoFieldEdit.reschedule(newDue)),
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
    final suffix = highOnDay >= 3
        ? context.strings.alreadyHighPriorityItemsThatDay(highOnDay)
        : '';
    AppToast.show(
      context,
      message: context.strings.movedToReschedule(day.month, day.day, suffix),
      actionLabel: context.strings.undo,
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
      title: context.strings.formattedValueBuild2(
        _displayedMonth.year,
        _displayedMonth.month,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppPressable(
            onTap: () => _pageController.previousPage(
              duration: AppMotion.tabSwitch,
              curve: Curves.easeOut,
            ),

            behavior: HitTestBehavior.translucent,
            semanticLabel: context.strings.previousMonthBuild,
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
            semanticLabel: context.strings.backToToday,
            child: Text(
              context.strings.today,
              style: AppTextStyles.footnote.copyWith(color: c.brand),
            ),
          ),
          AppPressable(
            onTap: () => _pageController.nextPage(
              duration: AppMotion.tabSwitch,
              curve: Curves.easeOut,
            ),

            behavior: HitTestBehavior.translucent,
            semanticLabel: context.strings.nextMonthBuild,
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
              context.strings.noTasksThisMonth,
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
