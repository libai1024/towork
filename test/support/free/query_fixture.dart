import 'package:towork/domain/workspace/workspace_commands.dart';

String get queryNote => '备忘🙂' * 700;
WorkspaceCommand queryFixture() => WorkspaceCommand(
  operationId: 'query-seed',
  actions: [
    WorkspaceMutation(
      actionId: 'a1',
      kind: WorkspaceEntityKind.category,
      entityId: 'work',
      mutation: WorkspaceMutationKind.create,
      patch: {'name': '工作'},
    ),
    WorkspaceMutation(
      actionId: 'a2',
      kind: WorkspaceEntityKind.category,
      entityId: 'child',
      mutation: WorkspaceMutationKind.create,
      patch: {'name': '项目', 'parent_id': 'work'},
    ),
    WorkspaceMutation(
      actionId: 'a3',
      kind: WorkspaceEntityKind.category,
      entityId: 'personal',
      mutation: WorkspaceMutationKind.create,
      patch: {'name': '个人'},
    ),
    for (final id in ['target', 'same-title'])
      WorkspaceMutation(
        actionId: id,
        kind: WorkspaceEntityKind.todo,
        entityId: id,
        mutation: WorkspaceMutationKind.create,
        patch: {
          'title': '同名周会',
          'note': queryNote,
          'category_id': id == 'target' ? 'child' : 'personal',
          'priority': 'high',
          'tags': ['周会'],
          'due_at': '2026-09-24T01:00:00Z',
        },
      ),
  ],
);
