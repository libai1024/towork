import 'dart:convert';

import 'model_gateway.dart';

/// Deterministic local guard, NOT a provider tokenizer or account quota.
/// UTF-8 JSON bytes intentionally overestimate typical text token counts.
class ContextWindow {
  const ContextWindow({this.tokenBudget = 128000});
  final int tokenBudget;

  static const notice = <String, Object?>{
    'role': 'system',
    'content':
        '部分较早对话未包含在本次上下文中，完整历史仍保存在 App。不要猜测缺失内容；指代不明确时向用户澄清，业务现状以重新查询的结果为准。',
  };

  // Conservative local reserve for each bounded image; not provider token usage.
  static int _cost(Object? json) =>
      utf8.encode(jsonEncode(json)).length +
      (json is JsonObject && json['_towork_attachment_id'] != null ? 16000 : 0);

  static int estimateInput(List<JsonObject> messages, List<JsonObject> tools) =>
      256 +
      messages.fold<int>(0, (sum, m) => sum + _cost(m) + 16) +
      _cost(tools) +
      tools.length * 32;

  ContextSelection select(
    List<JsonObject> history, {
    List<JsonObject> tools = const [],
    int outputReserve = 0,
    int previouslyOmittedTurns = 0,
    bool includeNotice = true,
  }) {
    if (tokenBudget < 1 || outputReserve < 0 || previouslyOmittedTurns < 0) {
      throw const ModelFailure(ModelFailureCode.configuration);
    }
    _validateProtocol(history);
    // Only the first system message is the persistent application policy.
    // Per-turn clock/undo messages directly before a user move with that turn.
    final pinned = history.first['role'] == 'system' ? 1 : 0;
    final starts = <int>[];
    for (var i = pinned; i < history.length; i++) {
      if (history[i]['role'] != 'user') continue;
      var start = i;
      while (start > pinned &&
          {'system', 'developer'}.contains(history[start - 1]['role'])) {
        start--;
      }
      starts.add(start);
    }
    if (starts.isEmpty || starts.first != pinned) {
      throw const ModelFailure(ModelFailureCode.protocol);
    }
    final costs = [for (final message in history) _cost(message) + 16];
    var estimate = estimateInput(history, tools);
    var omitted = 0;
    var noticeCost = includeNotice && previouslyOmittedTurns > 0
        ? _cost(notice) + 16
        : 0;
    while (estimate + noticeCost + outputReserve > tokenBudget &&
        omitted < starts.length - 1) {
      for (var i = starts[omitted]; i < starts[omitted + 1]; i++) {
        estimate -= costs[i];
      }
      omitted++;
      noticeCost = includeNotice ? _cost(notice) + 16 : 0;
    }
    // Never shorten the latest input, its reasoning, tool arguments or receipts.
    if (estimate + noticeCost + outputReserve > tokenBudget) {
      throw const ModelFailure(ModelFailureCode.contextBudget);
    }
    return ContextSelection(
      messages: [
        ...history.take(pinned),
        if (noticeCost > 0) notice,
        ...history.skip(starts[omitted]),
      ],
      omittedTurns: omitted,
      estimatedInputTokens: estimate + noticeCost,
    );
  }

  /// Only complete exchanges can be sent or removed. Parallel tool results may
  /// arrive out of order, but must cover exactly the previous assistant's IDs.
  static void _validateProtocol(List<JsonObject> history) {
    if (history.isEmpty) {
      throw const ModelFailure(ModelFailureCode.protocol);
    }
    final pending = <String>{};
    for (final message in history) {
      final role = message['role'];
      if (role == 'tool') {
        if (!pending.remove(message['tool_call_id'])) {
          throw const ModelFailure(ModelFailureCode.protocol);
        }
        continue;
      }
      if (pending.isNotEmpty ||
          !{'system', 'developer', 'user', 'assistant'}.contains(role)) {
        throw const ModelFailure(ModelFailureCode.protocol);
      }
      final calls = message['tool_calls'];
      if (calls == null) continue;
      if (role != 'assistant' || calls is! List) {
        throw const ModelFailure(ModelFailureCode.protocol);
      }
      for (final call in calls) {
        final id = call is Map ? call['id'] : null;
        if (id is! String || id.isEmpty || !pending.add(id)) {
          throw const ModelFailure(ModelFailureCode.protocol);
        }
      }
    }
    if (pending.isNotEmpty) {
      throw const ModelFailure(ModelFailureCode.protocol);
    }
  }
}

class ContextSelection {
  ContextSelection({
    required List<JsonObject> messages,
    required this.omittedTurns,
    required this.estimatedInputTokens,
  }) : messages = List.unmodifiable(messages.map(immutableJson));
  final List<JsonObject> messages;
  final int omittedTurns;
  final int estimatedInputTokens;
}
