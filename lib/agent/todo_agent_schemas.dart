import '../domain/ai/model_gateway.dart';
import 'agent_reminders.dart';
import 'agent_tool_registry.dart';
import 'business_agent_tools.dart';
import 'memory_agent_tools.dart';
import 'todo_step_agent_edit.dart';

class TodoAgentSchemas {
  static final List<JsonObject> schemas = List.unmodifiable([
    ...BusinessAgentTools.schemas,
    ...MemoryAgentTools.schemas,
    ...AgentToolRegistry.schemas,
    _schema(
      'todo_list',
      'Query materialized local todos before selecting an exact target. Combine filters with AND. due_from is inclusive; due_before is exclusive; write both as local time with the UTC offset from the time anchor (2026-11-15T00:00:00+08:00). Results carry *_local copies of stored UTC times; quote those to the user. Results include versions. Note/tag previews may be truncated as flagged; use todo_get before replacing notes or tags. All queries in a batch see the pre-write snapshot. Use next_page_token with unchanged filters; cursor_stale means restart. Recurring future windows may be incomplete; do not claim exhaustive future totals.',
      {
        'query': {'type': 'string', 'maxLength': 200},
        'status': {
          'type': 'string',
          'enum': ['pending', 'inProgress', 'done', 'cancelled', 'active'],
        },
        'after_id': {
          'type': 'string',
          'description': 'Legacy ID ascending cursor only; prefer page_token.',
        },
        'limit': {'type': 'integer', 'minimum': 1, 'maximum': 50},
        'category_id': {
          'type': ['string', 'null'],
          'description': 'Omit for all; null for uncategorized. Query category_list for IDs.',
        },
        'include_descendants': {'type': 'boolean'},
        'tags': {
          'type': 'array',
          'items': {'type': 'string'},
          'maxItems': 100,
          'description':
              'Must contain all specified tags; exact case-sensitive match.',
        },
        'priority': {
          'type': 'string',
          'enum': ['urgent', 'high', 'medium', 'low', 'none'],
        },
        'due_from': {
          'type': 'string',
          'description': 'Inclusive ISO-8601 date-time with offset.',
        },
        'due_before': {
          'type': 'string',
          'description': 'Exclusive ISO-8601 date-time with offset.',
        },
        'no_due': {
          'type': 'boolean',
          'description': 'Cannot combine true with due_from/due_before.',
        },
        'order_by': {
          'type': 'string',
          'enum': ['id', 'due_at', 'priority', 'updated_at'],
        },
        'direction': {
          'type': 'string',
          'enum': ['asc', 'desc'],
          'description': 'Default asc; priority asc is urgent first, missing due dates always last, ties use ID ascending.',
        },
        'page_token': {'type': 'string', 'maxLength': 1024},
      },
      const [],
    ),
    _schema(
      'category_list',
      'Find exact category IDs, names and parents before assigning or filtering todos. Multiple matching names require clarification. Read-only; archived categories excluded by default.',
      {
        'query': {'type': 'string', 'maxLength': 200},
        'parent_id': {
          'type': ['string', 'null'],
          'description':
              'Omit for all levels; null for roots; ID for direct children.',
        },
        'include_archived': {'type': 'boolean'},
        'after_id': {'type': 'string'},
        'limit': {'type': 'integer', 'minimum': 1, 'maximum': 50},
      },
      const [],
    ),
    _schema(
      'todo_get',
      'Read one exact todo including reminders, source reference and a bounded note segment. Do not replace full notes or tags using truncated list previews. Note offsets count Unicode code points; subsequent segments require the returned expected_version. version_changed means restart. Missing/deleted records return not_found.',
      {
        'id': {'type': 'string'},
        'expected_version': {'type': 'integer', 'minimum': 1},
        'step_offset': {
          'type': 'integer',
          'minimum': 0,
          'maximum': 100,
          'description': 'Use next_step_offset with expected_version for more ordered steps.',
        },
        'note_offset': {'type': 'integer', 'minimum': 0, 'maximum': 100000},
        'note_limit': {'type': 'integer', 'minimum': 1, 'maximum': 4000},
      },
      const ['id'],
    ),
    _schema(
      'todo_create',
      'Create a one-off todo. due_at is local time with the UTC offset from the time anchor. Leave unmentioned fields out.',
      fields,
      const ['title'],
    ),
    _schema(
      'todo_update',
      'Edit exactly one previously queried todo at its expected version. Only send changed fields. status reopens (pending), starts (inProgress) or cancels a todo; finishing uses todo_complete.',
      {
        ..._target,
        'patch': {
          'type': 'object',
          'properties': {
            ...fields,
            ...TodoStepAgentEdit.fields,
            'status': {
              'type': 'string',
              'enum': ['pending', 'inProgress', 'cancelled'],
            },
          },
          'additionalProperties': false,
          'minProperties': 1,
        },
      },
      const ['id', 'expected_version', 'patch'],
    ),
    _schema(
      'todo_complete',
      'Complete only this todo, using its queried version.',
      _target,
      const ['id', 'expected_version'],
    ),
    _schema(
      'todo_delete',
      'Delete only this todo, subject to application confirmation.',
      _target,
      const ['id', 'expected_version'],
    ),
    _schema(
      'todo_repeat_create',
      'Create a recurring todo atomically. Supply the first due date (local time with offset), RRULE (DAILY/WEEKLY/MONTHLY) and IANA timezone. Ask if date, timezone or recurrence intent is unclear. Future instances are generated locally in bounded windows.',
      {...fields, ..._repeatFields},
      const ['title', 'due_at', 'repeat_rule', 'repeat_timezone'],
    ),
    _schema(
      'todo_repeat_start',
      'Start a repeat series from a previously queried non-series todo with a due date.',
      {..._target, ..._repeatFields},
      const ['id', 'expected_version', 'repeat_rule', 'repeat_timezone'],
    ),
    _schema(
      'todo_repeat_update',
      'Edit a queried recurring todo. Explicitly choose current or current_and_future according to user intent; ask when unclear. Only current_and_future can change/clear repeat_rule or timezone. Completed historical occurrences are preserved.',
      {
        ..._repeatTarget,
        'patch': {
          'type': 'object',
          'properties': {
            ...fields,
            ...TodoStepAgentEdit.fields,
            ..._repeatFields,
            'repeat_rule': {
              'type': ['string', 'null'],
            },
          },
          'additionalProperties': false,
          'minProperties': 1,
        },
      },
      const [
        'id',
        'expected_version',
        'expected_series_version',
        'scope',
        'patch',
      ],
    ),
    _schema(
      'todo_repeat_delete',
      'Delete a queried occurrence with explicit current or current_and_future scope. Ask if scope is unclear. Future scope stops generation and removes pending future occurrences, preserving other completed facts.',
      _repeatTarget,
      const ['id', 'expected_version', 'expected_series_version', 'scope'],
    ),
  ]);

  static const _repeatFields = <String, Object?>{
    'repeat_rule': {'type': 'string'},
    'repeat_timezone': {
      'type': 'string',
      'description': 'IANA timezone, e.g. Asia/Shanghai',
    },
  };
  static const _repeatTarget = <String, Object?>{
    ..._target,
    'expected_series_version': {'type': 'integer', 'minimum': 1},
    'scope': {
      'type': 'string',
      'enum': ['current', 'current_and_future'],
    },
  };
  static const _target = <String, Object?>{
    'id': {'type': 'string'},
    'expected_version': {'type': 'integer', 'minimum': 1},
  };
  static const fields = <String, Object?>{
    'title': {'type': 'string', 'maxLength': 2000},
    'note': {
      'type': ['string', 'null'],
      'maxLength': 100000,
    },
    'due_at': {
      'type': ['string', 'null'],
      'description':
          'ISO-8601 with offset, e.g. 2026-11-15T15:00:00+08:00. null clears.',
    },
    'reminders': AgentReminders.schema,
    'category_id': {
      'type': ['string', 'null'],
    },
    'priority': {
      'type': 'string',
      'enum': ['none', 'low', 'medium', 'high', 'urgent'],
    },
    'tags': {
      'type': 'array',
      'items': {'type': 'string'},
      'maxItems': 100,
    },
  };

  static JsonObject _schema(
    String name,
    String description,
    JsonObject fields,
    List<String> required,
  ) => immutableJson({
    'type': 'function',
    'function': {
      'name': name,
      'description': description,
      'parameters': {
        'type': 'object',
        'properties': fields,
        'required': required,
        'additionalProperties': false,
      },
    },
  });
}
