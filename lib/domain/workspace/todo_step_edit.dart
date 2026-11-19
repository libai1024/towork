import '../models/todo.dart';
import 'workspace_commands.dart';

enum StepAction { add, rename, move, remove, check }

class TodoStepEdit {
  const TodoStepEdit.add(this.id, this.title)
    : action = StepAction.add,
      delta = 0,
      done = false;
  const TodoStepEdit.rename(this.id, this.title)
    : action = StepAction.rename,
      delta = 0,
      done = false;
  const TodoStepEdit.move(this.id, this.delta)
    : action = StepAction.move,
      title = '',
      done = false;
  const TodoStepEdit.remove(this.id)
    : action = StepAction.remove,
      title = '',
      delta = 0,
      done = false;
  const TodoStepEdit.check(this.id, this.done)
    : action = StepAction.check,
      title = '',
      delta = 0;
  final StepAction action;
  final String id, title;
  final int delta;
  final bool done;

  List<TodoStep> apply(List<TodoStep> before) {
    final steps = [...before];
    final index = steps.indexWhere((step) => step.id == id);
    if ((action == StepAction.add) != (index < 0)) {
      throw const WorkspaceFailure(WorkspaceFailureCode.versionConflict);
    }
    switch (action) {
      case StepAction.add:
        steps.add(TodoStep(id: id, title: title.trim()));
      case StepAction.rename:
        steps[index] = steps[index].copyWith(title: title.trim());
      case StepAction.move:
        final target = index + delta;
        if (target < 0 || target >= steps.length || delta.abs() != 1) {
          throw const WorkspaceFailure(WorkspaceFailureCode.validation);
        }
        steps.insert(target, steps.removeAt(index));
      case StepAction.remove:
        steps.removeAt(index);
      case StepAction.check:
        steps[index] = steps[index].copyWith(done: done);
    }
    return TodoStep.decode(steps.map((s) => s.toJson()).toList());
  }

  Map<String, Object?> patch(List<TodoStep> before, TodoStatus status) {
    if (status == TodoStatus.cancelled) {
      throw const WorkspaceFailure(WorkspaceFailureCode.validation);
    }
    final steps = apply(before);
    final changed =
        action == StepAction.check &&
        before.firstWhere((s) => s.id == id).done != done;
    return {
      'steps': [for (final s in steps) s.toJson()],
      if (changed && done && steps.every((s) => s.done)) 'status': 'done',
      if (changed && !done && status == TodoStatus.done) 'status': 'pending',
    };
  }
}
