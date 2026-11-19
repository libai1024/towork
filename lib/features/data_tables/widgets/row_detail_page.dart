import '../../../app/business_ui_commands.dart';

import 'package:flutter/material.dart' hide DataRow;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/workspace_nav_bar.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../app/providers.dart';
import '../../../domain/models/models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_text_styles.dart';
import 'badges.dart';
import 'field_editors.dart';
import 'formatters.dart';
import 'repository_command.dart';
import 'history_sheet.dart';
import 'local_image_import_page.dart';
import '../../../app/local_workspace_session.dart';

/// 行详情页（07-data-tables.md §3.3）：全宽字段列表，点按单字段弹编辑器。
class RowDetailPage extends ConsumerWidget {
  const RowDetailPage({super.key, required this.tableId, required this.rowId});

  final String tableId;
  final String rowId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    ref.watch(dataTableProvider);
    final repo = ref.read(dataTableProvider.notifier);
    final table = repo.tableById(tableId);
    DataRow? row;
    for (final r in repo.rowsOf(tableId)) {
      if (r.id == rowId) row = r;
    }

    if (table == null || table.archived || row == null) {
      return Scaffold(
        backgroundColor: c.bgGround,
        body: SafeArea(
          child: AppEmptyState(
            icon: LucideIcons.fileQuestion,
            title: '这条记录已不存在',
            actionLabel: '返回数据表',
            onAction: () => context.popOrGo(AppRoutes.dataTable(tableId)),
          ),
        ),
      );
    }

    final firstField = table.columns.isEmpty ? null : table.columns.first.name;
    final title = row.values[firstField] ?? '记录详情';

    return Scaffold(
      backgroundColor: c.bgGround,
      body: SafeArea(
        child: Column(
          children: [
            WorkspaceNavBar(
              title: title,
              onBack: () => context.popOrGo(AppRoutes.dataTable(tableId)),
              actions: [
                WorkspaceToolbarGroup(
                  children: [
                    WorkspaceToolbarAction(
                      icon: LucideIcons.history,
                      label: '变更历史',
                      onTap: () =>
                          showRowHistorySheet(context, table: table, row: row!),
                    ),
                  ],
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: c.bgPrimary,
                      borderRadius: AppRadii.brLg,
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < table.columns.length; i++) ...[
                          if (i > 0)
                            Divider(
                              indent: 16,
                              height: 0.5,
                              thickness: 0.5,
                              color: c.separator,
                            ),
                          _FieldRow(
                            table: table,
                            row: row,
                            column: table.columns[i],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (ref.watch(localWorkspaceSessionProvider) != null)
                    RowImageSources(rowId: row.id),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '更新于 ${relativeTime(row.updatedAt)}',
                        style: AppTextStyles.caption.copyWith(
                          color: c.labelTertiary,
                        ),
                      ),
                      if (row.source == DataChangeSource.ai) ...[
                        const SizedBox(width: 6),
                        const AiBadge(),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldRow extends ConsumerWidget {
  const _FieldRow({
    required this.table,
    required this.row,
    required this.column,
  });

  final DataTableDef table;
  final DataRow row;
  final DataColumnDef column;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final raw = row.values[column.name] ?? '';
    final isBool = column.fieldType == DataFieldType.boolean;

    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          column.name,
          style: AppTextStyles.footnote.copyWith(color: c.labelSecondary),
        ),
        if (column.isRequired)
          Text(
            ' *',
            style: AppTextStyles.footnote.copyWith(color: c.labelPrimary),
          ),
      ],
    );

    if (isBool) {
      final value = raw == 'true';
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(child: label),
            Switch(
              value: value,
              activeTrackColor: c.brand,
              onChanged: (v) {
                runDataCommand(context, () async {
                  await ref
                      .read(businessUiCommandsProvider)
                      .updateCell(table, row, column.name, boolRaw(v));
                  if (!context.mounted) return;
                  HapticFeedback.lightImpact();
                  AppToast.show(context, message: '已保存');
                });
              },
            ),
          ],
        ),
      );
    }

    final display = formatCellValue(column, raw);
    return AppPressable(
      onTap: () => _edit(context, ref),
      borderRadius: AppRadii.brLg,
      semanticLabel: '编辑${column.name}',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(flex: 2, child: label),
            Expanded(
              flex: 3,
              child: Text(
                display.isEmpty ? '未填写' : display,
                style: isNumericColumn(column)
                    ? tabularStyle(
                        AppTextStyles.body.copyWith(color: c.labelPrimary),
                      )
                    : AppTextStyles.body.copyWith(
                        color: display.isEmpty
                            ? c.labelTertiary
                            : c.labelPrimary,
                      ),
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronRight, size: 16, color: c.labelQuaternary),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final result = await showFieldEditor(
      context,
      column: column,
      current: row.values[column.name],
      onSave: (value) => ref
          .read(businessUiCommandsProvider)
          .updateCell(table, row, column.name, value),
    );
    if (result == null || !context.mounted) return;
    if (result == (row.values[column.name] ?? '')) return;
    HapticFeedback.lightImpact();
    AppToast.show(context, message: '已保存');
  }
}
