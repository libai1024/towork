import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../domain/ai/agent_run.dart';
import '../domain/ai/model_gateway.dart';
import '../domain/workspace/workspace_commands.dart';
import 'memory_agent_tools.dart';
import '../domain/workspace/workspace_queries.dart';
import '../domain/workspace/workspace_validation.dart';
import '../domain/data_tables/business_queries.dart';
import 'agent_reminders.dart';
import 'agent_time.dart';
import 'agent_tool_registry.dart';
import 'business_agent_tools.dart';
import 'agent_tool_changes.dart';
import 'recurrence_agent_tools.dart';

/// The model can only propose these schemas. IDs, provenance and permissions are
/// supplied by trusted application code, never by arbitrary model patches.
class TodoAgentTools {
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
        'note_offset': {'type': 'integer', 'minimum': 0, 'maximum': 100000},
        'note_limit': {'type': 'integer', 'minimum': 1, 'maximum': 4000},
      },
      const ['id'],
    ),
    _schema(
      'todo_create',
      'Create a one-off todo. due_at is local time with the UTC offset from the time anchor. Leave unmentioned fields out.',
      _fields,
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
            ..._fields,
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
      {..._fields, ..._repeatFields},
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
            ..._fields,
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
  static const _fields = <String, Object?>{
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

  /// 归一化之后库内接受的字段：`reminders` 已换成 `remind_rules`。
  static final _stored = {
    for (final key in _fields.keys)
      if (key != 'reminders') key,
    'remind_rules',
  };
  static const _editableStatuses = {'pending', 'inProgress', 'cancelled'};

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

  static String digest(JsonObject data) =>
      sha256.convert(utf8.encode(canonicalWorkspaceJson(data))).toString();

  /// 一次模型回复最多带多少个工具调用；超过即整批拒绝。
  static const maxCallsPerBatch = 20;

  /// [precomputed] carries SQL-backed results for read tool calls, keyed by
  /// tool_call_id; absent entries fall back to the shared snapshot path.
  static JsonObject prepare(
    AgentRun run,
    ModelCompleted completion,
    WorkspaceSnapshot snapshot,
    DateTime now, {
    Map<String, Object?> precomputed = const {},
    Duration? localOffset,
  }) {
    final context = AgentToolContext(
      snapshot: snapshot,
      now: now,
      localOffset: localOffset ?? Duration.zero,
    );
    final rawCalls = completion.assistantMessage['tool_calls'];
    if (completion.finishReason != 'tool_calls' ||
        completion.assistantMessage['role'] != 'assistant' ||
        rawCalls is! List ||
        rawCalls.isEmpty ||
        rawCalls.length > maxCallsPerBatch) {
      throw const AgentFailure(AgentFailureCode.invalid);
    }
    final usedIds = <String>{};
    final targets = <String>{};
    final calls = <JsonObject>[];
    final nextEntities = {...snapshot.entities};
    for (var index = 0; index < rawCalls.length; index++) {
      final raw = rawCalls[index];
      if (raw is! Map<String, Object?> ||
          raw['type'] != 'function' ||
          raw['id'] is! String ||
          (raw['id']! as String).isEmpty ||
          (raw['id']! as String).length > 200 ||
          !usedIds.add(raw['id']! as String) ||
          raw['function'] is! Map<String, Object?>) {
        throw const AgentFailure(AgentFailureCode.invalid);
      }
      final function = raw['function']! as JsonObject;
      final name = function['name'];
      if (function['arguments'] is! String) {
        throw const AgentFailure(AgentFailureCode.invalid);
      }
      final decoded = jsonDecode(function['arguments']! as String);
      if (decoded is! Map<String, Object?>) {
        throw const AgentFailure(AgentFailureCode.invalid);
      }
      // 业务表工具的键是用户自定义字段 ID，不做待办语义的时间与提醒换算。
      final args =
          BusinessQueries.names.contains(name) ||
              BusinessAgentTools.writes.contains(name)
          ? decoded
          : AgentReminders.translate(AgentTime.normalize(decoded));
      if (AgentToolRegistry.read(name) case final tool?) {
        calls.add({
          'tool_call_id': raw['id'],
          'name': name,
          'operation': 'query',
          'result': tool.call(args, context),
        });
        continue;
      }
      if (BusinessQueries.names.contains(name)) {
        if (precomputed.containsKey(raw['id'])) {
          calls.add({
            'tool_call_id': raw['id'],
            'name': name,
            'operation': 'query',
            'result': precomputed[raw['id']],
          });
          continue;
        }
        calls.add({
          'tool_call_id': raw['id'],
          'name': name,
          'operation': 'query',
          'result': BusinessQueries.query(name! as String, snapshot, args),
        });
        continue;
      }
      if ({'todo_list', 'todo_get', 'category_list'}.contains(name)) {
        final result = switch (name) {
          'todo_list' => WorkspaceQueries.todos(snapshot, args),
          'todo_get' => WorkspaceQueries.todo(snapshot, args),
          _ => WorkspaceQueries.categories(snapshot, args),
        };
        calls.add({
          'tool_call_id': raw['id'],
          'name': name,
          'operation': 'query',
          'result': localOffset == null
              ? result
              : AgentTime.localize(result, localOffset),
        });
        continue;
      }
      final stableSuffix = digest({
        'run': run.id,
        'round': run.round,
        'index': index,
      });
      if (BusinessAgentTools.writes.contains(name)) {
        final call = BusinessAgentTools.prepare(
          name: name! as String,
          args: args,
          callId: raw['id']! as String,
          suffix: stableSuffix,
          inputId: run.inputId,
          snapshot: snapshot,
          now: now,
        );
        for (final mutation in AgentToolChanges.mutations(call)) {
          if (!targets.add(mutation.key)) {
            throw const AgentFailure(AgentFailureCode.invalid);
          }
          nextEntities[mutation.key] = AgentToolChanges.project(
            mutation,
            snapshot,
            now,
          );
        }
        calls.add(call);
        continue;
      }
      if (MemoryAgentTools.names.contains(name)) {
        // Only the executor can supply a persisted result.
        final result = precomputed[raw['id']];
        if (result is! Map<String, Object?>) {
          throw const AgentFailure(AgentFailureCode.invalid);
        }
        MemoryAgentTools.validateCall(name, args);
        calls.add({
          'tool_call_id': raw['id'],
          'name': name,
          'operation': 'query',
          'result': result,
        });
        continue;
      }
      if (RecurrenceAgentTools.names.contains(name)) {
        final call = RecurrenceAgentTools.prepare(
          name: name! as String,
          args: args,
          callId: raw['id']! as String,
          planId: 'ar_$stableSuffix',
          inputId: run.inputId,
          sourceModel: run.profile.model,
          sourceProvider: run.profile.product.wireId,
          snapshot: snapshot,
          now: now,
        );
        for (final mutation in AgentToolChanges.mutations(call)) {
          if (!targets.add(mutation.key)) {
            throw const AgentFailure(AgentFailureCode.invalid);
          }
          nextEntities[mutation.key] = AgentToolChanges.project(
            mutation,
            snapshot,
            now,
          );
        }
        calls.add(call);
        continue;
      }
      final create = name == 'todo_create';
      final deleting = name == 'todo_delete';
      final complete = name == 'todo_complete';
      if (!create && !deleting && !complete && name != 'todo_update') {
        throw const AgentFailure(AgentFailureCode.invalid);
      }
      _keys(
        args,
        create
            ? _stored
            : {'id', 'expected_version', if (name == 'todo_update') 'patch'},
        create
            ? {'title'}
            : {'id', 'expected_version', if (name == 'todo_update') 'patch'},
      );
      final String id;
      WorkspaceEntity? before;
      JsonObject patch;
      if (create) {
        id = 'at_$stableSuffix';
        patch = {
          ...args,
          'source': 'ai',
          'source_message_id': run.inputId,
          'source_model': run.profile.model,
          'source_provider': run.profile.product.wireId,
        };
      } else {
        if (args['id'] is! String || args['expected_version'] is! int) {
          throw const AgentFailure(AgentFailureCode.invalid);
        }
        id = args['id']! as String;
        validateWorkspaceId(id);
        before = snapshot.find(WorkspaceEntityKind.todo, id);
        if (before == null ||
            before.isDeleted ||
            before.version != args['expected_version']) {
          throw const WorkspaceFailure(WorkspaceFailureCode.versionConflict);
        }
        if (name == 'todo_update') {
          if (args['patch'] is! JsonObject ||
              (args['patch']! as JsonObject).isEmpty) {
            throw const AgentFailure(AgentFailureCode.invalid);
          }
          patch = args['patch']! as JsonObject;
          _keys(patch, {..._stored, 'status'}, {});
          if (patch.containsKey('status') &&
              !_editableStatuses.contains(patch['status'])) {
            throw const AgentFailure(AgentFailureCode.invalid);
          }
        } else {
          patch = complete ? {'status': 'done'} : {};
        }
      }
      if (!targets.add('todo:$id')) {
        throw const AgentFailure(AgentFailureCode.invalid);
      }
      final afterData = deleting
          ? before!.data
          : applyWorkspacePatch(
              WorkspaceEntityKind.todo,
              before?.data,
              patch,
              now,
            );
      if (!deleting &&
          (patch.containsKey('remind_rules') || patch.containsKey('due_at')) &&
          AgentReminders.danglingOffset(afterData)) {
        throw const WorkspaceFailure(WorkspaceFailureCode.validation);
      }
      final after = WorkspaceEntity(
        kind: WorkspaceEntityKind.todo,
        id: id,
        version: (before?.version ?? 0) + 1,
        data: afterData,
        createdAt: before?.createdAt ?? now,
        updatedAt: now,
        deletedAt: deleting ? now : null,
      );
      nextEntities[after.key] = after;
      calls.add({
        'tool_call_id': raw['id'],
        'name': name,
        'operation': create
            ? 'create'
            : deleting
            ? 'delete'
            : complete
            ? 'complete'
            : 'edit',
        'before': before?.toJson(),
        'after': deleting ? null : afterData,
        'intent_patch': patch,
        'mutation': WorkspaceMutation(
          actionId: 'aa_$stableSuffix',
          kind: WorkspaceEntityKind.todo,
          entityId: id,
          mutation: create
              ? WorkspaceMutationKind.create
              : deleting
              ? WorkspaceMutationKind.delete
              : WorkspaceMutationKind.update,
          expectedVersion: before?.version,
          patch: deleting ? {} : afterData,
        ).toJson(),
      });
    }
    if (targets.length > 500) throw const AgentFailure(AgentFailureCode.budget);
    validateWorkspaceGraph(nextEntities.values);
    final proposal = <String, Object?>{
      'id': 'ap_${digest({'run': run.id, 'round': run.round})}',
      'run_id': run.id,
      'round': run.round,
      'calls': calls,
    };
    return immutableJson({...proposal, 'digest': digest(proposal)});
  }

  static void _keys(
    JsonObject args,
    Set<String> allowed,
    Set<String> required,
  ) {
    if (args.keys.any((k) => !allowed.contains(k)) ||
        required.any((k) => !args.containsKey(k))) {
      throw const AgentFailure(AgentFailureCode.invalid);
    }
  }
}
