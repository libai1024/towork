import '../models/models.dart';
import 'list_store.dart';

abstract class TodoReadStore extends ListStore<Todo> {
  TodoReadStore(super.initial);

  Todo? byId(String? id) =>
      id == null ? null : snapshot.where((todo) => todo.id == id).firstOrNull;
}

abstract class TodoStore extends TodoReadStore {
  TodoStore(super.initial);
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
  });
  void insertRaw(Todo todo);
  void insertAt(int index, Todo todo);
  void removeById(String id);
  void updateTodo(Todo todo);
  void toggleDone(String id);
  void reassignTodos(Set<String> categoryIds);
  void removeTodosIn(Set<String> categoryIds);
  void restoreAll(List<Todo> snapshot);
}
