import 'package:towork/l10n/strings.dart';

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
    AppToast.show(
      context,
      message: context.strings.createdCreatetable(table.name),
    );
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
      title: context.strings.createFromTemplate,
      child: Consumer(
        builder: (sheetContext, sheetRef, _) => ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            for (final template in sheetRef.watch(dataTableTemplatesProvider))
              AppPressable(
                semanticLabel: context.strings.createFromTemplateShowtemplates(
                  template.name,
                ),
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
                        context.strings.fields(template.columns.length),
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
              title: context.strings.dataTables,
              onBack: () =>
                  context.canPop() ? context.pop() : context.go(AppRoutes.home),
              actions: [
                GlassIconButton(
                  icon: LucideIcons.copy,
                  label: context.strings.createFromTemplate,
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
                                context.strings.tables(library.tables.length),
                                style: AppTextStyles.caption.copyWith(
                                  color: c.labelSecondary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                context.strings.recentlyUpdated,
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
                                  ? context.strings.noMatchingTables
                                  : context.strings.noTablesYet,
                              actionLabel: filter.query.isNotEmpty
                                  ? context.strings.clearSearch
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
                      addLabel: context.strings.newTable,
                      hint: context.strings.searchTables,
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
    final sub = context.strings.fieldsRows(
      table.columns.length,
      summary.rowCount,
      relativeTime(lastUpdate),
    );

    return AppPressable(
      onTap: () => context.push(AppRoutes.dataTable(table.id)),
      onLongPress: () => _showContextSheet(context, ref),
      borderRadius: AppRadii.brLg,
      semanticLabel: pending > 0
          ? context.strings.fieldsRowsAiChangesToReview(
              table.name,
              table.columns.length,
              summary.rowCount,
              pending,
            )
          : context.strings.fieldsRowsBuild(
              table.name,
              table.columns.length,
              summary.rowCount,
            ),
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
          message: context.strings.csvExported(file.uri.pathSegments.last),
        );
      }
    } catch (_) {
      if (context.mounted) {
        AppToast.show(context, message: context.strings.exportFailedTryAgain);
      }
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
            label: context.strings.rename,
            onTap: () async {
              Navigator.of(context).pop();
              await _rename(context, ref);
            },
          ),
          _SheetAction(
            icon: LucideIcons.folder,
            label: context.strings.changeType,
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
            label: context.strings.copyTableStructure,
            onTap: () {
              runDataCommand(context, () async {
                final copy = await ref
                    .read(businessUiCommandsProvider)
                    .createTable(
                      name: context.strings.copy(table.name),
                      iconKey: table.iconKey,
                      description: table.description,
                      columns: table.columns,
                      typeId: table.typeId,
                    );
                if (!context.mounted) return;
                Navigator.of(context).pop();
                AppToast.show(
                  context,
                  message: context.strings.createdCopy(copy.name),
                );
              });
            },
          ),
          _SheetAction(
            icon: LucideIcons.upload,
            label: context.strings.exportCsv,
            onTap: () {
              Navigator.of(context).pop();
              _exportTable(table, ref, context);
            },
          ),
          _SheetAction(
            icon: LucideIcons.archive,
            label: context.strings.archive,
            color: c.labelPrimary,
            onTap: () async {
              Navigator.of(context).pop();
              final confirmed = await showAppConfirmDialog(
                context,
                title: context.strings.archiveThisTable,
                message: context.strings.archivedTablesAreHiddenArchiveATable,
                confirmLabel: context.strings.archive,
                destructive: true,
              );
              if (!confirmed || !context.mounted) return;
              await runDataCommand(context, () async {
                await ref.read(businessUiCommandsProvider).archiveTable(table);
                if (!context.mounted) return;
                AppToast.show(
                  context,
                  message: context.strings.archivedShowcontextsheet(table.name),
                );
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
      column: DataColumnDef(name: context.strings.rename, type: 'text'),
      current: table.name,
      onSave: (value) =>
          ref.read(businessUiCommandsProvider).renameTable(table, value),
    );
    if (name != null && name != table.name && context.mounted) {
      AppToast.show(context, message: context.strings.renamedTo(name));
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
