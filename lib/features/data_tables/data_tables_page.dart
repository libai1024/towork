import '../../app/business_ui_commands.dart';
import '../../app/exports.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/glass_surface.dart';
import '../../core/widgets/workspace_bottom_bar.dart';
import '../../core/widgets/workspace_nav_bar.dart';
import '../../core/widgets/workspace_scope_rail.dart';
import '../../domain/models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_text_styles.dart';
import 'application/data_table_library.dart';
import 'data_table_export.dart';
import 'widgets/badges.dart';
import 'widgets/confirm_dialog.dart';
import 'widgets/data_table_type_sheet.dart';
import 'widgets/field_editors.dart';
import 'widgets/formatters.dart';
import 'widgets/new_table_sheet.dart';
import 'widgets/repository_command.dart';

/// A compact type index beside a live table library; controls float over content.
class DataTablesPage extends ConsumerStatefulWidget {
  const DataTablesPage({super.key});

  @override
  ConsumerState<DataTablesPage> createState() => _DataTablesPageState();
}

class _DataTablesPageState extends ConsumerState<DataTablesPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(dataTableLibraryFilterProvider).query,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createTable({DataTableTemplate? template}) async {
    final table = await showNewTableSheet(
      context,
      template: template,
      initialTypeId: ref.read(dataTableLibraryProvider).newTableTypeId,
    );
    if (table == null || !mounted) return;
    AppToast.show(context, message: '已创建「${table.name}」');
    context.push(AppRoutes.dataTable(table.id));
  }

  Future<void> _createType() async {
    final type = await showCreateDataTableTypeSheet(context);
    if (type == null || !mounted) return;
    ref.read(dataTableLibraryFilterProvider.notifier).selectType(type.id);
    _searchController.clear();
    ref.read(dataTableLibraryFilterProvider.notifier).search('');
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(dataTableLibraryFilterProvider.notifier).search('');
  }

  Future<void> _showTemplates() async {
    final template = await AppSheet.show<DataTableTemplate>(
      context,
      title: '从模板新建',
      child: Consumer(
        builder: (sheetContext, sheetRef, _) => ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            for (final template in sheetRef.watch(dataTableTemplatesProvider))
              AppPressable(
                semanticLabel: '从模板新建：${template.name}',
                borderRadius: AppRadii.brLg,
                onTap: () => Navigator.of(sheetContext).pop(template),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(tableIcon(template.iconKey), size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(template.name)),
                      Text(
                        '${template.columns.length} 字段',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.of(sheetContext).labelSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (template != null && mounted) await _createTable(template: template);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final library = ref.watch(dataTableLibraryProvider);
    final filter = ref.watch(dataTableLibraryFilterProvider);
    final controller = ref.read(dataTableLibraryFilterProvider.notifier);
    return Scaffold(
      backgroundColor: c.bgGround,
      body: SafeArea(
        child: Column(
          children: [
            WorkspaceNavBar(
              title: '核心数据',
              onBack: () =>
                  context.canPop() ? context.pop() : context.go(AppRoutes.home),
              actions: [
                GlassIconButton(
                  icon: LucideIcons.copy,
                  label: '从模板新建',
                  onTap: _showTemplates,
                ),
              ],
            ),
            Expanded(
              child: Stack(
                children: [
                  WorkspaceScopeLayout(
                    items: [
                      for (final type in library.types)
                        WorkspaceScopeItem(
                          id: type.id,
                          label: type.name,
                          count: type.count,
                        ),
                    ],
                    selectedId: library.selectedTypeId,
                    onSelected: controller.selectType,
                    onAdd: _createType,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                      children: [
                        SizedBox(
                          height: 36,
                          child: Row(
                            children: [
                              Text(
                                '${library.tables.length} 张表',
                                style: AppTextStyles.caption.copyWith(
                                  color: c.labelSecondary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '最近更新',
                                style: AppTextStyles.caption.copyWith(
                                  color: c.labelSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (library.tables.isEmpty)
                          SizedBox(
                            height: 240,
                            child: AppEmptyState(
                              icon: filter.query.isNotEmpty
                                  ? LucideIcons.search
                                  : LucideIcons.table,
                              title: filter.query.isNotEmpty
                                  ? '没有匹配的数据表'
                                  : '还没有数据表',
                              actionLabel: filter.query.isNotEmpty
                                  ? '清除搜索'
                                  : null,
                              onAction: filter.query.isNotEmpty
                                  ? _clearSearch
                                  : null,
                            ),
                          ),
                        for (var i = 0; i < library.tables.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              thickness: .5,
                              color: c.separator,
                            ),
                          _TableListTile(summary: library.tables[i]),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: WorkspaceBottomBar(
                      searchController: _searchController,
                      onSearchChanged: controller.search,
                      onClear: _clearSearch,
                      onAdd: () => _createTable(),
                      addLabel: '新建表',
                      hint: '搜索数据表',
                    ),
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

class _TableListTile extends ConsumerWidget {
  const _TableListTile({required this.summary});

  final DataTableSummary summary;
  DataTableDef get table => summary.table;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final pending = summary.pendingCount;
    final lastUpdate = summary.updatedAt;
    final sub =
        '${table.columns.length} 字段 ${summary.rowCount} 行 ${relativeTime(lastUpdate)}';

    return AppPressable(
      onTap: () => context.push(AppRoutes.dataTable(table.id)),
      onLongPress: () => _showContextSheet(context, ref),
      borderRadius: AppRadii.brLg,
      semanticLabel: pending > 0
          ? '${table.name}，${table.columns.length} 字段 ${summary.rowCount} 行，有 $pending 处 AI 待确认变更'
          : '${table.name}，${table.columns.length} 字段 ${summary.rowCount} 行',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 50),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
          child: Row(
            children: [
              Icon(tableIcon(table.iconKey), size: 20, color: c.labelSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      table.name,
                      style: AppTextStyles.body.copyWith(
                        color: c.labelPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: AppTextStyles.caption.copyWith(
                        color: c.labelSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (pending > 0) ...[
                AiBadge(count: pending),
                const SizedBox(width: 6),
              ],
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: c.labelQuaternary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportTable(
    DataTableDef table,
    WidgetRef ref,
    BuildContext context,
  ) async {
    try {
      final directory = await ref.read(exportsDirectoryProvider.future);
      final file = await exportDataTableCsv(
        table: table,
        rows: ref.read(dataTableProvider.notifier).rowsOf(table.id),
        directory: directory,
      );
      if (context.mounted) {
        AppToast.show(
          context,
          message: '已导出 CSV ${file.uri.pathSegments.last}',
        );
      }
    } catch (_) {
      if (context.mounted) AppToast.show(context, message: '导出失败，请重试');
    }
  }

  void _showContextSheet(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    AppSheet.show<void>(
      context,
      title: table.name,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetAction(
            icon: LucideIcons.pencil,
            label: '重命名',
            onTap: () async {
              Navigator.of(context).pop();
              await _rename(context, ref);
            },
          ),
          _SheetAction(
            icon: LucideIcons.folder,
            label: '修改类型',
            onTap: () async {
              Navigator.of(context).pop();
              final selected = await showDataTableTypePicker(
                context,
                selectedId: table.typeId,
              );
              if (selected == null || !context.mounted) return;
              await runDataCommand(
                context,
                () => ref
                    .read(businessUiCommandsProvider)
                    .assignType(table, selected.id),
              );
            },
          ),
          _SheetAction(
            icon: LucideIcons.copy,
            label: '复制表结构',
            onTap: () {
              runDataCommand(context, () async {
                final copy = await ref
                    .read(businessUiCommandsProvider)
                    .createTable(
                      name: '${table.name} 副本',
                      iconKey: table.iconKey,
                      description: table.description,
                      columns: table.columns,
                      typeId: table.typeId,
                    );
                if (!context.mounted) return;
                Navigator.of(context).pop();
                AppToast.show(context, message: '已复制出「${copy.name}」');
              });
            },
          ),
          _SheetAction(
            icon: LucideIcons.upload,
            label: '导出 CSV',
            onTap: () {
              Navigator.of(context).pop();
              _exportTable(table, ref, context);
            },
          ),
          _SheetAction(
            icon: LucideIcons.archive,
            label: '归档',
            color: c.labelPrimary,
            onTap: () async {
              Navigator.of(context).pop();
              final confirmed = await showAppConfirmDialog(
                context,
                title: '归档这张表？',
                message: '归档后不在列表显示，数据仍保留。删除需先进归档。',
                confirmLabel: '归档',
                destructive: true,
              );
              if (!confirmed || !context.mounted) return;
              await runDataCommand(context, () async {
                await ref.read(businessUiCommandsProvider).archiveTable(table);
                if (!context.mounted) return;
                AppToast.show(context, message: '已归档「${table.name}」');
              });
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final name = await showFieldEditor(
      context,
      column: DataColumnDef(name: '重命名', type: 'text'),
      current: table.name,
      onSave: (value) =>
          ref.read(businessUiCommandsProvider).renameTable(table, value),
    );
    if (name != null && name != table.name && context.mounted) {
      AppToast.show(context, message: '已重命名为「$name」');
    }
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fg = color ?? c.labelPrimary;
    return AppPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? c.labelSecondary),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.body.copyWith(color: fg)),
          ],
        ),
      ),
    );
  }
}
