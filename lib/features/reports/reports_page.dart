import '../../app/local_workspace_session.dart';
import '../../app/routes.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/workspace_nav_bar.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/workspace_scope_rail.dart';
import '../../core/widgets/workspace_bottom_bar.dart';
import '../../app/providers.dart';
import '../../domain/models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'report_actions.dart';
import 'report_utils.dart';
import 'widgets/generate_report_sheet.dart';
import 'widgets/production_reports_view.dart';

/// 按覆盖周期月份分组的报告列表，使用窄索引与紧凑双行记录。
class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  /// 0 全部 / 1 周报 / 2 月报
  String _filter = 'all';
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  void _openGenerateSheet() {
    AppSheet.show<void>(
      context,
      title: '生成报告',
      child: GenerateReportSheet(
        onGenerate: (start, end, type, periodLabel, categories, saveDefault) {
          ref.read(reportLastCategoryIdsProvider.notifier).state = categories
              .map((e) => e.id)
              .toSet();
          if (saveDefault) {
            ref.read(reportDefaultCategoryIdsProvider.notifier).state =
                categories.map((e) => e.id).toSet();
          }
          final report = ref
              .read(reportListProvider.notifier)
              .startGeneration(
                periodStart: start,
                periodEnd: end,
                type: type,
                periodLabel: periodLabel,
                categories: categories,
              );
          Navigator.of(context).pop();
          context.push(AppRoutes.report(report.id));
        },
      ),
    );
  }

  Future<void> _refresh() async {
    // 纯 UI 阶段：本地数据即时可得，保留短暂下拉手感。
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    // 生产分支：存在本地工作区时改用 SQLite 归档报告；演示模式走原逻辑。
    if (ref.watch(localWorkspaceSessionProvider) != null) {
      return const ProductionReportsView();
    }
    final c = AppColors.of(context);
    final reports = ref
        .watch(reportListProvider)
        .where((r) => r.deletedAt == null)
        .toList();
    final query = _query.trim().toLowerCase();
    final filtered = reports.where((r) {
      final matchesType = switch (_filter) {
        'weekly' => r.type == ReportType.weekly,
        'monthly' => r.type == ReportType.monthly,
        _ => true,
      };
      return matchesType &&
          (query.isEmpty ||
              '${r.title} ${reportTypeLabel(r.type)} ${r.periodLabel} ${rangeLabel(r.periodStart, r.periodEnd)} ${r.summary} ${r.contentMarkdown}'
                  .toLowerCase()
                  .contains(query));
    }).toList()..sort((a, b) => b.periodEnd.compareTo(a.periodEnd));

    return Scaffold(
      backgroundColor: c.bgGround,
      body: SafeArea(
        child: Column(
          children: [
            WorkspaceNavBar(
              title: '报告',
              onBack: () =>
                  context.canPop() ? context.pop() : context.go(AppRoutes.home),
            ),
            Expanded(
              child: WorkspaceScopeLayout(
                items: [
                  WorkspaceScopeItem(
                    id: 'all',
                    label: '全部',
                    count: reports.length,
                  ),
                  WorkspaceScopeItem(
                    id: 'weekly',
                    label: '周报',
                    count: reports
                        .where((r) => r.type == ReportType.weekly)
                        .length,
                  ),
                  WorkspaceScopeItem(
                    id: 'monthly',
                    label: '月报',
                    count: reports
                        .where((r) => r.type == ReportType.monthly)
                        .length,
                  ),
                ],
                selectedId: _filter,
                onSelected: (value) => setState(() => _filter = value),
                child: reports.isEmpty
                    ? _buildEmptyAll(c)
                    : filtered.isEmpty
                    ? _buildEmptyFiltered(c)
                    : _buildList(c, filtered),
              ),
            ),
            WorkspaceBottomBar(
              searchController: _searchController,
              onSearchChanged: (value) => setState(() => _query = value),
              onClear: _clearSearch,
              onAdd: _openGenerateSheet,
              addLabel: '生成报告',
              hint: '搜索报告',
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 列表：按月分组
  // ---------------------------------------------------------------------------

  Widget _buildList(AppColors c, List<Report> filtered) {
    // 按周期结束所在月份分组（Map 字面量保持插入倒序）。
    final groups = <String, List<Report>>{};
    for (final r in filtered) {
      groups.putIfAbsent(monthGroupLabel(r.periodEnd), () => []).add(r);
    }

    final entries = <Object>[
      for (final group in groups.entries) ...[group.key, ...group.value],
    ];
    return RefreshIndicator(
      color: c.brand,
      backgroundColor: c.bgPrimary,
      onRefresh: _refresh,
      child: ListView.builder(
        key: const ValueKey('report-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 0, 16, 24),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          if (entry is String) {
            return Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 4),
              child: Text(
                entry,
                style: AppTextStyles.caption.copyWith(
                  color: c.labelTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }
          return _buildCard(c, entry as Report);
        },
      ),
    );
  }

  Widget _buildCard(AppColors c, Report report) {
    final card = _ReportRow(
      report: report,
      onTap: () => context.push(AppRoutes.report(report.id)),
      onLongPress: () => _showCardMenu(report),
      onRetry: () => confirmRegenerate(context, ref, report),
    );
    // 生成中卡片不提供左滑删除
    if (report.status == ReportStatus.generating) return card;
    return Dismissible(
      key: ValueKey('report_${report.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        confirmDeleteReport(context, ref, report);
        return false;
      },
      background: Container(
        decoration: BoxDecoration(
          color: c.labelPrimary,
          borderRadius: AppRadii.brLg,
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.trash2, size: 16, color: c.onBrand),
            const SizedBox(width: 4),
            Text(
              '删除',
              style: AppTextStyles.body.copyWith(
                color: c.onBrand,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      child: card,
    );
  }

  /// 长按上下文菜单（§5.1）。
  void _showCardMenu(Report report) {
    AppSheet.show<void>(
      context,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ReportMenuRow(
                icon: LucideIcons.fileText,
                label: '导出 Markdown',
                onTap: () {
                  Navigator.of(context).pop();
                  exportReportMarkdown(context, ref, report);
                },
              ),
              ReportMenuRow(
                icon: LucideIcons.copy,
                label: '复制全文',
                onTap: () {
                  Navigator.of(context).pop();
                  copyReportMarkdown(context, report);
                },
              ),
              ReportMenuRow(
                icon: report.isRead ? LucideIcons.mail : LucideIcons.mailOpen,
                label: report.isRead ? '标为未读' : '标为已读',
                onTap: () {
                  Navigator.of(context).pop();
                  ref
                      .read(reportListProvider.notifier)
                      .markRead(report.id, read: !report.isRead);
                },
              ),
              ReportMenuRow(
                icon: LucideIcons.refreshCw,
                label: '重新生成',
                onTap: () {
                  Navigator.of(context).pop();
                  confirmRegenerate(context, ref, report);
                },
              ),
              ReportMenuRow(
                icon: LucideIcons.trash2,
                label: '删除',
                destructive: true,
                onTap: () {
                  Navigator.of(context).pop();
                  confirmDeleteReport(context, ref, report);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 空状态（§6.2）
  // ---------------------------------------------------------------------------

  Widget _buildEmptyAll(AppColors c) => AppEmptyState(
    icon: LucideIcons.fileText,
    title: '还没有报告',
    actionLabel: '生成报告',
    onAction: _openGenerateSheet,
  );

  Widget _buildEmptyFiltered(AppColors c) => AppEmptyState(
    icon: LucideIcons.search,
    title: _query.trim().isEmpty ? '暂无报告' : '没有找到相关报告',
    actionLabel: '清除筛选',
    onAction: () {
      _searchController.clear();
      setState(() {
        _filter = 'all';
        _query = '';
      });
    },
  );
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({
    required this.report,
    required this.onTap,
    required this.onLongPress,
    required this.onRetry,
  });

  final Report report;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final unread = !report.isRead;
    final generating = report.status == ReportStatus.generating;
    final failed = report.status == ReportStatus.failed;
    final done = report.stats.doneCount;
    final metadata = failed
        ? failureText(report.failureReason)
        : generating
        ? '生成中…'
        : '${rangeLabel(report.periodStart, report.periodEnd)}${done == null ? '' : ' 完成 $done 项'}';

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.separator, width: .5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppPressable(
              onTap: onTap,
              onLongPress: onLongPress,
              behavior: HitTestBehavior.opaque,
              semanticLabel:
                  '${reportTypeLabel(report.type)}，${report.periodLabel}。${report.title}${unread ? '。未读' : ''}',
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 72),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 26,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              failed
                                  ? LucideIcons.fileWarning
                                  : LucideIcons.fileText,
                              size: 18,
                              color: c.labelSecondary,
                            ),
                            if (unread && !failed)
                              Positioned(
                                right: 2,
                                top: -3,
                                child: Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: c.labelPrimary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              failed
                                  ? '${reportNavTitle(report)}没写成'
                                  : report.title,
                              style: AppTextStyles.body.copyWith(
                                color: c.labelPrimary,
                                fontWeight: unread
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              metadata,
                              style: AppTextStyles.caption.copyWith(
                                color: c.labelSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (generating) ...[
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                minHeight: 2,
                                color: c.labelPrimary,
                                backgroundColor: c.fill1,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!failed) ...[
                        const SizedBox(width: 6),
                        Text(
                          reportTypeLabel(report.type),
                          style: AppTextStyles.caption.copyWith(
                            color: c.labelSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (failed)
            AppPressable(
              onTap: onRetry,
              semanticLabel: '重试',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '重试',
                  style: AppTextStyles.footnote.copyWith(
                    color: c.labelPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
