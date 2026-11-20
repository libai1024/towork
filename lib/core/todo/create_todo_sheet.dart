import 'package:towork/l10n/strings.dart';
import 'package:flutter/cupertino.dart'
    show CupertinoDatePicker, CupertinoDatePickerMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../app/todo/async_todo_commands.dart';
import '../../app/workspace_clock.dart';
import '../workspace_actions.dart';
import '../../domain/models/todo.dart';
import '../../domain/workspace/workspace_commands.dart';
import '../widgets/app_day_calendar.dart';
import '../widgets/app_sheet.dart';
import '../widgets/app_button.dart';
import '../widgets/app_toast.dart';
import '../widgets/sheet_composer.dart';
import '../widgets/app_inline_input.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'todo_field_row.dart';
import 'todo_steps_editor.dart';
import 'todo_utils.dart';
import '../widgets/workspace_action_menu.dart';

enum _Due { none, today, tomorrow, nextWeek, calendar, time }

class CreateTodoSheet extends ConsumerStatefulWidget {
  const CreateTodoSheet({
    super.key,
    this.categoryId,
    this.dueAt,
    this.status = TodoStatus.pending,
  });

  final String? categoryId;
  final DateTime? dueAt;
  final TodoStatus status;

  @override
  ConsumerState<CreateTodoSheet> createState() => _CreateTodoSheetState();
}

class _CreateTodoSheetState extends ConsumerState<CreateTodoSheet> {
  final _text = TextEditingController();
  final _note = TextEditingController();
  final _stepsKey = GlobalKey<TodoStepsEditorState>();
  List<TodoStep> _steps = [];
  final _noteFocus = FocusNode();
  final _reminderId = newWorkspaceId('reminder');
  TodoPriority _priority = TodoPriority.none;
  late TodoStatus _status = widget.status;
  int? _remindMinutes;
  final _operationId = newWorkspaceId('create');
  bool _saving = false;
  late String? _category = widget.categoryId;
  late DateTime? _dueAt = widget.dueAt;

  @override
  void dispose() {
    _noteFocus.dispose();
    _note.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _text.text.trim();
    if (_saving || title.isEmpty) return;
    setState(() => _saving = true);
    if (!await (_stepsKey.currentState?.flush() ?? Future.value(true)) ||
        !mounted) {
      if (mounted) setState(() => _saving = false);
      return;
    }
    final result = await workspaceUi(
      context,
      () => ref
          .read(asyncTodoCommandsProvider)
          .create(
            title: title,
            categoryId: _category,
            dueAt: _dueAt,
            status: _status,
            priority: _priority,
            steps: _steps,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            remindRules: [
              if (_dueAt != null && _remindMinutes != null)
                RemindRule(id: _reminderId, offsetMinutes: _remindMinutes),
            ],
            operationId: _operationId,
          ),
    );
    if (!mounted) return;
    if (result == null) {
      setState(() => _saving = false);
    } else {
      AppToast.show(context, message: context.strings.created);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(workspaceClockProvider).now;
    ref.watch(categoryListProvider);
    final categories = ref.read(categoryListProvider.notifier);
    final category = categories.byId(_category);
    final c = AppColors.of(context);
    DateTime due(int days, int hour) =>
        DateTime(now.year, now.month, now.day + days, hour);
    final presets = {
      _Due.today: (label: context.strings.today, date: due(0, 18)),
      _Due.tomorrow: (label: context.strings.tomorrow, date: due(1, 9)),
      _Due.nextWeek: (
        label: context.strings.nextMonday,
        date: due(8 - now.weekday, 9),
      ),
    };
    final current = _dueAt;
    final matching = presets.entries
        .where((e) => e.value.date == current)
        .firstOrNull;
    final dayLabel = current == null
        ? ''
        : matching?.value.label ??
              (current.year == now.year
                  ? context.strings.formattedValue(current.month, current.day)
                  : '${current.year}/${current.month}/${current.day}');
    final dateLabel = current == null
        ? context.strings.noDueDate
        : '$dayLabel ${current.hour.toString().padLeft(2, '0')}:${current.minute.toString().padLeft(2, '0')}';

    final reminders = {
      -1: context.strings.noneLabel,
      0: context.strings.whenDue,
      15: context.strings.minutesBeforeBuild,
      60: context.strings.hourBefore,
      1440: context.strings.dayBefore,
    };
    Widget property({
      required IconData icon,
      required String label,
      required String value,
      required ValueChanged<BuildContext> onOpen,
    }) => Builder(
      builder: (anchor) => Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: TodoFieldRow(
          icon: icon,
          label: label,
          value: value,
          inset: 0,
          onTap: () => onOpen(anchor),
        ),
      ),
    );
    return SheetComposer(
      title: context.strings.newTask,
      hint: context.strings.taskTitle,
      controller: _text,
      fieldKey: const ValueKey('todo-create-title'),
      action: context.strings.create,
      saving: _saving,
      onChanged: (_) => setState(() {}),
      onCommit: _save,
      onNext: _noteFocus.requestFocus,
      fields: Column(
        children: [
          TextField(
            key: const ValueKey('todo-create-note'),
            controller: _note,
            focusNode: _noteFocus,
            enabled: !_saving,
            minLines: 1,
            maxLines: 4,
            keyboardType: TextInputType.multiline,
            style: AppTextStyles.body.copyWith(color: c.labelPrimary),
            decoration: appInlineInput(
              hintText: context.strings.addANote,
              hintStyle: AppTextStyles.body.copyWith(color: c.labelSecondary),
              padding: const EdgeInsets.symmetric(vertical: 8),
              constraints: const BoxConstraints(minHeight: 44),
            ),
          ),
          AbsorbPointer(
            absorbing: _saving,
            child: TodoStepsEditor(
              key: _stepsKey,
              steps: _steps,
              onEdit: (edit) async {
                return await workspaceUi(context, () async {
                      setState(() => _steps = edit.apply(_steps));
                      return true;
                    }) ??
                    false;
              },
            ),
          ),
          Divider(height: 1, thickness: .6, color: c.separator),
          property(
            icon: LucideIcons.calendar,
            label: context.strings.dueDate,
            value: dateLabel,
            onOpen: (anchor) async {
              final choice = await showWorkspaceActionMenu<_Due>(
                anchor,
                selected: current == null
                    ? _Due.none
                    : matching?.key ?? _Due.calendar,
                items: [
                  (
                    value: _Due.none,
                    label: context.strings.noDueDate,
                    icon: LucideIcons.minus,
                  ),
                  for (final entry in presets.entries)
                    (
                      value: entry.key,
                      label: entry.value.label,
                      icon: LucideIcons.calendarDays,
                    ),
                  (
                    value: _Due.time,
                    label: context.strings.setTime,
                    icon: LucideIcons.clock,
                  ),
                  (
                    value: _Due.calendar,
                    label: context.strings.chooseDate,
                    icon: LucideIcons.calendar,
                  ),
                ],
              );
              if (choice == null || !context.mounted) return;
              if (choice == _Due.time) {
                final date = current ?? due(0, 18);
                var selection = date;
                final picked = await AppSheet.show<DateTime>(
                  context,
                  title: context.strings.due,
                  child: Builder(
                    builder: (sheet) => SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 148,
                            child: CupertinoDatePicker(
                              mode: CupertinoDatePickerMode.time,
                              use24hFormat: true,
                              initialDateTime: date,
                              onDateTimeChanged: (value) => selection = value,
                            ),
                          ),
                          AppButton(
                            label: context.strings.ok,
                            onPressed: () => Navigator.pop(sheet, selection),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                if (mounted && picked != null) {
                  setState(
                    () => _dueAt = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      picked.hour,
                      picked.minute,
                    ),
                  );
                }
              } else if (choice == _Due.calendar) {
                final day = await AppSheet.show<DateTime>(
                  context,
                  title: context.strings.dueDate,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: AppDayCalendar(
                      selected: current,
                      now: now,
                      onSelected: (day) => Navigator.pop(context, day),
                    ),
                  ),
                );
                if (mounted && day != null) {
                  setState(
                    () => _dueAt = DateTime(
                      day.year,
                      day.month,
                      day.day,
                      current?.hour ?? 18,
                      current?.minute ?? 0,
                    ),
                  );
                }
              } else {
                setState(() {
                  _dueAt = presets[choice]?.date;
                  if (_dueAt == null) _remindMinutes = null;
                });
              }
            },
          ),
          property(
            icon: LucideIcons.folder,
            label: context.strings.category,
            value: category?.name ?? context.strings.uncategorized,
            onOpen: (anchor) async {
              final picked = await showWorkspaceActionMenu<(String?,)>(
                anchor,
                selected: (_category,),
                items: [
                  (
                    value: (null,),
                    label: context.strings.uncategorized,
                    icon: LucideIcons.folder,
                  ),
                  for (final root in categories.roots) ...[
                    (
                      value: (root.id,),
                      label: root.name,
                      icon: LucideIcons.folder,
                    ),
                    for (final child in categories.childrenOf(root.id))
                      (
                        value: (child.id,),
                        label: '${root.name}/${child.name}',
                        icon: LucideIcons.folder,
                      ),
                  ],
                ],
              );
              if (mounted && picked != null) {
                setState(() => _category = picked.$1);
              }
            },
          ),
          property(
            icon: LucideIcons.flag,
            label: context.strings.priority,
            value: _priority.label,
            onOpen: (anchor) async {
              final p = await showWorkspaceActionMenu<TodoPriority>(
                anchor,
                selected: _priority,
                items: [
                  for (final priority in TodoPriority.values)
                    (
                      value: priority,
                      label: priority.label,
                      icon: LucideIcons.flag,
                    ),
                ],
              );
              if (mounted && p != null) setState(() => _priority = p);
            },
          ),
          property(
            icon: LucideIcons.circleCheck,
            label: context.strings.status,
            value: _status.label,
            onOpen: (anchor) async {
              final s = await showWorkspaceActionMenu<TodoStatus>(
                anchor,
                selected: _status,
                items: [
                  for (final status in TodoStatus.values)
                    (
                      value: status,
                      label: status.label,
                      icon: LucideIcons.circle,
                    ),
                ],
              );
              if (mounted && s != null) setState(() => _status = s);
            },
          ),
          if (current != null)
            property(
              icon: LucideIcons.bell,
              label: context.strings.reminder,
              value: reminders[_remindMinutes ?? -1]!,
              onOpen: (anchor) async {
                final m = await showWorkspaceActionMenu<int>(
                  anchor,
                  selected: _remindMinutes ?? -1,
                  items: [
                    for (final option in reminders.entries)
                      (
                        value: option.key,
                        label: option.value,
                        icon: LucideIcons.bell,
                      ),
                  ],
                );
                if (mounted && m != null) {
                  setState(() => _remindMinutes = m < 0 ? null : m);
                }
              },
            ),
        ],
      ),
    );
  }
}
