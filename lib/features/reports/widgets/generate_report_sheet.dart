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

  static const _quickLabels = ['本周', '上周', '本月', '上月'];

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
      ReportType.weekly => '第 ${isoWeekNumber(_start)} 周',
      ReportType.monthly => '${_start.year} 年 ${_start.month} 月',
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
                  '周期',
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
                        label: '${_start.month} 月 ${_start.day} 日',
                        onTap: () => _pickDate(true),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _DateButton(
                        label: '${_end.month} 月 ${_end.day} 日',
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
                      '包含分类',
                      style: AppTextStyles.subhead.copyWith(
                        color: c.labelSecondary,
                      ),
                    ),
                    const Spacer(),
                    AppPressable(
                      onTap: _toggleSelectAll,

                      behavior: HitTestBehavior.translucent,
                      semanticLabel: allSelected ? '清空' : '全选',
                      child: Text(
                        allSelected ? '清空' : '全选',
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
                  semanticLabel: '保存为定时报告默认范围',
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
                        '保存为定时报告默认范围',
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
                          '周报 周一 08:00　月报 每月 1 日 08:00',
                          style: AppTextStyles.caption.copyWith(
                            color: c.labelTertiary,
                          ),
                        ),
                      ),
                      AppPressable(
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push(AppRoutes.settings);
                          AppToast.show(context, message: '在「定时报告」一节调整');
                        },

                        behavior: HitTestBehavior.translucent,
                        semanticLabel: '去调整定时报告',
                        child: Text(
                          '去调整 ›',
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
                label: '生成报告',
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

/// 周期快捷 Chip（单选）：选中 fill2 + labelPrimary，未选 fill1 + labelSecondary。
class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppPressable(
      onTap: onTap,

      behavior: HitTestBehavior.translucent,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: AppMotion.tabSwitch,
        curve: Curves.easeOut,
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? c.fill2 : c.fill1,
          borderRadius: AppRadii.brFull,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.footnote.copyWith(
            color: selected ? c.labelPrimary : c.labelSecondary,
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// 自定义日期按钮：fill1 底 r-md 高 40，body + chevron-down 16。
class _DateButton extends StatelessWidget {
  const _DateButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppPressable(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      semanticLabel: '选择日期：$label',
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: c.fill1, borderRadius: AppRadii.brMd),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(color: c.labelPrimary),
              ),
            ),
            Icon(LucideIcons.chevronDown, size: 16, color: c.labelSecondary),
          ],
        ),
      ),
    );
  }
}

/// 分类多选 Chip：高 32 r-full；选中 = brand 1px 描边 + brand 字 + check 12。
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppPressable(
      onTap: onTap,

      behavior: HitTestBehavior.translucent,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: AppMotion.tabSwitch,
        curve: Curves.easeOut,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.transparent : c.fill1,
          borderRadius: AppRadii.brFull,
          border: selected ? Border.all(color: c.brand, width: 1) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(LucideIcons.check, size: 12, color: c.brand),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTextStyles.footnote.copyWith(
                color: selected ? c.brand : c.labelSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
