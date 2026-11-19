import 'package:towork/app/todo/async_todo_commands.dart';
import 'package:towork/app/workspace_ui_commands.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/app/workspace_clock.dart';
import 'package:towork/data/repositories/category_repository.dart';
import 'package:towork/data/repositories/todo_repository.dart';
import 'package:towork/domain/models/models.dart';
import 'package:towork/core/todo/todo_utils.dart';
import 'package:towork/app/todo/todo_view_model.dart';

final _now = DateTime(2026, 9, 23, 12);
const _blue = Color(0xFF007AFF);
const _categories = [
  Category(id: 'work', name: '工作', color: _blue, sortOrder: 1),
  Category(id: 'home', name: '生活', color: _blue, sortOrder: 0),
  Category(id: 'project', name: '项目', color: _blue, parentId: 'work'),
];

Todo _todo(
  String id, {
  String? title,
  String? note,
  String? category,
  TodoStatus status = TodoStatus.pending,
  int order = 0,
  DateTime? due,
  DateTime? completed,
  DateTime? updated,
}) => Todo(
  id: id,
  title: title ?? id,
  note: note,
  categoryId: category,
  status: status,
  sortOrder: order,
  dueAt: due,
  completedAt: completed,
  updatedAt: updated,
  createdAt: _now.subtract(const Duration(days: 7)),
);

(TodoViewModel, TodoRepository, CategoryRepository) _fixture(List<Todo> items) {
  final todos = TodoRepository(initial: items, clock: () => _now);
  final categories = CategoryRepository(initial: _categories);
  addTearDown(todos.dispose);
  addTearDown(categories.dispose);
  return (
    TodoViewModel(todos: todos, categories: categories, clock: () => _now),
    todos,
    categories,
  );
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed),
  );

  test('category subtree, search, quick filter and completion compose', () {
    final (model, _, _) = _fixture([
      _todo('root', title: '预算', category: 'work', due: _now),
      _todo('child', note: '预算', category: 'project', due: _now),
      _todo('other', title: '预算', category: 'home', due: _now),
      _todo('later', title: '预算', category: 'work', due: DateTime(2026, 10)),
      _todo('unmatched', title: '招聘', category: 'work', due: _now),
      _todo('done', title: '预算', category: 'work', status: TodoStatus.done),
    ]);
    final today = model.overview(
      const TodoQuery(
        filter: TodoQuickFilter.today,
        categoryId: 'work',
        search: ' 预算 ',
      ),
    );
    expect(today.visible.map((t) => t.id), ['root', 'child']);
    // Badges follow the category subtree, independently of the search text.
    expect(today.counts[TodoQuickFilter.today], 3);
    expect(today.counts[TodoQuickFilter.all], 4);
    final child = model.overview(const TodoQuery(categoryId: 'project'));
    expect(child.counts[TodoQuickFilter.all], 1);
    expect(child.visible.single.id, 'child');
    expect(model.overview(const TodoQuery()).counts[TodoQuickFilter.all], 5);
    expect(
      model
          .overview(const TodoQuery(categoryId: 'work', showCompleted: false))
          .visible
          .map((t) => t.id),
      ['root', 'child', 'later', 'unmatched'],
    );
    expect(
      model
          .overview(
            const TodoQuery(filter: TodoQuickFilter.done, showCompleted: false),
          )
          .visible
          .single
          .id,
      'done',
    );
  });

  test(
    'category groups aggregate children in root order with stable task order',
    () {
      final (model, _, _) = _fixture([
        _todo('child', category: 'project', order: 2),
        _todo('none'),
        _todo('root', category: 'work', order: 1),
        _todo('home', category: 'home'),
      ]);
      final overview = model.overview(const TodoQuery());
      expect(overview.groups.map((g) => g.key), ['home', 'work', '_none']);
      expect(overview.groups[1].todos.map((t) => t.id), ['root', 'child']);
      expect(model.categoryDisplay(overview.visible.first), ('工作/项目', _blue));
      expect(() => overview.visible.clear(), throwsUnsupportedError);
      expect(() => overview.groups[1].todos.clear(), throwsUnsupportedError);
    },
  );

  test(
    'board preserves active order and combines closed states by recent change',
    () {
      final (model, _, _) = _fixture([
        _todo('pending-later', order: 2),
        _todo('pending-first', order: 1),
        _todo('progress', status: TodoStatus.inProgress),
        _todo('done', status: TodoStatus.done, completed: _now),
        _todo(
          'cancelled',
          status: TodoStatus.cancelled,
          updated: _now.subtract(const Duration(hours: 1)),
        ),
        _todo('old-done', status: TodoStatus.done),
      ]);
      final columns = model.overview(const TodoQuery()).columns;
      expect(columns.map((c) => c.status), [
        TodoStatus.inProgress,
        TodoStatus.pending,
        TodoStatus.done,
      ]);
      expect(columns[1].todos.map((t) => t.id), [
        'pending-first',
        'pending-later',
      ]);
      expect(columns[2].todos.map((t) => t.id), [
        'done',
        'cancelled',
        'old-done',
      ]);
    },
  );

  test(
    'batch completion deduplicates IDs and undo preserves later content edits',
    () {
      final (model, todos, _) = _fixture([
        _todo('progress', status: TodoStatus.inProgress, note: '原备注'),
        _todo('pending'),
        _todo('closed', status: TodoStatus.cancelled),
      ]);
      final mutation = model.complete([
        'progress',
        'pending',
        'progress',
        'closed',
        'missing',
      ]);
      expect(mutation.count, 2);
      expect(todos.byId('progress')!.completedAt, _now);
      todos.updateTodo(
        todos.byId('progress')!.copyWith(title: '修改标题', note: '新备注'),
      );
      mutation.undo();
      final restored = todos.byId('progress')!;
      expect(restored.status, TodoStatus.inProgress);
      expect(restored.completedAt, isNull);
      expect(restored.title, '修改标题');
      expect(restored.note, '新备注');
      expect(todos.byId('pending')!.status, TodoStatus.pending);
      expect(todos.byId('closed')!.status, TodoStatus.cancelled);
      model.complete(['progress']);
      mutation.undo();
      expect(
        todos.byId('progress')!.status,
        TodoStatus.done,
        reason: 'undo receipts are one-use',
      );
    },
  );

  test(
    'completion undo cannot revive deleted tasks or replace later statuses',
    () {
      final (model, todos, _) = _fixture([_todo('deleted'), _todo('changed')]);
      final mutation = model.complete(['deleted', 'changed']);
      todos.removeById('deleted');
      todos.updateTodo(
        todos.byId('changed')!.copyWith(status: TodoStatus.inProgress),
      );
      mutation.undo();
      expect(todos.byId('deleted'), isNull);
      expect(todos.byId('changed')!.status, TodoStatus.inProgress);

      final toggled = model.toggleDone('changed');
      toggled.undo();
      expect(todos.byId('changed')!.status, TodoStatus.inProgress);
      expect(model.toggleDone('missing').count, 0);
    },
  );

  test(
    'batch nullable field changes use current records and keep unrelated data',
    () {
      final (model, todos, _) = _fixture([
        _todo('a', category: 'work', due: _now, note: '保留备注'),
        _todo('b', category: 'home', due: _now),
      ]);
      todos.updateTodo(todos.byId('a')!.copyWith(title: '最新标题'));
      expect(model.setCategory(['a', 'a', 'missing'], null), 1);
      expect(model.setDue(['a', 'missing'], null), 1);
      final changed = todos.byId('a')!;
      expect(changed.title, '最新标题');
      expect(changed.note, '保留备注');
      expect(changed.categoryId, isNull);
      expect(changed.dueAt, isNull);
      expect(todos.byId('b')!.categoryId, 'home');
      expect(todos.byId('b')!.dueAt, _now);
    },
  );

  test('delete undo restores original ordering without overwriting concurrent edits', () {
    final (model, todos, _) = _fixture([
      _todo('a'),
      _todo('b'),
      _todo('c'),
      _todo('d'),
    ]);
    final deleted = model.delete(['d', 'b', 'b', 'missing']);
    expect(deleted.count, 2);
    expect(todos.snapshot.map((t) => t.id), ['a', 'c']);
    todos.updateTodo(todos.byId('c')!.copyWith(title: '稍后编辑'));
    deleted.undo();
    expect(todos.snapshot.map((t) => t.id), ['a', 'b', 'c', 'd']);
    expect(todos.byId('c')!.title, '稍后编辑');

    final removedAgain = model.delete(['b']);
    todos.insertRaw(_todo('new'));
    todos.insertRaw(_todo('b', title: '重新创建'));
    removedAgain.undo();
    expect(todos.snapshot.where((t) => t.id == 'b').length, 1);
    expect(todos.byId('b')!.title, '重新创建');
    expect(todos.byId('new'), isNotNull);
  });

  test(
    'quick and board creation use repository validation and requested status',
    () async {
      final (_, todos, categories) = _fixture([]);
      final model = AsyncTodoCommands(
        WorkspaceUiCommands(todos, categories),
        () => _now,
      );
      final pending = await model.create(
        title: '  待办  ',
        categoryId: 'project',
        dueAt: _now,
      );
      expect(pending.title, '待办');
      expect(pending.categoryId, 'project');
      expect(pending.dueAt, _now);
      expect(pending.status, TodoStatus.pending);
      expect(
        (await model.create(
          title: '进行中',
          status: TodoStatus.inProgress,
        )).completedAt,
        isNull,
      );
      final done = await model.create(title: '完成', status: TodoStatus.done);
      expect(done.completedAt, _now);
      expect(todos.byId(done.id)!.status, TodoStatus.done);
      await expectLater(model.create(title: '  '), throwsException);
      expect(todos.snapshot.length, 3);
    },
  );

  test('overview provider reacts to task and category changes without duplicate state', () async {
    final container = ProviderContainer(
      overrides: [
        todoListProvider.overrideWith(
          (ref) => TodoRepository(initial: [_todo('a', category: 'work')]),
        ),
        categoryListProvider.overrideWith(
          (ref) => CategoryRepository(initial: _categories),
        ),
      ],
    );
    addTearDown(container.dispose);
    const query = TodoQuery();
    final subscription = container.listen(
      todoOverviewProvider(query),
      (_, _) {},
    );
    addTearDown(subscription.close);
    expect(subscription.read().groups.single.title, '工作');
    container
        .read(categoryListProvider.notifier)
        .updateCategory('work', name: '工作事项');
    expect(
      container.read(todoOverviewProvider(query)).groups.single.title,
      '工作事项',
    );
    await container
        .read(asyncTodoCommandsProvider)
        .create(title: 'b', categoryId: 'home');
    final overview = container.read(todoOverviewProvider(const TodoQuery()));
    expect(overview.visible.map((t) => t.id), hasLength(2));
    expect(overview.groups.map((g) => g.title), ['生活', '工作事项']);
  });

  test('a deadline between minute ticks updates overdue membership and global counts', () {
    fakeAsync((async) {
      final start = DateTime(2026, 9, 23, 12, 0, 10);
      final due = start.add(const Duration(seconds: 5));
      final container = ProviderContainer(
        overrides: [
          workspaceNowProvider.overrideWithValue(
            () => start.add(async.elapsed),
          ),
          todoListProvider.overrideWith(
            (ref) => TodoRepository(initial: [_todo('a', due: due)]),
          ),
          categoryListProvider.overrideWith(
            (ref) => CategoryRepository(initial: []),
          ),
        ],
      );
      final subscription = container.listen(
        todoOverviewProvider(const TodoQuery(filter: TodoQuickFilter.overdue)),
        (_, _) {},
      );
      expect(subscription.read().visible, isEmpty);
      async.elapse(const Duration(seconds: 5));
      expect(
        subscription.read().visible,
        isEmpty,
        reason: 'exact deadline is not yet overdue',
      );
      async.elapse(const Duration(microseconds: 1));
      final afterDeadline = subscription.read();
      expect(afterDeadline.visible.single.id, 'a');
      expect(afterDeadline.counts[TodoQuickFilter.overdue], 1);
      expect(
        afterDeadline.now.minute,
        0,
        reason: 'does not wait for the next minute tick',
      );
      subscription.close();
      async.elapse(Duration.zero);
      expect(async.pendingTimers, isEmpty);
      container.dispose();
      async.elapse(Duration.zero); // Drain Riverpod's disposal scheduler.
      expect(async.pendingTimers, isEmpty);
    });
  });

  test(
    'midnight changes the current-day filter without editing any repository',
    () {
      fakeAsync((async) {
        final start = DateTime(2026, 9, 23, 23, 59, 59);
        final container = ProviderContainer(
          overrides: [
            workspaceNowProvider.overrideWithValue(
              () => start.add(async.elapsed),
            ),
            todoListProvider.overrideWith(
              (ref) => TodoRepository(
                initial: [
                  _todo('yesterday', due: DateTime(2026, 9, 23, 18)),
                  _todo('today', due: DateTime(2026, 9, 24, 9)),
                ],
              ),
            ),
            categoryListProvider.overrideWith(
              (ref) => CategoryRepository(initial: []),
            ),
          ],
        );
        final subscription = container.listen(
          todoOverviewProvider(const TodoQuery(filter: TodoQuickFilter.today)),
          (_, _) {},
        );
        expect(subscription.read().visible.single.id, 'yesterday');
        async.elapse(const Duration(seconds: 1));
        expect(subscription.read().visible.single.id, 'today');
        expect(subscription.read().now, DateTime(2026, 9, 24));
        subscription.close();
        container.dispose();
        async.elapse(Duration.zero); // Drain Riverpod's disposal scheduler.
        expect(async.pendingTimers, isEmpty);
      });
    },
  );

  test(
    'backgrounding cancels deadline timers and resume refreshes the projection',
    () {
      fakeAsync((async) {
        final start = DateTime(2026, 9, 23, 12, 0, 10);
        final container = ProviderContainer(
          overrides: [
            workspaceNowProvider.overrideWithValue(
              () => start.add(async.elapsed),
            ),
            todoListProvider.overrideWith(
              (ref) => TodoRepository(
                initial: [
                  _todo('a', due: start.add(const Duration(seconds: 5))),
                ],
              ),
            ),
            categoryListProvider.overrideWith(
              (ref) => CategoryRepository(initial: []),
            ),
          ],
        );
        final subscription = container.listen(
          todoOverviewProvider(
            const TodoQuery(filter: TodoQuickFilter.overdue),
          ),
          (_, _) {},
        );
        binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        expect(subscription.read().visible, isEmpty);
        async.elapse(Duration.zero);
        expect(async.pendingTimers, isEmpty);
        async.elapse(const Duration(hours: 1));
        expect(subscription.read().visible, isEmpty);
        binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        expect(subscription.read().visible.single.id, 'a');
        subscription.close();
        container.dispose();
        async.elapse(Duration.zero); // Drain Riverpod's disposal scheduler.
        expect(async.pendingTimers, isEmpty);
      });
    },
  );
}
