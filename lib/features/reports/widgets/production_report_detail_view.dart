import 'package:towork/l10n/strings.dart';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/report_generation.dart';
import '../../../app/routes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/workspace_nav_bar.dart';
import '../../../domain/reports/report_documents.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../report_export.dart';
import '../report_production.dart';
import 'report_poster.dart';
import 'report_common.dart';

part 'report_stat_card.dart';

/// 报告详情的生产分支：读取 SQLite 归档的冻结快照渲染数字，
/// 总结仅在用户主动点击时调用模型。演示模式不构建本视图。
class ProductionReportDetailView extends ConsumerStatefulWidget {
  const ProductionReportDetailView({super.key, required this.reportId});

  final String reportId;

  @override
  ConsumerState<ProductionReportDetailView> createState() =>
      _ProductionReportDetailViewState();
}

class _ProductionReportDetailViewState
    extends ConsumerState<ProductionReportDetailView> {
  bool _summarizing = false;
  bool _exporting = false;
  final GlobalKey _posterKey = GlobalKey();

  Future<void> _exportPoster(ReportDocument report) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final support = await getApplicationSupportDirectory();
      final exports = Directory('${support.path}/exports');
      await exports.create(recursive: true);
      final file = await exportReportPosterPng(_posterKey, report, exports);
      if (mounted) {
        AppToast.show(context, message: context.strings.posterSaved(file.path));
      }
    } on Object {
      if (mounted) {
        AppToast.show(
          context,
          message: context.strings.posterExportFailedTryAgain,
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _copyMarkdown(ReportDocument report) {
    Clipboard.setData(ClipboardData(text: reportMarkdown(report)));
    AppToast.show(context, message: context.strings.markdownCopied);
  }

  Future<void> _summarize() async {
    if (_summarizing) return;
    // .value 在 provider 重载间隙会是 null 而静默放弃；等待 future。
    final service = await ref.read(reportGenerationProvider.future);
    final report = await ref.read(
      productionReportProvider(widget.reportId).future,
    );
    if (report == null || service == null) return;
    setState(() => _summarizing = true);
    try {
      await service.summarize(report);
    } on Object {
      if (mounted) {
        AppToast.show(
          context,
          message: context.strings.summaryFailedYouCanRetry,
        );
      }
    } finally {
      // 列表 provider 是详情 provider 的依赖，失效后两者一并刷新。
      ref.invalidate(productionReportListProvider);
      if (mounted) setState(() => _summarizing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final reportAsync = ref.watch(productionReportProvider(widget.reportId));
    return Scaffold(
      backgroundColor: c.bgGround,
      body: SafeArea(
        child: reportAsync.when(
          skipLoadingOnReload: true,
          loading: () => Column(
            children: [
              WorkspaceNavBar(
                title: context.strings.report,
                onBack: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.reports),
              ),
              const Expanded(
                child: Center(child: CircularProgressIndicator.adaptive()),
              ),
            ],
          ),
          error: (_, _) => _buildLoadError(c),
          data: (report) =>
              report == null ? _buildNotFound(c) : _buildContent(c, report),
        ),
      ),
    );
  }

  /// 读取失败 ≠ 报告不存在：provider 出错时快照数据仍在本地，
  /// 给重试出口而不是误导用户以为报告被删了。
  Widget _buildLoadError(AppColors c) {
    return Column(
      children: [
        WorkspaceNavBar(
          title: context.strings.report,
          onBack: () => context.go(AppRoutes.reports),
        ),
        Expanded(
          child: AppEmptyState(
            icon: LucideIcons.cloudOff,
            title: context.strings.couldntReadReport,
            message: context.strings.localSnapshotRetained,
            actionLabel: context.strings.retry,
            onAction: () => ref.invalidate(productionReportListProvider),
          ),
        ),
      ],
    );
  }

  Widget _buildNotFound(AppColors c) {
    return Column(
      children: [
        WorkspaceNavBar(
          title: context.strings.report,
          onBack: () => context.go(AppRoutes.reports),
        ),
        Expanded(
          child: AppEmptyState(
            icon: LucideIcons.cloudOff,
            title: context.strings.reportNotFound,
            actionLabel: context.strings.backToList,
            onAction: () => context.go(AppRoutes.reports),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(AppColors c, ReportDocument report) {
    final m = report.metrics;
    return Column(
      children: [
        WorkspaceNavBar(
          title: productionNavTitle(report),
          onBack: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.reports),
        ),
        Expanded(
          child: ListView(
            key: const ValueKey('production-report-detail'),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            children: [
              Text(
                '${_kindLabel(report)} ${productionRangeLabel(report)} '
                '${report.timezone}',
                style: AppTextStyles.footnote.copyWith(color: c.labelTertiary),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                productionPeriodLabel(report),
                style: AppTextStyles.title1.copyWith(color: c.labelPrimary),
              ),
              const SizedBox(height: AppSpacing.md),
              _completionCard(c, report),
              const SizedBox(height: AppSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _StatCard(
                      value: '${m.created}',
                      label: context.strings.add,
                      sub: context.strings.tasksCreatedDuringThePeriod,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _StatCard(
                      value: '${m.completed}',
                      label: context.strings.complete,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _StatCard(
                      value: '${m.overdueAtEnd}',
                      label: context.strings.overdueBuild,
                      emphasized: m.overdueAtEnd > 0,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _StatCard(
                      value: '${m.openAtEnd}',
                      label: context.strings.unfinishedAtPeriodEnd,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _section(
                c,
                title: context.strings.byCategory,
                child: _categoryList(c, report),
              ),
              const SizedBox(height: AppSpacing.sm),
              _section(
                c,
                title: context.strings.vsLastPeriod,
                child: _compareList(c, report),
              ),
              const SizedBox(height: AppSpacing.sm),
              _section(
                c,
                title: context.strings.dataRows,
                child: _dataRowsCard(c, report),
              ),
              const SizedBox(height: AppSpacing.sm),
              _summarySection(c, report),
              const SizedBox(height: AppSpacing.sm),
              _section(
                c,
                title: context.strings.poster,
                child: Column(
                  children: [
                    RepaintBoundary(
                      key: _posterKey,
                      child: ReportPoster(report: report),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: context.strings.exportPosterPng,
                            icon: LucideIcons.imageDown,
                            type: AppButtonType.secondary,
                            loading: _exporting,
                            onPressed: () => _exportPoster(report),
                            expand: true,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: AppButton(
                            label: context.strings.copyMarkdown,
                            icon: LucideIcons.clipboardCopy,
                            type: AppButtonType.ghost,
                            onPressed: () => _copyMarkdown(report),
                            expand: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _kindLabel(ReportDocument report) => switch (report.kind) {
    ReportPeriodKind.weekly => context.strings.weeklyReport,
    ReportPeriodKind.monthly => context.strings.monthlyReport,
    ReportPeriodKind.custom => context.strings.customReport,
  };

  // ---------------------------------------------------------------------------
  // 大数字卡
  // ---------------------------------------------------------------------------

  Widget _completionCard(AppColors c, ReportDocument report) {
    final completion = report.metrics.completion;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: c.bgPrimary,
        borderRadius: AppRadii.brLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  productionCompletionLabel(report),
                  style: AppTextStyles.title1.copyWith(
                    color: completion.value == null
                        ? c.labelQuaternary
                        : c.labelPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                context.strings.completionRateCompletioncard(
                  productionCompletionFraction(report),
                ),
                style: AppTextStyles.body.copyWith(
                  color: c.labelPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            completion.label,
            style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 分类分布 / 上期对比 / 数据行
  // ---------------------------------------------------------------------------

  Widget _categoryList(AppColors c, ReportDocument report) {
    final byCategory = report.metrics.byCategory;
    if (byCategory.isEmpty) {
      return _plainCard(
        c,
        child: Text(
          context.strings.noCategoryRecordsThisPeriod,
          style: AppTextStyles.footnote.copyWith(color: c.labelTertiary),
        ),
      );
    }
    return _plainCard(
      c,
      child: Column(
        children: [
          for (var i = 0; i < byCategory.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Color(byCategory[i].colorValue),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    byCategory[i].name,
                    style: AppTextStyles.footnote.copyWith(
                      color: c.labelPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  context.strings.createdCompleted(
                    byCategory[i].created,
                    byCategory[i].completed,
                  ),
                  style: AppTextStyles.footnote.copyWith(
                    color: c.labelSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _compareList(AppColors c, ReportDocument report) {
    final m = report.metrics;
    final previousCompleted = m.previousCompleted;
    final previousRate = m.previousCompletion?.value;
    final currentRate = m.completion.value;
    final rateText = previousRate == null || currentRate == null
        ? context.strings.noPreviousCompletionRate
        : '${context.strings.previousPeriod(_signed(currentRate - previousRate, 'pt'))}'
              '${previousRate.round()}%）';
    return _plainCard(
      c,
      child: Column(
        children: [
          _compareRow(
            c,
            icon: _trendIcon(
              previousCompleted == null ? 0 : m.completed - previousCompleted,
            ),
            label: context.strings.complete,
            text: previousCompleted == null
                ? context.strings.noPreviousRecords
                : '${context.strings.previousPeriod(_signed(m.completed - previousCompleted, context.strings.itemsComparelist))}'
                      '${context.strings.itemsComparelist2(previousCompleted)}',
          ),
          const SizedBox(height: AppSpacing.sm),
          _compareRow(
            c,
            icon: previousRate == null || currentRate == null
                ? LucideIcons.minus
                : _trendIcon(currentRate - previousRate),
            label: context.strings.completionRateBuildpie,
            text: rateText,
          ),
        ],
      ),
    );
  }

  IconData _trendIcon(num delta) => delta > 0
      ? LucideIcons.trendingUp
      : delta < 0
      ? LucideIcons.trendingDown
      : LucideIcons.minus;

  String _signed(num delta, String unit) {
    final rounded = (delta * 10).round() / 10;
    final text = rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : '$rounded';
    return delta > 0
        ? '+$text $unit'
        : delta < 0
        ? '$text $unit'
        : '0 $unit';
  }

  Widget _compareRow(
    AppColors c, {
    required IconData icon,
    required String label,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, size: 12, color: c.labelSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.footnote.copyWith(color: c.labelPrimary),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.footnote.copyWith(color: c.labelSecondary),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _dataRowsCard(AppColors c, ReportDocument report) {
    final m = report.metrics;
    return _plainCard(
      c,
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.strings.totalRows(m.dataRowsTotal),
              style: AppTextStyles.footnote.copyWith(color: c.labelPrimary),
            ),
          ),
          Text(
            context.strings.rowsAddedThisPeriod(m.dataRowsCreated),
            style: AppTextStyles.footnote.copyWith(color: c.labelSecondary),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 总结区（用户主动触发）
  // ---------------------------------------------------------------------------

  Widget _summarySection(AppColors c, ReportDocument report) {
    final failed = report.status == ReportDocumentStatus.failed;
    final ready = report.status == ReportDocumentStatus.summaryReady;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AiBadge(),
            const SizedBox(width: AppSpacing.xs),
            Text(
              context.strings.aiSummary,
              style: AppTextStyles.caption.copyWith(
                color: c.labelTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: c.bgPrimary,
            borderRadius: AppRadii.brLg,
          ),
          child: ready && report.summary != null
              ? Text(
                  report.summary!,
                  key: const ValueKey('report-summary'),
                  style: AppTextStyles.body.copyWith(color: c.labelPrimary),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (failed) ...[
                      Row(
                        children: [
                          Icon(
                            LucideIcons.triangleAlert,
                            size: 14,
                            color: c.overdueForeground,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              context.strings.summaryFailedSnapshotRetained,
                              style: AppTextStyles.footnote.copyWith(
                                color: c.labelPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ] else
                      Text(
                        context.strings.kimiWritesTheSummaryUsingTheFigures,
                        style: AppTextStyles.footnote.copyWith(
                          color: c.labelTertiary,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    AppButton(
                      label: failed
                          ? context.strings.retrySummary
                          : context.strings.generatingSummary,
                      type: AppButtonType.secondary,
                      onPressed: _summarize,
                      loading: _summarizing,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 通用
  // ---------------------------------------------------------------------------

  Widget _section(
    AppColors c, {
    required String title,
    required Widget child,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: AppTextStyles.caption.copyWith(
          color: c.labelTertiary,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      child,
    ],
  );

  Widget _plainCard(AppColors c, {required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(color: c.bgPrimary, borderRadius: AppRadii.brLg),
    child: child,
  );
}
