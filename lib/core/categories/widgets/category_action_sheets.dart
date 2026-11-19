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
            label: '新建子分类',
            action: CategoryAction.newChild,
          ),
        _ActionRow(
          icon: LucideIcons.penLine,
          label: '重命名',
          action: CategoryAction.rename,
        ),
        if (canSort)
          _ActionRow(
            icon: LucideIcons.arrowUpDown,
            label: '排序',
            action: CategoryAction.sort,
          ),
        _ActionRow(
          icon: LucideIcons.arrowUp,
          label: '上移',
          action: CategoryAction.moveUp,
          enabled: canMoveUp,
        ),
        _ActionRow(
          icon: LucideIcons.arrowDown,
          label: '下移',
          action: CategoryAction.moveDown,
          enabled: canMoveDown,
        ),
        _ActionRow(
          icon: LucideIcons.archive,
          label: '归档',
          action: CategoryAction.archive,
        ),
        _ActionRow(
          icon: LucideIcons.trash2,
          label: '删除',
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
      children: const [
        _ActionRow(
          icon: LucideIcons.archiveRestore,
          label: '恢复分类',
          action: ArchivedAction.restore,
        ),
        _ActionRow(
          icon: LucideIcons.trash2,
          label: '彻底删除',
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
      if (widget.todoCount > 0) '${widget.todoCount} 条待办',
      if (widget.childCount > 0) '${widget.childCount} 个子分类',
      if (widget.seriesCount > 0) '${widget.seriesCount} 个重复系列',
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
              '删除「${widget.name}」？',
              style: AppTextStyles.title2.copyWith(color: c.labelPrimary),
            ),
          ),
          if (parts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                '里面有${parts.join('、')}。',
                style: AppTextStyles.body.copyWith(color: c.labelSecondary),
              ),
            ),
            const SizedBox(height: 16),
            _option(
              c,
              strategy: CategoryDeleteStrategy.todosToInbox,
              label: '待办移到「未分类」，子分类提升为一级',
            ),
            const SizedBox(height: 4),
            _option(
              c,
              strategy: CategoryDeleteStrategy.deleteAll,
              label: '待办与子分类一并删除',
            ),
            if (widget.seriesCount > 0) ...[
              const SizedBox(height: 12),
              Text(
                _strategy == CategoryDeleteStrategy.todosToInbox
                    ? '本分类的后续重复待办也移到「未分类」；子分类的系列保留原分类。'
                    : '同时停止这 ${widget.seriesCount} 个系列。'
                          '${widget.detachedCount > 0 ? '已移到其他分类或未分类的 ${widget.detachedCount} 条待办保留，并取消重复。' : ''}',
                style: AppTextStyles.footnote.copyWith(color: c.labelSecondary),
              ),
            ],
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: '取消',
                  type: AppButtonType.secondary,
                  expand: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: '删除',
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
