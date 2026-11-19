import '../../domain/models/models.dart';
import '../../domain/repositories/category_store.dart';
import '../seeds/category_seed.dart';

import 'package:flutter/material.dart' show Color;

import '../../domain/repositories/repository_error.dart';
import 'repository_validation.dart';

class CategoryRepository extends CategoryStore {
  CategoryRepository({List<Category>? initial, this.idFactory})
    : super(_validateTree(initial ?? seedCategories()));

  int _seq = 100;
  final String Function()? idFactory;

  @override
  List<Category> get roots =>
      state.where((e) => e.parentId == null && !e.archived).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  @override
  List<Category> childrenOf(String parentId) =>
      state.where((e) => e.parentId == parentId && !e.archived).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  @override
  List<Category> get archivedRoots =>
      state.where((e) => e.parentId == null && e.archived).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  @override
  List<Category> archivedChildrenOf(String parentId) =>
      state.where((e) => e.parentId == parentId && e.archived).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  @override
  Category? byId(String? id) {
    if (id == null) return null;
    for (final e in state) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// 自身 + 直接子分类（严格两级，子分类无后代）。
  @override
  Set<String> subtreeIds(String id) => {
    id,
    for (final e in state)
      if (e.parentId == id) e.id,
  };

  @override
  void add(Category category) => state = _validateTree([...state, category]);

  @override
  Category createCategory({
    required String name,
    required Color color,
    String iconKey = 'folder',
    String? parentId,
  }) {
    String id;
    do {
      id = idFactory?.call() ?? 'cat_gen_${_seq++}';
    } while (byId(id) != null);
    final category = Category(
      id: id,
      name: requireText(name, '分类名称'),
      color: color,
      iconKey: iconKey,
      parentId: parentId,
      sortOrder: _nextSortOrder(parentId),
    );
    add(category);
    return category;
  }

  @override
  void updateCategory(
    String id, {
    String? name,
    Color? color,
    String? iconKey,
  }) {
    state = [
      for (final e in state)
        e.id == id
            ? e.copyWith(
                name: name == null ? null : requireText(name, '分类名称'),
                color: color,
                iconKey: iconKey,
              )
            : e,
    ];
  }

  int _nextSortOrder(String? parentId) {
    var max = -1;
    for (final e in state) {
      if (e.parentId == parentId && !e.archived && e.sortOrder > max) {
        max = e.sortOrder;
      }
    }
    return max + 1;
  }

  List<Category> _siblings(String? parentId) =>
      state.where((e) => e.parentId == parentId && !e.archived).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  Category _rebuild(
    Category e, {
    required String? parentId,
    required int sortOrder,
    bool? archived,
  }) {
    return Category(
      id: e.id,
      version: e.version,
      name: e.name,
      color: e.color,
      iconKey: e.iconKey,
      parentId: parentId,
      sortOrder: sortOrder,
      archived: archived ?? e.archived,
    );
  }

  /// 拖拽/归属变更落点生效：同级重排 + 层级调整（04 §5.6）。
  /// 严格两级：含子分类的一级分类不得降级，父级必须是一级。非法返回 false。
  @override
  bool moveCategory(String id, String? newParentId, int newIndex) {
    final category = byId(id);
    if (category == null || category.archived || newParentId == id) {
      return false;
    }
    if (newParentId != null) {
      final target = byId(newParentId);
      if (target == null || target.parentId != null || target.archived) {
        return false;
      }
      if (state.any((child) => child.parentId == id)) return false;
    }
    final oldParentId = category.parentId;
    final oldSiblings = _siblings(oldParentId)..removeWhere((e) => e.id == id);
    final newSiblings = newParentId == oldParentId
        ? oldSiblings
        : _siblings(newParentId);
    final clamped = newIndex.clamp(0, newSiblings.length);
    newSiblings.insert(clamped, category);

    final reindexed = <String, Category>{};
    for (var i = 0; i < newSiblings.length; i++) {
      final e = newSiblings[i];
      reindexed[e.id] = _rebuild(
        e,
        parentId: e.id == id ? newParentId : e.parentId,
        sortOrder: i,
      );
    }
    if (newParentId != oldParentId) {
      for (var i = 0; i < oldSiblings.length; i++) {
        reindexed[oldSiblings[i].id] = _rebuild(
          oldSiblings[i],
          parentId: oldParentId,
          sortOrder: i,
        );
      }
    }
    state = [for (final e in state) reindexed[e.id] ?? e];
    return true;
  }

  /// 同级上移/下移（无障碍替代拖拽，04 §5.4）。越界返回 false。
  @override
  bool moveWithinSiblings(String id, int delta) {
    final category = byId(id);
    if (category == null) return false;
    final siblings = _siblings(category.parentId);
    final index = siblings.indexWhere((e) => e.id == id);
    final target = index + delta;
    if (index < 0 || target < 0 || target >= siblings.length) return false;
    return moveCategory(id, category.parentId, target);
  }

  /// 归档/恢复，子树级联（04 §2.2「归档是状态不是层级」）。
  @override
  void setArchived(String id, bool archived) {
    final ids = subtreeIds(id);
    final parentId = byId(id)?.parentId;
    if (!archived && parentId != null) ids.add(parentId);
    state = [
      for (final e in state)
        ids.contains(e.id)
            ? _rebuild(
                e,
                parentId: e.parentId,
                sortOrder: e.sortOrder,
                archived: archived,
              )
            : e,
    ];
  }

  /// 删除分类与子树。
  @override
  void removeSubtree(String id) {
    final ids = subtreeIds(id);
    state = state.where((e) => !ids.contains(e.id)).toList();
  }

  /// 删除分类但把子分类提升为一级（保持相对顺序，接到一级末尾）。
  @override
  void removeKeepChildren(String id) {
    final children = state.where((child) => child.parentId == id).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    var next = _nextSortOrder(null);
    final promoted = <String, Category>{
      for (final child in children)
        child.id: _rebuild(child, parentId: null, sortOrder: next++),
    };
    state = [
      for (final e in state)
        if (e.id != id) promoted[e.id] ?? e,
    ];
  }

  /// 撤销快照恢复（归档/删除的「撤销」窗口）。
  @override
  void restoreAll(List<Category> snapshot) => state = _validateTree(snapshot);
}

List<Category> _validateTree(Iterable<Category> categories) {
  final items = requireUniqueIds(categories, (Category item) => item.id);
  final byId = {for (final item in items) item.id: item};
  for (final item in items) {
    requireText(item.name, '分类名称');
    if (item.parentId == null) continue;
    final parent = byId[item.parentId];
    if (parent == null ||
        parent.id == item.id ||
        parent.parentId != null ||
        (parent.archived && !item.archived)) {
      throw const RepositoryException(
        RepositoryErrorCode.invalidInput,
        '分类必须属于有效的一级分类',
      );
    }
  }
  return items;
}
