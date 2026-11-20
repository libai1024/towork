import 'package:towork/l10n/strings.dart';

import '../../app/business_row_search_provider.dart';
import '../../app/business_ui_commands.dart';
import '../../app/exports.dart';
import '../../app/local_workspace_session.dart';
import '../../app/routes.dart';

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide DataRow;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/workspace_nav_bar.dart';
import '../../app/providers.dart';
import '../../domain/models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/add_row_sheet.dart';
import 'application/ai_write_policy.dart';
import 'widgets/ai_confirm_sheet.dart';
import 'widgets/ai_write_feedback.dart';
import 'widgets/badges.dart';
import 'widgets/confirm_dialog.dart';
import 'widgets/field_management_sheet.dart';
import 'widgets/formatters.dart';
import 'widgets/field_editors.dart';
import 'widgets/repository_command.dart';
import 'widgets/history_sheet.dart';
import 'widgets/row_filter_sheet.dart';
import 'widgets/screenshot_flow_page.dart';
import 'widgets/data_table_type_sheet.dart';
import 'data_table_export.dart';

part 'data_table_record_card.dart';

/// 表格视图页（07-data-tables.md §3.2，移动端 = 卡片式记录流）。
class DataTableDetailPage extends ConsumerStatefulWidget {
  const DataTableDetailPage({super.key, required this.tableId});

  final String tableId;

  @override
  ConsumerState<DataTableDetailPage> createState() =>
      _DataTableDetailPageState();
}

enum _SortMode { recent, firstAsc, firstDesc }

enum _SourceFilter { all, manual, ai }

class _DataTableDetailPageState extends ConsumerState<DataTableDetailPage> {
  final _searchController = TextEditingController();
  final Set<String> _highlighted = {};
  final List<Timer> _timers = [];

  String _query = '';
  _SortMode _sort = _SortMode.recent;
  _SourceFilter _filter = _SourceFilter.all;
  bool _pushShown = false;

  // SQL 结果模式（已应用行筛选条件时启用）。
  List<RowFilterCondition> _filters = const [];
  bool _searching = false;
  List<Map<String, Object?>> _sqlItems = const [];
  int _sqlTotal = 0;
  String? _sqlNextToken;
  String? _sqlStamp;
  int _sqlSeq = 0;

  @override
  void initState() {
    super.initState();
    // 模拟收到 AI 批次：700ms 后按当前权限分配自动写入和人工确认。
    _timers.add(
      Timer(const Duration(milliseconds: 700), () {
        if (!mounted || _pushShown) return;
        // A row deep link also builds this parent offstage. Do not cover its
        // active child with the parent's simulated update dialog.
        if (ModalRoute.of(context)?.isCurrent != true) return;
        final repo = ref.read(dataTableProvider.notifier);
        final batches = repo.batchesOf(widget.tableId);
        if (batches.isEmpty) return;
        _pushShown = true;
        _receiveAiBatch(batches.first);
      }),
    );
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _searchController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // AI 写入确认
  // -------------------------------------------------------------------------

  void _receiveAiBatch(PendingAiBatch batch) {
    AiWriteResult? result;
    final repo = ref.read(dataTableProvider.notifier);
    final policy = ref.read(dataTableAiPolicyProvider);
    final succeeded = runRepositoryCommand(context, () {
      result = policy.receive(batch.id, ref.read(aiWritePermissionProvider));
    });
    if (!succeeded) {
      // A rejected automatic write leaves the whole proposed subset pending.
      _openConfirmSheet(batch);
      return;
    }
    if (result!.hasWrites) {
      HapticFeedback.mediumImpact();
      _highlight(result!.affectedRowIds);
      showAiWriteFeedback(context, repo, result!);
    }
    final pending = result!.pendingBatch;
    if (pending != null) _openConfirmSheet(pending);
  }

  void _openConfirmSheet(PendingAiBatch batch) {
    final repo = ref.read(dataTableProvider.notifier);
    final table = repo.tableById(widget.tableId);
    if (table == null) return;
    // Explicit review and unselected changes never become background writes.
    ref.read(dataTableAiPolicyProvider).requireReview(batch.id);
    AppSheet.show<void>(
      context,
      child: AiConfirmSheet(
        table: table,
        batch: batch,
        onApply: (ids) {
          final affected = repo.applyPendingBatch(batch.id, ids);
          if (affected.isEmpty) return;
          HapticFeedback.mediumImpact();
          _highlight(affected);
          showAiWriteFeedback(
            context,
            repo,
            AiWriteResult(
              affectedRowIds: affected,
              appliedChanges: batch.changes
                  .where((change) => ids.contains(change.id))
                  .toList(),
            ),
          );
        },
        onDiscard: () {
          repo.discardPendingBatch(batch.id);
          AppToast.show(context, message: context.strings.analysisDiscarded);
        },
      ),
    );
  }

  void _highlight(List<String> rowIds) {
    setState(() => _highlighted.addAll(rowIds));
    _timers.add(
      Timer(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _highlighted.removeAll(rowIds));
      }),
    );
  }

  // -------------------------------------------------------------------------
  // 截图导入 / 新增行 / 表设置
  // -------------------------------------------------------------------------

  void _openCameraActions() {
    if (ref.read(localWorkspaceSessionProvider) != null) {
      _openScreenshotFlow();
      return;
    }
    final c = AppColors.of(context);
    AppSheet.show<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (icon, label) in [
            (LucideIcons.camera, context.strings.takePhoto),
            (LucideIcons.images, context.strings.chooseFromPhotos),
          ])
            AppPressable(
              onTap: () {
                Navigator.of(context).pop();
                _openScreenshotFlow();
              },
              semanticLabel: label,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 20, color: c.labelSecondary),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: AppTextStyles.body.copyWith(color: c.labelPrimary),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _openScreenshotFlow() async {
    final result = await Navigator.of(context).push<AiWriteResult>(
      MaterialPageRoute(
        builder: (_) => ScreenshotFlowPage(tableId: widget.tableId),
        fullscreenDialog: true,
      ),
    );
    if (result == null || !result.hasWrites || !mounted) return;
    HapticFeedback.mediumImpact();
    _highlight(result.affectedRowIds);
    showAiWriteFeedback(context, ref.read(dataTableProvider.notifier), result);
  }

  Future<void> _openAddRow(DataTableDef table) async {
    final row = await showAddRowSheet(context, table);
    if (row == null || !mounted) return;
    _highlight([row.id]);
    AppToast.show(context, message: context.strings.rowAdded);
  }

  /// 导出 CSV：表头 + 全部行（按更新时间升序）；带 BOM 便于 Excel 直接打开。
  Future<void> _exportCsv(DataTableDef table) async {
    try {
      final rows =
          ref.read(dataTableProvider.notifier).rowsOf(table.id).toList()
            ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      final directory = await ref.read(exportsDirectoryProvider.future);
      final file = await exportDataTableCsv(
        table: table,
        rows: rows,
        directory: directory,
      );
      if (!mounted) return;
      AppToast.show(
        context,
        message: context.strings.exportedRowsTo(
          rows.length,
          file.uri.pathSegments.last,
        ),
      );
    } catch (_) {
      if (mounted) {
        AppToast.show(context, message: context.strings.exportFailedTryAgain);
      }
    }
  }

  void _openTableSettings(DataTableDef table) {
    final c = AppColors.of(context);
    AppSheet.show<void>(
      context,
      title: table.name,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _settingsAction(
            c,
            LucideIcons.pencil,
            context.strings.rename,
            () async {
              Navigator.of(context).pop();
              await _renameTable(table);
            },
          ),
          _settingsAction(
            c,
            LucideIcons.folder,
            context.strings.changeType,
            () async {
              Navigator.of(context).pop();
              final selected = await showDataTableTypePicker(
                context,
                selectedId: table.typeId,
              );
              if (selected == null || !mounted) return;
              await runDataCommand(
                context,
                () => ref
                    .read(businessUiCommandsProvider)
                    .assignType(table, selected.id),
              );
            },
          ),
          _settingsAction(
            c,
            LucideIcons.listTree,
            context.strings.manageFields,
            () {
              Navigator.of(context).pop();
              showFieldManagementSheet(context, ref, table);
            },
          ),
          _settingsAction(c, LucideIcons.upload, context.strings.exportCsv, () {
            Navigator.of(context).pop();
            _exportCsv(table);
          }),
          _settingsAction(
            c,
            LucideIcons.archive,
            context.strings.archive,
            color: c.labelPrimary,
            () async {
              Navigator.of(context).pop();
              final confirmed = await showAppConfirmDialog(
                context,
                title: context.strings.archiveThisTable,
                message: context.strings.archivedTablesAreHiddenFromTheList,
                confirmLabel: context.strings.archive,
                destructive: true,
              );
              if (!confirmed || !mounted) return;
              await runDataCommand(context, () async {
                await ref.read(businessUiCommandsProvider).archiveTable(table);
                if (!mounted) return;
                context.pop();
              });
            },
          ),
          _settingsAction(
            c,
            LucideIcons.trash2,
            context.strings.deleteTable,
            color: c.red,
            () async {
              Navigator.of(context).pop();
              final rowCount = ref
                  .read(dataTableProvider.notifier)
                  .rowsOf(table.id)
                  .length;
              final confirmed = await showAppConfirmDialog(
                context,
                title: context.strings.deleteThisTable,
                message: rowCount == 0
                    ? context.strings.youCanUndoTheDeletion
                    : context.strings.alsoDeletesRowsYouCanUndoThe(rowCount),
                confirmLabel: context.strings.deleteLabel,
                destructive: true,
              );
              if (!confirmed || !mounted) return;
              // Stay on this page: it turns into an empty state after the
              // delete, and the undo toast can restore it in place.
              await runDataCommand(context, () async {
                final change = await ref
                    .read(businessUiCommandsProvider)
                    .deleteTable(table);
                if (!mounted) return;
                AppToast.show(
                  context,
                  message: context.strings.deletedEditcategory(table.name),
                  actionLabel: context.strings.undo,
                  onAction: () => runDataCommand(context, change.undo),
                );
              });
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _settingsAction(
    AppColors c,
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return AppPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? c.labelSecondary),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: color ?? c.labelPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _renameTable(DataTableDef table) async {
    final name = await showFieldEditor(
      context,
      column: DataColumnDef(name: context.strings.rename, type: 'text'),
      current: table.name,
      onSave: (value) =>
          ref.read(businessUiCommandsProvider).renameTable(table, value),
    );
    if (name != null && name != table.name && mounted) {
      AppToast.show(context, message: context.strings.renamedTo(name));
    }
  }

  // -------------------------------------------------------------------------
  // 筛选 / 排序
  // -------------------------------------------------------------------------

  /// 来源筛选只作用于内存投影列表，SQL 条件模式下不生效。
  void _openSourceSheet() {
    AppSheet.show<void>(
      context,
      title: context.strings.source,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (mode, label) in [
            (_SourceFilter.all, context.strings.allLabel),
            (_SourceFilter.manual, context.strings.addedByMe),
            (_SourceFilter.ai, context.strings.addedByAi),
          ])
            _optionRow(label, _filter == mode, () {
              setState(() => _filter = mode);
              Navigator.of(context).pop();
            }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _openRowFilterSheet(DataTableDef table) {
    showRowFilterSheet(
      context,
      table: table,
      initialConditions: _filters,
      onApply: _applyRowFilters,
    );
  }

  void _applyRowFilters(List<RowFilterCondition> conditions) {
    setState(() {
      _filters = List.unmodifiable(conditions);
      if (conditions.isNotEmpty) {
        // 条件走 SQL 查询，来源筛选不可组合，重置为全部。
        _filter = _SourceFilter.all;
      } else {
        _resetSqlState();
      }
    });
    if (conditions.isNotEmpty) {
      _refreshSqlResults();
    }
  }

  void _clearRowFilters() {
    setState(() {
      _filters = const [];
      _resetSqlState();
    });
  }

  void _resetSqlState() {
    _sqlItems = const [];
    _sqlTotal = 0;
    _sqlNextToken = null;
    _sqlStamp = null;
    _sqlSeq++;
  }

  void _openSortSheet() {
    AppSheet.show<void>(
      context,
      title: context.strings.reorder,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (mode, label) in [
            (_SortMode.recent, context.strings.recentlyUpdatedFirst),
            (_SortMode.firstAsc, context.strings.firstFieldAZ),
            (_SortMode.firstDesc, context.strings.firstFieldZA),
          ])
            _optionRow(label, _sort == mode, () {
              setState(() => _sort = mode);
              Navigator.of(context).pop();
              // SQL 模式下排序映射为首字段升/降序；recent 用查询默认顺序。
              if (_filters.isNotEmpty) {
                _refreshSqlResults();
              }
            }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _optionRow(String label, bool selected, VoidCallback onTap) {
    final c = AppColors.of(context);
    return AppPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: c.labelPrimary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (selected) Icon(LucideIcons.check, size: 18, color: c.brand),
          ],
        ),
      ),
    );
  }

  List<DataRow> _visibleRows(DataTableStore repo, DataTableDef table) {
    var rows = repo.rowsOf(table.id);
    if (_query.isNotEmpty) {
      rows = rows
          .where(
            (r) => r.values.values.any((v) => v.toLowerCase().contains(_query)),
          )
          .toList();
    }
    if (_filter != _SourceFilter.all) {
      final source = _filter == _SourceFilter.ai
          ? DataChangeSource.ai
          : DataChangeSource.manual;
      rows = rows.where((r) => r.source == source).toList();
    }
    if (_sort != _SortMode.recent && table.columns.isNotEmpty) {
      final first = table.columns.first.name;
      rows.sort(
        (a, b) => _sort == _SortMode.firstAsc
            ? (a.values[first] ?? '').compareTo(b.values[first] ?? '')
            : (b.values[first] ?? '').compareTo(a.values[first] ?? ''),
      );
    }
    return rows;
  }

  // -------------------------------------------------------------------------
  // SQL 结果模式（businessRowSearchProvider）
  // -------------------------------------------------------------------------

  BusinessRowSearch? _currentSearch() {
    if (ref.read(localWorkspaceSessionProvider) == null) return null;
    return ref.read(businessRowSearchProvider).valueOrNull;
  }

  Map<String, Object?> _buildSearchArgs(
    DataTableDef table, {
    String? pageToken,
  }) {
    final fieldIds = [
      for (final column in table.columns)
        if (column.id != null) column.id!,
    ].take(8).toList();
    final firstId = _sort == _SortMode.recent || table.columns.isEmpty
        ? null
        : table.columns.first.id;
    return {
      'table_id': table.id,
      if (fieldIds.isNotEmpty) 'field_ids': fieldIds,
      if (_filters.isNotEmpty)
        'filters': [
          for (final filter in _filters)
            {
              'field_id': filter.fieldId,
              'op': filter.op,
              'value': filter.value,
            },
        ],
      if (_query.isNotEmpty) 'query': _query,
      if (firstId != null) ...{
        'sort_field_id': firstId,
        'sort_desc': _sort == _SortMode.firstDesc,
      },
      'limit': 20,
      'page_token': ?pageToken,
    };
  }

  Future<void> _refreshSqlResults() async {
    if (_filters.isEmpty || _searching) return;
    final search = _currentSearch();
    if (search == null) return;
    final table = ref
        .read(dataTableProvider.notifier)
        .tableById(widget.tableId);
    if (table == null) return;
    final seq = ++_sqlSeq;
    setState(() => _searching = true);
    await runDataCommand(context, () async {
      final result = await search.rows(_buildSearchArgs(table));
      if (!mounted || seq != _sqlSeq) return;
      _applySqlResult(result);
    });
    if (!mounted) return;
    if (seq == _sqlSeq) setState(() => _searching = false);
  }

  Future<void> _loadMoreSqlResults() async {
    if (_searching || _sqlNextToken == null) return;
    final search = _currentSearch();
    if (search == null) return;
    final table = ref
        .read(dataTableProvider.notifier)
        .tableById(widget.tableId);
    if (table == null) return;
    final seq = ++_sqlSeq;
    setState(() => _searching = true);
    await runDataCommand(context, () async {
      final result = await search.rows(
        _buildSearchArgs(table, pageToken: _sqlNextToken),
      );
      if (!mounted || seq != _sqlSeq) return;
      if (result['error'] == 'cursor_stale') {
        // 数据在翻页间隙变化：静默重置到第一页重查一次。
        final fresh = await search.rows(_buildSearchArgs(table));
        if (!mounted || seq != _sqlSeq) return;
        _applySqlResult(fresh);
        return;
      }
      final items = (result['items'] as List).cast<Map<String, Object?>>();
      setState(() {
        _sqlItems = [..._sqlItems, ...items];
        _sqlTotal = result['total'] as int? ?? _sqlTotal;
        _sqlNextToken = result['next_page_token'] as String?;
      });
    });
    if (!mounted) return;
    if (seq == _sqlSeq) setState(() => _searching = false);
  }

  void _applySqlResult(Map<String, Object?> result) {
    setState(() {
      _sqlItems = (result['items'] as List)
          .cast<Map<String, Object?>>()
          .toList();
      _sqlTotal = result['total'] as int? ?? 0;
      _sqlNextToken = result['next_page_token'] as String?;
    });
  }

  /// SQL 预览值（字段 ID → 原始值）转展示值（列名 → 字符串），
  /// bool 用 'true'/'false' 以复用 formatCellValue。
  Map<String, String> _sqlDisplayValues(
    DataTableDef table,
    Map<String, Object?> values,
  ) => {
    for (final column in table.columns)
      if (column.id != null && values[column.id] != null)
        column.name: values[column.id!] is bool
            ? boolRaw(values[column.id!] as bool)
            : values[column.id!].toString(),
  };

  Widget _buildSqlBody(AppColors c, DataTableDef table) {
    if (_searching && _sqlItems.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_sqlItems.isEmpty) {
      return AppEmptyState(
        icon: LucideIcons.search,
        title: _query.isEmpty
            ? context.strings.noMatchingRecords
            : context.strings.noResultsFor(_query),
        message: context.strings.adjustTheFiltersOrTryAnotherKeyword,
        actionLabel: context.strings.clearFilters,
        onAction: _clearRowFilters,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      itemCount: _sqlItems.length + 2,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              context.strings.results(_sqlTotal),
              style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
            ),
          );
        }
        if (i == _sqlItems.length + 1) {
          if (_sqlNextToken == null) return const SizedBox(height: 4);
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: AppButton(
              label: context.strings.loadMore,
              type: AppButtonType.secondary,
              expand: true,
              loading: _searching,
              onPressed: _loadMoreSqlResults,
            ),
          );
        }
        final item = _sqlItems[i - 1];
        final rowId = item['id'] as String;
        return _RecordCard(
          table: table,
          values: _sqlDisplayValues(
            table,
            (item['values'] as Map).cast<String, Object?>(),
          ),
          highlighted: _highlighted.contains(rowId),
          fromAi: item['source'] == 'ai',
          onTap: () => context.push(AppRoutes.dataRow(table.id, rowId)),
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // 构建
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    ref.watch(dataTableProvider);
    final repo = ref.read(dataTableProvider.notifier);
    final table = repo.tableById(widget.tableId);

    if (table == null || table.archived) {
      return Scaffold(
        backgroundColor: c.bgGround,
        body: SafeArea(
          child: Column(
            children: [
              WorkspaceNavBar(
                title: context.strings.data,
                onBack: () => context.popOrGo(AppRoutes.dataTables),
              ),
              Expanded(
                child: AppEmptyState(
                  icon: LucideIcons.table,
                  title: context.strings.tableUnavailable,
                  message: context.strings.itMayHaveBeenArchivedOrDeleted,
                  actionLabel: context.strings.backToList,
                  onAction: () => context.popOrGo(AppRoutes.dataTables),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final allRows = repo.rowsOf(table.id);
    final rows = _visibleRows(repo, table);
    final pending = repo.pendingCountOf(table.id);

    // SQL 结果模式：已应用行筛选条件。演示模式（无本地库）不进入。
    final session = ref.watch(localWorkspaceSessionProvider);
    // 条件监视：演示模式短路，不触发 localDatabaseProvider（测试环境无插件）。
    final sqlCapable =
        session != null &&
        ref.watch(businessRowSearchProvider).valueOrNull != null;
    final sqlMode = _filters.isNotEmpty;
    if (sqlMode) {
      // 数据变化（增删改、AI 写入）后自动重查第一页。
      final stamp =
          '${table.version}:'
          '${allRows.length}:'
          '${allRows.fold<int>(0, (sum, row) => sum + row.version)}';
      if (stamp != _sqlStamp) {
        _sqlStamp = stamp;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _filters.isNotEmpty && !_searching) {
            _refreshSqlResults();
          }
        });
      }
    }

    return Scaffold(
      backgroundColor: c.bgGround,
      body: SafeArea(
        child: Column(
          children: [
            WorkspaceNavBar(
              title: table.name,
              onBack: () => context.popOrGo(AppRoutes.dataTables),
              actions: [
                WorkspaceToolbarGroup(
                  children: [
                    WorkspaceToolbarAction(
                      icon: LucideIcons.moreHorizontal,
                      label: context.strings.tableSettings,
                      onTap: () => _openTableSettings(table),
                    ),
                    WorkspaceToolbarAction(
                      icon: LucideIcons.camera,
                      label: context.strings.importScreenshot,
                      onTap: _openCameraActions,
                    ),
                    WorkspaceToolbarAction(
                      icon: LucideIcons.plus,
                      label: context.strings.newRow,
                      onTap: () => _openAddRow(table),
                    ),
                  ],
                ),
              ],
            ),
            Expanded(
              child: sqlMode
                  ? _buildSqlBody(c, table)
                  : _buildBody(c, table, rows, allRows.length),
            ),
            // 状态条为待确认入口保留 44 点触控区。
            Container(
              height: pending > 0 ? 44 : 24,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    context.strings.rows(allRows.length),
                    style: AppTextStyles.caption.copyWith(
                      color: c.labelTertiary,
                    ),
                  ),
                  const Spacer(),
                  if (pending > 0)
                    AppPressable(
                      onTap: () {
                        final batches = repo.batchesOf(table.id);
                        if (batches.isNotEmpty) {
                          _openConfirmSheet(batches.first);
                        }
                      },

                      behavior: HitTestBehavior.translucent,
                      semanticLabel: context.strings.aiChangesAwaitingReview,
                      child: PendingBadge(count: pending),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: WorkspaceSearchField(
                      controller: _searchController,
                      hint: context.strings.searchRows,
                      onChanged: (value) {
                        setState(() => _query = value.trim().toLowerCase());
                        if (_filters.isNotEmpty) _refreshSqlResults();
                      },
                      onClear: () {
                        _searchController.clear();
                        setState(() => _query = '');
                        if (_filters.isNotEmpty) _refreshSqlResults();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  WorkspaceToolbarGroup(
                    children: [
                      if (!sqlMode)
                        WorkspaceToolbarAction(
                          icon: LucideIcons.slidersHorizontal,
                          label: context.strings.source,
                          active: _filter != _SourceFilter.all,
                          onTap: _openSourceSheet,
                        ),
                      if (sqlCapable)
                        WorkspaceToolbarAction(
                          icon: LucideIcons.filter,
                          label: context.strings.filter,
                          active: sqlMode,
                          onTap: () => _openRowFilterSheet(table),
                        ),
                      WorkspaceToolbarAction(
                        icon: LucideIcons.arrowUpDown,
                        label: context.strings.reorder,
                        active: _sort != _SortMode.recent,
                        onTap: _openSortSheet,
                      ),
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

  Widget _buildBody(
    AppColors c,
    DataTableDef table,
    List<DataRow> rows,
    int total,
  ) {
    if (total == 0) {
      return AppEmptyState(
        icon: LucideIcons.table,
        title: context.strings.noDataYet,
        actionLabel: context.strings.createARow,
        onAction: () => _openAddRow(table),
      );
    }
    if (rows.isEmpty) {
      return AppEmptyState(
        icon: LucideIcons.search,
        title: context.strings.noResultsFor(_query),
        actionLabel: context.strings.clearSearch,
        onAction: () {
          _searchController.clear();
          setState(() {
            _query = '';
            _filter = _SourceFilter.all;
          });
        },
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      itemCount: rows.length,
      itemBuilder: (context, i) {
        final row = rows[i];
        return _RecordCard(
          table: table,
          values: row.values,
          highlighted: _highlighted.contains(row.id),
          fromAi: row.source == DataChangeSource.ai,
          updatedAt: row.updatedAt,
          onTap: () => context.push(AppRoutes.dataRow(table.id, row.id)),
          onLongPress: () => _showRowContext(table, row),
        );
      },
    );
  }

  void _showRowContext(DataTableDef table, DataRow row) {
    final c = AppColors.of(context);
    AppSheet.show<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _settingsAction(
            c,
            LucideIcons.history,
            context.strings.changeHistory,
            () {
              Navigator.of(context).pop();
              showRowHistorySheet(context, table: table, row: row);
            },
          ),
          _settingsAction(c, LucideIcons.copy, context.strings.copyRow, () {
            runDataCommand(context, () async {
              final copy = await ref
                  .read(businessUiCommandsProvider)
                  .addRow(table, Map.of(row.values));
              if (!mounted) return;
              Navigator.of(context).pop();
              _highlight([copy.id]);
              AppToast.show(context, message: context.strings.rowCopied);
            });
          }),
          _settingsAction(
            c,
            LucideIcons.trash2,
            context.strings.deleteLabel,
            color: c.labelPrimary,
            () async {
              Navigator.of(context).pop();
              final confirmed = await showAppConfirmDialog(
                context,
                title: context.strings.deleteThisRow,
                message: context.strings.willBeDeletedYouCanReviewIt(
                  row.values[table.columns.first.name] ?? '',
                ),
                confirmLabel: context.strings.deleteLabel,
                destructive: true,
              );
              if (!confirmed || !mounted) return;
              await runDataCommand(context, () async {
                final change = await ref
                    .read(businessUiCommandsProvider)
                    .deleteRow(row);
                if (!mounted) return;
                HapticFeedback.mediumImpact();
                AppToast.show(
                  context,
                  message: context.strings.deleted,
                  actionLabel: context.strings.undo,
                  onAction: () => runDataCommand(context, change.undo),
                );
              });
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
