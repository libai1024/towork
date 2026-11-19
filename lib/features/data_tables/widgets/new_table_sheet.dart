import '../../../app/business_ui_commands.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_field_label.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../domain/models/models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_text_styles.dart';
import 'formatters.dart';
import 'repository_command.dart';
import 'data_table_type_sheet.dart';

/// 从模板/空白新建表（07-data-tables.md §5.1）：预填表名 + 字段预览（可删可加）。
/// 返回新建的 DataTableDef（取消返回 null）。
Future<DataTableDef?> showNewTableSheet(
  BuildContext context, {
  DataTableTemplate? template,
  String? initialTypeId,
}) {
  return AppSheet.show<DataTableDef>(
    context,
    title: '新建表',
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .80,
      ),
      child: _NewTableSheet(template: template, initialTypeId: initialTypeId),
    ),
  );
}

class _NewTableSheet extends ConsumerStatefulWidget {
  const _NewTableSheet({this.template, this.initialTypeId});

  final DataTableTemplate? template;
  final String? initialTypeId;

  @override
  ConsumerState<_NewTableSheet> createState() => _NewTableSheetState();
}

class _NewTableSheetState extends ConsumerState<_NewTableSheet> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.template?.name ?? '',
  );
  late final List<DataColumnDef> _columns = List.of(
    widget.template?.columns ??
        [
          DataColumnDef(name: '名称', type: 'text', isRequired: true),
          DataColumnDef(name: '备注', type: 'text'),
        ],
  );
  bool _nameError = false;
  bool _saving = false;
  late String? _typeId = widget.initialTypeId;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_saving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = true);
      return;
    }
    setState(() => _saving = true);
    await runDataCommand(context, () async {
      final table = await ref
          .read(businessUiCommandsProvider)
          .createTable(
            name: name,
            iconKey: widget.template?.iconKey ?? 'table',
            description: widget.template?.description ?? '',
            columns: _columns,
            seedRows: widget.template?.seedRows ?? const [],
            typeId: _typeId,
          );
      if (mounted) Navigator.of(context).pop(table);
    });
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _addField() async {
    final column = await AppSheet.show<DataColumnDef>(
      context,
      title: '添加字段',
      child: const SingleChildScrollView(child: _AddFieldSheet()),
    );
    if (column == null || !mounted) return;
    setState(() => _columns.add(column));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AbsorbPointer(
      absorbing: _saving,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                TextField(
                  controller: _nameController,
                  autofocus: widget.template == null,
                  style: AppTextStyles.body.copyWith(color: c.labelPrimary),
                  cursorColor: c.brand,
                  onChanged: (_) {
                    if (_nameError) setState(() => _nameError = false);
                  },
                  decoration: InputDecoration(
                    hintText: '表名',
                    errorText: _nameError ? '请输入表名' : null,
                  ),
                ),
                const SizedBox(height: 12),
                DataTableTypeField(
                  value: _typeId,
                  onChanged: (value) => setState(() => _typeId = value),
                ),
                const SizedBox(height: 16),
                Text(
                  '字段（${_columns.length}）',
                  style: AppTextStyles.caption.copyWith(
                    color: c.labelTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: c.bgPrimary,
                    borderRadius: AppRadii.brLg,
                    border: Border.all(color: c.separator, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < _columns.length; i++) ...[
                        if (i > 0)
                          Divider(
                            indent: 16,
                            height: 0.5,
                            thickness: 0.5,
                            color: c.separator,
                          ),
                        _FieldPreviewRow(
                          column: _columns[i],
                          onDelete: () => setState(() => _columns.removeAt(i)),
                        ),
                      ],
                      Divider(
                        indent: 16,
                        height: 0.5,
                        thickness: 0.5,
                        color: c.separator,
                      ),
                      AppPressable(
                        onTap: _addField,
                        borderRadius: AppRadii.brLg,
                        semanticLabel: '添加字段',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Icon(LucideIcons.plus, size: 16, color: c.brand),
                              const SizedBox(width: 8),
                              Text(
                                '添加字段',
                                style: AppTextStyles.body.copyWith(
                                  color: c.brand,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: AppButton(
              label: '创建',
              expand: true,
              loading: _saving,
              onPressed: _create,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldPreviewRow extends StatelessWidget {
  const _FieldPreviewRow({required this.column, required this.onDelete});

  final DataColumnDef column;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              column.name,
              style: AppTextStyles.body.copyWith(color: c.labelPrimary),
            ),
          ),
          if (column.isRequired)
            Text(
              '必填',
              style: AppTextStyles.caption.copyWith(color: c.labelPrimary),
            ),
          const SizedBox(width: 8),
          Text(
            fieldTypeLabel(column.type),
            style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
          ),
          const SizedBox(width: 8),
          AppPressable(
            onTap: onDelete,

            behavior: HitTestBehavior.translucent,
            semanticLabel: '删除字段${column.name}',
            child: Icon(LucideIcons.x, size: 16, color: c.labelQuaternary),
          ),
        ],
      ),
    );
  }
}

/// 逐行添加字段：字段名 + 类型 chip + 必填开关（v1 简化 schema 编辑器）。
class _AddFieldSheet extends StatefulWidget {
  const _AddFieldSheet();

  @override
  State<_AddFieldSheet> createState() => _AddFieldSheetState();
}

class _AddFieldSheetState extends State<_AddFieldSheet> {
  final _nameController = TextEditingController();
  final _optionsController = TextEditingController(text: '选项一\n选项二');
  String? _optionsError;
  String _type = 'text';
  bool _required = false;

  static const _types = [
    'text',
    'number',
    'money',
    'date',
    'datetime',
    'enum',
    'bool',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _optionsController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final options = _type == 'enum'
        ? _optionsController.text
              .split('\n')
              .map((v) => v.trim())
              .where((v) => v.isNotEmpty)
              .toList()
        : <String>[];
    if (_type == 'enum' &&
        (options.isEmpty ||
            options.length > 100 ||
            options.toSet().length != options.length)) {
      setState(() => _optionsError = '请填写不重复的选项，每行一个');
      return;
    }
    Navigator.of(context).pop(
      DataColumnDef(
        name: name,
        type: _type,
        isRequired: _required,
        enumOptions: options,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            style: AppTextStyles.body.copyWith(color: c.labelPrimary),
            cursorColor: c.brand,
            decoration: const InputDecoration(hintText: '字段名'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in _types)
                AppChip(
                  label: fieldTypeLabel(type),
                  selected: _type == type,
                  onTap: () => setState(() => _type = type),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_type == 'enum') ...[
            AppFieldLabel(
              label: '选项',
              child: TextField(
                controller: _optionsController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: '每行一个选项',
                  errorText: _optionsError,
                ),
                onChanged: (_) => setState(() => _optionsError = null),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Text(
                '必填',
                style: AppTextStyles.body.copyWith(color: c.labelPrimary),
              ),
              const Spacer(),
              Switch(
                value: _required,
                activeTrackColor: c.brand,
                onChanged: (v) => setState(() => _required = v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppButton(label: '添加', expand: true, onPressed: _save),
        ],
      ),
    );
  }
}
