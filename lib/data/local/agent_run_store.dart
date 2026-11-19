import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../domain/ai/agent_run.dart';
import '../../domain/ai/model_gateway.dart';
import '../../domain/workspace/workspace_commands.dart';
import 'app_database.dart';

class SqliteAgentRunStore implements AgentRunStore {
  SqliteAgentRunStore(this.db);
  final AppDatabase db;

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AgentFailure {
      rethrow;
    } catch (_) {
      throw const AgentFailure(AgentFailureCode.storage);
    }
  }

  AgentRun _decode(AgentRunRow row) {
    final run = AgentRun.fromJson(
      (jsonDecode(row.payload) as Map).cast<String, Object?>(),
    );
    if (run.id != row.id ||
        run.revision != row.revision ||
        run.status.name != row.status ||
        run.sessionId != row.sessionId ||
        run.inputId != row.inputId) {
      throw const AgentFailure(AgentFailureCode.storage);
    }
    return run;
  }

  @override
  Future<AgentRun> read(String id) => _guard(() async {
    final row = await (db.select(
      db.agentRunRows,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    if (row == null) throw const AgentFailure(AgentFailureCode.invalid);
    return _decode(row);
  });

  @override
  Future<AgentRun> create(AgentRun run) => _guard(() async {
    if (run.status != AgentRunStatus.queued ||
        run.revision != 1 ||
        run.round != 0 ||
        run.proposal != null ||
        run.usage.isNotEmpty ||
        run.receipts.isNotEmpty ||
        run.failureCode != null) {
      throw const AgentFailure(AgentFailureCode.invalid);
    }
    final initial = sha256
        .convert(
          utf8.encode(canonicalWorkspaceJson({...run.toJson()}..remove('id'))),
        )
        .toString();
    return db.transaction(() async {
      final old =
          await (db.select(db.agentRunRows)..where(
                (r) =>
                    r.sessionId.equals(run.sessionId) &
                    r.inputId.equals(run.inputId),
              ))
              .getSingleOrNull();
      if (old != null) {
        if (old.initialRequest != initial) {
          throw const AgentFailure(AgentFailureCode.conflict);
        }
        return _decode(old);
      }
      await db
          .into(db.agentRunRows)
          .insert(
            AgentRunRowsCompanion.insert(
              id: run.id,
              sessionId: run.sessionId,
              inputId: run.inputId,
              revision: run.revision,
              status: run.status.name,
              initialRequest: initial,
              payload: jsonEncode(run.toJson()),
            ),
          );
      await _event(run);
      return run;
    });
  });

  @override
  Future<AgentRun> save(
    AgentRun next, {
    required int expectedRevision,
    String? decisionDigest,
  }) => _guard(
    () => db.transaction(() async {
      final old = await read(next.id);
      if (old.revision != expectedRevision ||
          next.revision != expectedRevision + 1 ||
          old.sessionId != next.sessionId ||
          old.inputId != next.inputId ||
          old.historyOmittedTurns != next.historyOmittedTurns ||
          canonicalWorkspaceJson(old.toJson()['profile']) !=
              canonicalWorkspaceJson(next.toJson()['profile']) ||
          (old.isTerminal &&
              !(old.status == AgentRunStatus.failed &&
                  {
                    AgentRunStatus.interrupted,
                    AgentRunStatus.awaitingConfirmation,
                  }.contains(next.status))) ||
          !_transitions[old.status]!.contains(next.status) ||
          next.round < old.round ||
          next.round > old.round + 1 ||
          next.history.length < old.history.length ||
          next.usage.length < old.usage.length ||
          canonicalWorkspaceJson(next.usage.take(old.usage.length).toList()) !=
              canonicalWorkspaceJson(old.usage) ||
          canonicalWorkspaceJson(
                next.history.take(old.history.length).toList(),
              ) !=
              canonicalWorkspaceJson(old.history) ||
          next.receipts.length < old.receipts.length ||
          !List.generate(
            old.receipts.length,
            (i) => old.receipts[i] == next.receipts[i],
          ).every((e) => e)) {
        throw const AgentFailure(AgentFailureCode.conflict);
      }
      final count =
          await (db.update(db.agentRunRows)..where(
                (r) =>
                    r.id.equals(next.id) & r.revision.equals(expectedRevision),
              ))
              .write(
                AgentRunRowsCompanion(
                  revision: Value(next.revision),
                  status: Value(next.status.name),
                  payload: Value(jsonEncode(next.toJson())),
                ),
              );
      if (count != 1) throw const AgentFailure(AgentFailureCode.conflict);
      await _event(next, decisionDigest: decisionDigest);
      return next;
    }),
  );

  /// 把失败的运行改绑到当前模型配置，使「换个模型重试」成为可能。
  ///
  /// 这是唯一允许改变运行所属模型的入口，且只对已失败的运行开放：
  /// 进行中或等待确认的运行仍然绑定原配置，配置一变就按冲突处理。
  Future<AgentRun> rebind(
    String id, {
    required int expectedRevision,
    required ModelProfile profile,
  }) => _guard(
    () => db.transaction(() async {
      final old = await read(id);
      if (old.revision != expectedRevision ||
          old.status != AgentRunStatus.failed) {
        throw const AgentFailure(AgentFailureCode.conflict);
      }
      final next = old.rebound(profile);
      final count =
          await (db.update(db.agentRunRows)..where(
                (r) => r.id.equals(id) & r.revision.equals(expectedRevision),
              ))
              .write(
                AgentRunRowsCompanion(
                  revision: Value(next.revision),
                  payload: Value(jsonEncode(next.toJson())),
                ),
              );
      if (count != 1) throw const AgentFailure(AgentFailureCode.conflict);
      await _event(next);
      return next;
    }),
  );

  Future<void> _event(AgentRun run, {String? decisionDigest}) async {
    await db
        .into(db.agentRunEvents)
        .insert(
          AgentRunEventsCompanion.insert(
            runId: run.id,
            sequence: run.revision,
            payload: jsonEncode({
              'recorded_at': DateTime.now().toUtc().toIso8601String(),
              'state': run.status.name,
              'round': run.round,
              'history_length': run.history.length,
              'context_omitted_turns': run.contextOmittedTurns,
              'estimated_input_tokens': run.estimatedInputTokens,
              'proposal_id': run.proposal?['id'],
              'proposal_digest': run.proposal?['digest'],
              'receipts': run.receipts,
              'failure_code': run.failureCode,
              'decision_digest': ?decisionDigest,
            }),
          ),
        );
  }

  /// Call only at application startup after the previous process has ended.
  /// Never use this as a concurrent-worker lease or silently replay network work.
  Future<int> interruptAbandonedGenerations() => _guard(
    () => db.transaction(() async {
      final rows = await (db.select(
        db.agentRunRows,
      )..where((r) => r.status.equals(AgentRunStatus.generating.name))).get();
      for (final row in rows) {
        final run = _decode(row);
        await save(
          run.next(AgentRunStatus.interrupted),
          expectedRevision: run.revision,
        );
      }
      return rows.length;
    }),
  );
}

const _transitions = <AgentRunStatus, Set<AgentRunStatus>>{
  AgentRunStatus.failed: {
    AgentRunStatus.interrupted,
    AgentRunStatus.awaitingConfirmation,
  },
  AgentRunStatus.queued: {
    AgentRunStatus.generating,
    AgentRunStatus.cancelled,
    AgentRunStatus.failed,
  },
  AgentRunStatus.generating: {
    AgentRunStatus.generating,
    AgentRunStatus.ready,
    AgentRunStatus.succeeded,
    AgentRunStatus.failed,
    AgentRunStatus.cancelled,
    AgentRunStatus.interrupted,
  },
  AgentRunStatus.ready: {
    AgentRunStatus.awaitingConfirmation,
    AgentRunStatus.generating,
    AgentRunStatus.failed,
    AgentRunStatus.cancelled,
  },
  AgentRunStatus.awaitingConfirmation: {
    AgentRunStatus.awaitingConfirmation,
    AgentRunStatus.generating,
    AgentRunStatus.failed,
    AgentRunStatus.cancelled,
  },
  AgentRunStatus.interrupted: {
    AgentRunStatus.generating,
    AgentRunStatus.cancelled,
    AgentRunStatus.failed,
  },
};
