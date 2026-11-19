import '../models/todo.dart';
import 'workspace_commands.dart';

/// Append position is assigned from committed tasks after idempotency is checked.
/// The request contains only form values, so replay survives a lost receipt.
class AppendTodo extends WorkspaceMutation {
  AppendTodo({
    required String operationId,
    required String title,
    String? note,
    TodoPriority priority = TodoPriority.none,
    TodoStatus status = TodoStatus.pending,
    List<TodoStep> steps = const [],
    List<RemindRule> remindRules = const [],
    DateTime? dueAt,
    String? categoryId,
    TodoSource source = TodoSource.manual,
    String? sourceMessageId,
  }) : super(
         actionId: 'a_0',
         kind: WorkspaceEntityKind.todo,
         entityId: '${operationId}_t_0',
         mutation: WorkspaceMutationKind.create,
         patch: {
           'title': title.trim(),
           'note': note,
           'priority': priority.name,
           'status':
               status != TodoStatus.cancelled &&
                   steps.isNotEmpty &&
                   steps.every((step) => step.done)
               ? 'done'
               : status.name,
           if (steps.isNotEmpty) 'steps': [for (final s in steps) s.toJson()],
           'remind_rules': [
             for (final rule in remindRules)
               {
                 'id': rule.id,
                 'offset_minutes': rule.offsetMinutes,
                 'absolute_at': rule.absoluteAt?.toUtc().toIso8601String(),
               },
           ],
           'due_at': dueAt?.toUtc().toIso8601String(),
           'category_id': categoryId,
           'source': source.name,
           'source_message_id': sourceMessageId,
         },
       );

  @override
  Map<String, Object?> patchFor(WorkspaceSnapshot current) => {
    ...patch,
    'sort_order': current.todos.length,
  };

  @override
  Map<String, Object?> toJson() => {...super.toJson(), 'position': 'append'};
}
