import 'dart:convert';

/// Pairs bounded display payloads with their actual registered function calls.
/// Assistant prose, old turns, failed calls and duplicate results add no UI.
Map<int, ({String name, Object? ui})> toolUiResults(
  List<Map<String, Object?>> history,
  int historyStart,
  Set<String> names,
) {
  final pending = <String, String>{};
  final results = <int, ({String name, Object? ui})>{};
  for (var i = historyStart + 1; i < history.length; i++) {
    final message = history[i];
    final calls = message['tool_calls'];
    if (message['role'] == 'assistant' && calls is List) {
      for (final call in calls) {
        if (call is! Map) continue;
        final function = call['function'];
        final id = call['id'];
        if (id is! String) continue;
        pending.remove(id);
        if (call['type'] == 'function' &&
            function is Map &&
            names.contains(function['name'])) {
          pending[id] = function['name'] as String;
        }
      }
    }
    if (message['role'] != 'tool') continue;
    final name = pending.remove(message['tool_call_id']);
    final content = message['content'];
    if (name == null || content is! String || content.length > 256 * 1024) {
      continue;
    }
    try {
      final result = jsonDecode(content);
      if (result is Map && !result.containsKey('error')) {
        results[i] = (name: name, ui: result['ui']);
      }
    } on FormatException {
      // A malformed historical display must not hide the rest of the reply.
    }
  }
  return results;
}
