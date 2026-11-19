import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide DataRow;
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../domain/data_tables/business_validation.dart';
import '../../../domain/models/models.dart';
import '../../../domain/workspace/workspace_commands.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_text_styles.dart';
import 'formatters.dart';

/// 行级筛选条件（本地库 SQL 查询模式）。[fieldId] 是工作区字段 ID；
/// [value] 已按类型规范化——text/enum/date/datetime 为 String、bool 为 bool、
/// number/money 为十进制字符串（eq 用 canonical 形式）。
class RowFilterCondition {
  const RowFilterCondition({
    required this.fieldId,
    required this.op,
    this.value,
  });

  final String fieldId;

  /// eq | contains | gt | ge | lt | le（按字段类型受限，见 [rowFilterOpsFor]）。
  final String op;
  final Object? value;

  RowFilterCondition withOp(String op) =>
      RowFilterCondition(fieldId: fieldId, op: op, value: value);

  RowFilterCondition withValue(Object? value) =>
      RowFilterCondition(fieldId: fieldId, op: op, value: value);
}

/// 操作的中文名（面板展示用）。
const rowFilterOpLabels = <String, String>{
  'eq': '等于',
  'contains': '包含',
  'gt': '大于',
  'ge': '大于等于',
  'lt': '小于',
  'le': '小于等于',
};

/// 与 sqlite_row_query 的校验保持一致：text/enum → eq|contains，
/// number/money/date/datetime → 区间比较，bool → 仅 eq。
List<String> rowFilterOpsFor(DataColumnDef column) =>
    switch (column.fieldType) {
      DataFieldType.text || DataFieldType.selection => const ['eq', 'contains'],
      DataFieldType.boolean => const ['eq'],
      _ => const ['eq', 'gt', 'ge', 'lt', 'le'],
    };

/// 数字/金额输入校验：空串视为未填（返回 null）；eq 要求 canonical 十进制
/// （金额不超过精度位小数），区间比较只要求能解析为有限数字。
String? validateRowFilterNumber(DataColumnDef column, String op, String text) {
  if (text.isEmpty) return null;
  final money = column.fieldType == DataFieldType.money;
  if (op == 'eq') {
    try {
      canonicalBusinessDecimal(text, scale: money ? column.scale : null);
      return null;
    } on WorkspaceFailure {
      return money ? '金额需为数字，且不超过 ${column.scale} 位小数' : '请输入数字';
    }
  }
  final parsed = double.tryParse(text);
  return parsed != null && parsed.isFinite ? null : '请输入数字';
}

/// 打开行筛选面板（风格同字段管理面板）。应用时回调完整条件；
/// 清除筛选同样走 [onApply]，只是回调空列表。
Future<void> showRowFilterSheet(
  BuildContext context, {
  required DataTableDef table,
  required List<RowFilterCondition> initialConditions,
  required ValueChanged<List<RowFilterCondition>> onApply,
}) {
  return AppSheet.show<void>(
    context,
    title: '筛选',
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .75,
      ),
      child: _RowFilterSheet(
        table: table,
        initialConditions: initialConditions,
        onApply: onApply,
      ),
    ),
  );
}

class _RowFilterSheet extends StatefulWidget {
  const _RowFilterSheet({
    required this.table,
    required this.initialConditions,
    required this.onApply,
  });

  final DataTableDef table;
  final List<RowFilterCondition> initialConditions;
  final ValueChanged<List<RowFilterCondition>> onApply;

  @override
  State<_RowFilterSheet> createState() => _RowFilterSheetState();
}

class _RowFilterSheetState extends State<_RowFilterSheet> {
  static const maxConditions = 4;

  late final List<RowFilterCondition> _conditions = [
    for (final condition in widget.initialConditions) condition,
  ];

  List<DataColumnDef> get _columns => [
    for (final column in widget.table.columns)
      if (column.id != null) column,
  ];

  DataColumnDef? _columnOf(String fieldId) {
    for (final column in _columns) {
      if (column.id == fieldId) return column;
    }
    return null;
  }

  RowFilterCondition _blankCondition(DataColumnDef column) =>
      RowFilterCondition(
        fieldId: column.id!,
        op: 'eq',
        value: column.fieldType == DataFieldType.boolean ? false : null,
      );

  void _addCondition() {
    if (_conditions.length >= maxConditions) return;
    final column = _columns.isEmpty ? null : _columns.first;
    if (column == null) return;
    setState(() => _conditions.add(_blankCondition(column)));
  }

  void _changeCondition(int index, RowFilterCondition condition) {
    // 字段切换时重置操作与值，避免跨类型残留非法 op。
    final sameField = _conditions[index].fieldId == condition.fieldId;
    setState(() {
      _conditions[index] = sameField
          ? condition
          : (_columnOf(condition.fieldId) == null
                ? condition
                : _blankCondition(_columnOf(condition.fieldId)!));
    });
  }

  void _removeCondition(int index) {
    setState(() => _conditions.removeAt(index));
  }

  Future<void> _apply() async {
    final applied = <RowFilterCondition>[];
    for (final condition in _conditions) {
      final column = _columnOf(condition.fieldId);
      if (column == null) continue;
      if (column.fieldType == DataFieldType.boolean) {
        applied.add(condition.withValue(condition.value == true));
        continue;
      }
      final value = condition.value;
      if (value is! String || value.trim().isEmpty) continue;
      final text = value.trim();
      if (column.fieldType == DataFieldType.number ||
          column.fieldType == DataFieldType.money) {
        if (validateRowFilterNumber(column, condition.op, text) != null) {
          // 面板内的输入校验已实时提示；这里兜底阻止提交。
          HapticFeedback.heavyImpact();
          return;
        }
        final money = column.fieldType == DataFieldType.money;
        applied.add(
          condition.withValue(
            condition.op == 'eq' && money
                ? canonicalBusinessDecimal(text, scale: column.scale)
                : condition.op == 'eq'
                ? canonicalBusinessDecimal(text)
                : text,
          ),
        );
        continue;
      }
      applied.add(condition.withValue(text));
    }
    widget.onApply(applied);
    Navigator.of(context).pop();
  }

  // -------------------------------------------------------------------------
  // 构建
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  _conditions.isEmpty
                      ? '按字段添加条件，最多 4 个'
                      : '共 ${_conditions.length} 个条件',
                  style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
                ),
              ),
              for (var i = 0; i < _conditions.length; i++)
                _ConditionCard(
                  key: ValueKey('row-filter-condition-$i'),
                  table: widget.table,
                  condition: _conditions[i],
                  onChanged: (condition) => _changeCondition(i, condition),
                  onRemove: () => _removeCondition(i),
                ),
              if (_columns.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '这张表还没有可筛选的字段',
                    style: AppTextStyles.body.copyWith(color: c.labelTertiary),
                  ),
                )
              else if (_conditions.length < maxConditions)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: AppButton(
                    label: '添加条件',
                    icon: LucideIcons.plus,
                    type: AppButtonType.secondary,
                    expand: true,
                    onPressed: _addCondition,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    '最多 $maxConditions 个条件',
                    style: AppTextStyles.caption.copyWith(
                      color: c.labelQuaternary,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              AppButton(
                label: '清除筛选',
                type: AppButtonType.ghost,
                onPressed: () {
                  widget.onApply(const []);
                  Navigator.of(context).pop();
                },
              ),
              const Spacer(),
              AppButton(label: '应用筛选', onPressed: _apply),
            ],
          ),
        ),
      ],
    );
  }
}

/// 单条条件卡片：字段横滑 chips → 操作 chips → 按类型分派的值输入。
class _ConditionCard extends StatefulWidget {
  const _ConditionCard({
    super.key,
    required this.table,
    required this.condition,
    required this.onChanged,
    required this.onRemove,
  });

  final DataTableDef table;
  final RowFilterCondition condition;
  final ValueChanged<RowFilterCondition> onChanged;
  final VoidCallback onRemove;

  @override
  State<_ConditionCard> createState() => _ConditionCardState();
}

class _ConditionCardState extends State<_ConditionCard> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.condition.value is String
        ? widget.condition.value as String
        : '',
  );
  String? _error;

  DataColumnDef? get _column {
    for (final column in widget.table.columns) {
      if (column.id == widget.condition.fieldId) return column;
    }
    return null;
  }

  @override
  void didUpdateWidget(covariant _ConditionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.condition.fieldId != widget.condition.fieldId) {
      _controller.text = widget.condition.value is String
          ? widget.condition.value as String
          : '';
      _error = null;
    } else if (oldWidget.condition.op != widget.condition.op) {
      final column = _column;
      _error =
          column != null &&
              (column.fieldType == DataFieldType.number ||
                  column.fieldType == DataFieldType.money)
          ? validateRowFilterNumber(
              column,
              widget.condition.op,
              _controller.text,
            )
          : null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reportText(String text) {
    final column = _column;
    if (column == null) return;
    final trimmed = text.trim();
    String? error;
    if (column.fieldType == DataFieldType.number ||
        column.fieldType == DataFieldType.money) {
      error = validateRowFilterNumber(column, widget.condition.op, trimmed);
    }
    setState(() => _error = error);
    widget.onChanged(
      widget.condition.withValue(trimmed.isEmpty ? null : trimmed),
    );
  }

  Future<void> _pickDate({required bool withTime}) async {
    final picked = await _showDatePickerSheet(
      context,
      withTime: withTime,
      current: widget.condition.value is String
          ? widget.condition.value as String
          : null,
    );
    if (picked != null && mounted) {
      // 日期面板的「清除」以空串返回，这里归一为未选值。
      widget.onChanged(
        widget.condition.withValue(picked.isEmpty ? null : picked),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final column = _column;
    if (column == null) {
      return const SizedBox.shrink();
    }
    final type = column.fieldType;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: c.bgPrimary,
        borderRadius: AppRadii.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部：字段横滑 chips。
          SizedBox(
            height: 44,
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final candidate in widget.table.columns)
                          if (candidate.id != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: AppChip(
                                label: candidate.name,
                                selected:
                                    candidate.id == widget.condition.fieldId,
                                onTap: () => widget.onChanged(
                                  RowFilterCondition(
                                    fieldId: candidate.id!,
                                    op: 'eq',
                                    value:
                                        candidate.fieldType ==
                                            DataFieldType.boolean
                                        ? false
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
                AppPressable(
                  onTap: widget.onRemove,
                  semanticLabel: '移除此条件',
                  borderRadius: AppRadii.brMd,
                  child: SizedBox(
                    width: 40,
                    height: 44,
                    child: Icon(
                      LucideIcons.x,
                      size: 18,
                      color: c.labelSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 操作选择（bool 仅 eq，不显示 chips）。
          if (type != DataFieldType.boolean) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final op in rowFilterOpsFor(column))
                  AppChip(
                    label: rowFilterOpLabels[op]!,
                    selected: widget.condition.op == op,
                    onTap: () => widget.onChanged(widget.condition.withOp(op)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          _buildValueEditor(c, column),
        ],
      ),
    );
  }

  Widget _buildValueEditor(AppColors c, DataColumnDef column) {
    final type = column.fieldType;
    switch (type) {
      case DataFieldType.boolean:
        return Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: c.fill1,
            borderRadius: AppRadii.brSm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '取值',
                  style: AppTextStyles.body.copyWith(color: c.labelPrimary),
                ),
              ),
              Switch(
                value: widget.condition.value == true,
                activeTrackColor: c.brand,
                onChanged: (v) =>
                    widget.onChanged(widget.condition.withValue(v)),
              ),
            ],
          ),
        );
      case DataFieldType.selection:
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in column.enumOptions)
              AppChip(
                label: option,
                selected: widget.condition.value == option,
                onTap: () =>
                    widget.onChanged(widget.condition.withValue(option)),
              ),
          ],
        );
      case DataFieldType.date || DataFieldType.datetime:
        final raw = widget.condition.value is String
            ? widget.condition.value as String
            : null;
        final parsed = raw == null ? null : DateTime.tryParse(raw);
        final display = raw == null
            ? '选择日期'
            : (parsed == null
                  ? raw
                  : type == DataFieldType.datetime
                  ? formatDateTime(parsed.toLocal())
                  : formatDate(parsed));
        return Row(
          children: [
            Expanded(
              child: AppPressable(
                onTap: () =>
                    _pickDate(withTime: type == DataFieldType.datetime),
                semanticLabel: '选择日期',
                borderRadius: AppRadii.brSm,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: c.fill1,
                    borderRadius: AppRadii.brSm,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 18,
                        color: c.labelSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          display,
                          style: AppTextStyles.body.copyWith(
                            color: raw == null
                                ? c.labelTertiary
                                : c.labelPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (raw != null)
              AppPressable(
                onTap: () => widget.onChanged(widget.condition.withValue(null)),
                semanticLabel: '清除日期',
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    LucideIcons.circleX,
                    size: 18,
                    color: c.labelSecondary,
                  ),
                ),
              ),
          ],
        );
      case DataFieldType.number || DataFieldType.money:
        final money = type == DataFieldType.money;
        return TextField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
          ],
          onChanged: _reportText,
          style: AppTextStyles.body.copyWith(color: c.labelPrimary),
          cursorColor: c.brand,
          decoration: InputDecoration(
            hintText: money
                ? '如 1250.00'
                : (column.unit == null ? '如 3.5' : '如 3.5（${column.unit}）'),
            errorText: _error,
          ),
        );
      case DataFieldType.text:
        return TextField(
          controller: _controller,
          onChanged: _reportText,
          style: AppTextStyles.body.copyWith(color: c.labelPrimary),
          cursorColor: c.brand,
          decoration: const InputDecoration(hintText: '输入内容'),
        );
    }
  }
}

/// 日期值选择（沿用 field_editors 的快捷 chip + 滚轮模式）。
Future<String?> _showDatePickerSheet(
  BuildContext context, {
  required bool withTime,
  String? current,
}) {
  return AppSheet.show<String>(
    context,
    title: withTime ? '选择日期时间' : '选择日期',
    child: _DatePickerValueSheet(withTime: withTime, current: current),
  );
}

class _DatePickerValueSheet extends StatefulWidget {
  const _DatePickerValueSheet({required this.withTime, this.current});

  final bool withTime;
  final String? current;

  @override
  State<_DatePickerValueSheet> createState() => _DatePickerValueSheetState();
}

class _DatePickerValueSheetState extends State<_DatePickerValueSheet> {
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
                  ('下周一', today.add(Duration(days: toMonday))),
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
                  onTap: () => Navigator.of(context).pop(''),
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
                onPressed: () => Navigator.of(context).pop(
                  widget.current != null && _parse(widget.current) == _selected
                      ? widget.current!
                      : widget.withTime
                      ? _selected.toUtc().toIso8601String()
                      : formatDate(_selected),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
