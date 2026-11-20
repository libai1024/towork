import 'package:towork/l10n/strings.dart';

import '../../../app/local_workspace_session.dart';
import 'local_image_import_page.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/workspace_nav_bar.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../app/providers.dart';
import '../../../domain/models/models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_text_styles.dart';
import '../application/ai_write_policy.dart';
import 'ai_confirm_sheet.dart';
import 'ai_write_feedback.dart';
import 'formatters.dart';
import 'repository_command.dart';

part 'screenshot_progress.dart';

/// 截图上传分析流程（07-data-tables.md §3.6，纯 UI 模拟，不接 OCR/上传）：
/// 已选图 →（压缩上传进度）→ AI 提取中逐字段填充 → diff 确认 → 落库。
/// 结束时返回最后一次落库结果（调用方负责高亮 + Toast，与撤销范围一致）。
class ScreenshotFlowPage extends ConsumerStatefulWidget {
  const ScreenshotFlowPage({super.key, required this.tableId});

  final String tableId;

  @override
  ConsumerState<ScreenshotFlowPage> createState() => _ScreenshotFlowPageState();
}

enum _FlowStep { picked, uploading, extracting }

class _ScreenshotFlowPageState extends ConsumerState<ScreenshotFlowPage> {
  _FlowStep _step = _FlowStep.picked;
  int _filled = 0;
  bool _slow = false;
  bool _finished = false;
  final List<Timer> _timers = [];

  late final _ExtractionPlan _plan = _buildPlan();

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // 模拟提取计划（按表 schema 生成真实感数据）
  // -------------------------------------------------------------------------

  _ExtractionPlan _buildPlan() {
    final repo = ref.read(dataTableProvider.notifier);
    if (widget.tableId == 'dt_stock') {
      String? mtId;
      String mtOldCount = '';
      String mtOldPrice = '';
      for (final r in repo.rowsOf('dt_stock')) {
        if (r.values['名称'] == '贵州茅台') {
          mtId = r.id;
          mtOldCount = r.values['持仓(股)'] ?? '';
          mtOldPrice = r.values['现价'] ?? '';
        }
      }
      return _ExtractionPlan(
        fileLabel: context.strings.holdingsPng,
        reason: context.strings.fromTheHoldingsScreenshotAddedSharesOf,
        sourceLabel: context.strings.analysisOfHoldingsPng,
        items: [
          _ExtractItem(
            label: context.strings.kweichowMoutaiShares,
            value: context.strings.shares,
          ),
          _ExtractItem(
            label: context.strings.kweichowMoutaiPrice,
            value: '¥1,680.50',
            lowConfidence: true,
          ),
          _ExtractItem(label: context.strings.tencentAdded, value: '00700'),
          _ExtractItem(
            label: context.strings.tencentShares,
            value: context.strings.sharesBuildplan,
          ),
          _ExtractItem(
            label: context.strings.tencentCostBasis,
            value: '¥320.50',
          ),
        ],
        changes: [
          if (mtId != null)
            PendingRowChange(
              id: 'pc_flow_update',
              action: DataChangeAction.update,
              rowId: mtId,
              rowLabel: context.strings.kweichowMoutai,
              fields: [
                PendingFieldChange(
                  field: '持仓(股)',
                  oldValue: mtOldCount,
                  newValue: '500',
                  confidence: 0.96,
                ),
                PendingFieldChange(
                  field: '现价',
                  oldValue: mtOldPrice,
                  newValue: '1680.50',
                  confidence: 0.62,
                ),
              ],
            ),
          PendingRowChange(
            id: 'pc_flow_create',
            action: DataChangeAction.create,
            rowLabel: context.strings.tencent,
            createValues: {
              '名称': context.strings.tencent,
              '代码': '00700',
              '持仓(股)': '300',
              '成本价': '320.50',
              '现价': '322.80',
            },
          ),
        ],
      );
    }
    if (widget.tableId == 'dt_archive') {
      return _ExtractionPlan(
        fileLabel: context.strings.receiptJpg,
        reason: context.strings.extractedAnArchiveReceiptFromThePhoto,
        sourceLabel: context.strings.analysisOfReceiptJpg,
        items: [
          _ExtractItem(label: context.strings.archiveId, value: 'JS-2026-0033'),
          _ExtractItem(
            label: context.strings.titleBuildplan,
            value: context.strings.planningRecordsTransferredByTheHousingBureau,
          ),
          _ExtractItem(
            label: context.strings.volumesBuildplan,
            value: '6',
            lowConfidence: true,
          ),
          _ExtractItem(
            label: context.strings.transferringAgency,
            value: context.strings.municipalHousingBureau,
          ),
        ],
        changes: [
          PendingRowChange(
            id: 'pc_flow_create',
            action: DataChangeAction.create,
            rowLabel: 'JS-2026-0033',
            createValues: {
              '档号': 'JS-2026-0033',
              '题名':
                  context.strings.planningRecordsTransferredByTheHousingBureau,
              '年度': '2026',
              '卷数': '6',
              '移交单位': context.strings.municipalHousingBureau,
              '接收日期': '2026-09-23',
              '密级': '内部',
              '已数字化': 'false',
            },
          ),
        ],
      );
    }
    // 通用：取 schema 前几个字段造一条新行。
    final table = repo.tableById(widget.tableId);
    final columns = table?.columns ?? const <DataColumnDef>[];
    final values = <String, String>{};
    for (final col in columns) {
      values[col.name] = switch (col.fieldType) {
        DataFieldType.number => '1',
        DataFieldType.money => '0.00',
        DataFieldType.date => formatDate(DateTime.now()),
        DataFieldType.datetime => formatDateTime(DateTime.now()),
        DataFieldType.selection =>
          col.enumOptions.isEmpty ? '' : col.enumOptions.first,
        DataFieldType.boolean => 'false',
        DataFieldType.text => context.strings.recordFromScreenshot,
      };
    }
    values.removeWhere((_, v) => v.isEmpty);
    return _ExtractionPlan(
      fileLabel: context.strings.screenshotPng,
      reason: context.strings.foundARecordInTheScreenshotConfirm,
      sourceLabel: context.strings.analysisOfScreenshotPng,
      items: [
        for (final e in values.entries)
          _ExtractItem(label: e.key, value: e.value),
      ],
      changes: [
        PendingRowChange(
          id: 'pc_flow_create',
          action: DataChangeAction.create,
          rowLabel: values.values.isEmpty
              ? context.strings.newRecord
              : values.values.first,
          createValues: values,
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // 流程推进
  // -------------------------------------------------------------------------

  void _startAnalysis() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    setState(() {
      _step = _FlowStep.uploading;
      _filled = 0;
      _slow = false;
      _finished = false;
    });
    // 压缩上传（长边 2048 / JPEG 85）模拟 700ms，随后进入提取。
    _timers.add(
      Timer(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(() => _step = _FlowStep.extracting);
        for (var i = 0; i < _plan.items.length; i++) {
          _timers.add(
            Timer(Duration(milliseconds: 520 * (i + 1)), () {
              if (mounted) setState(() => _filled = i + 1);
            }),
          );
        }
        _timers.add(
          Timer(
            Duration(milliseconds: 520 * _plan.items.length + 500),
            _finishExtraction,
          ),
        );
        _timers.add(
          Timer(const Duration(seconds: 15), () {
            if (mounted && !_finished) setState(() => _slow = true);
          }),
        );
      }),
    );
  }

  Future<void> _finishExtraction() async {
    if (!mounted || _finished) return;
    setState(() => _finished = true);
    final repo = ref.read(dataTableProvider.notifier);
    final table = repo.tableById(widget.tableId);
    if (table == null) {
      Navigator.of(context).pop();
      return;
    }
    late final PendingAiBatch batch;
    if (!runRepositoryCommand(context, () {
      batch = repo.pushPendingBatch(
        tableId: widget.tableId,
        reason: _plan.reason,
        sourceLabel: _plan.sourceLabel,
        changes: _plan.changes,
      );
    })) {
      setState(() {
        _finished = false;
        _step = _FlowStep.picked;
      });
      return;
    }
    final policy = ref.read(dataTableAiPolicyProvider);
    AiWriteResult? applied;
    final succeeded = runRepositoryCommand(context, () {
      applied = policy.receive(batch.id, ref.read(aiWritePermissionProvider));
    });
    final pending = succeeded ? applied!.pendingBatch : batch;
    if (pending == null) {
      if (mounted) Navigator.of(context).pop(applied);
      return;
    }
    if (applied?.hasWrites == true) {
      showAiWriteFeedback(
        context,
        repo,
        applied!,
        onUndone: () => applied = null,
      );
    }
    policy.requireReview(pending.id);
    // Dismissing the sheet leaves the remaining proposal available for review.
    // A mixed batch is two authorized commands; the returned result and undo
    // feedback describe the latest successful command, not the whole proposal.
    await AppSheet.show<void>(
      context,
      child: AiConfirmSheet(
        table: table,
        batch: pending,
        onApply: (ids) {
          final affected = repo.applyPendingBatch(pending.id, ids);
          applied = AiWriteResult(
            affectedRowIds: affected,
            appliedChanges: pending.changes
                .where((change) => ids.contains(change.id))
                .toList(),
          );
        },
        onDiscard: () {
          repo.discardPendingBatch(pending.id);
        },
      ),
    );
    if (mounted) Navigator.of(context).pop(applied);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (ref.watch(localWorkspaceSessionProvider) != null) {
      return LocalImageImportPage(tableId: widget.tableId);
    }
    final table = ref
        .read(dataTableProvider.notifier)
        .tableById(widget.tableId);
    return Scaffold(
      backgroundColor: c.bgGround,
      body: SafeArea(
        child: Column(
          children: [
            WorkspaceNavBar(
              title: context.strings.importScreenshotBuild(
                table == null ? '' : ' ${table.name}',
              ),
              backLabel: context.strings.cancelImageAnalysis,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: switch (_step) {
                _FlowStep.picked => _buildPicked(c),
                _FlowStep.uploading ||
                _FlowStep.extracting => _buildExtracting(c),
              },
            ),
          ],
        ),
      ),
    );
  }

  // 步骤 1：已选图 待上传
  Widget _buildPicked(AppColors c) {
    final mq = MediaQuery.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _ImagePlaceholder(
            label: _plan.fileLabel,
            height: mq.size.height * 0.4,
            iconSize: 48,
          ),
          const Spacer(),
          AppButton(
            label: context.strings.startAnalysis,
            icon: LucideIcons.scanLine,
            expand: true,
            onPressed: _startAnalysis,
          ),
          const SizedBox(height: 8),
          AppButton(
            label: context.strings.chooseAgain,
            type: AppButtonType.ghost,
            expand: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // 步骤 2/3：上传进度 → AI 提取中（骨架逐字段填充）
  Widget _buildExtracting(AppColors c) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              _ImagePlaceholder(
                label: _plan.fileLabel,
                height: 120,
                width: 120,
                iconSize: 32,
              ),
              if (_step == _FlowStep.uploading) const _UploadProgressBar(),
            ],
          ),
          const SizedBox(height: 16),
          if (_finished)
            Icon(LucideIcons.check, size: 20, color: c.brand)
          else
            const _DotsPulse(),
          const SizedBox(height: 8),
          Text(
            _finished
                ? context.strings.extractionComplete
                : _step == _FlowStep.uploading
                ? context.strings.uploadingImage
                : context.strings.readingImage,
            style: AppTextStyles.body.copyWith(color: c.labelSecondary),
          ),
          if (_slow)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                context.strings.takingLongerThanExpected,
                style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
              ),
            ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: _plan.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final item = _plan.items[i];
                final extracted = i < _filled;
                return Row(
                  children: [
                    SizedBox(
                      width: 132,
                      child: Text(
                        item.label,
                        style: AppTextStyles.caption.copyWith(
                          color: c.labelTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: extracted
                            ? Column(
                                key: ValueKey('v$i'),
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.value,
                                    style: AppTextStyles.body.copyWith(
                                      color: item.lowConfidence
                                          ? c.labelSecondary
                                          : c.labelPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (item.lowConfidence)
                                    Text(
                                      context.strings.aiIsUnsurePleaseVerify,
                                      style: AppTextStyles.caption.copyWith(
                                        color: c.labelSecondary,
                                      ),
                                    ),
                                ],
                              )
                            : AppSkeleton(
                                key: ValueKey('s$i'),
                                height: 18,
                                radius: AppRadii.xs,
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ExtractionPlan {
  const _ExtractionPlan({
    required this.fileLabel,
    required this.reason,
    required this.sourceLabel,
    required this.items,
    required this.changes,
  });

  final String fileLabel;
  final String reason;
  final String sourceLabel;
  final List<_ExtractItem> items;
  final List<PendingRowChange> changes;
}

class _ExtractItem {
  const _ExtractItem({
    required this.label,
    required this.value,
    this.lowConfidence = false,
  });

  final String label;
  final String value;
  final bool lowConfidence;
}
