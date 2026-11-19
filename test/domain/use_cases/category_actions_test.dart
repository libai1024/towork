import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/data/repositories/category_repository.dart';
import 'package:towork/data/repositories/todo_repository.dart';
import 'package:towork/domain/models/models.dart';
import 'package:towork/domain/repositories/repository_error.dart';
import 'package:towork/domain/use_cases/category_actions.dart';

const color = Color(0xFF1783FF);
final now = DateTime.utc(2026, 9, 23);
Category category(String id, {String? parent, bool archived = false}) =>
    Category(
      id: id,
      name: id,
      color: color,
      parentId: parent,
      archived: archived,
    );
Todo task(String id, String? categoryId) =>
    Todo(id: id, title: id, categoryId: categoryId, createdAt: now);

class FailingCategories extends CategoryRepository {
  FailingCategories() : super(initial: [category('root')]);
  @override
  void restoreAll(List<Category> snapshot) => throw const RepositoryException(
    RepositoryErrorCode.conflict,
    'write rejected',
  );
}

void main() {
  late CategoryRepository categories;
  late TodoRepository todos;
  late CategoryActions actions;
  final receipts = <CategoryUndo>[];
  CategoryUndo track(CategoryUndo receipt) {
    receipts.add(receipt);
    return receipt;
  }

  setUp(() {
    categories = CategoryRepository(
      initial: [
        category('root'),
        category('child', parent: 'root'),
        category('other'),
      ],
    );
    todos = TodoRepository(
      initial: [
        task('root-task', 'root'),
        task('child-task', 'child'),
        task('other-task', 'other'),
      ],
      clock: () => now,
    );
    actions = CategoryActions(categories: categories, todos: todos);
  });
  tearDown(() {
    for (final receipt in receipts) {
      receipt.dispose();
    }
    receipts.clear();
    categories.dispose();
    todos.dispose();
  });

  test('undo compensates only affected records and preserves unrelated additions and edits', () {
    final undo = track(actions.delete('root'));
    expect(categories.byId('child')!.parentId, isNull);
    expect(todos.byId('root-task')!.categoryId, isNull);
    expect(todos.byId('child-task')!.categoryId, 'child');

    final addedCategory = categories.createCategory(name: '新增', color: color);
    final addedTask = todos.addTodo(title: '新任务', categoryId: addedCategory.id);
    todos.updateTodo(todos.byId('other-task')!.copyWith(title: '后续编辑'));
    final editedOther = todos.byId('other-task');
    expect(undo.undo(), CategoryUndoResult.restored);

    expect(categories.byId('root'), isNotNull);
    expect(categories.byId('child')!.parentId, 'root');
    expect(todos.byId('root-task')!.categoryId, 'root');
    expect(identical(categories.byId(addedCategory.id), addedCategory), isTrue);
    expect(identical(todos.byId(addedTask.id), addedTask), isTrue);
    expect(identical(todos.byId('other-task'), editedOther), isTrue);
    expect(undo.undo(), CategoryUndoResult.unavailable);
  });

  test('a related todo edit rejects the entire compensation without overwriting it', () {
    final undo = track(actions.delete('root'));
    todos.updateTodo(todos.byId('root-task')!.copyWith(title: '已经改过'));
    expect(undo.undo(), CategoryUndoResult.conflict);
    expect(todos.byId('root-task')!.title, '已经改过');
    expect(todos.byId('root-task')!.categoryId, isNull);
    expect(categories.byId('root'), isNull);
    expect(categories.byId('child')!.parentId, isNull);
  });

  test('a related category edit is not overwritten by restoration', () {
    final undo = track(actions.delete('root'));
    categories.updateCategory('child', name: '已重命名');
    expect(undo.undo(), CategoryUndoResult.conflict);
    expect(categories.byId('child')!.name, '已重命名');
    expect(categories.byId('root'), isNull);
  });

  test('a task deleted after moving to inbox is not resurrected', () {
    final undo = track(actions.delete('root'));
    todos.removeById('root-task');
    expect(undo.undo(), CategoryUndoResult.conflict);
    expect(todos.byId('root-task'), isNull);
    expect(categories.byId('root'), isNull);
  });

  test('archiving and its undo never write or roll back task state', () {
    var writes = 0;
    final remove = todos.addListener((_) => writes++, fireImmediately: false);
    addTearDown(remove);
    final undo = track(actions.setArchived('root', true));
    expect(writes, 0);
    expect(categories.byId('root')!.archived, isTrue);
    expect(categories.byId('child')!.archived, isTrue);
    todos.updateTodo(todos.byId('root-task')!.copyWith(title: '归档后的编辑'));
    final edited = todos.byId('root-task');
    expect(writes, 1);
    expect(undo.undo(), CategoryUndoResult.restored);
    expect(writes, 1);
    expect(identical(todos.byId('root-task'), edited), isTrue);
    expect(categories.byId('root')!.archived, isFalse);
    expect(categories.byId('child')!.archived, isFalse);
  });

  test('archiving undo does not revive a child deleted later', () {
    final undo = track(actions.setArchived('root', true));
    categories.removeSubtree('child');
    expect(undo.undo(), CategoryUndoResult.conflict);
    expect(categories.byId('child'), isNull);
    expect(categories.byId('root')!.archived, isTrue);
  });

  test('deletion uses the current tree after confirmation, for categories and todos alike', () {
    final preConfirmationIds = categories.subtreeIds('root');
    expect(preConfirmationIds, {'root', 'child'});
    // While confirmation is open, one child moves out and a new one is added.
    categories.moveCategory('child', 'other', 0);
    final addedChild = categories.createCategory(
      name: '新子分类',
      color: color,
      parentId: 'root',
    );
    final addedTask = todos.addTodo(title: '新子待办', categoryId: addedChild.id);
    final undo = track(
      actions.delete('root', policy: CategoryDeletionPolicy.deleteSubtree),
    );

    expect(categories.byId('root'), isNull);
    expect(categories.byId(addedChild.id), isNull);
    expect(todos.byId('root-task'), isNull);
    expect(todos.byId(addedTask.id), isNull);
    expect(categories.byId('child')!.parentId, 'other');
    expect(todos.byId('child-task')!.categoryId, 'child');
    expect(
      todos.snapshot.every(
        (todo) =>
            todo.categoryId == null || categories.byId(todo.categoryId) != null,
      ),
      isTrue,
    );

    final unrelated = todos.addTodo(title: '之后的新待办', categoryId: 'other');
    expect(undo.undo(), CategoryUndoResult.restored);
    expect(todos.byId(unrelated.id), same(unrelated));
    expect(categories.byId(addedChild.id)!.parentId, 'root');
    expect(categories.byId('child')!.parentId, 'other');
  });

  test('a newly attached descendant rejects a restoration that would create three levels', () {
    final undo = track(actions.delete('root'));
    final added = categories.createCategory(
      name: '新孙分类',
      color: color,
      parentId: 'child',
    );
    expect(undo.undo(), CategoryUndoResult.conflict);
    expect(categories.byId(added.id)!.parentId, 'child');
    expect(categories.byId('child')!.parentId, isNull);
    expect(categories.byId('root'), isNull);
  });

  test(
    'delete-recreate-delete ABA is detected and never resurrects that category',
    () {
      final original = categories.byId('root')!;
      final undo = track(
        actions.delete('root', policy: CategoryDeletionPolicy.deleteSubtree),
      );
      categories.add(original);
      categories.removeSubtree('root');
      expect(undo.undo(), CategoryUndoResult.conflict);
      expect(categories.byId('root'), isNull);
      expect(todos.byId('root-task'), isNull);
    },
  );

  test(
    'an undo whose original parent was deleted cannot produce an orphan',
    () {
      final undo = track(actions.delete('child'));
      categories.removeSubtree('root');
      expect(undo.undo(), CategoryUndoResult.conflict);
      expect(categories.byId('child'), isNull);
      expect(todos.byId('child-task')!.categoryId, isNull);
    },
  );

  test('expired receipts cannot later apply stale compensations', () {
    final undo = track(actions.delete('root'));
    undo.dispose();
    expect(undo.undo(), CategoryUndoResult.unavailable);
    expect(categories.byId('root'), isNull);
  });

  test(
    'failure of the second repository write compensates the first write',
    () {
      final failing = FailingCategories();
      addTearDown(failing.dispose);
      final before = todos.snapshot;
      final command = CategoryActions(categories: failing, todos: todos);
      expect(() => command.delete('root'), throwsA(isA<RepositoryException>()));
      expect(todos.snapshot, orderedEquals(before));
      expect(todos.byId('root-task')!.categoryId, 'root');
      expect(failing.byId('root'), isNotNull);
    },
  );
}
