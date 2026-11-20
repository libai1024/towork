import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../widgets/app_button.dart';
import '../widgets/app_chip.dart';
import '../widgets/app_day_calendar.dart';
import 'todo_editor_controls.dart';
import 'todo_utils.dart';

class TodoDueEditor extends StatefulWidget {
  const TodoDueEditor({super.key, required this.todo, required this.onChanged});

  final Todo todo;
  final ValueChanged<DateTime?> onChanged;

  @override
  State<TodoDueEditor> createState() => _DueEditorState();
}

class _DueEditorState extends State<TodoDueEditor> {
  bool _showCalendar = false;

  DateTime _withCurrentTime(DateTime day) {
    final due = widget.todo.dueAt;
    if (due != null && (due.hour != 0 || due.minute != 0)) {
      return DateTime(day.year, day.month, day.day, due.hour, due.minute);
    }
    return DateTime(day.year, day.month, day.day, 18);
  }

  Future<void> _pickTime() async {
    final due = widget.todo.dueAt ?? DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: due.hour, minute: due.minute),
    );
    if (picked == null) return;
    final day = dayOnly(widget.todo.dueAt ?? DateTime.now());
    widget.onChanged(
      DateTime(day.year, day.month, day.day, picked.hour, picked.minute),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final now = DateTime.now();
    final today = dayOnly(now);
    final due = widget.todo.dueAt;
    final hasTime = due != null && (due.hour != 0 || due.minute != 0);

    final quick = <(String, DateTime)>[
      (context.strings.today, _withCurrentTime(today)),
      (
        context.strings.tomorrow,
        _withCurrentTime(today.add(const Duration(days: 1))),
      ),
      (
        context.strings.nextMonday,
        _withCurrentTime(today.add(Duration(days: 8 - today.weekday))),
      ),
    ];

    return TodoEditorBox(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, target) in quick)
              AppChip(
                label: label,
                selected: due != null && isSameDay(due, target),
                onTap: () => widget.onChanged(target),
              ),
            AppChip(
              label: context.strings.chooseDateBuild2,
              icon: LucideIcons.calendar,
              selected: _showCalendar,
              onTap: () => setState(() => _showCalendar = !_showCalendar),
            ),
          ],
        ),
        if (_showCalendar) ...[
          const SizedBox(height: 12),
          AppDayCalendar(
            selected: due,
            onSelected: (day) => widget.onChanged(_withCurrentTime(day)),
          ),
        ],
        const SizedBox(height: 12),
        Divider(height: 0.5, color: c.separator),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              context.strings.time,
              style: AppTextStyles.body.copyWith(color: c.labelSecondary),
            ),
            if (hasTime)
              Text(
                timeLabel(due),
                style: AppTextStyles.body.copyWith(color: c.labelPrimary),
              )
            else
              Text(
                context.strings.allDay,
                style: AppTextStyles.body.copyWith(color: c.labelTertiary),
              ),
            if (hasTime)
              AppButton(
                label: context.strings.clearTime,
                type: AppButtonType.ghost,
                onPressed: () => widget.onChanged(dayOnly(due)),
              )
            else
              AppButton(
                label: context.strings.addTime,
                type: AppButtonType.ghost,
                onPressed: _pickTime,
              ),
          ],
        ),
        if (due != null) ...[
          const SizedBox(height: 8),
          Divider(height: 0.5, color: c.separator),
          const SizedBox(height: 4),
          Center(
            child: AppButton(
              label: context.strings.clearDueDate,
              type: AppButtonType.ghost,
              onPressed: () => widget.onChanged(null),
            ),
          ),
          Center(
            child: Text(
              context.strings.removesTheTaskFromTodayThisWeek,
              style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
            ),
          ),
        ],
      ],
    );
  }
}
