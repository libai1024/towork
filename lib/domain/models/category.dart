import 'dart:ui' show Color;

const Object _keep = Object();

/// 两级分类树（规范 §1.5 预设 8 色盘取色）。
class Category {
  const Category({
    required this.id,
    this.version = 0,
    required this.name,
    required this.color,
    this.iconKey = 'folder',
    this.parentId,
    this.sortOrder = 0,
    this.archived = false,
  });

  final String id;
  final int version;
  final String name;
  final Color color;

  /// Lucide 图标键，限客户端策展集（04-categories.md §8.1），缺省 folder。
  final String iconKey;
  final String? parentId;
  final int sortOrder;
  final bool archived;

  Category copyWith({
    String? name,
    Color? color,
    String? iconKey,
    Object? parentId = _keep,
    int? sortOrder,
    bool? archived,
  }) {
    return Category(
      id: id,
      version: version,
      name: name ?? this.name,
      color: color ?? this.color,
      iconKey: iconKey ?? this.iconKey,
      parentId: identical(parentId, _keep)
          ? this.parentId
          : parentId as String?,
      sortOrder: sortOrder ?? this.sortOrder,
      archived: archived ?? this.archived,
    );
  }
}
