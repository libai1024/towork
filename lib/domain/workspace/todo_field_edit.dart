import '../models/todo.dart';

enum _Operation { toggle, complete, reschedule }

class TodoFieldEdit {
  const TodoFieldEdit.toggleDone()
    : _operation = _Operation.toggle,
      dueAt = null;
  const TodoFieldEdit.complete()
    : _operation = _Operation.complete,
      dueAt = null;
  const TodoFieldEdit.reschedule(this.dueAt)
    : _operation = _Operation.reschedule;
  final _Operation _operation;
  final DateTime? dueAt;

  bool includes(Todo todo) =>
      _operation != _Operation.complete || todo.isActive;
  bool changes(Todo todo) =>
      _operation != _Operation.reschedule || todo.dueAt != dueAt;
  TodoStatus _status(Todo todo) =>
      _operation == _Operation.toggle && todo.status == TodoStatus.done
      ? TodoStatus.pending
      : TodoStatus.done;

  Map<String, Object?> patch(Todo todo) => _operation == _Operation.reschedule
      ? {'due_at': dueAt?.toUtc().toIso8601String()}
      : {'status': _status(todo).name};

  Todo applyTo(Todo todo, DateTime now) => _operation == _Operation.reschedule
      ? todo.copyWith(dueAt: dueAt)
      : todo.copyWith(
          status: _status(todo),
          completedAt: _status(todo) == TodoStatus.done ? now : null,
        );
}
