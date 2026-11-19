import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../domain/models/models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'formatters.dart';
import 'repository_command.dart';

/// 按字段类型分派的单元格编辑器（07-data-tables.md §3.3）。
/// 返回值：null = 取消；'' = 清除该字段；其他 = 新值（原始字符串）。
/// bool 类型不走这里，在行详情内直接 Switch 即时保存。
Future<String?> showFieldEditor(
  BuildContext context, {
  required DataColumnDef column,
  String? current,
  FutureOr<void> Function(String)? onSave,
}) {
  final editor = switch (column.fieldType) {
    DataFieldType.number || DataFieldType.money => _NumberEditorSheet(
      column: column,
      current: current,
      money: column.fieldType == DataFieldType.money,
      onSave: onSave,
    ),
    DataFieldType.date || DataFieldType.datetime => _DateEditorSheet(
      current: current,
      withTime: column.fieldType == DataFieldType.datetime,
      onSave: onSave,
    ),
    DataFieldType.selection => _EnumEditorSheet(
      column: column,
      current: current,
      onSave: onSave,
    ),
    DataFieldType.text ||
    DataFieldType.boolean => _TextEditorSheet(current: current, onSave: onSave),
  };
  return AppSheet.show<String>(
    context,
    title: column.name,
    child: _SavingEditor(child: SingleChildScrollView(child: editor)),
  );
}

class _SavingEditor extends StatefulWidget {
  const _SavingEditor({required this.child});
  final Widget child;
  @override
  State<_SavingEditor> createState() => _SavingEditorState();
}

class _SavingEditorState extends State<_SavingEditor> {
  bool busy = false;
  Future<void> save(
    String value,
    FutureOr<void> Function(String)? callback,
  ) async {
    if (busy) return;
    setState(() => busy = true);
    final saved = await runDataCommand(context, () async {
      await callback?.call(value);
    });
    if (!mounted) return;
    setState(() => busy = false);
    if (saved) Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AbsorbPointer(
      absorbing: busy,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [if (busy) const LinearProgressIndicator(), widget.child],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// text：多行输入
// ---------------------------------------------------------------------------

class _TextEditorSheet extends StatefulWidget {
  const _TextEditorSheet({this.current, this.onSave});

  final String? current;
  final FutureOr<void> Function(String)? onSave;

  @override
  State<_TextEditorSheet> createState() => _TextEditorSheetState();
}

class _TextEditorSheetState extends State<_TextEditorSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.current,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 2,
            maxLines: 5,
            style: AppTextStyles.body.copyWith(color: c.labelPrimary),
            cursorColor: c.brand,
            decoration: const InputDecoration(hintText: '输入内容'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              AppButton(
                label: '取消',
                type: AppButtonType.ghost,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Spacer(),
              AppButton(
                label: '保存',
                onPressed: () =>
                    _saveField(context, _controller.text.trim(), widget.onSave),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// number / money：数值输入，数字键盘，¥ 前缀 / unit 后缀
// ---------------------------------------------------------------------------

class _NumberEditorSheet extends StatefulWidget {
  const _NumberEditorSheet({
    required this.column,
    this.current,
    required this.money,
    this.onSave,
  });

  final DataColumnDef column;
  final String? current;
  final FutureOr<void> Function(String)? onSave;
  final bool money;

  @override
  State<_NumberEditorSheet> createState() => _NumberEditorSheetState();
}

class _NumberEditorSheetState extends State<_NumberEditorSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.current,
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      _saveField(context, '', widget.onSave);
      return;
    }
    if (!(double.tryParse(text)?.isFinite ?? false)) {
      setState(() => _error = '请输入数字');
      HapticFeedback.heavyImpact();
      return;
    }
    _saveField(context, text, widget.onSave);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final unit = widget.money ? '¥' : widget.column.unit;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
            ],
            style: tabularStyle(
              AppTextStyles.body.copyWith(color: c.labelPrimary),
            ),
            decoration: InputDecoration(
              hintText: '0',
              prefixText: widget.money ? '¥ ' : null,
              suffixText: widget.money ? null : unit,
              errorText: _error,
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              AppButton(
                label: '取消',
                type: AppButtonType.ghost,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Spacer(),
              AppButton(label: '保存', onPressed: _save),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// date / datetime：快捷 chip + 系统滚轮选择器
// ---------------------------------------------------------------------------

class _DateEditorSheet extends StatefulWidget {
  const _DateEditorSheet({this.current, required this.withTime, this.onSave});

  final String? current;
  final FutureOr<void> Function(String)? onSave;
  final bool withTime;

  @override
  State<_DateEditorSheet> createState() => _DateEditorSheetState();
}

class _DateEditorSheetState extends State<_DateEditorSheet> {
  late DateTime _selected = _parse(widget.current) ?? DateTime.now();

  static DateTime? _parse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw.replaceAll(' ', 'T'))?.toLocal();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var toMonday = (DateTime.monday + 7 - today.weekday) % 7;
    if (toMonday == 0) toMonday = 7;
    final nextMonday = today.add(Duration(days: toMonday));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (label, day) in [
                  ('今天', today),
                  ('明天', today.add(const Duration(days: 1))),
                  ('下周一', nextMonday),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AppChip(
                      label: label,
                      onTap: () => setState(
                        () => _selected = DateTime(
                          day.year,
                          day.month,
                          day.day,
                          _selected.hour,
                          _selected.minute,
                        ),
                      ),
                    ),
                  ),
                AppChip(
                  label: '清除',
                  onTap: () => _saveField(context, '', widget.onSave),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 180,
            child: CupertinoDatePicker(
              mode: widget.withTime
                  ? CupertinoDatePickerMode.dateAndTime
                  : CupertinoDatePickerMode.date,
              initialDateTime: _selected,
              use24hFormat: true,
              onDateTimeChanged: (v) => _selected = v,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              AppButton(
                label: '取消',
                type: AppButtonType.ghost,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Spacer(),
              AppButton(
                label: '保存',
                onPressed: () => _saveField(
                  context,
                  widget.current != null && _parse(widget.current) == _selected
                      ? widget.current!
                      : widget.withTime
                      ? _selected.toUtc().toIso8601String()
                      : formatDate(_selected),
                  widget.onSave,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// enum：≤5 个选项用胶囊流，更多用单选列表（选中 brand 对勾）
// ---------------------------------------------------------------------------

class _EnumEditorSheet extends StatelessWidget {
  const _EnumEditorSheet({required this.column, this.current, this.onSave});

  final DataColumnDef column;
  final String? current;
  final FutureOr<void> Function(String)? onSave;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final options = column.enumOptions;
    if (options.length <= 5) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              AppChip(
                label: option,
                height: 32,
                selected: option == current,
                onTap: () => _saveField(context, option, onSave),
              ),
          ],
        ),
      );
    }
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: options.length,
        itemBuilder: (context, i) {
          final option = options[i];
          final selected = option == current;
          return InkWell(
            onTap: () => _saveField(context, option, onSave),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option,
                        style: AppTextStyles.body.copyWith(
                          color: c.labelPrimary,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (selected)
                      Icon(LucideIcons.check, size: 18, color: c.brand),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

Future<void> _saveField(
  BuildContext context,
  String value,
  FutureOr<void> Function(String)? onSave,
) => context.findAncestorStateOfType<_SavingEditorState>()!.save(value, onSave);
