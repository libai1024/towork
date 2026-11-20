import 'package:towork/l10n/strings.dart';

import '../../app/local_workspace_session.dart';
import '../../app/routes.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/app_skeleton.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/workspace_nav_bar.dart';
import '../../app/providers.dart';
import '../../domain/models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'report_actions.dart';
import 'report_utils.dart';
import 'widgets/production_report_detail_view.dart';
import 'widgets/report_common.dart';
import 'widgets/report_markdown.dart';
import 'widgets/report_stats_grid.dart';

part 'report_incomplete_banner.dart';

/// 报告详情（06-reports.md §3.3 / §3.4）。
/// 进入即标已读；生成中显示进度卡（三点脉冲 + 阶段文案轮换 + 不定量进度条）。
class ReportDetailPage extends ConsumerStatefulWidget {
  const ReportDetailPage({super.key, required this.reportId});

  final String reportId;

  @override
  ConsumerState<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends ConsumerState<ReportDetailPage> {
  Timer? _stageTimer;
  int _stageIndex = 0;

  static List<String> get _stageLabels => [
    strings.countingCompletedTasks,
    strings.summarizingCategories,
    strings.aggregatingData,
    strings.generatingSummary,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final report = ref
          .read(reportListProvider.notifier)
          .byId(widget.reportId);
      if (report == null) return;
      if (report.status == ReportStatus.ready && !report.isRead) {
        ref.read(reportListProvider.notifier).markRead(report.id);
      }
      if (report.status == ReportStatus.generating) _ensureStageTimer();
    });
  }

  @override
  void dispose() {
    _stageTimer?.cancel();
    super.dispose();
  }

  void _ensureStageTimer() {
    if (_stageTimer != null) return;
    // 减弱动态效果：阶段文案保持首条，不做连续轮换。
    if (MediaQuery.disableAnimationsOf(context)) return;
    _stageTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _stageIndex = (_stageIndex + 1) % _stageLabels.length);
    });
  }

  void _stopStageTimer() {
    _stageTimer?.cancel();
    _stageTimer = null;
  }

  /// 返回：生成中时提示后台继续（§3.4）。
  void _goBack(Report? report) {
    if (report != null && report.status == ReportStatus.generating) {
      AppToast.show(
        context,
        message: context.strings.theReportWillContinueInTheBackground,
      );
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.reports);
    }
  }

  void _confirmStop(Report report) {
    final c = AppColors.of(context);
    AppSheet.show<void>(
      context,
      title: context.strings.stopGeneratingConfirmstop,
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
            Text(
              context.strings.thePartialDraftWillBeDiscarded,
              style: AppTextStyles.body.copyWith(color: c.labelSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: context.strings.keepGenerating,
                    type: AppButtonType.secondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: context.strings.stop,
                    type: AppButtonType.destructive,
                    onPressed: () {
                      ref
                          .read(reportListProvider.notifier)
                          .stopGeneration(report.id);
                      Navigator.of(context).pop();
                      _goBack(null);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 更多菜单（§5.3）：标为未读｜重新生成｜删除。
  void _showMoreMenu(Report report) {
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
                icon: report.isRead ? LucideIcons.mail : LucideIcons.mailOpen,
                label: report.isRead
                    ? context.strings.markUnread
                    : context.strings.markRead,
                onTap: () {
                  Navigator.of(context).pop();
                  ref
                      .read(reportListProvider.notifier)
                      .markRead(report.id, read: !report.isRead);
                  AppToast.show(
                    context,
                    message: report.isRead
                        ? context.strings.markedUnread
                        : context.strings.markedRead,
                  );
                },
              ),
              ReportMenuRow(
                icon: LucideIcons.refreshCw,
                label: context.strings.regenerateConfirmregenerate,
                onTap: () {
                  Navigator.of(context).pop();
                  confirmRegenerate(context, ref, report);
                },
              ),
              ReportMenuRow(
                icon: LucideIcons.trash2,
                label: context.strings.deleteLabel,
                destructive: true,
                onTap: () {
                  Navigator.of(context).pop();
                  confirmDeleteReport(context, ref, report, popAfter: true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 生产分支：存在本地工作区时改用 SQLite 归档报告；演示模式走原逻辑。
    if (ref.watch(localWorkspaceSessionProvider) != null) {
      return ProductionReportDetailView(reportId: widget.reportId);
    }
    final c = AppColors.of(context);
    // 生成完成 / 外部状态变化时的收尾：标已读 + 停阶段计时器。
    ref.listen(reportListProvider, (_, _) {
      final r = ref.read(reportListProvider.notifier).byId(widget.reportId);
      if (r == null) return;
      if (r.status == ReportStatus.generating) {
        _ensureStageTimer();
      } else {
        _stopStageTimer();
        if (r.status == ReportStatus.ready && !r.isRead) {
          ref.read(reportListProvider.notifier).markRead(r.id);
        }
      }
    });

    final reports = ref.watch(reportListProvider);
    Report? report;
    for (final r in reports) {
      if (r.id == widget.reportId && r.deletedAt == null) report = r;
    }

    return Scaffold(
      backgroundColor: c.bgGround,
      body: SafeArea(
        child: report == null
            ? _buildNotFound(c)
            : Column(
                children: [
                  _buildAppBar(c, report),
                  Expanded(
                    child: report.status == ReportStatus.generating
                        ? _buildGenerating(c, report)
                        : _buildReady(c, report),
                  ),
                ],
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 顶栏
  // ---------------------------------------------------------------------------

  Widget _buildAppBar(AppColors c, Report report) {
    final generating = report.status == ReportStatus.generating;
    return WorkspaceNavBar(
      title: generating ? context.strings.generating : reportNavTitle(report),
      onBack: () => _goBack(report),
      actions: [
        WorkspaceToolbarGroup(
          children: [
            if (generating)
              WorkspaceToolbarAction(
                icon: LucideIcons.square,
                label: context.strings.stopGenerating,
                onTap: () => _confirmStop(report),
              )
            else ...[
              WorkspaceToolbarAction(
                icon: LucideIcons.share,
                label: context.strings.share,
                onTap: () => showReportShareSheet(context, ref, report),
              ),
              WorkspaceToolbarAction(
                icon: LucideIcons.ellipsis,
                label: context.strings.more,
                onTap: () => _showMoreMenu(report),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 生成中（§3.4）
  // ---------------------------------------------------------------------------

  Widget _buildGenerating(AppColors c, Report report) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          reportHeaderLine(report),
          style: AppTextStyles.footnote.copyWith(color: c.labelTertiary),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: c.bgPrimary,
            borderRadius: AppRadii.brXl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const PulsingDots(),
                  const SizedBox(width: 10),
                  // 阶段文案轮换（200ms 淡入淡出；减弱动态效果时瞬时切换）
                  AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : AppMotion.tabSwitch,
                    child: Text(
                      _stageLabels[_stageIndex],
                      key: ValueKey(_stageIndex),
                      style: AppTextStyles.body.copyWith(color: c.labelPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.strings.aboutSeconds,
                style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: AppRadii.brFull,
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: c.brand,
                  backgroundColor: c.fill1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // 正文骨架（fill1 呼吸块）
        const AppSkeleton(height: 14),
        const SizedBox(height: AppSpacing.sm),
        const FractionallySizedBox(
          widthFactor: 0.7,
          alignment: Alignment.centerLeft,
          child: AppSkeleton(height: 14),
        ),
        const SizedBox(height: AppSpacing.sm),
        const FractionallySizedBox(
          widthFactor: 0.9,
          alignment: Alignment.centerLeft,
          child: AppSkeleton(height: 14),
        ),
        const SizedBox(height: AppSpacing.sm),
        const FractionallySizedBox(
          widthFactor: 0.55,
          alignment: Alignment.centerLeft,
          child: AppSkeleton(height: 14),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 已生成（§3.3）
  // ---------------------------------------------------------------------------

  Widget _buildReady(AppColors c, Report report) {
    final generatedAt = report.generatedAt ?? report.createdAt;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: [
        // 报告头
        Text(
          reportHeaderLine(report),
          style: AppTextStyles.footnote.copyWith(color: c.labelTertiary),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          report.title,
          style: AppTextStyles.title1.copyWith(color: c.labelPrimary),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const AiBadge(),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                'Kimi ${mmddHm(generatedAt)}',
                style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        // 部分失败横幅（§6.4）
        if (report.incompleteSections.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _IncompleteBanner(
            categoryNames: report.incompleteSections,
            onRegenerate: () => confirmRegenerate(context, ref, report),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        // 大数字卡片区
        ReportStatsGrid(stats: report.stats, compareText: compareLabel(report)),
        // Markdown 正文区
        ReportMarkdown(content: report.contentMarkdown),
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
            title: context.strings.thisReportHasBeenDeleted,
            actionLabel: context.strings.backToList,
            onAction: () => context.go(AppRoutes.reports),
          ),
        ),
      ],
    );
  }
}
