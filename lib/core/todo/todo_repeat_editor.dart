import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';

import '../../domain/models/models.dart';
import '../../domain/recurrence/recurrence_schedule.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../widgets/app_button.dart';
import '../widgets/app_chip.dart';
import '../widgets/app_day_calendar.dart';
import 'recurrence_preview.dart';
import 'todo_editor_controls.dart';
import 'todo_utils.dart';

class TodoRepeatEditor extends StatefulWidget {
  const TodoRepeatEditor({
    super.key,
    required this.todo,
    required this.onChanged,
  });

  final Todo todo;
  final Future<bool> Function(String? rule, String timezone) onChanged;

  @override
  State<TodoRepeatEditor> createState() => _RepeatEditorState();
}

class _RepeatEditorState extends State<TodoRepeatEditor> {
  late RepeatSpec _spec;
  bool _unmappable = false;
  bool _confirmClear = false;
  bool _saving = false;
  late String _timezone;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _timezone = widget.todo.repeatTimezone ?? 'Asia/Shanghai';
    _unmappable = false;
    final rule = widget.todo.repeatRule;
    if (rule != null) {
      final parsed = RepeatSpec.fromRrule(rule);
      if (parsed == null) {
        _unmappable = true;
        _spec = RepeatSpec(
          weekdays: {
            RecurrenceTimeZones.civil(
              widget.todo.dueAt ?? widget.todo.createdAt,
              _timezone,
            ).weekday,
          },
        );
      } else {
        _spec = parsed;
      }
    } else {
      _spec = RepeatSpec(
        weekdays: {
          RecurrenceTimeZones.civil(
            widget.todo.dueAt ?? widget.todo.createdAt,
            _timezone,
          ).weekday,
        },
      );
    }
  }

  Future<void> _apply({bool clear = false}) async {
    if (_saving) return;
    setState(() => _saving = true);
    final saved = await widget.onChanged(
      clear ? null : _spec.toRrule(),
      _timezone,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (!saved || clear) _load();
    });
  }

  @override
  void didUpdateWidget(covariant TodoRepeatEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_saving &&
        (widget.todo.repeatRule != _spec.toRrule() ||
            widget.todo.repeatTimezone != _timezone) &&
        (oldWidget.todo.repeatRule != widget.todo.repeatRule ||
            oldWidget.todo.repeatTimezone != widget.todo.repeatTimezone)) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (_unmappable) {
      // 无法映射的复杂规则降级为只读 + 重置
      return TodoEditorBox(
        children: [
          Text(
            context.strings.customRuleReadOnly,
            style: AppTextStyles.body.copyWith(color: c.labelSecondary),
          ),
          const SizedBox(height: 8),
          AppButton(
            label: context.strings.resetRule,
            type: AppButtonType.ghost,
            onPressed: () => setState(() {
              _unmappable = false;
              _spec = RepeatSpec(
                weekdays: {
                  RecurrenceTimeZones.civil(
                    widget.todo.dueAt ?? widget.todo.createdAt,
                    _timezone,
                  ).weekday,
                },
              );
              _apply();
            }),
          ),
        ],
      );
    }

    final unit = switch (_spec.freq) {
      RepeatFreq.daily => context.strings.days,
      RepeatFreq.weekly => context.strings.week,
      RepeatFreq.monthly => context.strings.month,
      RepeatFreq.yearly => context.strings.year,
    };

    return AbsorbPointer(
      absorbing: _saving,
      child: TodoEditorBox(
        children: [
          _editorLabel(c, context.strings.frequency),
          Wrap(
            spacing: 8,
            children: [
              for (final (label, f) in [
                (context.strings.dailyBuild, RepeatFreq.daily),
                (context.strings.weeklyBuild, RepeatFreq.weekly),
                (context.strings.monthlyBuild, RepeatFreq.monthly),
                (context.strings.yearly, RepeatFreq.yearly),
              ])
                AppChip(
                  label: label,
                  selected: _spec.freq == f,
                  onTap: () => setState(() {
                    _spec.freq = f;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _editorLabel(c, context.strings.interval),
              Text(
                context.strings.every,
                style: AppTextStyles.body.copyWith(color: c.labelSecondary),
              ),
              TodoEditorStepper(
                label: context.strings.repeatInterval,
                value: _spec.interval,
                min: 1,
                max: 99,
                onChanged: (v) => setState(() {
                  _spec.interval = v;
                }),
              ),
              Text(
                unit,
                style: AppTextStyles.body.copyWith(color: c.labelSecondary),
              ),
            ],
          ),
          if (_spec.freq == RepeatFreq.weekly) ...[
            const SizedBox(height: 12),
            _editorLabel(c, context.strings.repeatOn),
            Wrap(
              spacing: 8,
              children: [
                for (var d = 1; d <= 7; d++)
                  AppChip(
                    label: RepeatSpec.weekdayNames[d - 1],
                    selected: _spec.weekdays.contains(d),
                    onTap: () => setState(() {
                      if (_spec.weekdays.contains(d)) {
                        if (_spec.weekdays.length > 1) _spec.weekdays.remove(d);
                      } else {
                        _spec.weekdays.add(d);
                      }
                    }),
                  ),
              ],
            ),
          ],
          if (_spec.freq == RepeatFreq.monthly) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _editorLabel(c, context.strings.monthlyBuild),
                TodoEditorStepper(
                  label: context.strings.dayOfMonth,
                  value: _spec.monthDay,
                  min: 1,
                  max: 31,
                  onChanged: (v) => setState(() {
                    _spec.monthDay = v;
                  }),
                ),
                Text(
                  context.strings.weekdaySunday,
                  style: AppTextStyles.body.copyWith(color: c.labelSecondary),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _editorLabel(c, context.strings.ends),
          Wrap(
            spacing: 8,
            children: [
              for (final (label, e) in [
                (context.strings.never, RepeatEnd.never),
                (context.strings.onDate, RepeatEnd.until),
                (context.strings.afterNOccurrences, RepeatEnd.count),
              ])
                AppChip(
                  label: label,
                  selected: _spec.end == e,
                  onTap: () => setState(() {
                    _spec.end = e;
                    _spec.until ??= dayOnly(DateTime.now())
                        .add(const Duration(days: 30));
                  }),
                ),
            ],
          ),
          if (_spec.end == RepeatEnd.until) ...[
            const SizedBox(height: 8),
            AppDayCalendar(
              selected: _spec.until,
              onSelected: (d) => setState(() {
                _spec.until = d;
              }),
            ),
          ],
          if (_spec.end == RepeatEnd.count) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TodoEditorStepper(
                  label: context.strings.numberOfOccurrences,
                  value: _spec.count,
                  min: 1,
                  max: 99,
                  onChanged: (v) => setState(() {
                    _spec.count = v;
                  }),
                ),
                Text(
                  context.strings.times,
                  style: AppTextStyles.body.copyWith(color: c.labelSecondary),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Divider(height: 0.5, color: c.separator),
          const SizedBox(height: 8),
          _editorLabel(c, context.strings.fixedTimeZone),
          DropdownButton<String>(
            key: const ValueKey('repeat-timezone'),
            value: _timezone,
            isExpanded: true,
            style: AppTextStyles.footnote.copyWith(color: c.labelPrimary),
            dropdownColor: Theme.of(context).scaffoldBackgroundColor,
            items: [
              for (final zone in RecurrenceTimeZones.names)
                DropdownMenuItem(
                  value: zone,
                  child: Text(zone, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (zone) {
              if (zone == null) return;
              setState(() => _timezone = zone);
            },
          ),
          const SizedBox(height: 8),
          RecurrencePreview(
            rule: _spec.toRrule(),
            anchor: widget.todo.dueAt,
            timezone: _timezone,
          ),
          const SizedBox(height: 8),
          Text(
            context.strings.shortMonthsUseTheLastDayDuring,
            style: AppTextStyles.footnote.copyWith(color: c.labelTertiary),
          ),
          const SizedBox(height: 8),
          Text(
            context.strings.summary(_spec.summary()),
            style: AppTextStyles.footnote.copyWith(color: c.labelSecondary),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: context.strings.saveRecurrence,
            expand: true,
            enabled: !_saving,
            onPressed: () => _apply(),
          ),
          const SizedBox(height: 4),
          Center(
            child: AppButton(
              label: _confirmClear
                  ? context.strings.clearRecurrence
                  : context.strings.clearRecurrenceBuild,
              type: AppButtonType.ghost,
              onPressed: () {
                if (_confirmClear) {
                  _apply(clear: true);
                } else {
                  setState(() => _confirmClear = true);
                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted) setState(() => _confirmClear = false);
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _editorLabel(AppColors c, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: AppTextStyles.footnote.copyWith(color: c.labelTertiary),
    ),
  );
}
