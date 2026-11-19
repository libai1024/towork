import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/app_pressable.dart';
import '../../../app/providers.dart';
import '../../../domain/models/models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../core/categories/category_catalog.dart';

/// Keep the arrow's full touch target while indenting child labels by 12 points.
const double kCategoryRowLeft = 12;
const double kRootSeparatorIndent = 96;
const double kChildRowIndent = 72;
const double kChildSeparatorIndent = 108;

/// 分类行（04 §3.2）：父子分类用缩进区分/ 归档行灰化。
/// 行内：展开箭头 + 色块图标 + 名称 + 「N 项 P%」统计 + 更多/拖拽手柄。
class CategoryRow extends StatelessWidget {
  const CategoryRow({
    super.key,
    required this.category,
    required this.stats,
    this.isChild = false,
    this.archived = false,
    this.hasChildren = false,
    this.expanded = false,
    this.sortMode = false,
    this.dropHighlighted = false,
    this.dragging = false,
    this.onTap,
    this.onLongPress,
    this.onToggleExpand,
    this.onMore,
    this.onDragStarted,
    this.onDragEnded,
  });

  final Category category;
  final CategoryStats stats;
  final bool isChild;
  final bool archived;
  final bool hasChildren;
  final bool expanded;

  /// 排序模式：行尾显示拖拽手柄，点击/长按失效（04 §3.3）。
  final bool sortMode;

  /// 拖拽悬停 350ms 降级高亮（inset 1px brand 描边 + brand25 底）。
  final bool dropHighlighted;

  /// 本行正在被拖拽：原位行变暗，浮起态由 feedback 承担。
  final bool dragging;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggleExpand;
  final VoidCallback? onMore;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final minHeight = isChild ? 44.0 : 48.0;
    final iconColor = archived ? c.labelTertiary : c.categoryForeground;
    final blockColor = archived ? c.fill2 : c.categorySurface(category.color);
    final nameColor = archived ? c.labelTertiary : c.labelPrimary;

    final row = AnimatedContainer(
      duration: AppMotion.tabSwitch,
      curve: Curves.easeOut,
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        color: dropHighlighted ? c.brand25 : Colors.transparent,
        border: dropHighlighted
            ? Border.all(color: c.brand, width: 1, strokeAlign: -1)
            : null,
        borderRadius: dropHighlighted ? AppRadii.brLg : null,
      ),
      child: Row(
        children: [
          const SizedBox(width: kCategoryRowLeft),
          if (isChild)
            const SizedBox(width: kChildRowIndent - kCategoryRowLeft)
          else
            _expandArrow(c),
          _colorBlock(c, iconColor, blockColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category.name,
              style: AppTextStyles.body.copyWith(color: nameColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _stats(c),
          if (!isChild && !archived) ...[
            const SizedBox(width: 4),
            sortMode ? _dragHandle(c) : _moreButton(c),
          ] else
            const SizedBox(width: 12),
        ],
      ),
    );

    return Semantics(
      label: _semanticsLabel,
      child: AppPressable(
        onTap: sortMode ? null : onTap,
        onLongPress: (sortMode || archived) ? null : onLongPress,
        behavior: HitTestBehavior.opaque,
        semanticLabel: _semanticsLabel,
        child: AnimatedOpacity(
          opacity: dragging ? 0.35 : 1,
          duration: AppMotion.tabSwitch,
          child: row,
        ),
      ),
    );
  }

  String get _semanticsLabel {
    final rate = stats.completionRate;
    final rateText = archived || rate == null ? '完成率未知' : '完成率 $rate%';
    if (archived) {
      return '已归档分类，${category.name}，${stats.open} 条待办，双击查看恢复选项';
    }
    if (isChild) {
      return '子分类，${category.name}，${stats.open} 条待办，$rateText';
    }
    return '分类，${category.name}，${stats.open} 条待办，$rateText'
        '${hasChildren ? (expanded ? '，子分类已展开' : '，含子分类，已收起') : ''}'
        '。双击编辑，长按拖拽排序。';
  }

  /// 展开箭头：仅含子分类时渲染，否则占位保持对齐（04 §3.2）。
  Widget _expandArrow(AppColors c) {
    if (!hasChildren) return const SizedBox(width: 44);
    return AppPressable(
      onTap: sortMode ? null : onToggleExpand,
      behavior: HitTestBehavior.opaque,
      semanticLabel: expanded ? '收起子分类' : '展开子分类',
      child: Center(
        child: AnimatedRotation(
          turns: expanded ? 0.25 : 0,
          duration: AppMotion.tabSwitch,
          child: Icon(
            LucideIcons.chevronRight,
            size: 16,
            color: c.labelTertiary,
          ),
        ),
      ),
    );
  }

  Widget _colorBlock(AppColors c, Color iconColor, Color blockColor) {
    final size = isChild ? 24.0 : 28.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: blockColor, borderRadius: AppRadii.brSm),
      child: Icon(
        categoryIconFor(category.iconKey),
        size: 16,
        color: iconColor,
      ),
    );
  }

  /// 「{未完成数} 项 {完成率}%」；完成率保持中性辅助文案；
  /// 无待办「0 项 —」；归档行停止统计完成率「N 项 —」（04 §3.2）。
  Widget _stats(AppColors c) {
    final base = AppTextStyles.footnote.copyWith(color: c.labelTertiary);
    if (archived) {
      return Text('${stats.open} 项 —', style: base);
    }
    final rate = stats.completionRate;
    if (rate == null) {
      return Text('${stats.open} 项 —', style: base);
    }
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: '${stats.open} 项 '),
          TextSpan(
            text: '$rate%',
            style: TextStyle(color: c.labelTertiary),
          ),
        ],
      ),
    );
  }

  Widget _moreButton(AppColors c) {
    return AppPressable(
      onTap: onMore,
      behavior: HitTestBehavior.opaque,
      semanticLabel: '${category.name} 更多操作',
      child: Center(
        child: Icon(LucideIcons.ellipsis, size: 20, color: c.labelTertiary),
      ),
    );
  }

  /// 排序模式拖拽手柄（04 §3.3）：按住手柄拖拽。
  Widget _dragHandle(AppColors c) {
    final grip = SizedBox(
      width: 44,
      height: 44,
      child: Center(
        child: Icon(LucideIcons.gripVertical, size: 16, color: c.labelTertiary),
      ),
    );
    return Draggable<Category>(
      data: category,
      feedback: CategoryRowFeedback(category: category, stats: stats),
      childWhenDragging: Opacity(opacity: 0.3, child: grip),
      onDragStarted: onDragStarted,
      onDragEnd: (_) => onDragEnded?.call(),
      child: grip,
    );
  }
}

/// 拖拽浮起态（04 §5.6）：scale 1.02 + 浮层阴影
///（dark 下改 1px separator 描边，规范 §3.3）。
class CategoryRowFeedback extends StatelessWidget {
  const CategoryRowFeedback({
    super.key,
    required this.category,
    required this.stats,
  });

  final Category category;
  final CategoryStats stats;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width - 32;
    return Material(
      color: Colors.transparent,
      child: Transform.scale(
        scale: 1.02,
        child: Container(
          width: width,
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            color: c.bgPrimary,
            borderRadius: AppRadii.brLg,
            border: isDark ? Border.all(color: c.separator, width: 1) : null,
            boxShadow: isDark
                ? null
                : [
                    // TODO(token): 阴影色无 token，按规范 §3.3 取 rgba(0,0,0,0.10)。
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: c.categorySurface(category.color),
                  borderRadius: AppRadii.brSm,
                ),
                child: Icon(
                  categoryIconFor(category.iconKey),
                  size: 16,
                  color: categoryIconColor(c, category.color),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.name,
                  style: AppTextStyles.body.copyWith(color: c.labelPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${stats.open} 项',
                style: AppTextStyles.footnote.copyWith(color: c.labelTertiary),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}
