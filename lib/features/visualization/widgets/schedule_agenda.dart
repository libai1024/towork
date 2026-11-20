import 'package:towork/l10n/repository_messages.dart';
import 'package:towork/l10n/strings.dart';

import '../../../core/todo/todo_step_actions.dart';

import 'package:flutter/material.dart';

import '../../../core/workspace_actions.dart';
import '../../../app/todo/async_todo_commands.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/widgets/app_day_calendar.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/workspace_nav_bar.dart';
import '../../../domain/models/models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../app/todo/todo_view_model.dart';
import '../../../core/todo/todo_detail_sheet.dart';
import '../../../core/todo/todo_item.dart';
import '../view_models/schedule_overview.dart';

/// The same calendar and agenda stack on phones and sit side by side when their
/// actual parent offers enough width. Both layouts share task mutation paths.
class ScheduleAgenda extends ConsumerWidget {
  const ScheduleAgenda({
    super.key,
    required this.data,
    required this.weekOnly,
    required this.onWeekModeChanged,
    required this.onSelected,
    this.searching = false,
  });

  final ScheduleOverview data;
  final bool weekOnly;
  final ValueChanged<bool> onWeekModeChanged;
  final ValueChanged<DateTime> onSelected;
  final bool searching;

  Future<void> _mutate(
    BuildContext context,
    Future<TodoMutation> Function() action,
    String label,
  ) async {
    try {
      final receipt = await workspaceUi(context, action);
      if (!context.mounted || receipt == null) return;
      if (receipt.count == 0) return;
      AppToast.show(
        context,
        message: label,
        actionLabel: context.strings.undo,
        onAction: () => workspaceUi(context, () async {
          await receipt.undo();
          return true;
        }),
      );
    } on RepositoryException catch (error) {
      AppToast.show(context, message: repositoryErrorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    ref.watch(categoryListProvider);
    final categories = ref.read(categoryListProvider.notifier);
    final model = ref.watch(asyncTodoCommandsProvider);
    final entries = <Object>[
      if (data.pending.isNotEmpty) ...[context.strings.task, ...data.pending],
      if (data.completed.isNotEmpty) ...[
        context.strings.completed,
        ...data.completed,
      ],
    ];

    Widget task(Todo todo) => TodoListItem(
      key: ValueKey('schedule-task-${todo.id}'),
      todo: todo,
      now: data.now,
      plainCategory: true,
      categoryLabel: categories.byId(todo.categoryId)?.name,
      onToggleDone: () async {
        if (!await confirmRemainingSteps(context, [todo]) || !context.mounted) {
          return;
        }
        await _mutate(
          context,
          () => model.toggleDone(todo.id),
          todo.isActive ? context.strings.completed : context.strings.restored,
        );
      },
      onTap: () => showTodoDetailSheet(
        context,
        todo.id,
        onDeleted: (deleted) => _mutate(
          context,
          () => model.delete([deleted.id]),
          context.strings.deleted,
        ),
      ),
    );

    Widget entry(int index) {
      final value = entries[index];
      if (value is Todo) return task(value);
      final count = value == context.strings.task
          ? data.pending.length
          : data.completed.length;
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 3),
        child: Text(
          '$value $count',
          style: AppTextStyles.caption.copyWith(color: c.labelSecondary),
        ),
      );
    }

    final calendar = Padding(
      key: const ValueKey('schedule-calendar-pane'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: AppDayCalendar(
        selected: data.day,
        now: data.now,
        weekOnly: weekOnly,
        dayCounts: data.dayCounts,
        onSelected: onSelected,
        onPageChanged: onSelected,
        headerTrailing: SizedBox(
          width: 94,
          child: WorkspaceSegmentedControl(
            labels: [context.strings.month, context.strings.week],
            selectedIndex: weekOnly ? 1 : 0,
            onChanged: (value) => onWeekModeChanged(value == 1),
          ),
        ),
      ),
    );
    final heading = Padding(
      key: const ValueKey('schedule-agenda-heading'),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.strings.formattedValueBuild5(
                data.day.month,
                data.day.day,
                context.strings.mtwtfss[data.day.weekday - 1],
              ),
              style: AppTextStyles.subhead.copyWith(color: c.labelPrimary),
            ),
          ),
          Text(
            context.strings.itemsBuild(data.total),
            key: const ValueKey('schedule-count'),
            style: AppTextStyles.caption.copyWith(color: c.labelSecondary),
          ),
        ],
      ),
    );
    final empty = Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      child: Text(
        searching
            ? context.strings.noMatchingTasksBuild
            : context.strings.noTasksOnThisDay,
        style: AppTextStyles.body.copyWith(color: c.labelSecondary),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return Row(
            key: const ValueKey('schedule-split-layout'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: (constraints.maxWidth * .43).clamp(350.0, 440.0),
                child: SingleChildScrollView(child: calendar),
              ),
              VerticalDivider(width: 1, thickness: .5, color: c.separator),
              Expanded(
                child: CustomScrollView(
                  key: const ValueKey('schedule-agenda-list'),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
                      sliver: SliverToBoxAdapter(child: heading),
                    ),
                    if (entries.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: empty,
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 16, 24),
                      sliver: SliverList.builder(
                        itemCount: entries.length,
                        itemBuilder: (context, index) => entry(index),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        return CustomScrollView(
          key: const ValueKey('schedule-stacked-layout'),
          slivers: [
            SliverToBoxAdapter(child: calendar),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverToBoxAdapter(child: heading),
            ),
            if (entries.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: empty,
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              sliver: SliverList.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) => entry(index),
              ),
            ),
          ],
        );
      },
    );
  }
}
