part of 'categories_page.dart';

/// 拖拽落点意图（04-categories.md §5.6）。
/// gap = 间隙落点（同级排序 / 提升为一级）；demote = 悬停 350ms 降级为子。
class _DropIntent {
  const _DropIntent.gap({
    required this.anchorId,
    required this.parentId,
    required this.index,
  }) : demoteTargetId = null;

  const _DropIntent.demote(String targetId)
    : demoteTargetId = targetId,
      anchorId = targetId,
      parentId = null,
      index = -1;

  /// 产生该意图的行（用于 onLeave 时判断是否清除）。
  final String anchorId;

  /// gap：目标父级（null = 一级）。
  final String? parentId;

  /// gap：在同级中的插入位。
  final int index;

  /// demote：目标一级分类 id。
  final String? demoteTargetId;

  bool get isDemote => demoteTargetId != null;

  bool sameAs(_DropIntent? other) {
    if (other == null) return false;
    return anchorId == other.anchorId &&
        parentId == other.parentId &&
        index == other.index &&
        demoteTargetId == other.demoteTargetId;
  }
}
