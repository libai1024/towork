import '../domain/ai/agent_run.dart';
import '../domain/ai/model_gateway.dart';
import '../domain/recurrence/recurrence_plans.dart';
import '../domain/workspace/workspace_commands.dart';
import '../domain/workspace/workspace_validation.dart';
import 'agent_tool_changes.dart';

/// Trusted translation from a bounded model intent to the same plans used by
/// manual editing. Neither tool IDs nor series metadata come from model patches.
class RecurrenceAgentTools {
  static const names = {
    'todo_repeat_create',
    'todo_repeat_start',
    'todo_repeat_update',
    'todo_repeat_delete',
  };
  static const fields = {
    'title',
    'note',
    'due_at',
    'category_id',
    'priority',
    'tags',
    'remind_rules',
  };

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

  static JsonObject prepare({
    required String name,
    required JsonObject args,
    required String callId,
    required String planId,
    required String inputId,
    required String sourceModel,
    String? sourceProvider,
    required WorkspaceSnapshot snapshot,
    required DateTime now,
  }) {
    final create = name == 'todo_repeat_create';
    final start = name == 'todo_repeat_start';
    final deleting = name == 'todo_repeat_delete';
    if (!names.contains(name)) {
      throw const AgentFailure(AgentFailureCode.invalid);
    }
    final required = create
        ? {'title', 'due_at', 'repeat_rule', 'repeat_timezone'}
        : {
            'id',
            'expected_version',
            if (start) ...[
              'repeat_rule',
              'repeat_timezone',
            ] else ...[
              'expected_series_version',
              'scope',
            ],
            if (name == 'todo_repeat_update') 'patch',
          };
    _keys(args, {...required, if (create) ...fields}, required);
    final id = create ? 'at_$planId' : args['id'];
    if (id is! String) throw const AgentFailure(AgentFailureCode.invalid);
    validateWorkspaceId(id);
    var planningSnapshot = snapshot;
    final before = snapshot.find(WorkspaceEntityKind.todo, id);
    if (create) {
      if (before != null) {
        throw const WorkspaceFailure(WorkspaceFailureCode.versionConflict);
      }
      final data = applyWorkspacePatch(WorkspaceEntityKind.todo, null, {
        for (final field in fields)
          if (args.containsKey(field)) field: args[field],
        'source': 'ai',
        'source_message_id': inputId,
        'source_model': sourceModel,
        'source_provider': ?sourceProvider,
      }, now);
      planningSnapshot = WorkspaceSnapshot([
        ...snapshot.entities.values,
        WorkspaceEntity(
          kind: WorkspaceEntityKind.todo,
          id: id,
          version: 1,
          data: data,
          createdAt: now,
          updatedAt: now,
        ),
      ]);
    } else {
      if (args['expected_version'] is! int ||
          before == null ||
          before.isDeleted ||
          before.version != args['expected_version']) {
        throw const WorkspaceFailure(WorkspaceFailureCode.versionConflict);
      }
      if (!start) {
        final seriesId = before.data['series_id'];
        final series = seriesId is String
            ? snapshot.find(WorkspaceEntityKind.series, seriesId)
            : null;
        if (series == null ||
            series.isDeleted ||
            args['expected_series_version'] is! int ||
            args['expected_series_version'] != series.version) {
          throw const WorkspaceFailure(WorkspaceFailureCode.versionConflict);
        }
      }
    }
    final scope = create || start
        ? RecurrenceScope.currentAndFuture
        : switch (args['scope']) {
            'current' => RecurrenceScope.current,
            'current_and_future' => RecurrenceScope.currentAndFuture,
            _ => throw const AgentFailure(AgentFailureCode.invalid),
          };
    final planner = RecurrencePlans(planningSnapshot, now: now);
    final target = planningSnapshot.find(WorkspaceEntityKind.todo, id)!;
    final patch = args['patch'];
    if (!create && !start && !deleting) {
      if (patch is! JsonObject || patch.isEmpty) {
        throw const AgentFailure(AgentFailureCode.invalid);
      }
      _keys(patch, {...fields, 'repeat_rule', 'repeat_timezone'}, {});
    }
    var anchor = now;
    for (final value in [
      target.data['due_at'],
      target.data['occurrence_at'],
      if (patch is JsonObject) patch['due_at'],
    ]) {
      if (value is String) {
        final date = DateTime.tryParse(value);
        if (date != null && date.isAfter(anchor)) anchor = date;
      }
    }
    final through = anchor.add(const Duration(days: 90));
    final WorkspaceCommand command;
    if (create || start) {
      if (args['repeat_rule'] is! String ||
          args['repeat_timezone'] is! String) {
        throw const AgentFailure(AgentFailureCode.invalid);
      }
      command = planner.start(
        id,
        rule: args['repeat_rule']! as String,
        timezone: args['repeat_timezone']! as String,
        operationId: planId,
        through: through,
      );
    } else if (deleting) {
      command = planner.delete(id, scope: scope, operationId: planId);
    } else {
      command = planner.edit(
        id,
        patch! as JsonObject,
        scope: scope,
        operationId: planId,
        through: through,
      );
    }
    final mutations = [
      for (final m in command.actions)
        if (create && m.kind == WorkspaceEntityKind.todo && m.entityId == id)
          WorkspaceMutation(
            actionId: m.actionId,
            kind: m.kind,
            entityId: id,
            mutation: WorkspaceMutationKind.create,
            patch: m.patch,
          )
        else
          m,
    ];
    final effects = <JsonObject>[];
    final next = {...snapshot.entities};
    for (final mutation in mutations) {
      final after = AgentToolChanges.project(mutation, snapshot, now);
      next[after.key] = after;
      effects.add({
        'operation': mutation.mutation == WorkspaceMutationKind.update
            ? 'edit'
            : mutation.mutation.name,
        'before': snapshot.entities[mutation.key]?.toJson(),
        'after': after.isDeleted ? null : after.data,
        'kind': mutation.kind.name,
        'entity_id': mutation.entityId,
      });
    }
    validateWorkspaceGraph(next.values);
    final selected = next['todo:$id']!;
    return immutableJson({
      'tool_call_id': callId,
      'name': name,
      'operation': create
          ? 'create'
          : deleting
          ? 'delete'
          : 'edit',
      'before': before?.toJson(),
      'after': selected.isDeleted ? null : selected.data,
      'scope': scope == RecurrenceScope.current
          ? 'current'
          : 'current_and_future',
      'target_id': id,
      'recurrence_intent': {
        'args': args,
        'plan_id': planId,
        'input_id': inputId,
        'source_model': sourceModel,
        'source_provider': ?sourceProvider,
      },
      'mutations': mutations.map((m) => m.toJson()).toList(),
      'effects': effects,
    });
  }

  /// A refresh deliberately re-queries versions, then displays a new immutable
  /// proposal. The executor requires fresh explicit approval before committing.
  static JsonObject refresh(
    JsonObject call,
    WorkspaceSnapshot snapshot,
    DateTime now,
  ) {
    final intent = call['recurrence_intent']! as JsonObject;
    final args = {...intent['args']! as JsonObject};
    if (call['name'] != 'todo_repeat_create') {
      final todo = snapshot.find(
        WorkspaceEntityKind.todo,
        args['id']! as String,
      );
      if (todo == null || todo.isDeleted) {
        throw const WorkspaceFailure(WorkspaceFailureCode.notFound);
      }
      args['expected_version'] = todo.version;
      if (call['name'] != 'todo_repeat_start') {
        final id = todo.data['series_id'];
        final series = id is String
            ? snapshot.find(WorkspaceEntityKind.series, id)
            : null;
        args['expected_series_version'] = series?.version;
      }
    }
    return prepare(
      name: call['name']! as String,
      args: args,
      callId: call['tool_call_id']! as String,
      planId: intent['plan_id']! as String,
      inputId: intent['input_id']! as String,
      sourceModel: intent['source_model'] as String? ?? '',
      sourceProvider: intent['source_provider'] as String?,
      snapshot: snapshot,
      now: now,
    );
  }
}
