/// Stable names preserve existing preferences while labels explain the policy.
enum AiWritePermission {
  askAll('总是询问', 'AI 写入待办和表格前都会先确认'),
  askOnChange('智能确认', '待办新增、编辑、完成直接生效，删除前确认；表格写入需确认'),
  auto('自动执行', '待办自动执行并保留修改记录；表格写入仍需确认');

  const AiWritePermission(this.label, this.consequence);
  final String label;
  final String consequence;
}

enum AgentOperation { query, create, edit, complete, delete }

enum PermissionDecision { execute, confirm }

/// Shared by task and business-table tools. This is only the authorization
/// decision: validation, version checks and a transaction are still required.
PermissionDecision evaluatePermission(
  AiWritePermission permission,
  AgentOperation operation,
) {
  if (operation == AgentOperation.query ||
      permission == AiWritePermission.auto) {
    return PermissionDecision.execute;
  }
  if (permission == AiWritePermission.askAll ||
      operation == AgentOperation.delete) {
    return PermissionDecision.confirm;
  }
  return PermissionDecision.execute;
}
