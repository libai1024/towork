import '../domain/ai/agent_run.dart';
import '../domain/ai/model_gateway.dart';
import '../domain/ai/permission_policy.dart';
import 'business_agent_tools.dart';
import 'todo_agent_tools.dart';

/// A decision is bound to one durable proposal and an exact set of tool calls.
class AgentToolDecision {
  AgentToolDecision._(
    this.proposal,
    this.calls,
    this.selected,
    this.digest,
    this.approval,
  );
  final JsonObject proposal;
  final List<JsonObject> calls;
  final Set<String> selected;
  final String digest;
  final AgentApproval? approval;
  factory AgentToolDecision.forRun(AgentRun run, AgentApproval? approval) {
    final proposal = run.proposal;
    if (proposal == null ||
        !{
          AgentRunStatus.ready,
          AgentRunStatus.awaitingConfirmation,
        }.contains(run.status)) {
      throw const AgentFailure(AgentFailureCode.conflict);
    }
    final data = {...proposal}..remove('digest');
    if (proposal['digest'] != TodoAgentTools.digest(data) ||
        proposal['run_id'] != run.id ||
        proposal['round'] != run.round) {
      throw const AgentFailure(AgentFailureCode.invalid);
    }
    if (approval != null &&
        (run.status != AgentRunStatus.awaitingConfirmation ||
            approval.runRevision != run.revision ||
            approval.proposalId != proposal['id'] ||
            approval.digest != proposal['digest'])) {
      throw const AgentFailure(AgentFailureCode.conflict);
    }
    final calls = (proposal['calls']! as List).cast<JsonObject>();
    final callIds = calls.map((c) => c['tool_call_id']! as String).toSet();
    final selected = approval?.selectedToolCallIds?.toSet() ?? callIds;
    if (approval != null &&
        (selected.isEmpty ||
            selected.length !=
                (approval.selectedToolCallIds?.length ?? callIds.length) ||
            !callIds.containsAll(selected))) {
      throw const AgentFailure(AgentFailureCode.invalid);
    }
    final decisionDigest = TodoAgentTools.digest({
      'run': run.toJson(),
      'approval': approval == null
          ? null
          : {'selected': selected.toList()..sort(), 'reject': approval.reject},
    });
    return AgentToolDecision._(
      proposal,
      calls,
      selected,
      decisionDigest,
      approval,
    );
  }

  ({List<JsonObject> executing, List<JsonObject> remaining}) select(
    AiWritePermission permission,
  ) {
    final executing = calls
        .where(
          (call) =>
              call['operation'] == 'query' ||
              (approval == null
                  ? call['requires_review'] != true &&
                        !BusinessAgentTools.writes.contains(call['name']) &&
                        evaluatePermission(
                              permission,
                              AgentOperation.values.byName(
                                call['operation']! as String,
                              ),
                            ) ==
                            PermissionDecision.execute
                  : selected.contains(call['tool_call_id'])),
        )
        .toList();
    final remaining = calls.where((call) => !executing.contains(call)).toList();
    return (executing: executing, remaining: remaining);
  }
}
