import 'package:towork/domain/workspace/workspace_commands.dart';

String get businessLongNote => '原始🙂' * 900;
WorkspaceCommand businessAgentFixture() => WorkspaceCommand(
  operationId: 'business-seed',
  actions: [
    WorkspaceMutation(
      actionId: 'table',
      kind: WorkspaceEntityKind.dataTable,
      entityId: 'ledger',
      mutation: WorkspaceMutationKind.create,
      patch: {
        'name': '项目账本',
        'fields': [
          {'id': 'title', 'name': '项目', 'type': 'text', 'required': true},
          {'id': 'amount', 'name': '金额', 'type': 'money', 'unit': '元'},
          {'id': 'note', 'name': '备注', 'type': 'text'},
          {'id': 'paid', 'name': '已支付', 'type': 'boolean'},
          {
            'id': 'stage',
            'name': '阶段',
            'type': 'selection',
            'options': List.generate(25, (i) => '阶段$i'),
          },
        ],
      },
    ),
    for (final id in ['keep', 'remove'])
      WorkspaceMutation(
        actionId: id,
        kind: WorkspaceEntityKind.dataRow,
        entityId: id,
        mutation: WorkspaceMutationKind.create,
        patch: {
          'table_id': 'ledger',
          'values': {
            'title': id == 'keep' ? '项目甲' : '待删除项目',
            'amount': '12345678901234567890.10',
            'note': businessLongNote,
            'paid': false,
          },
        },
      ),
    WorkspaceMutation(
      actionId: 'todo',
      kind: WorkspaceEntityKind.todo,
      entityId: 'todo',
      mutation: WorkspaceMutationKind.create,
      patch: {'title': '核对账本'},
    ),
  ],
);
