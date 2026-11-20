import 'package:towork/l10n/strings.dart';

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

part 'field_management_row.dart';

/// 字段管理面板（07-data-tables.md 表设置入口）：列出字段 + 重命名 / 删除，
/// 底部展开「添加字段」表单。不提供修改已有字段类型 / 精度 / 必填的能力。
void showFieldManagementSheet(
  BuildContext context,
  WidgetRef ref,
  DataTableDef table,
) {
  AppSheet.show<void>(
    context,
    title: context.strings.manageFields,
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
  DataFieldType.text => strings.text,
  DataFieldType.number => strings.number,
  DataFieldType.money => strings.currency,
  DataFieldType.date => strings.date,
  DataFieldType.datetime => strings.dateAndTime,
  DataFieldType.selection => strings.singleSelect,
  DataFieldType.boolean => strings.boolean,
};

List<(String, String)> get _typeChoices => [
  (strings.text, 'text'),
  (strings.number, 'number'),
  (strings.currency, 'money'),
  (strings.date, 'date'),
  (strings.dateAndTime, 'datetime'),
  (strings.singleSelect, 'enum'),
  (strings.boolean, 'bool'),
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
        title: context.strings.deletionUnavailable,
        message: context.strings.tooManyRecordsUseThisFieldTo,
        confirmLabel: context.strings.gotIt,
      );
      return;
    }
    final confirmed = await showAppConfirmDialog(
      context,
      title: context.strings.deleteField(column.name),
      message: usage == 0
          ? context.strings.thisFieldHasNoValues
          : context.strings.alsoClearsThisFieldInRows(usage),
      confirmLabel: context.strings.deleteLabel,
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
        message: context.strings.fieldDeleted,
        actionLabel: context.strings.undo,
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
      _parsedOptions.isEmpty
          ? context.strings.enterOneOfTheOptions
          : context.strings.enterAnOptionEG(_parsedOptions.first),
    'number' => context.strings.eG,
    'money' => context.strings.eGBackfillhint,
    _ => context.strings.defaultForExistingRecords,
  };

  Future<void> _submitAdd() async {
    if (_saving) return;
    final repo = ref.read(dataTableProvider.notifier);
    final rowCount = repo.rowsOf(widget.tableId).length;
    final name = _name.text.trim();
    final options = _parsedOptions;
    final backfill = _backfill.text.trim();
    final nameError = name.isEmpty ? context.strings.fieldNameIsRequired : null;
    final optionsError = _type == 'enum' && options.isEmpty
        ? context.strings.provideAtLeastOneCommaSeparatedOption
        : null;
    // 必填且现有行数 > 0 时，补默认值本身必填；不满足时界面阻止提交。
    final backfillError = _required && rowCount > 0 && backfill.isEmpty
        ? context.strings.provideAValueForExistingRecordsBefore
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
        message: context.strings.fieldAdded,
        actionLabel: context.strings.undo,
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
          context.strings.tableUnavailable,
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
            context.strings.fieldsBuildfieldlist(table.columns.length),
            style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
          ),
        ),
        const SizedBox(height: 4),
        Flexible(
          child: table.columns.isEmpty
              ? Center(
                  heightFactor: 2,
                  child: Text(
                    context.strings.noFieldsYet,
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
            label: context.strings.addFieldBuildfieldlist,
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
      AppToast.show(context, message: context.strings.renamedTo(name));
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
                label: context.strings.fieldNameBuildaddform,
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
              _formLabel(c, context.strings.type),
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
                  label: context.strings.options,
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
                      hintText: context.strings.commaSeparated,
                      errorText: _optionsError,
                    ),
                  ),
                ),
                if (_optionsError == null && _parsedOptions.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    context.strings.optionsBuildaddform(_parsedOptions.length),
                    style: AppTextStyles.caption.copyWith(
                      color: c.labelTertiary,
                    ),
                  ),
                ],
              ],
              if (isNumber || isMoney) ...[
                const SizedBox(height: 10),
                AppFieldLabel(
                  label: context.strings.unitOptional,
                  child: TextField(
                    controller: _unit,
                    enabled: !_saving,
                    style: AppTextStyles.body.copyWith(color: c.labelPrimary),
                    decoration: InputDecoration(
                      hintText: context.strings.eGSharesMinutes,
                    ),
                  ),
                ),
              ],
              if (isMoney) ...[
                const SizedBox(height: 10),
                _formLabel(c, context.strings.decimalPlaces),
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
                        context.strings.required,
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
                  label: context.strings.setADefaultForExistingRecords,
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
                  context.strings.appliesToAllExistingRows(rowCount),
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
                label: context.strings.cancel,
                type: AppButtonType.ghost,
                onPressed: _saving
                    ? null
                    : () => setState(() => _adding = false),
              ),
              const Spacer(),
              AppButton(
                label: context.strings.addBuild,
                loading: _saving,
                onPressed: _submitAdd,
              ),
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
