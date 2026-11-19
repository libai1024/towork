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
            '自定义规则（暂不支持编辑）',
            style: AppTextStyles.body.copyWith(color: c.labelSecondary),
          ),
          const SizedBox(height: 8),
          AppButton(
            label: '重置规则',
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
      RepeatFreq.daily => '天',
      RepeatFreq.weekly => '周',
      RepeatFreq.monthly => '月',
      RepeatFreq.yearly => '年',
    };

    return AbsorbPointer(
      absorbing: _saving,
      child: TodoEditorBox(
        children: [
          _editorLabel(c, '频率'),
          Wrap(
            spacing: 8,
            children: [
              for (final (label, f) in [
                ('每天', RepeatFreq.daily),
                ('每周', RepeatFreq.weekly),
                ('每月', RepeatFreq.monthly),
                ('每年', RepeatFreq.yearly),
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
              _editorLabel(c, '间隔'),
              Text(
                '每',
                style: AppTextStyles.body.copyWith(color: c.labelSecondary),
              ),
              TodoEditorStepper(
                label: '重复间隔',
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
            _editorLabel(c, '重复于'),
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
                _editorLabel(c, '每月'),
                TodoEditorStepper(
                  label: '每月日期',
                  value: _spec.monthDay,
                  min: 1,
                  max: 31,
                  onChanged: (v) => setState(() {
                    _spec.monthDay = v;
                  }),
                ),
                Text(
                  '日',
                  style: AppTextStyles.body.copyWith(color: c.labelSecondary),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _editorLabel(c, '结束'),
          Wrap(
            spacing: 8,
            children: [
              for (final (label, e) in [
                ('永不', RepeatEnd.never),
                ('于日期', RepeatEnd.until),
                ('N 次后', RepeatEnd.count),
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
                  label: '重复次数',
                  value: _spec.count,
                  min: 1,
                  max: 99,
                  onChanged: (v) => setState(() {
                    _spec.count = v;
                  }),
                ),
                Text(
                  '次',
                  style: AppTextStyles.body.copyWith(color: c.labelSecondary),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Divider(height: 0.5, color: c.separator),
          const SizedBox(height: 8),
          _editorLabel(c, '固定时区'),
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
            '月末不足所选日期时取最后一天；夏令时缺失时刻顺延至首个有效时刻，重复时刻只取一次。',
            style: AppTextStyles.footnote.copyWith(color: c.labelTertiary),
          ),
          const SizedBox(height: 8),
          Text(
            '摘要：${_spec.summary()}',
            style: AppTextStyles.footnote.copyWith(color: c.labelSecondary),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: '保存重复设置',
            expand: true,
            enabled: !_saving,
            onPressed: () => _apply(),
          ),
          const SizedBox(height: 4),
          Center(
            child: AppButton(
              label: _confirmClear ? '确认清除？' : '清除重复',
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
