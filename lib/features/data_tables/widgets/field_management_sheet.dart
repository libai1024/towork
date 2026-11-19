import '../../../app/business_ui_commands.dart';

import 'package:flutter/material.dart' hide DataRow;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/providers.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_field_label.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../domain/models/models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_text_styles.dart';
import 'confirm_dialog.dart';
import 'repository_command.dart';

/// 字段管理面板（07-data-tables.md 表设置入口）：列出字段 + 重命名 / 删除，
/// 底部展开「添加字段」表单。不提供修改已有字段类型 / 精度 / 必填的能力。
void showFieldManagementSheet(
  BuildContext context,
  WidgetRef ref,
  DataTableDef table,
) {
  AppSheet.show<void>(
    context,
    title: '管理字段',
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .75,
      ),
      child: _FieldManagementSheet(tableId: table.id),
    ),
  );
}

/// 类型中文名（text→文本、number→数字、money→金额、date→日期、
/// datetime→日期时间、enum→单选、bool→布尔）。
String fieldTypeName(DataColumnDef column) => switch (column.fieldType) {
  DataFieldType.text => '文本',
  DataFieldType.number => '数字',
  DataFieldType.money => '金额',
  DataFieldType.date => '日期',
  DataFieldType.datetime => '日期时间',
  DataFieldType.selection => '单选',
  DataFieldType.boolean => '布尔',
};

const List<(String, String)> _typeChoices = [
  ('文本', 'text'),
  ('数字', 'number'),
  ('金额', 'money'),
  ('日期', 'date'),
  ('日期时间', 'datetime'),
  ('单选', 'enum'),
  ('布尔', 'bool'),
];

class _FieldManagementSheet extends ConsumerStatefulWidget {
  const _FieldManagementSheet({required this.tableId});

  final String tableId;

  @override
  ConsumerState<_FieldManagementSheet> createState() =>
      _FieldManagementSheetState();
}

class _FieldManagementSheetState extends ConsumerState<_FieldManagementSheet> {
  bool _adding = false;
  bool _saving = false;

  final _name = TextEditingController();
  final _options = TextEditingController();
  final _unit = TextEditingController();
  final _backfill = TextEditingController();
  String _type = 'text';
  bool _required = false;
  int _scale = 2;
  String? _nameError;
  String? _optionsError;
  String? _backfillError;

  @override
  void dispose() {
    _name.dispose();
    _options.dispose();
    _unit.dispose();
    _backfill.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // 重命名 / 删除
  // -------------------------------------------------------------------------

  Future<bool> _renameField(DataColumnDef column, String name) async {
    if (name == column.name) return true;
    // 每次操作前取最新表；表可能已被删除或归档。
    final current = ref
        .read(dataTableProvider.notifier)
        .tableById(widget.tableId);
    if (current == null) return false;
    final commands = ref.read(businessUiCommandsProvider);
    return runDataCommand(
      context,
      () => commands.renameField(current, column.id ?? column.name, name),
    );
  }

  Future<void> _removeField(DataColumnDef column) async {
    final current = ref
        .read(dataTableProvider.notifier)
        .tableById(widget.tableId);
    if (current == null) return;
    final commands = ref.read(businessUiCommandsProvider);
    final fieldKey = column.id ?? column.name;
    final usage = commands.fieldUsageCount(current, fieldKey);
    // 一条命令 500 动作上限：字段本身 + N 行清值。
    if (usage + 1 > 500) {
      await showAppConfirmDialog(
        context,
        title: '暂时无法删除',
        message: '使用该字段的记录过多，暂不支持在此删除',
        confirmLabel: '知道了',
      );
      return;
    }
    final confirmed = await showAppConfirmDialog(
      context,
      title: '删除字段「${column.name}」？',
      message: usage == 0 ? '该字段没有已填数据。' : '同时清除 $usage 行记录中的字段值。',
      confirmLabel: '删除',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await runDataCommand(context, () async {
      final fresh = ref
          .read(dataTableProvider.notifier)
          .tableById(widget.tableId);
      if (fresh == null) return;
      final change = await commands.removeField(fresh, fieldKey);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      AppToast.show(
        context,
        message: '已删除字段',
        actionLabel: '撤销',
        onAction: () => runDataCommand(context, change.undo),
      );
    });
  }

  // -------------------------------------------------------------------------
  // 添加字段
  // -------------------------------------------------------------------------

  List<String> get _parsedOptions => [
    for (final part in _options.text.split(RegExp(r'[，,]')))
      if (part.trim().isNotEmpty) part.trim(),
  ];

  String get _backfillHint => switch (_type) {
    'bool' => 'true/false',
    'date' => '2026-09-24',
    'datetime' => '2026-09-24T12:00:00Z',
    'enum' =>
      _parsedOptions.isEmpty ? '填选项之一' : '填选项之一，如「${_parsedOptions.first}」',
    'number' => '如 3.5',
    'money' => '如 1250.00',
    _ => '为现有记录填入的默认内容',
  };

  Future<void> _submitAdd() async {
    if (_saving) return;
    final repo = ref.read(dataTableProvider.notifier);
    final rowCount = repo.rowsOf(widget.tableId).length;
    final name = _name.text.trim();
    final options = _parsedOptions;
    final backfill = _backfill.text.trim();
    final nameError = name.isEmpty ? '字段名不能为空' : null;
    final optionsError = _type == 'enum' && options.isEmpty
        ? '至少提供一个选项（用逗号分隔）'
        : null;
    // 必填且现有行数 > 0 时，补默认值本身必填；不满足时界面阻止提交。
    final backfillError = _required && rowCount > 0 && backfill.isEmpty
        ? '必填字段需要为现有记录补一个值'
        : null;
    if (nameError != null || optionsError != null || backfillError != null) {
      HapticFeedback.heavyImpact();
      setState(() {
        _nameError = nameError;
        _optionsError = optionsError;
        _backfillError = backfillError;
      });
      return;
    }
    final current = repo.tableById(widget.tableId);
    if (current == null) return;
    final commands = ref.read(businessUiCommandsProvider);
    final field = DataColumnDef(
      name: name,
      type: _type,
      isRequired: _required,
      enumOptions: options,
      unit: _unit.text.trim().isEmpty ? null : _unit.text.trim(),
      scale: _scale,
    );
    setState(() => _saving = true);
    final saved = await runDataCommand(context, () async {
      final change = await commands.addField(
        current,
        field,
        backfillValue: backfill.isEmpty ? null : backfill,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      AppToast.show(
        context,
        message: '已添加字段',
        actionLabel: '撤销',
        onAction: () => runDataCommand(context, change.undo),
      );
    });
    if (!mounted) return;
    if (!saved) {
      // 失败不关闭表单、不清空已填内容。
      setState(() => _saving = false);
      return;
    }
    setState(() {
      _saving = false;
      _adding = false;
      _name.clear();
      _options.clear();
      _unit.clear();
      _backfill.clear();
      _type = 'text';
      _required = false;
      _scale = 2;
      _nameError = null;
      _optionsError = null;
      _backfillError = null;
    });
  }

  // -------------------------------------------------------------------------
  // 构建
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    ref.watch(dataTableProvider);
    final table = ref
        .read(dataTableProvider.notifier)
        .tableById(widget.tableId);
    if (table == null) {
      return Center(
        child: Text(
          '这张表不在了',
          style: AppTextStyles.body.copyWith(color: c.labelTertiary),
        ),
      );
    }
    return PopScope(
      canPop: !_saving,
      child: AbsorbPointer(
        absorbing: _saving,
        child: _adding ? _buildAddForm(c) : _buildFieldList(c, table),
      ),
    );
  }

  Widget _buildFieldList(AppColors c, DataTableDef table) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '共 ${table.columns.length} 个字段',
            style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
          ),
        ),
        const SizedBox(height: 4),
        Flexible(
          child: table.columns.isEmpty
              ? Center(
                  heightFactor: 2,
                  child: Text(
                    '还没有字段',
                    style: AppTextStyles.body.copyWith(color: c.labelTertiary),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  itemCount: table.columns.length,
                  itemBuilder: (context, i) => _FieldRow(
                    column: table.columns[i],
                    onRename: () => _showRenameDialog(table.columns[i]),
                    onRemove: () => _removeField(table.columns[i]),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: AppButton(
            label: '添加字段',
            icon: LucideIcons.plus,
            type: AppButtonType.secondary,
            expand: true,
            onPressed: () => setState(() => _adding = true),
          ),
        ),
      ],
    );
  }

  Future<void> _showRenameDialog(DataColumnDef column) async {
    final name = await showDialog<String>(
      context: context,
      barrierColor: AppColors.of(context).scrim,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppColors.of(dialogContext).bgPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.brXl),
        child: _RenameFieldDialog(
          column: column,
          onSave: (name) => _renameField(column, name),
        ),
      ),
    );
    if (name != null && mounted) {
      AppToast.show(context, message: '已重命名为「$name」');
    }
  }

  Widget _buildAddForm(AppColors c) {
    final rowCount = ref
        .read(dataTableProvider.notifier)
        .rowsOf(widget.tableId)
        .length;
    final isEnum = _type == 'enum';
    final isNumber = _type == 'number';
    final isMoney = _type == 'money';
    final needsBackfill = _required && rowCount > 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              AppFieldLabel(
                label: '字段名称',
                child: TextField(
                  controller: _name,
                  enabled: !_saving,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) {
                    if (_nameError != null) setState(() => _nameError = null);
                  },
                  style: AppTextStyles.body.copyWith(color: c.labelPrimary),
                  decoration: InputDecoration(errorText: _nameError),
                ),
              ),
              const SizedBox(height: 10),
              _formLabel(c, '类型'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (label, value) in _typeChoices)
                    AppChip(
                      label: label,
                      selected: _type == value,
                      onTap: () => setState(() {
                        _type = value;
                        _optionsError = null;
                        _backfillError = null;
                      }),
                    ),
                ],
              ),
              if (isEnum) ...[
                const SizedBox(height: 10),
                AppFieldLabel(
                  label: '选项',
                  child: TextField(
                    controller: _options,
                    enabled: !_saving,
                    onChanged: (_) {
                      if (_optionsError != null) {
                        setState(() => _optionsError = null);
                      }
                    },
                    style: AppTextStyles.body.copyWith(color: c.labelPrimary),
                    decoration: InputDecoration(
                      hintText: '用逗号分隔',
                      errorText: _optionsError,
                    ),
                  ),
                ),
                if (_optionsError == null && _parsedOptions.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${_parsedOptions.length} 个选项',
                    style: AppTextStyles.caption.copyWith(
                      color: c.labelTertiary,
                    ),
                  ),
                ],
              ],
              if (isNumber || isMoney) ...[
                const SizedBox(height: 10),
                AppFieldLabel(
                  label: '单位（可选）',
                  child: TextField(
                    controller: _unit,
                    enabled: !_saving,
                    style: AppTextStyles.body.copyWith(color: c.labelPrimary),
                    decoration: const InputDecoration(hintText: '如：股、分钟'),
                  ),
                ),
              ],
              if (isMoney) ...[
                const SizedBox(height: 10),
                _formLabel(c, '精度（小数位）'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final value in [0, 1, 2, 3, 4, 5, 6])
                      AppChip(
                        label: '$value',
                        selected: _scale == value,
                        onTap: () => setState(() => _scale = value),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: c.fill1,
                  borderRadius: AppRadii.brSm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '必填',
                        style: AppTextStyles.body.copyWith(
                          color: c.labelPrimary,
                        ),
                      ),
                    ),
                    Switch(
                      value: _required,
                      activeTrackColor: c.brand,
                      onChanged: _saving
                          ? null
                          : (v) => setState(() {
                              _required = v;
                              _backfillError = null;
                            }),
                    ),
                  ],
                ),
              ),
              if (needsBackfill) ...[
                const SizedBox(height: 10),
                AppFieldLabel(
                  label: '为现有记录补默认值',
                  child: TextField(
                    controller: _backfill,
                    enabled: !_saving,
                    onChanged: (_) {
                      if (_backfillError != null) {
                        setState(() => _backfillError = null);
                      }
                    },
                    style: AppTextStyles.body.copyWith(color: c.labelPrimary),
                    decoration: InputDecoration(
                      hintText: _backfillHint,
                      errorText: _backfillError,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '将写入全部 $rowCount 行现有记录',
                  style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
                ),
              ],

              const SizedBox(height: 8),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              AppButton(
                label: '取消',
                type: AppButtonType.ghost,
                onPressed: _saving
                    ? null
                    : () => setState(() => _adding = false),
              ),
              const Spacer(),
              AppButton(label: '添加', loading: _saving, onPressed: _submitAdd),
            ],
          ),
        ),
      ],
    );
  }

  Widget _formLabel(AppColors c, String text) => Text(
    text,
    style: AppTextStyles.footnote.copyWith(color: c.labelSecondary),
  );
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.column,
    required this.onRename,
    required this.onRemove,
  });

  final DataColumnDef column;
  final VoidCallback onRename;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final typeLabel = fieldTypeName(column);
    final detail = column.unit == null
        ? typeLabel
        : '$typeLabel（${column.unit}）';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: c.bgPrimary,
        borderRadius: AppRadii.brMd,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          column.name,
                          style: AppTextStyles.body.copyWith(
                            color: c.labelPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (column.isRequired)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            '必填',
                            style: AppTextStyles.caption.copyWith(color: c.red),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: AppTextStyles.caption.copyWith(
                      color: c.labelTertiary,
                    ),
                  ),
                ],
              ),
            ),
            AppPressable(
              onTap: onRename,
              semanticLabel: '重命名「${column.name}」',
              borderRadius: AppRadii.brMd,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  LucideIcons.pencil,
                  size: 18,
                  color: c.labelSecondary,
                ),
              ),
            ),
            AppPressable(
              onTap: onRemove,
              semanticLabel: '删除「${column.name}」',
              borderRadius: AppRadii.brMd,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  LucideIcons.trash2,
                  size: 18,
                  color: c.labelSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 重命名字段对话框：沿用确认弹窗风格，非空校验，保存失败不关闭。
class _RenameFieldDialog extends StatefulWidget {
  const _RenameFieldDialog({required this.column, required this.onSave});

  final DataColumnDef column;
  final Future<bool> Function(String name) onSave;

  @override
  State<_RenameFieldDialog> createState() => _RenameFieldDialogState();
}

class _RenameFieldDialogState extends State<_RenameFieldDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.column.name,
  );
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _controller.text.trim();
    if (name.isEmpty) {
      HapticFeedback.heavyImpact();
      setState(() => _error = '字段名不能为空');
      return;
    }
    if (name == widget.column.name) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    final saved = await widget.onSave(name);
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(name);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AbsorbPointer(
      absorbing: _saving,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '重命名字段',
              style: AppTextStyles.title2.copyWith(color: c.labelPrimary),
            ),
            const SizedBox(height: 12),
            AppFieldLabel(
              label: '字段名称',
              child: TextField(
                controller: _controller,
                enabled: !_saving,
                autofocus: true,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _save(),
                style: AppTextStyles.body.copyWith(color: c.labelPrimary),
                decoration: InputDecoration(errorText: _error),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  label: '取消',
                  type: AppButtonType.ghost,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                AppButton(label: '保存', loading: _saving, onPressed: _save),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
