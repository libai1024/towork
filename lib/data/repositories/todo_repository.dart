import '../../domain/models/models.dart';
import '../../domain/repositories/todo_store.dart';
import '../seeds/todo_seed.dart';
import '../../domain/repositories/repository_error.dart';
import 'repository_validation.dart';

class TodoRepository extends TodoStore {
  TodoRepository({
    List<Todo>? initial,
    DateTime Function()? clock,
    this.idFactory,
  }) : _clock = clock ?? DateTime.now,
       super(
         requireUniqueIds(
           initial ?? seedTodos((clock ?? DateTime.now)()),
           (Todo todo) => todo.id,
         ),
       );

  final DateTime Function() _clock;

  int _seq = 1000;
  final String Function()? idFactory;

  @override
  Todo addTodo({
    required String title,
    String? note,
    List<RemindRule> remindRules = const [],
    TodoPriority priority = TodoPriority.none,
    DateTime? dueAt,
    DateTime? remindAt,
    String? categoryId,
    TodoSource source = TodoSource.manual,
    String? sourceMessageId,
    String? id,
  }) {
    if (id != null && byId(id) != null) {
      throw const RepositoryException(
        RepositoryErrorCode.conflict,
        '待办 ID 已存在',
      );
    }
    var nextId = id;
    while (nextId == null || byId(nextId) != null) {
      nextId = idFactory?.call() ?? 't_gen_${_seq++}';
    }
    final todo = Todo(
      id: nextId,
      title: requireText(title, '待办标题'),
      note: note,
      remindRules: remindRules,
      priority: priority,
      dueAt: dueAt,
      remindAt: remindAt,
      categoryId: categoryId,
      source: source,
      sourceMessageId: sourceMessageId,
      sortOrder: state.length,
      createdAt: _clock(),
      updatedAt: _clock(),
    );
    state = [todo, ...state];
    return todo;
  }

  @override
  void insertRaw(Todo todo) {
    if (byId(todo.id) != null) return;
    state = [todo, ...state];
  }

  /// 原位插回（删除撤销用）。
  @override
  void insertAt(int index, Todo todo) {
    if (state.any((e) => e.id == todo.id)) return;
    final list = [...state];
    list.insert(index.clamp(0, list.length), todo);
    state = list;
  }

  @override
  void removeById(String id) {
    state = state.where((e) => e.id != id).toList();
  }

  @override
  void updateTodo(Todo todo) {
    state = [
      for (final e in state)
        e.id == todo.id
            ? todo.copyWith(
                title: requireText(todo.title, '待办标题'),
                updatedAt: _clock(),
                completedAt: todo.status == TodoStatus.done
                    ? (todo.completedAt ?? _clock())
                    : null,
              )
            : e,
    ];
  }

  @override
  void toggleDone(String id) {
    state = [
      for (final e in state)
        if (e.id == id)
          e.copyWith(
            status: e.status == TodoStatus.done
                ? TodoStatus.pending
                : TodoStatus.done,
            completedAt: e.status == TodoStatus.done ? null : _clock(),
            updatedAt: _clock(),
          )
        else
          e,
    ];
  }

  /// 删除分类级联（04 §5.5）：把这些分类下的待办移到「未分类」。
  @override
  void reassignTodos(Set<String> categoryIds) {
    state = [
      for (final e in state)
        categoryIds.contains(e.categoryId) ? e.copyWith(categoryId: null) : e,
    ];
  }

  /// 删除分类级联：把这些分类下的待办一并删除。
  @override
  void removeTodosIn(Set<String> categoryIds) {
    state = state.where((e) => !categoryIds.contains(e.categoryId)).toList();
  }

  /// 撤销快照恢复。
  @override
  void restoreAll(List<Todo> snapshot) =>
      state = requireUniqueIds(snapshot, (todo) => todo.id);
}
