import 'todo_step_actions.dart';

import 'package:flutter/material.dart';

import '../workspace_actions.dart';
import '../../app/todo/async_todo_commands.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../app/routes.dart';
import '../widgets/app_day_calendar.dart';
import '../widgets/app_button.dart';
import '../widgets/app_pressable.dart';
import '../widgets/app_sheet.dart';
import '../widgets/app_toast.dart';
import '../widgets/glass_surface.dart';
import '../widgets/workspace_bottom_bar.dart';
import '../../domain/models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../categories/category_catalog.dart';
import 'create_todo_sheet.dart';
import '../../app/todo/daily_overview.dart';
import '../../app/todo/todo_view_model.dart';
import 'todo_detail_sheet.dart';
import 'todo_item.dart';

/// Scheme A: compact day sections with a persistent category rail.
/// Local state holds only the selected scope, date and disclosure state.
class DailyOverviewPanel extends ConsumerStatefulWidget {
  const DailyOverviewPanel({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  ConsumerState<DailyOverviewPanel> createState() => _DailyOverviewPanelState();
}

class _DailyOverviewPanelState extends ConsumerState<DailyOverviewPanel> {
  DateTime? _day;
  String? _category;
  bool _completedOpen = false;

  Future<void> _pickDay(DailyOverview data) async {
    final selected = await AppSheet.show<DateTime>(
      context,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppDayCalendar(
              selected: data.day,
              now: data.now,
              onSelected: (day) => Navigator.of(context).pop(day),
            ),
            AppPressable(
              semanticLabel: '回到今天',
              onTap: () =>
                  Navigator.of(context).pop(DateUtils.dateOnly(data.now)),
              child: const Text('回到今天'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _day = DateUtils.isSameDay(selected, data.now) ? null : selected;
      _completedOpen = false;
    });
  }

  Future<void> _mutate(
    Future<TodoMutation> Function() action,
    String message,
  ) async {
    try {
      final receipt = await workspaceUi(context, action);
      if (!mounted || receipt == null) return;
      if (receipt.count == 0) return;
      AppToast.show(
        context,
        message: message,
        actionLabel: '撤销',
        onAction: () => workspaceUi(context, () async {
          await receipt.undo();
          return true;
        }),
      );
    } on RepositoryException catch (error) {
      if (mounted) AppToast.show(context, message: error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    ref.watch(categoryListProvider);
    final categories = ref.read(categoryListProvider.notifier);
    final current = categories.byId(_category);
    final categoryId = current == null || current.archived
        ? null
        : current.parentId ?? current.id;
    final data = ref.watch(
      dailyOverviewProvider((day: _day, categoryId: categoryId)),
    );
    final model = ref.watch(asyncTodoCommandsProvider);
    final dayLabel = data.isToday ? '今天' : '${data.day.month}月${data.day.day}日';

    Widget task(Todo todo) {
      final category = categories.byId(todo.categoryId);
      return TodoListItem(
        key: ValueKey('overview-task-${todo.id}'),
        todo: todo,
        now: data.now,
        categoryLabel: category?.id == categoryId ? null : category?.name,
        categoryColor: category?.color,
        onToggleDone: () async {
          if (!await confirmRemainingSteps(context, [todo]) ||
              !context.mounted) {
            return;
          }
          await _mutate(
            () => model.toggleDone(todo.id),
            todo.isActive ? '已完成' : '已恢复',
          );
        },
        onTap: () => showTodoDetailSheet(
          context,
          todo.id,
          onDeleted: (deleted) =>
              _mutate(() => model.delete([deleted.id]), '已删除'),
        ),
      );
    }

    Widget section(String title, int count, {bool overdue = false}) => Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.caption.copyWith(
                color: overdue ? c.overdueForeground : c.labelSecondary,
              ),
            ),
          ),
          Text(
            '$count',
            style: AppTextStyles.caption.copyWith(color: c.labelSecondary),
          ),
        ],
      ),
    );

    Widget filter(String label, String? id, {Category? category}) {
      final selected = categoryId == id;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Semantics(
          selected: selected,
          child: AppPressable(
            key: ValueKey('overview-category-${id ?? 'all'}'),
            semanticLabel: '筛选分类：$label',
            onTap: () => setState(() => _category = id),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? c.bgPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...[
                    Icon(
                      category == null
                          ? LucideIcons.listFilter
                          : categoryIconFor(category.iconKey),
                      size: 17,
                      color: c.labelSecondary,
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? c.labelPrimary : c.labelSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      key: const ValueKey('daily-overview-panel'),
      color: c.bgSecondary,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AppPressable(
                            key: const ValueKey('overview-date'),
                            semanticLabel: '$dayLabel，选择日期',
                            onTap: () => _pickDay(data),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    dayLabel,
                                    style: AppTextStyles.title1.copyWith(
                                      color: c.labelPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  LucideIcons.chevronDown,
                                  size: 17,
                                  color: c.labelSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      GlassIconButton(
                        icon: LucideIcons.chevronRight,
                        label: '收起今日总览',
                        onTap: widget.onClose,
                      ),
                    ],
                  ),
                  Text(
                    '${data.day.year}年${data.day.month}月${data.day.day}日 周${'一二三四五六日'[data.day.weekday - 1]}',
                    style: AppTextStyles.caption.copyWith(
                      color: c.labelSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          // 与列表区头一致（今天/当天）：逾期只出现在今天视图，
                          // 计数口径分别标注，避免"0 项待完成却有逾期"的矛盾。
                          '${data.isToday ? '今天' : '当天'}待完成 ${data.pending.length} 项'
                          '${data.overdue.isEmpty ? '' : ' 逾期 ${data.overdue.length} 项'}',
                          style: AppTextStyles.caption.copyWith(
                            color: c.labelSecondary,
                          ),
                        ),
                      ),
                      Text(
                        '${data.completed.length} / ${data.total}',
                        key: const ValueKey('overview-progress-count'),
                        style: AppTextStyles.caption.copyWith(
                          color: c.labelSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  LinearProgressIndicator(
                    value: data.progress,
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(4),
                    backgroundColor: c.fill2,
                    color: c.labelPrimary,
                    semanticsLabel: '$dayLabel完成进度',
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 60,
                    child: ListView(
                      key: const ValueKey('overview-category-rail'),
                      children: [
                        filter('全部', null),
                        for (final root in categories.roots)
                          filter(root.name, root.id, category: root),
                      ],
                    ),
                  ),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.bgGround,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                        ),
                      ),
                      child: ListView(
                        key: ValueKey('overview-list-${data.day}-$categoryId'),
                        padding: const EdgeInsets.only(top: 3, bottom: 14),
                        children: [
                          if (data.overdue.isNotEmpty) ...[
                            section('逾期', data.overdue.length, overdue: true),
                            ...data.overdue.map(task),
                          ],
                          section(
                            data.isToday ? '今天' : '当天',
                            data.pending.length,
                          ),
                          if (data.pending.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Text(
                                '暂无待办',
                                style: AppTextStyles.body.copyWith(
                                  color: c.labelSecondary,
                                ),
                              ),
                            ),
                          ...data.pending.map(task),
                          AppPressable(
                            semanticLabel: '已完成 ${data.completed.length} 项',
                            onTap: () => setState(
                              () => _completedOpen = !_completedOpen,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _completedOpen
                                        ? LucideIcons.chevronDown
                                        : LucideIcons.chevronRight,
                                    size: 15,
                                    color: c.labelSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '已完成',
                                      style: AppTextStyles.caption.copyWith(
                                        color: c.labelSecondary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${data.completed.length}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: c.labelSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_completedOpen) ...data.completed.map(task),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 12, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: AppButton(
                      label: '全部待办',
                      type: AppButtonType.ghost,
                      icon: LucideIcons.listTodo,
                      onPressed: () {
                        widget.onClose();
                        context.push(
                          categoryId == null
                              ? AppRoutes.todos
                              : AppRoutes.todosForCategory(categoryId),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  WorkspaceAddButton(
                    label: '新建待办',
                    onTap: () => AppSheet.show<void>(
                      context,
                      child: CreateTodoSheet(
                        categoryId: categoryId,
                        dueAt: DateTime(
                          data.day.year,
                          data.day.month,
                          data.day.day,
                          18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
