import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../domain/models/models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_text_styles.dart';

enum MemoryCardAction { edit, copy, delete }

Future<String?> showMemoryLibraryMenu(BuildContext context) =>
    AppSheet.show<String>(
      context,
      title: context.strings.memoryLibrary,
      child: Builder(
        builder: (sheetContext) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (label, action) in [
                (context.strings.moreFilters, 'filter'),
                (context.strings.memoryRules, 'rules'),
                (context.strings.clearAllMemories, 'clear'),
              ])
                AppButton(
                  label: label,
                  type: AppButtonType.ghost,
                  expand: true,
                  onPressed: () => Navigator.pop(sheetContext, action),
                ),
            ],
          ),
        ),
      ),
    );

Future<void> showMemoryRules(BuildContext context) => AppSheet.show<void>(
  context,
  title: context.strings.memoryRules,
  child: SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.strings.theAiRemembersInformationYouMentionThat,
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 8),
        for (final (label, example) in [
          (
            context.strings.longTermPreferences,
            context.strings.leadWithTheConclusion,
          ),
          (
            context.strings.recurringWorkflows,
            context.strings.groupWeeklyReportsByProject,
          ),
          (
            context.strings.responsibilities,
            context.strings.iHandleContractApprovals,
          ),
          (
            context.strings.projectAgreements,
            context.strings.useTheSignedVersionForAcceptance,
          ),
          (
            context.strings.terminology,
            context.strings.northMeansTheNorthChinaProjectTeam,
          ),
          (
            context.strings.corrections,
            context.strings.weeklyReportsAreNowDueOnThursdays,
          ),
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.footnote.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(example, style: AppTextStyles.footnote)),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Text(
          context.strings.youCanPauseMemoryAtAnyTime,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.of(context).labelSecondary,
          ),
        ),
      ],
    ),
  ),
);

/// 长按卡片的操作菜单（§5.4）。
Future<MemoryCardAction?> showMemoryActionSheet(BuildContext context) {
  final c = AppColors.of(context);
  return AppSheet.show<MemoryCardAction>(
    context,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionRow(
            icon: LucideIcons.pencil,
            label: context.strings.edit,
            onTap: () => Navigator.pop(context, MemoryCardAction.edit),
          ),
          _ActionRow(
            icon: LucideIcons.copy,
            label: context.strings.copyContent,
            onTap: () => Navigator.pop(context, MemoryCardAction.copy),
          ),
          _ActionRow(
            icon: LucideIcons.trash2,
            label: context.strings.deleteLabel,
            color: c.labelPrimary,
            onTap: () => Navigator.pop(context, MemoryCardAction.delete),
          ),
        ],
      ),
    ),
  );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fg = color ?? c.labelPrimary;
    return AppPressable(
      onTap: onTap,
      borderRadius: AppRadii.brMd,
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? c.labelSecondary),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.body.copyWith(color: fg)),
          ],
        ),
      ),
    );
  }
}

/// 单条删除（轻确认，§5.4）：返回 true = 确认删除。
Future<bool> showDeleteMemoryConfirm(BuildContext context) async {
  final c = AppColors.of(context);
  final result = await AppSheet.show<bool>(
    context,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.strings.deleteThisMemory,
            style: AppTextStyles.subhead.copyWith(color: c.labelPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            context.strings.theAiWillNoLongerRememberIt,
            style: AppTextStyles.footnote.copyWith(color: c.labelSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: context.strings.cancel,
                  type: AppButtonType.secondary,
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: context.strings.deleteLabel,
                  type: AppButtonType.destructive,
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}

/// 更多筛选（§3.3）：来源 + 时效。返回 null = 未改动关闭。
Future<(MemorySource?, MemoryExpiryFilter)?> showMoreFilterSheet(
  BuildContext context, {
  required MemorySource? initialSource,
  required MemoryExpiryFilter initialExpiry,
}) async {
  var source = initialSource;
  var expiry = initialExpiry;
  final c = AppColors.of(context);

  return AppSheet.show<(MemorySource?, MemoryExpiryFilter)>(
    context,
    title: context.strings.filter,
    child: StatefulBuilder(
      builder: (context, setSheetState) {
        Widget section(String label, List<Widget> chips) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: chips),
            ],
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              section(context.strings.source, [
                AppChip(
                  label: context.strings.allLabel,
                  selected: source == null,
                  onTap: () => setSheetState(() => source = null),
                ),
                AppChip(
                  label: context.strings.extractedByAi,
                  selected: source == MemorySource.ai,
                  onTap: () => setSheetState(() => source = MemorySource.ai),
                ),
                AppChip(
                  label: context.strings.manual,
                  selected: source == MemorySource.manual,
                  onTap: () =>
                      setSheetState(() => source = MemorySource.manual),
                ),
              ]),
              const SizedBox(height: 16),
              section(context.strings.retention, [
                for (final f in MemoryExpiryFilter.values)
                  AppChip(
                    label: localizedBuiltin(f.label),
                    selected: expiry == f,
                    onTap: () => setSheetState(() => expiry = f),
                  ),
              ]),
              const SizedBox(height: 12),
              AppButton(
                label: context.strings.complete,
                expand: true,
                onPressed: () => Navigator.pop(context, (source, expiry)),
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// 免记忆模式开启确认（§5.7 轻确认）。
Future<bool> showPauseMemoryConfirm(BuildContext context) async {
  final c = AppColors.of(context);
  final result = await AppSheet.show<bool>(
    context,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.strings.pauseMemory,
            style: AppTextStyles.subhead.copyWith(color: c.labelPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            context.strings.newChatsWontAddMemoriesExistingMemories,
            style: AppTextStyles.footnote.copyWith(color: c.labelSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: context.strings.cancel,
                  type: AppButtonType.secondary,
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: context.strings.onLabel,
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}

/// 一键清空（重确认，§5.6）：「全部清空」需长按 1 秒生效，不提供撤销。
Future<bool> showClearAllConfirm(BuildContext context, int total) async {
  final c = AppColors.of(context);
  final result = await AppSheet.show<bool>(
    context,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.trash2, size: 24, color: c.labelPrimary),
          const SizedBox(height: 8),
          Text(
            context.strings.clearAllMemoriesShowclearallconfirm,
            style: AppTextStyles.title2.copyWith(color: c.labelPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            context.strings.deletesAllMemoriesIncludingAiExtractedAnd(total),
            style: AppTextStyles.body.copyWith(color: c.labelSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: context.strings.cancel,
                  type: AppButtonType.secondary,
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HoldToConfirmButton(
                  onConfirmed: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}

/// 长按 1 秒才生效的实心危险按钮（§5.6 防误触蓄意摩擦）。
class HoldToConfirmButton extends StatefulWidget {
  const HoldToConfirmButton({super.key, required this.onConfirmed});

  final VoidCallback onConfirmed;

  @override
  State<HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  bool _done = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_done) {
        _done = true;
        widget.onConfirmed();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _cancel() {
    if (!_done) _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      button: true,
      label: context.strings.holdForOneSecondToConfirmClearing,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPressStart: (_) => _ctrl.forward(),
        onLongPressEnd: (_) => _cancel(),
        onLongPressCancel: _cancel,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            final pressing = _ctrl.value > 0;
            return Container(
              height: 44,
              decoration: BoxDecoration(
                color: c.labelPrimary,
                borderRadius: AppRadii.brMd,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: pressing
                        ? CircularProgressIndicator(
                            value: _ctrl.value,
                            strokeWidth: 2,
                            color: c.onBrand,
                          )
                        : Icon(LucideIcons.trash2, size: 16, color: c.onBrand),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    pressing
                        ? context.strings.keepHolding
                        : context.strings.holdForSecondToClear,
                    style: AppTextStyles.body.copyWith(
                      color: c.onBrand,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 供页面复用的复制到剪贴板。
Future<void> copyMemoryContent(String content) =>
    Clipboard.setData(ClipboardData(text: content));
