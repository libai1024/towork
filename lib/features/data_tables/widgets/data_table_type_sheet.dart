import '../../../app/business_ui_commands.dart';
import 'repository_command.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/providers.dart' show dataTableProvider;
import '../../../core/widgets/sheet_composer.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../domain/models/data_table.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_text_styles.dart';

Future<DataTableType?> showCreateDataTableTypeSheet(BuildContext context) {
  return AppSheet.show<DataTableType>(context, child: const _CreateTypeSheet());
}

class _CreateTypeSheet extends ConsumerStatefulWidget {
  const _CreateTypeSheet();

  @override
  ConsumerState<_CreateTypeSheet> createState() => _CreateTypeSheetState();
}

class _CreateTypeSheetState extends ConsumerState<_CreateTypeSheet> {
  final _name = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await runDataCommand(context, () async {
      final type = await ref
          .read(businessUiCommandsProvider)
          .createType(_name.text);
      if (mounted) Navigator.of(context).pop(type);
    });
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return SheetComposer(
      title: '新增类型',
      hint: '类型名称',
      action: '创建',
      controller: _name,
      maxLength: 24,
      maxLines: 1,
      saving: _saving,
      onChanged: (_) => setState(() {}),
      onCommit: _save,
    );
  }
}

/// A wrapper distinguishes choosing unassigned from dismissing the picker.
class DataTableTypeSelection {
  const DataTableTypeSelection(this.id);
  final String? id;
}

Future<DataTableTypeSelection?> showDataTableTypePicker(
  BuildContext context, {
  String? selectedId,
}) {
  return AppSheet.show<DataTableTypeSelection>(
    context,
    title: '类型',
    child: _TypePicker(selectedId: selectedId),
  );
}

class _TypePicker extends ConsumerWidget {
  const _TypePicker({this.selectedId});
  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final types = ref.watch(dataTableProvider.select((bundle) => bundle.types));
    final c = AppColors.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .6,
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          for (final (id, name) in [
            (null, '未分类'),
            ...types.map((type) => (type.id, type.name)),
          ])
            AppPressable(
              semanticLabel: '选择类型$name',
              onTap: () =>
                  Navigator.of(context).pop(DataTableTypeSelection(id)),
              borderRadius: AppRadii.brLg,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 13,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: AppTextStyles.body.copyWith(
                          color: c.labelPrimary,
                        ),
                      ),
                    ),
                    if (id == selectedId)
                      Icon(LucideIcons.check, size: 18, color: c.labelPrimary),
                  ],
                ),
              ),
            ),
          AppPressable(
            semanticLabel: '新增类型',
            onTap: () async {
              final type = await showCreateDataTableTypeSheet(context);
              if (type != null && context.mounted) {
                Navigator.of(context).pop(DataTableTypeSelection(type.id));
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              child: Row(
                children: [
                  Icon(LucideIcons.plus, size: 18, color: c.labelSecondary),
                  const SizedBox(width: 10),
                  Text(
                    '新增类型',
                    style: AppTextStyles.body.copyWith(color: c.labelPrimary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DataTableTypeField extends ConsumerWidget {
  const DataTableTypeField({super.key, this.value, required this.onChanged});
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final types = ref.watch(dataTableProvider.select((bundle) => bundle.types));
    final name =
        types.where((type) => type.id == value).firstOrNull?.name ?? '未分类';
    final c = AppColors.of(context);
    return AppPressable(
      semanticLabel: '类型：$name',
      onTap: () async {
        final selected = await showDataTableTypePicker(
          context,
          selectedId: value,
        );
        if (selected != null && context.mounted) onChanged(selected.id);
      },
      borderRadius: AppRadii.brLg,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(color: c.fill1, borderRadius: AppRadii.brLg),
        child: Row(
          children: [
            Text(
              '类型',
              style: AppTextStyles.body.copyWith(color: c.labelSecondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(color: c.labelPrimary),
              ),
            ),
            const SizedBox(width: 6),
            Icon(LucideIcons.chevronRight, size: 16, color: c.labelSecondary),
          ],
        ),
      ),
    );
  }
}
