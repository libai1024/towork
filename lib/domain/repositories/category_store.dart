import 'package:flutter/material.dart' show Color;

import '../models/models.dart';
import 'list_store.dart';

abstract class CategoryStore extends ListStore<Category> {
  CategoryStore(super.initial);
  List<Category> get roots;
  List<Category> childrenOf(String parentId);
  List<Category> get archivedRoots;
  List<Category> archivedChildrenOf(String parentId);
  Category? byId(String? id);
  Set<String> subtreeIds(String id);
  void add(Category category);
  Category createCategory({
    required String name,
    required Color color,
    String iconKey = 'folder',
    String? parentId,
  });
  void updateCategory(String id, {String? name, Color? color, String? iconKey});
  bool moveCategory(String id, String? newParentId, int newIndex);
  bool moveWithinSiblings(String id, int delta);
  void setArchived(String id, bool archived);
  void removeSubtree(String id);
  void removeKeepChildren(String id);
  void restoreAll(List<Category> snapshot);
}
