import '../workspace/workspace_validation.dart';
import 'model_gateway.dart';

enum AgentRunStatus {
  queued,
  generating,
  ready,
  awaitingConfirmation,
  succeeded,
  failed,
  cancelled,
  interrupted,
}

enum AgentFailureCode { invalid, conflict, storage, budget, cancelled }

class AgentFailure implements Exception {
  const AgentFailure(this.code);
  final AgentFailureCode code;
  @override
  String toString() => 'AgentFailure(${code.name})';
}

/// Credentials and UI rendering state never belong in this durable record.
class AgentRun {
  AgentRun({
    required this.id,
    required this.sessionId,
    required this.inputId,
    required this.profile,
    required List<JsonObject> history,
    this.revision = 1,
    this.round = 0,
    this.status = AgentRunStatus.queued,
    JsonObject? proposal,
    List<JsonObject> usage = const [],
    List<String> receipts = const [],
    this.failureCode,
    this.historyOmittedTurns = 0,
    this.requestOmittedTurns = 0,
    this.estimatedInputTokens,
  }) : history = List.unmodifiable(history.map(immutableJson)),
       proposal = proposal == null ? null : immutableJson(proposal),
       usage = List.unmodifiable(usage.map(immutableJson)),
       receipts = List.unmodifiable(receipts) {
    for (final value in [id, sessionId, inputId]) {
      validateWorkspaceId(value);
    }
    if (revision < 1 ||
        round < 0 ||
        history.isEmpty ||
        historyOmittedTurns < 0 ||
        requestOmittedTurns < 0 ||
        (estimatedInputTokens != null && estimatedInputTokens! < 0)) {
      throw const AgentFailure(AgentFailureCode.invalid);
    }
  }

  final String id;
  final String sessionId;
  final String inputId;
  final ModelProfile profile;
  final int revision;
  final int round;
  final AgentRunStatus status;
  final List<JsonObject> history;
  final JsonObject? proposal;

  /// One entry per completed response; absent provider usage stays null.
  final List<JsonObject> usage;
  final List<String> receipts;
  final String? failureCode;
  final int historyOmittedTurns;
  final int requestOmittedTurns;

  /// Local UTF-8 estimate, never a provider usage or remaining quota value.
  final int? estimatedInputTokens;
  int get contextOmittedTurns => historyOmittedTurns + requestOmittedTurns;

  bool get isTerminal => {
    AgentRunStatus.succeeded,
    AgentRunStatus.failed,
    AgentRunStatus.cancelled,
  }.contains(status);

  AgentRun next(
    AgentRunStatus status, {
    int? round,
    List<JsonObject>? history,
    JsonObject? proposal,
    bool clearProposal = false,
    List<JsonObject>? usage,
    List<String>? receipts,
    String? failureCode,
    int? requestOmittedTurns,
    int? estimatedInputTokens,
  }) => AgentRun(
    id: id,
    sessionId: sessionId,
    inputId: inputId,
    profile: profile,
    revision: revision + 1,
    round: round ?? this.round,
    status: status,
    history: history ?? this.history,
    proposal: clearProposal ? null : proposal ?? this.proposal,
    usage: usage ?? this.usage,
    receipts: receipts ?? this.receipts,
    failureCode: failureCode,
    historyOmittedTurns: historyOmittedTurns,
    requestOmittedTurns: requestOmittedTurns ?? this.requestOmittedTurns,
    estimatedInputTokens: estimatedInputTokens ?? this.estimatedInputTokens,
  );

  /// 把一次失败的运行改绑到另一个模型配置。输入、历史、回执原样保留，
  /// 只换「由谁回答」；之后必须经显式重试才会继续。
  AgentRun rebound(ModelProfile profile) {
    if (status != AgentRunStatus.failed) {
      throw const AgentFailure(AgentFailureCode.conflict);
    }
    return AgentRun(
      id: id,
      sessionId: sessionId,
      inputId: inputId,
      profile: profile,
      revision: revision + 1,
      round: round,
      status: status,
      history: history,
      proposal: proposal,
      usage: usage,
      receipts: receipts,
      failureCode: failureCode,
      historyOmittedTurns: historyOmittedTurns,
      requestOmittedTurns: requestOmittedTurns,
      estimatedInputTokens: estimatedInputTokens,
    );
  }

  JsonObject toJson() => {
    'schema_version': 1,
    'id': id,
    'session_id': sessionId,
    'input_id': inputId,
    'revision': revision,
    'round': round,
    'status': status.name,
    'profile': {
      'model': profile.model,
      'product': profile.product.wireId,
      'region': profile.region.name,
      'revision': profile.revision,
      'disable_thinking': profile.disableThinking,
      // 只有自填地址的服务商才有；其余服务商的记录格式保持不变。
      if (profile.baseUrl != null) 'base_url': profile.baseUrl,
    },
    'history': history,
    'proposal': proposal,
    'usage': usage,
    'receipts': receipts,
    'failure_code': failureCode,
    if (historyOmittedTurns > 0) 'history_omitted_turns': historyOmittedTurns,
    if (requestOmittedTurns > 0) 'request_omitted_turns': requestOmittedTurns,
    if (estimatedInputTokens != null)
      'estimated_input_tokens': estimatedInputTokens,
  };

  factory AgentRun.fromJson(JsonObject json) {
    if (json['schema_version'] != 1) {
      throw const AgentFailure(AgentFailureCode.invalid);
    }
    final profile = (json['profile']! as Map).cast<String, Object?>();
    List<JsonObject> objects(String key) => (json[key]! as List)
        .map((e) => (e as Map).cast<String, Object?>())
        .toList();
    return AgentRun(
      id: json['id']! as String,
      sessionId: json['session_id']! as String,
      inputId: json['input_id']! as String,
      revision: json['revision']! as int,
      round: json['round']! as int,
      status: AgentRunStatus.values.byName(json['status']! as String),
      profile: ModelProfile(
        model: profile['model']! as String,
        product: ProviderKind.fromWire(profile['product']! as String),
        region: ProviderRegion.values.byName(profile['region']! as String),
        revision: profile['revision']! as int,
        disableThinking: profile['disable_thinking']! as bool,
        baseUrl: profile['base_url'] as String?,
      ),
      history: objects('history'),
      proposal: (json['proposal'] as Map?)?.cast<String, Object?>(),
      usage: objects('usage'),
      receipts: (json['receipts']! as List).cast<String>(),
      failureCode: json['failure_code'] as String?,
      historyOmittedTurns: json['history_omitted_turns'] as int? ?? 0,
      requestOmittedTurns: json['request_omitted_turns'] as int? ?? 0,
      estimatedInputTokens: json['estimated_input_tokens'] as int?,
    );
  }
}

/// Approval is scoped to one displayed, versioned proposal, never a policy change.
class AgentApproval {
  AgentApproval({
    required this.runRevision,
    required this.proposalId,
    required this.digest,
    List<String>? selectedToolCallIds,
    this.reject = false,
  }) : selectedToolCallIds = selectedToolCallIds == null
           ? null
           : List.unmodifiable(selectedToolCallIds);
  final int runRevision;
  final String proposalId;
  final String digest;

  /// Null accepts the displayed batch; a subset leaves other calls pending.
  final List<String>? selectedToolCallIds;
  final bool reject;
}

abstract interface class AgentRunStore {
  /// Same session/input and identical initial request returns the existing run.
  Future<AgentRun> create(AgentRun run);
  Future<AgentRun> read(String id);
  Future<AgentRun> save(AgentRun next, {required int expectedRevision});
}

/// 可选能力：一批工具调用被整体拒绝后，说明每一条的问题，供模型自行修正。
abstract interface class AgentToolDiagnostics {
  /// 键是 tool_call_id，值是稳定的错误码（`invalid_arguments`、
  /// `unknown_tool`、`version_conflict`、`not_found`）。逐条都合法时返回空表。
  /// 必须只读、无副作用，且不携带用户数据或上游原文。
  Future<Map<String, String>> diagnose(AgentRun run, ModelCompleted completion);
}

abstract interface class AgentToolExecutor {
  List<JsonObject> get schemas;
  Future<AgentRun> propose(AgentRun run, ModelCompleted completion);

  /// Permission, target versions, business effects and run receipt commit together.
  Future<AgentRun> execute(
    AgentRun run, {
    AgentApproval? approval,
    ModelCancellation? cancellation,
  });
}
