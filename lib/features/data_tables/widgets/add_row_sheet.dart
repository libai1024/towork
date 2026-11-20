import 'package:towork/l10n/strings.dart';

import '../../../app/business_ui_commands.dart';

import 'package:flutter/material.dart' hide DataRow;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../domain/models/models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_text_styles.dart';
import 'field_editors.dart';
import 'formatters.dart';
import 'repository_command.dart';

/// 新增行底部 Sheet（07-data-tables.md §3.2）：字段表单，
/// 点按字段按类型弹编辑器，保存时校验必填。
/// 返回新建的 DataRow（取消返回 null）。
Future<DataRow?> showAddRowSheet(BuildContext context, DataTableDef table) {
  return AppSheet.show<DataRow>(
    context,
    title: context.strings.addRow,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      child: _AddRowSheet(table: table),
    ),
  );
}

class _AddRowSheet extends ConsumerStatefulWidget {
  const _AddRowSheet({required this.table});

  final DataTableDef table;

  @override
  ConsumerState<_AddRowSheet> createState() => _AddRowSheetState();
}

class _AddRowSheetState extends ConsumerState<_AddRowSheet> {
  final Map<String, String> _values = {};
  final Set<String> _errors = {};
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    for (final field in widget.table.columns) {
      if (field.fieldType == DataFieldType.boolean && field.isRequired) {
        _values[field.name] = 'false';
      }
    }
  }

  Future<void> _editField(DataColumnDef column) async {
    final result = await showFieldEditor(
      context,
      column: column,
      current: _values[column.name],
    );
    if (result == null || !mounted) return;
    setState(() {
      if (result.isEmpty) {
        _values.remove(column.name);
      } else {
        _values[column.name] = result;
      }
      _errors.remove(column.name);
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final missing = <String>{
      for (final col in widget.table.columns)
        if (col.isRequired && (_values[col.name] ?? '').trim().isEmpty)
          col.name,
    };
    if (missing.isNotEmpty) {
      setState(
        () => _errors
          ..clear()
          ..addAll(missing),
      );
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() => _saving = true);
    await runDataCommand(context, () async {
      final row = await ref
          .read(businessUiCommandsProvider)
          .addRow(widget.table, Map.of(_values));
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.of(context).pop(row);
    });
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
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
                for (final column in widget.table.columns)
                  _AddRowField(
                    column: column,
                    value: _values[column.name],
                    error: _errors.contains(column.name),
                    onTap: () => _editField(column),
                    onBoolChanged: (v) {
                      setState(() => _values[column.name] = boolRaw(v));
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: AppButton(
              label: context.strings.save,
              expand: true,
              loading: _saving,
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddRowField extends StatelessWidget {
  const _AddRowField({
    required this.column,
    required this.value,
    required this.error,
    required this.onTap,
    required this.onBoolChanged,
  });

  final DataColumnDef column;
  final String? value;
  final bool error;
  final VoidCallback onTap;
  final ValueChanged<bool> onBoolChanged;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isBool = column.fieldType == DataFieldType.boolean;
    final display = formatCellValue(column, value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  column.name,
                  style: AppTextStyles.footnote.copyWith(
                    color: c.labelSecondary,
                  ),
                ),
              ),
              if (column.isRequired)
                Text(
                  ' *',
                  style: AppTextStyles.footnote.copyWith(color: c.labelPrimary),
                ),
              if (error) ...[
                const Spacer(),
                Text(
                  context.strings.required,
                  style: AppTextStyles.caption.copyWith(color: c.labelPrimary),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          if (isBool)
            Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: c.fill1,
                borderRadius: AppRadii.brSm,
                border: error
                    ? Border.all(color: c.labelPrimary, width: 1)
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      (value ?? '') == 'true'
                          ? context.strings.yes
                          : context.strings.no,
                      style: AppTextStyles.body.copyWith(color: c.labelPrimary),
                    ),
                  ),
                  Switch(
                    value: (value ?? '') == 'true',
                    activeTrackColor: c.brand,
                    onChanged: onBoolChanged,
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: c.fill1,
                  borderRadius: AppRadii.brSm,
                  border: error
                      ? Border.all(color: c.labelPrimary, width: 1)
                      : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        display.isEmpty ? context.strings.notSet : display,
                        style: isNumericColumn(column)
                            ? tabularStyle(
                                AppTextStyles.body.copyWith(
                                  color: c.labelPrimary,
                                ),
                              )
                            : AppTextStyles.body.copyWith(
                                color: display.isEmpty
                                    ? c.labelTertiary
                                    : c.labelPrimary,
                              ),
                      ),
                    ),
                    Icon(
                      _editorIcon(column),
                      size: 16,
                      color: c.labelQuaternary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _editorIcon(DataColumnDef column) => switch (column.fieldType) {
    DataFieldType.number || DataFieldType.money => LucideIcons.hash,
    DataFieldType.date || DataFieldType.datetime => LucideIcons.calendarDays,
    DataFieldType.selection => LucideIcons.list,
    _ => LucideIcons.squarePen,
  };
}
