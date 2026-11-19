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
          AppToast.show(context, message: '已丢弃本次分析结果');
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
            (LucideIcons.camera, '拍照'),
            (LucideIcons.images, '从相册选择'),
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
    AppToast.show(context, message: '已添加一行');
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
        message: '已导出 ${rows.length} 行 ${file.uri.pathSegments.last}',
      );
    } catch (_) {
      if (mounted) AppToast.show(context, message: '导出失败，请重试');
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
          _settingsAction(c, LucideIcons.pencil, '重命名', () async {
            Navigator.of(context).pop();
            await _renameTable(table);
          }),
          _settingsAction(c, LucideIcons.folder, '修改类型', () async {
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
          }),
          _settingsAction(c, LucideIcons.listTree, '管理字段', () {
            Navigator.of(context).pop();
            showFieldManagementSheet(context, ref, table);
          }),
          _settingsAction(c, LucideIcons.upload, '导出 CSV', () {
            Navigator.of(context).pop();
            _exportCsv(table);
          }),
          _settingsAction(
            c,
            LucideIcons.archive,
            '归档',
            color: c.labelPrimary,
            () async {
              Navigator.of(context).pop();
              final confirmed = await showAppConfirmDialog(
                context,
                title: '归档这张表？',
                message: '归档后不在列表显示，数据仍保留。',
                confirmLabel: '归档',
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
          _settingsAction(c, LucideIcons.trash2, '删除表', color: c.red, () async {
            Navigator.of(context).pop();
            final rowCount = ref
                .read(dataTableProvider.notifier)
                .rowsOf(table.id)
                .length;
            final confirmed = await showAppConfirmDialog(
              context,
              title: '删除这张表？',
              message: rowCount == 0
                  ? '删除后仍可通过撤销恢复。'
                  : '将同时删除 $rowCount 行记录；删除后仍可通过撤销恢复。',
              confirmLabel: '删除',
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
                message: '已删除「${table.name}」',
                actionLabel: '撤销',
                onAction: () => runDataCommand(context, change.undo),
              );
            });
          }),
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
      column: DataColumnDef(name: '重命名', type: 'text'),
      current: table.name,
      onSave: (value) =>
          ref.read(businessUiCommandsProvider).renameTable(table, value),
    );
    if (name != null && name != table.name && mounted) {
      AppToast.show(context, message: '已重命名为「$name」');
    }
  }

  // -------------------------------------------------------------------------
  // 筛选 / 排序
  // -------------------------------------------------------------------------

  /// 来源筛选只作用于内存投影列表，SQL 条件模式下不生效。
  void _openSourceSheet() {
    AppSheet.show<void>(
      context,
      title: '来源',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (mode, label) in [
            (_SourceFilter.all, '全部'),
            (_SourceFilter.manual, '我录入的'),
            (_SourceFilter.ai, 'AI 写入的'),
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
      title: '排序',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (mode, label) in [
            (_SortMode.recent, '最近更新优先'),
            (_SortMode.firstAsc, '首字段 A → Z'),
            (_SortMode.firstDesc, '首字段 Z → A'),
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
        title: _query.isEmpty ? '没有匹配的记录' : '没有找到「$_query」',
        message: '调整筛选条件，或换个关键词',
        actionLabel: '清除筛选',
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
              '共 $_sqlTotal 条结果',
              style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
            ),
          );
        }
        if (i == _sqlItems.length + 1) {
          if (_sqlNextToken == null) return const SizedBox(height: 4);
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: AppButton(
              label: '加载更多',
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
                title: '数据',
                onBack: () => context.popOrGo(AppRoutes.dataTables),
              ),
              Expanded(
                child: AppEmptyState(
                  icon: LucideIcons.table,
                  title: '这张表不在了',
                  message: '它可能被归档或删除了',
                  actionLabel: '返回列表',
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
                      label: '表设置',
                      onTap: () => _openTableSettings(table),
                    ),
                    WorkspaceToolbarAction(
                      icon: LucideIcons.camera,
                      label: '截图导入',
                      onTap: _openCameraActions,
                    ),
                    WorkspaceToolbarAction(
                      icon: LucideIcons.plus,
                      label: '新建行',
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
                    '${allRows.length} 行',
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
                      semanticLabel: '有待确认的 AI 变更',
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
                      hint: '搜索行',
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
                          label: '来源',
                          active: _filter != _SourceFilter.all,
                          onTap: _openSourceSheet,
                        ),
                      if (sqlCapable)
                        WorkspaceToolbarAction(
                          icon: LucideIcons.filter,
                          label: '筛选',
                          active: sqlMode,
                          onTap: () => _openRowFilterSheet(table),
                        ),
                      WorkspaceToolbarAction(
                        icon: LucideIcons.arrowUpDown,
                        label: '排序',
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
        title: '还没有数据',
        actionLabel: '新建一行',
        onAction: () => _openAddRow(table),
      );
    }
    if (rows.isEmpty) {
      return AppEmptyState(
        icon: LucideIcons.search,
        title: '没有找到「$_query」',
        actionLabel: '清除搜索',
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
          _settingsAction(c, LucideIcons.history, '变更历史', () {
            Navigator.of(context).pop();
            showRowHistorySheet(context, table: table, row: row);
          }),
          _settingsAction(c, LucideIcons.copy, '复制此行', () {
            runDataCommand(context, () async {
              final copy = await ref
                  .read(businessUiCommandsProvider)
                  .addRow(table, Map.of(row.values));
              if (!mounted) return;
              Navigator.of(context).pop();
              _highlight([copy.id]);
              AppToast.show(context, message: '已复制此行');
            });
          }),
          _settingsAction(c, LucideIcons.trash2, '删除', color: c.labelPrimary, () async {
            Navigator.of(context).pop();
            final confirmed = await showAppConfirmDialog(
              context,
              title: '删除这行？',
              message:
                  '「${row.values[table.columns.first.name] ?? ''}」将被删除，可在变更历史里追溯。',
              confirmLabel: '删除',
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
                message: '已删除',
                actionLabel: '撤销',
                onAction: () => runDataCommand(context, change.undo),
              );
            });
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// 记录卡片（07-data-tables.md §3.2）：首字段为标题，至多 4 个摘要字段。
/// 投影列表与 SQL 结果模式共用；[updatedAt] 为空（SQL 预览无时间戳）时不显示更新时间。
class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.table,
    required this.values,
    required this.highlighted,
    required this.fromAi,
    required this.onTap,
    this.updatedAt,
    this.onLongPress,
  });

  final DataTableDef table;

  /// 列名 → 原始字符串值（bool 用 'true'/'false'，经 formatCellValue 展示）。
  final Map<String, String> values;
  final bool highlighted;
  final bool fromAi;
  final DateTime? updatedAt;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final firstField = table.columns.isEmpty ? null : table.columns.first;
    final title = firstField == null ? '记录' : (values[firstField.name] ?? '');
    final summaryColumns = table.columns.skip(1).take(4).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        // 高亮反馈在减弱动态效果时瞬时出现/消失。
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: highlighted ? c.brand25 : c.bgPrimary,
          borderRadius: AppRadii.brLg,
        ),
        child: AppPressable(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: AppRadii.brLg,
          semanticLabel: title,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title.isEmpty ? '（未命名）' : title,
                        style: AppTextStyles.body.copyWith(
                          color: c.labelPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (fromAi) const AiBadge(),
                  ],
                ),
                if (summaryColumns.isNotEmpty) const SizedBox(height: 8),
                for (final column in summaryColumns)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 72,
                          child: Text(
                            column.name,
                            style: AppTextStyles.caption.copyWith(
                              color: c.labelTertiary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            formatCellValue(column, values[column.name]),
                            style: isNumericColumn(column)
                                ? tabularStyle(
                                    AppTextStyles.body.copyWith(
                                      color: c.labelPrimary,
                                    ),
                                  )
                                : AppTextStyles.body.copyWith(
                                    color: c.labelPrimary,
                                  ),
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (updatedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '更新于 ${relativeTime(updatedAt!)}',
                    style: AppTextStyles.caption.copyWith(
                      color: c.labelTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
