import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/report_generation.dart';
import '../../../app/routes.dart';
import '../../../core/widgets/workspace_action_menu.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/workspace_nav_bar.dart';
import '../../../domain/reports/report_documents.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../report_production.dart';

/// 报告页的生产分支：SQLite 归档列表 + 本周/本月生成入口。
/// 演示模式（无本地工作区）不会构建本视图。
class ProductionReportsView extends ConsumerStatefulWidget {
  const ProductionReportsView({super.key});

  @override
  ConsumerState<ProductionReportsView> createState() =>
      _ProductionReportsViewState();
}

class _ProductionReportsViewState extends ConsumerState<ProductionReportsView> {
  ReportPeriodKind? _generating;

  bool get _busy => _generating != null;

  Future<void> _generate(ReportPeriodKind kind) async {
    if (_busy) return;
    final service = ref.read(reportGenerationProvider).value;
    if (service == null) return;
    setState(() => _generating = kind);
    try {
      final report = await service.generate(
        kind: kind,
        timezone: kProductionReportTimezone,
      );
      ref.invalidate(productionReportListProvider);
      await ref.read(productionReportListProvider.future);
      if (!mounted) return;
      context.push(AppRoutes.report(report.id));
    } on Object {
      if (mounted) {
        AppToast.show(context, message: '报告生成失败，请重试');
      }
    } finally {
      if (mounted) setState(() => _generating = null);
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(productionReportListProvider);
    await ref.read(productionReportListProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    // 生成服务就绪前不渲染操作区（session 非空时它必然解析为服务）。
    // 服务 provider 失败时给出明确错误态，避免停留成无限加载。
    final generation = ref.watch(reportGenerationProvider);
    if (generation.isLoading || generation.hasError) {
      return Scaffold(
        backgroundColor: c.bgGround,
        body: SafeArea(
          child: Column(
            children: [
              WorkspaceNavBar(
                title: '报告',
                onBack: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.home),
              ),
              Expanded(
                child: generation.hasError
                    ? AppEmptyState(
                        icon: LucideIcons.cloudOff,
                        title: '报告服务不可用',
                        actionLabel: '重试',
                        onAction: () =>
                            ref.invalidate(reportGenerationProvider),
                      )
                    : const Center(child: CircularProgressIndicator.adaptive()),
              ),
            ],
          ),
        ),
      );
    }
    final reportsAsync = ref.watch(productionReportListProvider);
    return Scaffold(
      backgroundColor: c.bgGround,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WorkspaceNavBar(
              title: '报告',
              onBack: () =>
                  context.canPop() ? context.pop() : context.go(AppRoutes.home),
              actions: [
                WorkspaceToolbarGroup(
                  children: [
                    Builder(
                      builder: (anchor) => WorkspaceToolbarAction(
                        icon: _busy ? LucideIcons.hourglass : LucideIcons.plus,
                        label: _busy ? '正在生成报告' : '生成报告',
                        text: reportsAsync.valueOrNull?.isEmpty == true
                            ? '生成'
                            : null,
                        onTap: _busy
                            ? null
                            : () async {
                                final kind =
                                    await showWorkspaceActionMenu<
                                      ReportPeriodKind
                                    >(
                                      anchor,
                                      items: const [
                                        (
                                          value: ReportPeriodKind.weekly,
                                          label: '生成本周周报',
                                          icon: LucideIcons.calendarDays,
                                        ),
                                        (
                                          value: ReportPeriodKind.monthly,
                                          label: '生成本月月报',
                                          icon: LucideIcons.calendarRange,
                                        ),
                                      ],
                                    );
                                if (mounted && kind != null) {
                                  await _generate(kind);
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Expanded(
              child: reportsAsync.when(
                skipLoadingOnReload: true,
                skipLoadingOnRefresh: true,
                loading: () =>
                    const Center(child: CircularProgressIndicator.adaptive()),
                error: (_, _) => AppEmptyState(
                  icon: LucideIcons.cloudOff,
                  title: '报告读取失败',
                  actionLabel: '重试',
                  onAction: _refresh,
                ),
                data: (reports) => reports.isEmpty
                    ? AppEmptyState(icon: LucideIcons.fileText, title: '还没有报告')
                    : RefreshIndicator(
                        color: c.brand,
                        backgroundColor: c.bgPrimary,
                        onRefresh: _refresh,
                        child: ListView.builder(
                          key: const ValueKey('production-report-list'),
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            AppSpacing.lg,
                          ),
                          itemCount: reports.length + 1,
                          itemBuilder: (context, index) {
                            if (index == reports.length) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.sm,
                                ),
                                child: Center(
                                  child: Text(
                                    '周期按 $kProductionReportTimezone 时区计算',
                                    style: AppTextStyles.caption.copyWith(
                                      color: c.labelQuaternary,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: _ProductionReportCard(
                                report: reports[index],
                                onTap: () => context.push(
                                  AppRoutes.report(reports[index].id),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 单份报告卡：周期标签 + 状态 chip + 完成率与三项大数字。
class _ProductionReportCard extends StatelessWidget {
  const _ProductionReportCard({required this.report, required this.onTap});

  final ReportDocument report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final m = report.metrics;
    return AppPressable(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      semanticLabel:
          '${productionNavTitle(report)}，'
          '${productionStatusChip(report)}，'
          '完成率 ${productionCompletionLabel(report)}。',
      borderRadius: AppRadii.brLg,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: c.bgPrimary,
          borderRadius: AppRadii.brLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    productionPeriodLabel(report),
                    style: AppTextStyles.body.copyWith(
                      color: c.labelPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                _StatusChip(report: report),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productionCompletionLabel(report),
                        style: AppTextStyles.title3.copyWith(
                          color: c.labelPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '完成率 ${productionCompletionFraction(report)}',
                        style: AppTextStyles.caption.copyWith(
                          color: c.labelSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _metric(context, '${m.completed}', '完成')),
                Expanded(child: _metric(context, '${m.created}', '新增')),
                Expanded(child: _metric(context, '${m.overdueAtEnd}', '逾期')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(BuildContext context, String value, String label) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTextStyles.title3.copyWith(
            color: c.labelPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: c.labelSecondary),
        ),
      ],
    );
  }
}

/// 状态 chip：待总结 / 已总结 / 失败。
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.report});

  final ReportDocument report;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (Color bg, Color fg) = switch (report.status) {
      ReportDocumentStatus.snapshotReady => (
        c.brand.withValues(alpha: .1),
        c.brand,
      ),
      ReportDocumentStatus.summaryReady => (
        c.green.withValues(alpha: .12),
        c.green,
      ),
      ReportDocumentStatus.failed => (c.red.withValues(alpha: .12), c.red),
    };
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadii.brXs),
      alignment: Alignment.center,
      child: Text(
        productionStatusChip(report),
        style: AppTextStyles.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
