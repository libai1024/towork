import '../../agent/agent_tool_decision.dart';

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../agent/memory_agent_tools.dart';
import '../../agent/todo_agent_tools.dart';
import '../../agent/business_agent_tools.dart';
import '../../agent/agent_tool_changes.dart';
import '../../agent/recurrence_agent_tools.dart';
import '../../domain/ai/agent_run.dart';
import '../../domain/ai/model_gateway.dart';
import '../../domain/data_tables/business_queries.dart';
import '../../domain/repositories/memory_persistence.dart';
import '../../domain/settings/app_preferences.dart';
import '../../domain/workspace/workspace_commands.dart';
import '../../domain/workspace/workspace_validation.dart';
import 'agent_run_store.dart';
import 'app_database.dart';
import 'app_preferences_store.dart';
import 'memory_persistence.dart';
import 'sqlite_row_query.dart';
import 'workspace_command_store.dart';

/// Network and user interaction stay outside SQLite transactions. All business
/// effects and their tool messages are committed on the same database connection.
class SqliteAgentToolExecutor
    implements AgentToolExecutor, AgentToolDiagnostics {
  SqliteAgentToolExecutor(
    this.db, {
    DateTime Function()? clock,
    this.beforeJournal,
    this.requireCurrentConfiguration = false,
  }) : _clock = clock ?? DateTime.now;
  final AppDatabase db;
  final DateTime Function() _clock;

  /// Synchronous fault injection for the business-write / journal crash window.
  final void Function()? beforeJournal;
  final bool requireCurrentConfiguration;
  @override
  List<JsonObject> get schemas => TodoAgentTools.schemas;

  /// Rebase only the unexecuted intent on current data, then require a new
  /// approval. This never calls the model or silently executes a refreshed patch.
  Future<AgentRun> refreshProposal(
    String id, {
    required int expectedRevision,
  }) => _guard(
    () => db.transaction(() async {
      final store = SqliteAgentRunStore(db);
      final run = await store.read(id);
      if (run.revision != expectedRevision ||
          run.proposal == null ||
          !(run.status == AgentRunStatus.awaitingConfirmation ||
              run.status == AgentRunStatus.failed &&
                  {
                    'workspace_versionConflict',
                    'workspace_notFound',
                  }.contains(run.failureCode))) {
        throw const AgentFailure(AgentFailureCode.conflict);
      }
      final snapshot = await SqliteWorkspaceCommandStore(db).load();
      final now = _clock().toUtc();
      final calls = <JsonObject>[];
      final entities = {...snapshot.entities};
      for (final call in (run.proposal!['calls']! as List).cast<JsonObject>()) {
        if (call['business_intent'] != null || call['table_intent'] != null) {
          calls.add(BusinessAgentTools.refresh(call, snapshot, now));
          continue;
        }
        if (call['recurrence_intent'] != null) {
          calls.add(RecurrenceAgentTools.refresh(call, snapshot, now));
          continue;
        }
        final raw = call['mutation'];
        if (raw is! JsonObject || call['intent_patch'] is! JsonObject) {
          throw const AgentFailure(AgentFailureCode.invalid);
        }
        final kind = WorkspaceEntityKind.values.byName(raw['kind']! as String);
        final mutation = WorkspaceMutationKind.values.byName(
          raw['mutation']! as String,
        );
        final entityId = raw['entity_id']! as String;
        final before = snapshot.find(kind, entityId);
        if (mutation == WorkspaceMutationKind.create
            ? before != null
            : before == null || before.isDeleted) {
          throw WorkspaceFailure(
            WorkspaceFailureCode.versionConflict,
            entityId: entityId,
          );
        }
        final deleting = mutation == WorkspaceMutationKind.delete;
        final after = deleting
            ? before!.data
            : applyWorkspacePatch(
                kind,
                before?.data,
                call['intent_patch']! as JsonObject,
                now,
              );
        calls.add({
          ...call,
          'before': before?.toJson(),
          'after': deleting ? null : after,
          'mutation': {
            ...raw,
            'expected_version': before?.version,
            'patch': deleting ? <String, Object?>{} : after,
          },
        });
      }
      final targets = <String>{};
      for (final call in calls) {
        for (final mutation in AgentToolChanges.mutations(call)) {
          if (!targets.add(mutation.key)) {
            throw const AgentFailure(AgentFailureCode.invalid);
          }
          entities[mutation.key] = AgentToolChanges.project(
            mutation,
            snapshot,
            now,
          );
        }
      }
      if (targets.length > 500) {
        throw const AgentFailure(AgentFailureCode.budget);
      }
      validateWorkspaceGraph(entities.values);
      final proposal = <String, Object?>{
        'id':
            'ap_${TodoAgentTools.digest({'refresh': run.proposal!['id'], 'revision': run.revision})}',
        'run_id': run.id,
        'round': run.round,
        'calls': calls,
      };
      if (utf8.encode(jsonEncode(proposal)).length > 2 * 1024 * 1024) {
        throw const AgentFailure(AgentFailureCode.budget);
      }
      return store.save(
        run.next(
          AgentRunStatus.awaitingConfirmation,
          proposal: {...proposal, 'digest': TodoAgentTools.digest(proposal)},
        ),
        expectedRevision: run.revision,
      );
    }),
  );

  @override
  Future<AgentRun> propose(AgentRun run, ModelCompleted completion) =>
      _guard(() => _propose(run, completion));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AgentFailure {
      rethrow;
    } on ModelFailure {
      rethrow;
    } on WorkspaceFailure {
      rethrow;
    } on PreferenceFailure {
      rethrow;
    } on FormatException {
      throw const AgentFailure(AgentFailureCode.invalid);
    } catch (_) {
      throw const AgentFailure(AgentFailureCode.storage);
    }
  }

  Future<AgentRun> _propose(AgentRun run, ModelCompleted completion) async {
    if (run.status != AgentRunStatus.generating) {
      throw const AgentFailure(AgentFailureCode.conflict);
    }
    try {
      return await db.transaction(() async {
        final store = SqliteAgentRunStore(db);
        if ((await store.read(run.id)).revision != run.revision) {
          throw const AgentFailure(AgentFailureCode.conflict);
        }
        final commandStore = SqliteWorkspaceCommandStore(db);
        // Pure business reads load table definitions and page rows in SQL.
        final rawCalls = completion.assistantMessage['tool_calls'];
        final pureRead =
            rawCalls is List &&
            rawCalls.every(
              (raw) =>
                  raw is Map &&
                  raw['function'] is Map &&
                  BusinessQueries.names.contains(raw['function']['name']) &&
                  raw['function']['arguments'] is String,
            );
        final snapshot = pureRead
            ? await commandStore.loadTables()
            : await commandStore.load();
        final precomputed = <String, Object?>{};
        if (pureRead) {
          for (final raw in rawCalls) {
            final call = raw as Map;
            final function = call['function']! as Map;
            final name = function['name']! as String;
            final args = jsonDecode(
              function['arguments']! as String,
            ) as Map<String, Object?>;
            precomputed[call['id']! as String] = await switch (name) {
              'data_row_list' => SqliteRowQuery.rows(db, snapshot, args),
              'data_row_get' => SqliteRowQuery.cell(db, snapshot, args),
              _ => Future.value(BusinessQueries.query(name, snapshot, args)),
            };
          }
        }
        // Memory tools execute inline at propose time: the user's own
        // instruction is the intent, so pause/epoch/version gate them, never
        // the write tiers. Failures become readable tool results, not thrown
        // errors. A later failure in the batch rolls these writes back too.
        if (rawCalls is List) {
          for (final raw in rawCalls) {
            if (raw is! Map ||
                raw['id'] is! String ||
                raw['function'] is! Map ||
                !MemoryAgentTools.names.contains(raw['function']['name']) ||
                raw['function']['arguments'] is! String) {
              continue;
            }
            final decoded = jsonDecode(raw['function']['arguments']! as String);
            if (decoded is! Map<String, Object?>) {
              throw const AgentFailure(AgentFailureCode.invalid);
            }
            precomputed[raw['id']! as String] = await _memory(
              raw['function']['name']! as String,
              decoded,
              run,
            );
          }
        }
        // Image import has a locally selected table scope. Image text cannot
        // authorize deletes, todo actions or another table, even in auto mode.
        final image = await (db.select(
          db.localAttachments,
        )..where((r) => r.inputId.equals(run.inputId))).getSingleOrNull();
        if (image != null) {
          final calls = completion.assistantMessage['tool_calls'];
          if (calls is! List) {
            throw const AgentFailure(AgentFailureCode.invalid);
          }
          for (final raw in calls) {
            if (raw is! Map || raw['function'] is! Map) {
              throw const AgentFailure(AgentFailureCode.invalid);
            }
            final function = raw['function'] as Map;
            if (!{
                  'data_table_get',
                  'data_row_list',
                  'data_row_get',
                  'data_row_create',
                  'data_row_update',
                }.contains(function['name']) ||
                function['arguments'] is! String) {
              throw const AgentFailure(AgentFailureCode.invalid);
            }
            final args = jsonDecode(function['arguments'] as String);
            if ({
                  'data_row_create',
                  'data_row_update',
                }.contains(function['name']) &&
                (args is! Map || args['uncertain_field_ids'] is! List)) {
              throw const AgentFailure(AgentFailureCode.invalid);
            }
            if (args is! Map || args['table_id'] != image.tableId) {
              throw const AgentFailure(AgentFailureCode.invalid);
            }
          }
        }
        final proposal = TodoAgentTools.prepare(
          run,
          completion,
          snapshot,
          _clock().toUtc(),
          precomputed: precomputed,
          localOffset: _clock().timeZoneOffset,
        );
        if (utf8.encode(jsonEncode(proposal)).length > 2 * 1024 * 1024) {
          throw const AgentFailure(AgentFailureCode.budget);
        }
        return store.save(
          run.next(
            AgentRunStatus.ready,
            history: [...run.history, completion.assistantMessage],
            proposal: proposal,
            usage: [
              ...run.usage,
              {'round': run.round, 'usage': completion.usage},
            ],
          ),
          expectedRevision: run.revision,
        );
      });
    } on FormatException {
      throw const AgentFailure(AgentFailureCode.invalid);
    }
  }

  Future<Map<String, Object?>> _memory(
    String name,
    Map<String, Object?> args,
    AgentRun run,
  ) async {
    final memory = SqliteMemoryPersistence(db);
    try {
      switch (name) {
        case 'memory_create':
          final parsed = MemoryAgentTools.validate(args);
          final write = await memory.remember(
            content: parsed.content,
            kindId: parsed.kindId,
            source: MemoryPersistSource.ai,
            sourceMessageId: run.inputId,
          );
          return MemoryAgentTools.writeResult(
            memoryId: write.memoryId,
            version: write.version,
            epoch: write.epoch,
          );
        case 'memory_search':
          final parsed = MemoryAgentTools.validateSearch(args);
          final now = _clock().toUtc();
          final found = parsed.query.isEmpty
              ? await memory.list()
              : await memory.search(parsed.query, limit: parsed.limit);
          return {
            'items': [
              for (final item
                  in found
                      .where(
                        (m) => m.expiresAt == null || m.expiresAt!.isAfter(now),
                      )
                      .take(parsed.limit))
                MemoryAgentTools.item(
                  id: item.id,
                  version: item.version,
                  kindId: item.kindId,
                  content: item.content,
                  updatedAt: item.updatedAt,
                ),
            ],
            'match': parsed.query.isEmpty ? 'recent' : 'keyword',
          };
        default:
          final parsed = MemoryAgentTools.validateUpdate(args);
          final updated = await memory.update(
            parsed.id,
            content: parsed.content,
            kindId: parsed.kindId,
            expectedVersion: parsed.expectedVersion,
          );
          return MemoryAgentTools.writeResult(
            memoryId: updated.id,
            version: updated.version,
            epoch: updated.epoch,
          );
      }
    } on MemoryPersistenceFailure catch (failure) {
      return switch (failure.code) {
        MemoryPersistenceFailureCode.paused => MemoryAgentTools.pausedResult(),
        MemoryPersistenceFailureCode.epochChanged =>
          MemoryAgentTools.epochResult(),
        MemoryPersistenceFailureCode.notFound =>
          MemoryAgentTools.notFoundResult(),
        MemoryPersistenceFailureCode.versionConflict =>
          MemoryAgentTools.versionResult(),
        _ => MemoryAgentTools.invalidContentResult(),
      };
    }
  }

  /// 一批调用被整体拒绝后，逐条重放校验，告诉模型是哪一条、错在哪。
  ///
  /// 只读且无副作用：不写提案、不执行记忆写入。逐条都能通过说明问题出在
  /// 组合上（同一记录被改了两次、合起来破坏了引用关系）。
  @override
  Future<Map<String, String>> diagnose(
    AgentRun run,
    ModelCompleted completion,
  ) => _guard(() async {
    final rawCalls = completion.assistantMessage['tool_calls'];
    if (rawCalls is! List) return const {};
    if (rawCalls.length > TodoAgentTools.maxCallsPerBatch) {
      return {
        for (final raw in rawCalls)
          if (raw is Map && raw['id'] is String)
            raw['id']! as String: 'batch_too_large',
      };
    }
    final snapshot = await SqliteWorkspaceCommandStore(db).load();
    final now = _clock().toUtc();
    final problems = <String, String>{};
    for (final raw in rawCalls) {
      if (raw is! Map<String, Object?> || raw['id'] is! String) continue;
      final id = raw['id']! as String;
      final function = raw['function'];
      final name = function is Map ? function['name'] : null;
      try {
        if (MemoryAgentTools.names.contains(name)) {
          final decoded = jsonDecode((function! as Map)['arguments'] as String);
          if (decoded is! Map<String, Object?>) {
            throw const AgentFailure(AgentFailureCode.invalid);
          }
          MemoryAgentTools.validateCall(name, decoded);
          continue;
        }
        TodoAgentTools.prepare(
          run,
          ModelCompleted(
            assistantMessage: {
              'role': 'assistant',
              'tool_calls': [raw],
            },
            finishReason: 'tool_calls',
          ),
          snapshot,
          now,
        );
      } on WorkspaceFailure catch (failure) {
        problems[id] = switch (failure.code) {
          WorkspaceFailureCode.versionConflict => 'version_conflict',
          WorkspaceFailureCode.notFound => 'not_found',
          _ => 'invalid_arguments',
        };
      } on AgentFailure catch (failure) {
        if (failure.code != AgentFailureCode.invalid) rethrow;
        problems[id] =
            name is String &&
                TodoAgentTools.schemas.any(
                  (schema) => (schema['function']! as Map)['name'] == name,
                )
            ? 'invalid_arguments'
            : 'unknown_tool';
      } on FormatException {
        problems[id] = 'invalid_arguments';
      } on TypeError {
        problems[id] = 'invalid_arguments';
      }
    }
    return problems;
  });

  @override
  Future<AgentRun> execute(
    AgentRun run, {
    AgentApproval? approval,
    ModelCancellation? cancellation,
  }) => _guard(
    () => _execute(run, approval: approval, cancellation: cancellation),
  );

  Future<AgentRun> _execute(
    AgentRun run, {
    AgentApproval? approval,
    ModelCancellation? cancellation,
  }) async {
    void checkCancelled() {
      if (cancellation?.isCancelled ?? false) {
        throw const AgentFailure(AgentFailureCode.cancelled);
      }
    }

    checkCancelled();
    final decision = AgentToolDecision.forRun(run, approval);
    final proposal = decision.proposal;
    final decisionDigest = decision.digest;
    return db.transaction(() async {
      final store = SqliteAgentRunStore(db);
      if (requireCurrentConfiguration) {
        final config = await db.readConfiguration();
        if (config.version != run.profile.revision ||
            config.credentialRef == null ||
            config.profile.model != run.profile.model ||
            config.profile.product != run.profile.product ||
            config.profile.region != run.profile.region) {
          throw const ModelFailure(ModelFailureCode.configuration);
        }
      }
      final current = await store.read(run.id);
      // The caller may only execute the exact durable preview, not a reconstructed
      // object with the same revision and a newly computed digest.
      if (current.revision == run.revision &&
          canonicalWorkspaceJson(current.toJson()) !=
              canonicalWorkspaceJson(run.toJson())) {
        throw const AgentFailure(AgentFailureCode.conflict);
      }
      if (current.revision != run.revision) {
        // Only replay the exact prior decision, including its selected IDs.
        final event =
            await (db.select(db.agentRunEvents)..where(
                  (r) =>
                      r.runId.equals(run.id) &
                      r.sequence.equals(run.revision + 1),
                ))
                .getSingleOrNull();
        final recorded = event == null
            ? null
            : jsonDecode(event.payload) as Map;
        if (recorded?['decision_digest'] == decisionDigest) return current;
        throw const AgentFailure(AgentFailureCode.conflict);
      }
      final permission = (await SqliteAppPreferencesStore(
        db,
      ).loadOrCreate()).permission;
      if (approval == null &&
          run.status == AgentRunStatus.awaitingConfirmation) {
        return run;
      }
      final (:executing, :remaining) = decision.select(permission);
      if (executing.isEmpty) {
        checkCancelled();
        return store.save(
          run.next(AgentRunStatus.awaitingConfirmation),
          expectedRevision: run.revision,
          decisionDigest: decisionDigest,
        );
      }
      checkCancelled();
      final businessSnapshot =
          approval?.reject != true &&
              executing.any((call) => call['business_intent'] != null)
          ? await SqliteWorkspaceCommandStore(db).load()
          : null;
      final mutations = <WorkspaceMutation>[];
      for (final call in executing) {
        if (approval?.reject != true) {
          if (businessSnapshot != null) {
            BusinessAgentTools.validateCurrent(call, businessSnapshot);
          }
          mutations.addAll(AgentToolChanges.mutations(call));
        }
      }
      final receipt = mutations.isEmpty
          ? null
          : await SqliteWorkspaceCommandStore(db, clock: _clock).execute(
              WorkspaceCommand(
                operationId: proposal['id']! as String,
                source: 'agent',
                actions: mutations,
              ),
            );
      checkCancelled();
      final results = <JsonObject>[];
      for (final call in executing) {
        final effects = AgentToolChanges.mutations(call);
        final write = effects.isNotEmpty;
        final result = approval?.reject == true && write
            ? {'status': 'not_executed', 'reason': 'user_rejected'}
            : !write
            ? call['result']
            : call['business_intent'] != null
            ? {
                'operation_id': receipt!.operationId,
                'id': effects.single.entityId,
                'table_id': (call['business_table']! as Map)['id'],
                'version': receipt.affected
                    .singleWhere((e) => e.key == effects.single.key)
                    .version,
                'deleted': call['operation'] == 'delete',
              }
            : call['mutations'] == null
            ? {
                'operation_id': receipt!.operationId,
                'entity': receipt.affected
                    .singleWhere((e) => e.key == effects.single.key)
                    .toJson(),
              }
            : {
                'operation_id': receipt!.operationId,
                'scope': call['scope'],
                'target_id': call['target_id'],
                'changed_count': effects.length,
                'future_generation': call['scope'] == 'current'
                    ? 'unchanged'
                    : call['operation'] == 'delete' ||
                          (call['after'] as JsonObject?)?['repeat_rule'] == null
                    ? 'stopped_for_selected_scope'
                    : 'bounded_local_window',
                'entities': [
                  for (final e in receipt.affected.where(
                    (e) => effects.any((m) => m.key == e.key),
                  ))
                    {
                      'id': e.id,
                      'kind': e.kind.name,
                      'version': e.version,
                      'deleted': e.isDeleted,
                      for (final field in [
                        'title',
                        'status',
                        'due_at',
                        'repeat_rule',
                        'repeat_timezone',
                        'series_id',
                        'occurrence_index',
                      ])
                        if (e.data.containsKey(field)) field: e.data[field],
                    },
                ],
              };
        results.add({
          'role': 'tool',
          'tool_call_id': call['tool_call_id'],
          'content': jsonEncode(result),
        });
      }
      final remainder = remaining.isEmpty
          ? null
          : <String, Object?>{
              'id':
                  'ap_${TodoAgentTools.digest({'previous': proposal['id'], 'revision': run.revision})}',
              'run_id': run.id,
              'round': run.round,
              'calls': remaining,
            };
      beforeJournal?.call();
      final committed = await store.save(
        run.next(
          remainder == null
              ? AgentRunStatus.generating
              : AgentRunStatus.awaitingConfirmation,
          proposal: remainder == null
              ? null
              : {...remainder, 'digest': TodoAgentTools.digest(remainder)},
          history: [...run.history, ...results],
          clearProposal: remainder == null,
          receipts: [...run.receipts, if (receipt != null) receipt.operationId],
        ),
        expectedRevision: run.revision,
        decisionDigest: decisionDigest,
      );
      checkCancelled();
      return committed;
    });
  }
}
