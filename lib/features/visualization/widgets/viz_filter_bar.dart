import 'package:flutter/material.dart';

import '../../../core/widgets/app_pressable.dart';
import '../../../domain/models/models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_text_styles.dart';

/// 分类过滤条（05 文档 §3.1 C 区，高 44）。
/// 「全部」+ 一级分类 Chip 多选，横滑，末端 16px 渐隐。
class VizFilterBar extends StatelessWidget {
  const VizFilterBar({
    super.key,
    required this.roots,
    required this.selected,
    required this.onToggle,
    required this.onSelectAll,
  });

  final List<Category> roots;

  /// 勾选中的一级分类 id；空 = 全部。
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onSelectAll;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final announcement = selected.isEmpty
        ? '未筛选，显示全部'
        : '已筛选：${roots.where((r) => selected.contains(r.id)).map((r) => r.name).join('、')}，图表已更新';
    return Semantics(
      liveRegion: true,
      label: announcement,
      child: SizedBox(
        height: 52,
        child: Stack(
          children: [
            ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 4, 32, 4),
              children: [
                _FilterChip(
                  label: '全部',
                  selected: selected.isEmpty,
                  onTap: onSelectAll,
                ),
                for (final root in roots) ...[
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: root.name,
                    dotColor: root.color,
                    selected: selected.contains(root.id),
                    onTap: () => onToggle(root.id),
                    semanticLabel:
                        '筛选：${root.name}，${selected.contains(root.id) ? '已选中，双击取消' : '未选中'}',
                  ),
                ],
              ],
            ),
            // 末端渐隐（内容遮罩，规范 §3.1 合规）
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  width: 16,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [c.bgGround.withValues(alpha: 0), c.bgGround],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    this.dotColor,
    this.onTap,
    this.semanticLabel,
  });

  final String label;
  final bool selected;
  final Color? dotColor;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fg = selected ? c.bgGround : c.labelPrimary;
    return AppPressable(
      onTap: onTap,
      minSize: 44,
      behavior: HitTestBehavior.translucent,
      semanticLabel: semanticLabel ?? label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? c.labelPrimary : c.fill1,
          borderRadius: AppRadii.brFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: c.categoryAccent(dotColor!),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTextStyles.footnote.copyWith(color: fg, height: 1),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
