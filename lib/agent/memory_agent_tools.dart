import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../domain/ai/model_gateway.dart';
import '../domain/workspace/workspace_commands.dart';
import '../domain/workspace/workspace_validation.dart';

/// Memory tools (FC4). Durable user-stated facts can be retained, so these
/// execute inline like a read — gated only by pause, epoch and the record
/// version, never by the three-tier write policy. Image-scoped runs never see
/// them. Deleting stays a manual action in the memory page.
class MemoryAgentTools {
  static const names = {'memory_create', 'memory_search', 'memory_update'};
  static const kinds = {'fact', 'preference', 'event', 'profile'};

  /// 单条内容回给模型时的上限；完整内容仍在记忆页。
  static const previewRunes = 500;

  static List<Map<String, Object?>> get schemas => [
    schema,
    searchSchema,
    updateSchema,
  ];

  static Map<String, Object?> get schema => {
    'type': 'function',
    'function': {
      'name': 'memory_create',
      'description':
          'Save one durable user-stated fact useful across conversations, including '
          'standing preferences, workflows, responsibilities, project conventions '
          'and aliases. An explicit request is optional. Search first. Skip '
          'duplicates and use memory_update for corrections. Respect opt-outs '
          'and pause. Omit guesses, credentials, quoted material and one-off tasks.',
      'parameters': {
        'type': 'object',
        'properties': {
          'content': {
            'type': 'string',
            'minLength': 1,
            'maxLength': 2000,
            'description': 'The remembered statement, in the user\'s language.',
          },
          'kind': {
            'type': 'string',
            'enum': ['fact', 'preference', 'event', 'profile'],
            'description': 'Defaults to fact.',
          },
        },
        'required': ['content'],
        'additionalProperties': false,
      },
    },
  };

  static Map<String, Object?> get searchSchema => {
    'type': 'function',
    'function': {
      'name': 'memory_search',
      'description':
          'Look up saved facts and preferences. Keyword match ranked '
          'by overlap then recency, not semantic search: try the key nouns, '
          'and treat an empty result as "nothing matched", not "never said". '
          'Omit query to list the most recent memories. Results may be stale; '
          'the user\'s current words win.',
      'parameters': {
        'type': 'object',
        'properties': {
          'query': {'type': 'string', 'maxLength': 200},
          'limit': {'type': 'integer', 'minimum': 1, 'maximum': 20},
        },
        'required': <String>[],
        'additionalProperties': false,
      },
    },
  };

  static Map<String, Object?> get updateSchema => {
    'type': 'function',
    'function': {
      'name': 'memory_update',
      'description':
          'Update an existing fact when the user supplies a durable correction. '
          'Use the id and version from memory_search. Preserve unrelated facts, '
          'respect opt-outs and pause, and skip unchanged content.',
      'parameters': {
        'type': 'object',
        'properties': {
          'id': {'type': 'string'},
          'expected_version': {'type': 'integer', 'minimum': 1},
          'content': {'type': 'string', 'minLength': 1, 'maxLength': 2000},
          'kind': {
            'type': 'string',
            'enum': ['fact', 'preference', 'event', 'profile'],
          },
        },
        'required': ['id', 'expected_version'],
        'additionalProperties': false,
      },
    },
  };

  static Never _invalid() =>
      throw const WorkspaceFailure(WorkspaceFailureCode.validation);

  /// Shape-level validation only; persistence re-validates content bounds.
  static ({String content, String kindId}) validate(Map<String, Object?> args) {
    if (args.keys.any((k) => !{'content', 'kind'}.contains(k)) ||
        args['content'] is! String) {
      _invalid();
    }
    final kind = args['kind'] ?? 'fact';
    if (kind is! String || !kinds.contains(kind)) _invalid();
    return (content: args['content']! as String, kindId: kind);
  }

  static ({String query, int limit}) validateSearch(Map<String, Object?> args) {
    final query = args['query'] ?? '';
    final limit = args['limit'] ?? 8;
    if (args.keys.any((k) => !{'query', 'limit'}.contains(k)) ||
        query is! String ||
        query.length > 200 ||
        limit is! int ||
        limit < 1 ||
        limit > 20) {
      _invalid();
    }
    return (query: query.trim(), limit: limit);
  }

  static ({String id, int expectedVersion, String? content, String? kindId})
  validateUpdate(Map<String, Object?> args) {
    final id = args['id'];
    final version = args['expected_version'];
    final content = args['content'];
    final kind = args['kind'];
    if (args.keys.any(
          (k) => !{'id', 'expected_version', 'content', 'kind'}.contains(k),
        ) ||
        id is! String ||
        version is! int ||
        version < 1 ||
        (content == null && kind == null) ||
        (content != null && content is! String) ||
        (kind != null && (kind is! String || !kinds.contains(kind)))) {
      _invalid();
    }
    validateWorkspaceId(id);
    return (
      id: id,
      expectedVersion: version,
      content: content as String?,
      kindId: kind as String?,
    );
  }

  /// 按工具名做形状校验；未知名称同样算无效调用。
  static void validateCall(Object? name, Map<String, Object?> args) {
    switch (name) {
      case 'memory_create':
        validate(args);
      case 'memory_search':
        validateSearch(args);
      case 'memory_update':
        validateUpdate(args);
      default:
        _invalid();
    }
  }

  static Map<String, Object?> pausedResult() => const {
    'error': 'memory_paused',
  };

  static Map<String, Object?> invalidContentResult() => const {
    'error': 'invalid_content',
  };

  static Map<String, Object?> epochResult() => const {
    'error': 'memory_epoch_changed',
  };

  static Map<String, Object?> notFoundResult() => const {
    'error': 'memory_not_found',
  };

  static Map<String, Object?> versionResult() => const {
    'error': 'memory_version_changed',
    'hint': 'Search again and use the current version.',
  };

  static Map<String, Object?> writeResult({
    required String memoryId,
    required int version,
    required int epoch,
  }) => {'memory_id': memoryId, 'version': version, 'epoch': epoch};

  static Map<String, Object?> item({
    required String id,
    required int version,
    required String kindId,
    required String content,
    required DateTime updatedAt,
  }) {
    final runes = content.runes;
    final truncated = runes.length > previewRunes;
    return {
      'id': id,
      'version': version,
      'kind': kindId,
      'content': truncated
          ? String.fromCharCodes(runes.take(previewRunes))
          : content,
      if (truncated) 'content_truncated': true,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  /// Proposal calls never carry raw payloads; reuse the shared digest scheme.
  static String digest(JsonObject data) =>
      sha256.convert(utf8.encode(canonicalWorkspaceJson(data))).toString();
}
