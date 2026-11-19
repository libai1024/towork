import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../workspace_clock.dart';
import '../workspace_ui_commands.dart';
import '../../domain/models/models.dart';
import 'todo_view_model.dart';

final asyncTodoCommandsProvider = Provider<AsyncTodoCommands>(
  (ref) => AsyncTodoCommands(
    ref.watch(workspaceUiCommandsProvider),
    ref.watch(workspaceNowProvider),
  ),
);

class AsyncTodoCommands {
  AsyncTodoCommands(this.commands, this.clock);
  final WorkspaceUiCommands commands;
  final DateTime Function() clock;
  Future<TodoMutation> _change(
    TodoMutation Function(TodoViewModel) action,
  ) async {
    final change = await commands.run(
      (t, c) => action(TodoViewModel(todos: t, categories: c, clock: clock)),
    );
    return TodoMutation(count: change.value.count, undo: change.undo);
  }

  Future<TodoMutation> toggleDone(String id) =>
      _change((vm) => vm.toggleDone(id));
  Future<TodoMutation> complete(Iterable<String> ids) =>
      _change((vm) => vm.complete(ids));
  Future<TodoMutation> delete(Iterable<String> ids) =>
      _change((vm) => vm.delete(ids));
  Future<int> setCategory(Iterable<String> ids, String? categoryId) async =>
      (await commands.run(
        (t, c) => TodoViewModel(
          todos: t,
          categories: c,
          clock: clock,
        ).setCategory(ids, categoryId),
      )).value;
  Future<int> setDue(Iterable<String> ids, DateTime? dueAt) async =>
      (await commands.run(
        (t, c) => TodoViewModel(
          todos: t,
          categories: c,
          clock: clock,
        ).setDue(ids, dueAt),
      )).value;
  Future<Todo> create({
    required String title,
    String? note,
    TodoPriority priority = TodoPriority.none,
    List<RemindRule> remindRules = const [],
    String? categoryId,
    DateTime? dueAt,
    TodoStatus status = TodoStatus.pending,
    String? operationId,
  }) async {
    final result = await commands.appendTodo(
      title: title,
      note: note,
      priority: priority,
      remindRules: remindRules,
      categoryId: categoryId,
      dueAt: dueAt,
      status: status,
      operationId: operationId,
      clock: clock,
    );
    return result.value;
  }
}
