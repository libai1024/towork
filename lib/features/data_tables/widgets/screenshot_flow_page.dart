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
        fileLabel: '持仓_0921.png',
        reason: '从持仓截图识别：加仓贵州茅台 200 股，新买入腾讯控股 300 股。',
        sourceLabel: '截图「持仓_0921.png」的分析',
        items: const [
          _ExtractItem(label: '贵州茅台 持仓(股)', value: '500 股'),
          _ExtractItem(
            label: '贵州茅台 现价',
            value: '¥1,680.50',
            lowConfidence: true,
          ),
          _ExtractItem(label: '腾讯控股 新增', value: '00700'),
          _ExtractItem(label: '腾讯控股 持仓(股)', value: '300 股'),
          _ExtractItem(label: '腾讯控股 成本价', value: '¥320.50'),
        ],
        changes: [
          if (mtId != null)
            PendingRowChange(
              id: 'pc_flow_update',
              action: DataChangeAction.update,
              rowId: mtId,
              rowLabel: '贵州茅台',
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
            rowLabel: '腾讯控股',
            createValues: {
              '名称': '腾讯控股',
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
        fileLabel: '接收单_0923.jpg',
        reason: '从接收单照片提取一条档案接收记录，卷数字迹不太清楚。',
        sourceLabel: '截图「接收单_0923.jpg」的分析',
        items: const [
          _ExtractItem(label: '档号', value: 'JS-2026-0033'),
          _ExtractItem(label: '题名', value: '住建局移交规划档案'),
          _ExtractItem(label: '卷数', value: '6', lowConfidence: true),
          _ExtractItem(label: '移交单位', value: '市住建局'),
        ],
        changes: [
          PendingRowChange(
            id: 'pc_flow_create',
            action: DataChangeAction.create,
            rowLabel: 'JS-2026-0033',
            createValues: {
              '档号': 'JS-2026-0033',
              '题名': '住建局移交规划档案',
              '年度': '2026',
              '卷数': '6',
              '移交单位': '市住建局',
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
        DataFieldType.text => '截图提取的记录',
      };
    }
    values.removeWhere((_, v) => v.isEmpty);
    return _ExtractionPlan(
      fileLabel: '截图_0923.png',
      reason: '从截图里读出了一条记录，确认后写入。',
      sourceLabel: '截图「截图_0923.png」的分析',
      items: [
        for (final e in values.entries)
          _ExtractItem(label: e.key, value: e.value),
      ],
      changes: [
        PendingRowChange(
          id: 'pc_flow_create',
          action: DataChangeAction.create,
          rowLabel: values.values.isEmpty ? '新记录' : values.values.first,
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
              title: '截图导入${table == null ? '' : ' ${table.name}'}',
              backLabel: '取消截图分析',
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
            label: '开始分析',
            icon: LucideIcons.scanLine,
            expand: true,
            onPressed: _startAnalysis,
          ),
          const SizedBox(height: 8),
          AppButton(
            label: '重选',
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
                ? '提取完成'
                : _step == _FlowStep.uploading
                ? '正在上传图片…'
                : 'AI 正在读图…',
            style: AppTextStyles.body.copyWith(color: c.labelSecondary),
          ),
          if (_slow)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '比预期慢，仍在努力…',
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
                                      'AI 不太确定，请核对',
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

/// 图片占位（纯 UI 阶段无真实图片文件）。
class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({
    required this.label,
    required this.height,
    this.width,
    this.iconSize = 48,
  });

  final String label;
  final double height;
  final double? width;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(color: c.fill2, borderRadius: AppRadii.brXl),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.images, size: iconSize, color: c.labelQuaternary),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: c.labelSecondary),
          ),
        ],
      ),
    );
  }
}

/// 上传进度：2px brand 细条压在图片底部（§3.6 步骤 1）。
class _UploadProgressBar extends StatelessWidget {
  const _UploadProgressBar();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadii.xl),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOut,
        builder: (context, value, _) => SizedBox(
          height: 2,
          width: double.infinity,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(color: c.brand),
          ),
        ),
      ),
    );
  }
}

/// 三点脉冲（规范 §4.8 AI 思考中）。
class _DotsPulse extends StatefulWidget {
  const _DotsPulse();

  @override
  State<_DotsPulse> createState() => _DotsPulseState();
}

class _DotsPulseState extends State<_DotsPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              // 三角波错峰：每个点相位错开 1/3 周期。
              Opacity(
                opacity: () {
                  final phase = (_controller.value - i / 3) % 1.0;
                  final bump = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
                  return 0.25 + 0.75 * bump;
                }(),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: c.brand,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
