import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../widgets/app_button.dart';
import '../../widgets/app_pressable.dart';
import '../../widgets/app_sheet.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_text_styles.dart';

/// 分类操作弹层集（04-categories.md §5.4 / §5.5）：
/// 更多菜单、归档行操作、删除级联确认。

/// 更多菜单动作键。
enum CategoryAction {
  newChild,
  rename,
  sort,
  moveUp,
  moveDown,
  archive,
  delete,
}

/// 「更多」底部操作 Sheet（04 §5.4，行高 52）。
Future<CategoryAction?> showCategoryActions(
  BuildContext context, {
  required bool isRoot,
  required bool canSort,
  required bool canMoveUp,
  required bool canMoveDown,
}) {
  return AppSheet.show<CategoryAction>(
    context,
    child: ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        if (isRoot)
          _ActionRow(
            icon: LucideIcons.cornerDownRight,
            label: context.strings.newSubcategory,
            action: CategoryAction.newChild,
          ),
        _ActionRow(
          icon: LucideIcons.penLine,
          label: context.strings.rename,
          action: CategoryAction.rename,
        ),
        if (canSort)
          _ActionRow(
            icon: LucideIcons.arrowUpDown,
            label: context.strings.reorder,
            action: CategoryAction.sort,
          ),
        _ActionRow(
          icon: LucideIcons.arrowUp,
          label: context.strings.moveUp,
          action: CategoryAction.moveUp,
          enabled: canMoveUp,
        ),
        _ActionRow(
          icon: LucideIcons.arrowDown,
          label: context.strings.moveDown,
          action: CategoryAction.moveDown,
          enabled: canMoveDown,
        ),
        _ActionRow(
          icon: LucideIcons.archive,
          label: context.strings.archive,
          action: CategoryAction.archive,
        ),
        _ActionRow(
          icon: LucideIcons.trash2,
          label: context.strings.deleteLabel,
          action: CategoryAction.delete,
        ),
      ],
    ),
  );
}

/// 归档行操作 Sheet（04 §5.5）：恢复 / 彻底删除。
enum ArchivedAction { restore, delete }

Future<ArchivedAction?> showArchivedActions(BuildContext context) {
  return AppSheet.show<ArchivedAction>(
    context,
    child: ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        _ActionRow(
          icon: LucideIcons.archiveRestore,
          label: context.strings.restoreCategory,
          action: ArchivedAction.restore,
        ),
        _ActionRow(
          icon: LucideIcons.trash2,
          label: context.strings.deletePermanently,
          action: ArchivedAction.delete,
        ),
      ],
    ),
  );
}

class _ActionRow<T> extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.action,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final T action;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = !enabled ? c.labelQuaternary : c.labelPrimary;
    return AppPressable(
      onTap: enabled ? () => Navigator.of(context).pop(action) : null,
      behavior: HitTestBehavior.opaque,
      semanticLabel: label,
      child: SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 12),
              Text(label, style: AppTextStyles.body.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 删除级联策略（04 §8.3 cascade_strategy）。
enum CategoryDeleteStrategy {
  /// 待办移到「未分类」，子分类提升为一级（默认）。
  todosToInbox,

  /// 待办与子分类一并删除。
  deleteAll,
}

/// Shared deletion confirmation for every category entry point.
Future<CategoryDeleteStrategy?> showCategoryDeleteConfirm(
  BuildContext context, {
  required String name,
  required int todoCount,
  required int childCount,
  int seriesCount = 0,
  int detachedCount = 0,
}) {
  return AppSheet.show<CategoryDeleteStrategy>(
    context,
    child: _DeleteConfirmSheet(
      name: name,
      todoCount: todoCount,
      childCount: childCount,
      seriesCount: seriesCount,
      detachedCount: detachedCount,
    ),
  );
}

class _DeleteConfirmSheet extends StatefulWidget {
  const _DeleteConfirmSheet({
    required this.name,
    required this.todoCount,
    required this.childCount,
    required this.seriesCount,
    required this.detachedCount,
  });

  final String name;
  final int todoCount;
  final int childCount;
  final int seriesCount;
  final int detachedCount;

  @override
  State<_DeleteConfirmSheet> createState() => _DeleteConfirmSheetState();
}

class _DeleteConfirmSheetState extends State<_DeleteConfirmSheet> {
  CategoryDeleteStrategy _strategy = CategoryDeleteStrategy.todosToInbox;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final parts = <String>[
      if (widget.todoCount > 0) context.strings.tasks(widget.todoCount),
      if (widget.childCount > 0)
        context.strings.subcategories(widget.childCount),
      if (widget.seriesCount > 0)
        context.strings.recurringSeries(widget.seriesCount),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Text(
              context.strings.deleteLabelBuild(widget.name),
              style: AppTextStyles.title2.copyWith(color: c.labelPrimary),
            ),
          ),
          if (parts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                context.strings.contains(parts.join('、')),
                style: AppTextStyles.body.copyWith(color: c.labelSecondary),
              ),
            ),
            const SizedBox(height: 16),
            _option(
              c,
              strategy: CategoryDeleteStrategy.todosToInbox,
              label: context
                  .strings
                  .moveTasksToUncategorizedAndPromoteSubcategories,
            ),
            const SizedBox(height: 4),
            _option(
              c,
              strategy: CategoryDeleteStrategy.deleteAll,
              label: context.strings.deleteTasksAndSubcategories,
            ),
            if (widget.seriesCount > 0) ...[
              const SizedBox(height: 12),
              Text(
                _strategy == CategoryDeleteStrategy.todosToInbox
                    ? context.strings.futureTasksInThisCategoryWillMove
                    : '${context.strings.alsoStopTheseSeries(widget.seriesCount)}'
                          '${widget.detachedCount > 0 ? context.strings.keepTheTasksMovedElsewhereOrUncategorized(widget.detachedCount) : ''}',
                style: AppTextStyles.footnote.copyWith(color: c.labelSecondary),
              ),
            ],
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: context.strings.cancel,
                  type: AppButtonType.secondary,
                  expand: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: context.strings.deleteLabel,
                  type: AppButtonType.destructive,
                  expand: true,
                  onPressed: () => Navigator.of(context).pop(_strategy),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _option(
    AppColors c, {
    required CategoryDeleteStrategy strategy,
    required String label,
  }) {
    final selected = _strategy == strategy;
    return AppPressable(
      onTap: () => setState(() => _strategy = strategy),
      behavior: HitTestBehavior.opaque,
      borderRadius: AppRadii.brMd,
      semanticLabel: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? c.fill1 : Colors.transparent,
          borderRadius: AppRadii.brMd,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(color: c.labelPrimary),
              ),
            ),
            if (selected) Icon(LucideIcons.check, size: 16, color: c.brand),
          ],
        ),
      ),
    );
  }
}
