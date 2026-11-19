import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../domain/ai/agent_run.dart';
import '../domain/ai/model_gateway.dart';
import '../domain/workspace/workspace_commands.dart';
import 'memory_agent_tools.dart';
import 'todo_agent_schemas.dart';
import 'todo_step_agent_edit.dart';
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
  static final schemas = TodoAgentSchemas.schemas;

  /// 归一化之后库内接受的字段：`reminders` 已换成 `remind_rules`。
  static final _stored = {
    for (final key in TodoAgentSchemas.fields.keys)
      if (key != 'reminders') key,
    'remind_rules',
  };
  static const _editableStatuses = {'pending', 'inProgress', 'cancelled'};

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
          final stepEdit = patch.keys.any(TodoStepAgentEdit.fields.containsKey);
          if (stepEdit) {
            patch = TodoStepAgentEdit.translate(patch, before, stableSuffix);
          } else {
            _keys(patch, {..._stored, 'status'}, {});
          }
          if (!stepEdit &&
              patch.containsKey('status') &&
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
        if (patch.containsKey('steps') ||
            (complete &&
                (before?.data['steps'] as List? ?? []).any(
                  (s) => (s as Map)['done'] == false,
                )))
          'requires_review': true,
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
          patch: deleting
              ? {}
              : {
                  ...afterData,
                  if (patch.containsKey('steps')) 'steps': patch['steps'],
                },
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
