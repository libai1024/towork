import 'dart:convert';

import '../../domain/ai/model_gateway.dart';

/// Reassembles complete protocol messages without executing partial tools.
class ChatStreamAssembler {
  final _text = StringBuffer();
  final _reasoning = StringBuffer();
  final _tools = <int, _ToolParts>{};
  bool _hasReasoning = false;
  bool _done = false;
  String? _finishReason;
  JsonObject? _usage;

  bool get isComplete => _done;

  List<ModelEvent> add(String frame) {
    if (_done) throw const ModelFailure(ModelFailureCode.protocol);
    if (frame == '[DONE]') {
      if (_finishReason != 'stop' && _finishReason != 'tool_calls') {
        throw ModelFailure(
          _finishReason == 'length'
              ? ModelFailureCode.budget
              : ModelFailureCode.truncated,
        );
      }
      final ids = <String>{};
      final indices = _tools.keys.toList()..sort();
      final calls = <JsonObject>[];
      for (final index in indices) {
        final tool = _tools[index]!;
        if (tool.id.isEmpty || tool.name.isEmpty || !ids.add(tool.id)) {
          throw const ModelFailure(ModelFailureCode.protocol);
        }
        _object(tool.arguments.toString());
        calls.add({
          'id': tool.id,
          'type': 'function',
          'function': {
            'name': tool.name,
            'arguments': tool.arguments.toString(),
          },
        });
      }
      if ((_finishReason == 'tool_calls') != calls.isNotEmpty) {
        throw const ModelFailure(ModelFailureCode.protocol);
      }
      if (calls.isEmpty && _text.isEmpty) {
        throw const ModelFailure(ModelFailureCode.protocol);
      }
      _done = true;
      return [
        ModelCompleted(
          assistantMessage: {
            'role': 'assistant',
            'content': _text.isEmpty ? null : _text.toString(),
            if (_hasReasoning) 'reasoning_content': _reasoning.toString(),
            if (calls.isNotEmpty) 'tool_calls': calls,
          },
          finishReason: _finishReason!,
          usage: _usage,
        ),
      ];
    }
    final payload = _object(frame);
    if (payload['error'] != null) {
      throw const ModelFailure(ModelFailureCode.provider);
    }
    if (payload['usage'] case final Map<String, Object?> usage) {
      _usage = usage;
    }
    final choices = payload['choices'];
    if (choices is! List<Object?>) {
      throw const ModelFailure(ModelFailureCode.protocol);
    }
    if (choices.isEmpty) return const [];
    if (choices.length != 1 || choices.single is! JsonObject) {
      throw const ModelFailure(ModelFailureCode.protocol);
    }
    final choice = choices.single! as JsonObject;
    if (choice['index'] != 0 || _finishReason != null) {
      throw const ModelFailure(ModelFailureCode.protocol);
    }
    final delta = choice['delta'];
    if (delta is! JsonObject) {
      throw const ModelFailure(ModelFailureCode.protocol);
    }
    final content = _optionalText(delta['content']);
    final reasoning = _optionalString(delta['reasoning_content']);
    if (reasoning != null) {
      _hasReasoning = true;
      _reasoning.write(reasoning);
    }
    if (delta['tool_calls'] case final Object fragments) {
      if (fragments is! List<Object?>) {
        throw const ModelFailure(ModelFailureCode.protocol);
      }
      for (final fragment in fragments) {
        if (fragment is! JsonObject || fragment['index'] is! int) {
          throw const ModelFailure(ModelFailureCode.protocol);
        }
        final index = fragment['index']! as int;
        if (index < 0 || index >= 32) {
          throw const ModelFailure(ModelFailureCode.budget);
        }
        final parts = _tools.putIfAbsent(index, _ToolParts.new);
        if (fragment['type'] != null && fragment['type'] != 'function') {
          throw const ModelFailure(ModelFailureCode.protocol);
        }
        if (_optionalString(fragment['id']) case final String id) {
          if (parts.id.isNotEmpty && parts.id != id) {
            throw const ModelFailure(ModelFailureCode.protocol);
          }
          parts.id = id;
        }
        if (fragment['function'] case final Object function) {
          if (function is! JsonObject) {
            throw const ModelFailure(ModelFailureCode.protocol);
          }
          parts.name += _optionalString(function['name']) ?? '';
          parts.arguments.write(_optionalString(function['arguments']) ?? '');
        }
      }
    }
    _finishReason = _optionalString(choice['finish_reason']);
    if (content == null || content.isEmpty) return const [];
    _text.write(content);
    return [ModelTextDelta(content)];
  }

  static String? _optionalString(Object? value) {
    if (value == null || value is String) return value as String?;
    throw const ModelFailure(ModelFailureCode.protocol);
  }

  /// OpenAI 新版兼容生态会把 content 输出为分片数组
  /// （[{type:'text', text:'…'}]）；仅折叠文本分片，非文本分片视为协议失败，
  /// 不静默丢弃。
  static String? _optionalText(Object? value) {
    if (value is List<Object?>) {
      final text = StringBuffer();
      for (final part in value) {
        if (part is! JsonObject) {
          throw const ModelFailure(ModelFailureCode.protocol);
        }
        final type = part['type'];
        if (type != null && type != 'text') {
          throw const ModelFailure(ModelFailureCode.protocol);
        }
        final chunk = part['text'];
        if (chunk == null) continue;
        if (chunk is! String) {
          throw const ModelFailure(ModelFailureCode.protocol);
        }
        text.write(chunk);
      }
      return text.toString();
    }
    return _optionalString(value);
  }

  static JsonObject _object(String value) {
    try {
      final Object? decoded = jsonDecode(value);
      if (decoded is JsonObject) return decoded;
    } on FormatException {
      // Do not expose upstream content through parser diagnostics.
    }
    throw const ModelFailure(ModelFailureCode.protocol);
  }
}

class _ToolParts {
  String id = '';
  String name = '';
  final arguments = StringBuffer();
}
