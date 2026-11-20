import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../notifications/notification_diagnostics_sheet.dart';
import '../widgets/app_button.dart';
import '../widgets/app_chip.dart';
import '../widgets/app_day_calendar.dart';
import '../widgets/app_pressable.dart';
import '../widgets/app_sheet.dart';
import 'todo_editor_controls.dart';
import 'todo_utils.dart';

class TodoReminderEditor extends StatelessWidget {
  const TodoReminderEditor({
    super.key,
    required this.todo,
    required this.onChanged,
  });

  final Todo todo;
  final ValueChanged<List<RemindRule>> onChanged;

  void _addRule(BuildContext context) {
    AppSheet.show<void>(
      context,
      title: context.strings.addReminder,
      child: _AddReminderSheet(
        hasDue: todo.dueAt != null,
        onAdd: (rule) => onChanged([...todo.remindRules, rule]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final rules = todo.remindRules;
    final full = rules.length >= 5;
    return TodoEditorBox(
      children: [
        const NotificationPermissionHint(),
        for (final rule in rules)
          Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: c.brand,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    remindRuleLabel(rule),
                    style: AppTextStyles.body.copyWith(color: c.labelPrimary),
                  ),
                ),
                AppPressable(
                  onTap: () =>
                      onChanged(rules.where((e) => e.id != rule.id).toList()),
                  behavior: HitTestBehavior.translucent,
                  semanticLabel: context.strings.deleteReminder(
                    remindRuleLabel(rule),
                  ),
                  child: Icon(LucideIcons.x, size: 16, color: c.labelTertiary),
                ),
              ],
            ),
          ),
        if (rules.isNotEmpty) ...[Divider(height: 16, color: c.separator)],
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppButton(
              label: context.strings.addReminder,
              type: AppButtonType.ghost,
              icon: LucideIcons.plus,
              onPressed: full ? null : () => _addRule(context),
            ),
            if (full)
              Text(
                context.strings.upToReminders,
                style: AppTextStyles.caption.copyWith(color: c.labelQuaternary),
              ),
          ],
        ),
        if (todo.repeatRule != null) ...[
          const SizedBox(height: 4),
          Text(
            context.strings.recurringTasksSendRemindersBeforeEachDue,
            style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
          ),
        ],
      ],
    );
  }
}

class _AddReminderSheet extends StatefulWidget {
  const _AddReminderSheet({required this.hasDue, required this.onAdd});

  final bool hasDue;
  final ValueChanged<RemindRule> onAdd;

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  int _offset = 30;
  int _unit = 1;
  DateTime? _absDate;
  TimeOfDay? _absTime;

  int get _seq => DateTime.now().millisecondsSinceEpoch % 100000;

  void _addRelative(int minutes) {
    widget.onAdd(RemindRule(id: 'rr_$_seq', offsetMinutes: minutes));
    Navigator.of(context).pop();
  }

  void _addCustom() {
    _addRelative(_offset * _unit);
  }

  void _addAbsolute() {
    final d = _absDate;
    final t = _absTime;
    if (d == null || t == null) return;
    widget.onAdd(
      RemindRule(
        id: 'rr_$_seq',
        absoluteAt: DateTime(d.year, d.month, d.day, t.hour, t.minute),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final presets = [
      (context.strings.whenDue, 0),
      (context.strings.minutesBeforeBuild2, 5),
      (context.strings.minutesBeforeBuild3, 15),
      (context.strings.minutesBeforeBuild4, 30),
      (context.strings.hourBeforeBuild, 60),
      (context.strings.dayBeforeBuild, 60 * 24),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              context.strings.relativeToDueTime,
              style: AppTextStyles.footnote.copyWith(
                color: widget.hasDue ? c.labelSecondary : c.labelQuaternary,
              ),
            ),
          ),
          if (!widget.hasDue)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                context.strings.setADueTimeFirst,
                style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
              ),
            ),
          for (final (label, minutes) in presets)
            TodoOptionRow(
              label: label,
              enabled: widget.hasDue,
              onTap: () => _addRelative(minutes),
            ),
          if (widget.hasDue)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    context.strings.custom,
                    style: AppTextStyles.body.copyWith(color: c.labelSecondary),
                  ),
                  TodoEditorStepper(
                    label: context.strings.reminderLeadTime,
                    value: _offset,
                    min: 1,
                    max: 99,
                    onChanged: (v) => setState(() => _offset = v),
                  ),
                  for (final (u, label) in [
                    (1, context.strings.minutes),
                    (60, context.strings.hours),
                    (1440, context.strings.days),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: AppChip(
                        label: label,
                        selected: _unit == u,
                        onTap: () => setState(() => _unit = u),
                      ),
                    ),
                  AppButton(
                    label: context.strings.addBuild,
                    type: AppButtonType.ghost,
                    onPressed: _addCustom,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Divider(height: 0.5, color: c.separator),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              context.strings.specificTime,
              style: AppTextStyles.footnote.copyWith(color: c.labelSecondary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppDayCalendar(
              selected: _absDate,
              onSelected: (d) => setState(() => _absDate = d),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (label, tod) in [
                  (context.strings.am, const TimeOfDay(hour: 9, minute: 0)),
                  (context.strings.pm, const TimeOfDay(hour: 12, minute: 0)),
                  (
                    context.strings.pmBuild,
                    const TimeOfDay(hour: 18, minute: 0),
                  ),
                  (
                    context.strings.pmBuild2,
                    const TimeOfDay(hour: 20, minute: 0),
                  ),
                ])
                  AppChip(
                    label: label,
                    selected: _absTime == tod,
                    onTap: () => setState(() => _absTime = tod),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppButton(
              label: context.strings.addReminder,
              type: AppButtonType.primary,
              expand: true,
              enabled: _absDate != null && _absTime != null,
              onPressed: _addAbsolute,
            ),
          ),
        ],
      ),
    );
  }
}
