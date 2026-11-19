import '../domain/ai/agent_run.dart';
import '../domain/ai/model_gateway.dart';
import '../domain/models/todo.dart';
import '../domain/workspace/todo_step_edit.dart';
import '../domain/workspace/workspace_commands.dart';

class TodoStepAgentEdit {
  static const fields = {
    'add_steps': {
      'type': 'array',
      'minItems': 1,
      'maxItems': 20,
      'items': {'type': 'string', 'maxLength': TodoStep.maxTitle},
      'description': 'Append these titles in order. For a suggested breakdown, use show_question multiple to select steps first.',
    },
    'edit_step': {
      'type': 'object',
      'additionalProperties': false,
      'properties': {
        'id': {'type': 'string'},
        'action': {
          'type': 'string',
          'enum': ['check', 'rename', 'remove', 'up', 'down'],
        },
        'done': {'type': 'boolean'},
        'title': {'type': 'string', 'maxLength': TodoStep.maxTitle},
      },
      'required': ['id', 'action'],
      'description': 'Use an exact step ID from todo_get and clarify ambiguous names. check needs explicit done; rename needs title.',
    },
  };

  static JsonObject translate(
    JsonObject input,
    WorkspaceEntity before,
    String suffix,
  ) {
    Never invalid() => throw const AgentFailure(AgentFailureCode.invalid);
    if (input.length != 1) invalid();
    final steps = TodoStep.decode(before.data['steps'] ?? const []);
    final status = TodoStatus.values.byName(before.data['status']! as String);
    if (input.containsKey('add_steps')) {
      final names = input['add_steps'];
      if (names is! List ||
          names.isEmpty ||
          names.length > 20 ||
          status == TodoStatus.cancelled) {
        invalid();
      }
      var result = steps;
      for (final (i, title) in names.indexed) {
        if (title is! String) invalid();
        result = TodoStepEdit.add('as_${suffix}_$i', title).apply(result);
      }
      return {
        'steps': [for (final step in result) step.toJson()],
      };
    }
    final value = input['edit_step'];
    if (value is! JsonObject || value['id'] is! String) invalid();
    final id = value['id']! as String;
    final edit = switch (value) {
      {'action': 'check', 'done': final bool done} when value.length == 3 =>
        TodoStepEdit.check(id, done),
      {'action': 'rename', 'title': final String title}
          when value.length == 3 =>
        TodoStepEdit.rename(id, title),
      {'action': 'remove'} when value.length == 2 => TodoStepEdit.remove(id),
      {'action': 'up'} when value.length == 2 => TodoStepEdit.move(id, -1),
      {'action': 'down'} when value.length == 2 => TodoStepEdit.move(id, 1),
      _ => invalid(),
    };
    return edit.patch(steps, status);
  }
}
