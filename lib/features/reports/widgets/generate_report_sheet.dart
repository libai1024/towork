import 'package:towork/l10n/strings.dart';

import '../../../app/routes.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../app/providers.dart';
import '../../../domain/models/models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../report_utils.dart';

part 'report_scope_chips.dart';

/// 手动生成报告弹层（06-reports.md §3.2）。
/// 周期快捷 Chip 单选 + 自定义起止日期 + 分类多选 Chip + 定时默认范围选项。
class GenerateReportSheet extends ConsumerStatefulWidget {
  const GenerateReportSheet({super.key, required this.onGenerate});

  /// 点击「生成报告」回调：父级负责关弹层、插入生成中卡片并跳详情。
  final void Function(
    DateTime start,
    DateTime end,
    ReportType type,
    String periodLabel,
    List<ReportCategoryRef> categories,
    bool saveAsDefault,
  )
  onGenerate;

  @override
  ConsumerState<GenerateReportSheet> createState() =>
      _GenerateReportSheetState();
}

class _GenerateReportSheetState extends ConsumerState<GenerateReportSheet> {
  /// 0 本周 / 1 上周 / 2 本月 / 3 上月；-1 = 自定义（手动改日期后）。
  int _quick = 0;
  late DateTime _start;
  late DateTime _end;
  late Set<String> _selectedIds;
  bool _saveAsDefault = false;

  static List<String> get _quickLabels => [
    strings.thisWeek,
    strings.lastWeek,
    strings.thisMonth,
    strings.lastMonth,
  ];

  @override
  void initState() {
    super.initState();
    _applyQuick(0);
    final last = ref.read(reportLastCategoryIdsProvider);
    final roots = ref.read(categoryListProvider.notifier).roots;
    _selectedIds = last != null && last.isNotEmpty
        ? last.intersection(roots.map((e) => e.id).toSet())
        : roots.map((e) => e.id).toSet();
    if (_selectedIds.isEmpty) {
      _selectedIds = roots.map((e) => e.id).toSet();
    }
  }

  void _applyQuick(int quick) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisMonday = today.subtract(Duration(days: today.weekday - 1));
    final thisMonthFirst = DateTime(today.year, today.month, 1);
    final (start, end) = switch (quick) {
      0 => (thisMonday, today),
      1 => (
        thisMonday.subtract(const Duration(days: 7)),
        thisMonday.subtract(const Duration(days: 1)),
      ),
      2 => (thisMonthFirst, today),
      _ => (
        DateTime(today.year, today.month - 1, 1),
        thisMonthFirst.subtract(const Duration(days: 1)),
      ),
    };
    _quick = quick;
    _start = start;
    _end = end;
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030, 12, 31),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
      // 起始 > 结束时不报错，自动互换（§3.2）
      if (_start.isAfter(_end)) {
        final t = _start;
        _start = _end;
        _end = t;
      }
      _quick = -1;
    });
  }

  void _toggleCategory(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        if (_selectedIds.length == 1) {
          // 至少保留 1 个（§3.2）
          HapticFeedback.heavyImpact();
          return;
        }
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleSelectAll() {
    final roots = ref.read(categoryListProvider.notifier).roots;
    if (roots.isEmpty) return;
    setState(() {
      if (_selectedIds.length == roots.length) {
        // 清空（保留 1 个）
        _selectedIds = {roots.first.id};
      } else {
        _selectedIds = roots.map((e) => e.id).toSet();
      }
    });
  }

  void _submit() {
    if (_selectedIds.isEmpty) return;
    final categories = ref
        .read(categoryListProvider.notifier)
        .roots
        .where((e) => _selectedIds.contains(e.id))
        .map((e) => ReportCategoryRef(id: e.id, name: e.name, color: e.color))
        .toList();
    final type = switch (_quick) {
      0 || 1 => ReportType.weekly,
      2 || 3 => ReportType.monthly,
      _ => ReportType.custom,
    };
    final periodLabel = switch (type) {
      ReportType.weekly => context.strings.weekSubmit(isoWeekNumber(_start)),
      ReportType.monthly => context.strings.formattedValueBuild2(
        _start.year,
        _start.month,
      ),
      ReportType.custom => rangeLabel(_start, _end),
    };
    widget.onGenerate(
      _start,
      _end,
      type,
      periodLabel,
      categories,
      _saveAsDefault,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final roots = ref.watch(categoryListProvider.notifier).roots;
    final allSelected = roots.isNotEmpty && _selectedIds.length == roots.length;
    final canGenerate = _selectedIds.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 周期
                Text(
                  context.strings.period,
                  style: AppTextStyles.subhead.copyWith(
                    color: c.labelSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (var i = 0; i < _quickLabels.length; i++)
                      _QuickChip(
                        label: _quickLabels[i],
                        selected: _quick == i,
                        onTap: () => setState(() => _applyQuick(i)),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: _DateButton(
                        label: context.strings.formattedValueBuild4(
                          _start.month,
                          _start.day,
                        ),
                        onTap: () => _pickDate(true),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _DateButton(
                        label: context.strings.formattedValueBuild4(
                          _end.month,
                          _end.day,
                        ),
                        onTap: () => _pickDate(false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // 分类
                Row(
                  children: [
                    Text(
                      context.strings.includedCategories,
                      style: AppTextStyles.subhead.copyWith(
                        color: c.labelSecondary,
                      ),
                    ),
                    const Spacer(),
                    AppPressable(
                      onTap: _toggleSelectAll,

                      behavior: HitTestBehavior.translucent,
                      semanticLabel: allSelected
                          ? context.strings.clearAll
                          : context.strings.selectAll,
                      child: Text(
                        allSelected
                            ? context.strings.clearAll
                            : context.strings.selectAll,
                        style: AppTextStyles.caption.copyWith(color: c.brand),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final cat in roots)
                      _CategoryChip(
                        label: cat.name,
                        selected: _selectedIds.contains(cat.id),
                        onTap: () => _toggleCategory(cat.id),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(height: 0.5, color: c.separator),
                const SizedBox(height: AppSpacing.sm),
                // 选项
                AppPressable(
                  onTap: () => setState(() => _saveAsDefault = !_saveAsDefault),
                  behavior: HitTestBehavior.opaque,
                  semanticLabel:
                      context.strings.saveAsDefaultForScheduledReports,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: Checkbox(
                          value: _saveAsDefault,
                          onChanged: (v) =>
                              setState(() => _saveAsDefault = v ?? false),
                          activeColor: c.brand,
                          side: BorderSide(color: c.fill3, width: 1.5),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadii.brXs,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        context.strings.saveAsDefaultForScheduledReports,
                        style: AppTextStyles.body.copyWith(
                          color: c.labelPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          context.strings.weeklyOnMondayAtMonthlyOnThe,
                          style: AppTextStyles.caption.copyWith(
                            color: c.labelTertiary,
                          ),
                        ),
                      ),
                      AppPressable(
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push(AppRoutes.settings);
                          AppToast.show(
                            context,
                            message: context.strings.adjustInScheduledReports,
                          );
                        },

                        behavior: HitTestBehavior.translucent,
                        semanticLabel: context.strings.adjustScheduledReports,
                        child: Text(
                          context.strings.adjust,
                          style: AppTextStyles.caption.copyWith(color: c.brand),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(
                label: context.strings.generateReport,
                expand: true,
                enabled: canGenerate,
                onPressed: canGenerate ? _submit : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
