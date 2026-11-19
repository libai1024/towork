import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/agent/agent_runner.dart';
import 'package:towork/data/local/agent_run_store.dart';
import 'package:towork/data/local/agent_tool_executor.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/app_preferences_store.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';

import '../support/free/query_fixture.dart';
import '../support/free/scripted_query_model.dart';

void main() {
  late Directory dir;
  late AppDatabase db;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('query-agent');
    db = AppDatabase.background(File('${dir.path}/test.sqlite'));
    await SqliteWorkspaceCommandStore(db).execute(queryFixture());
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });
  AgentRun initial() => AgentRun(
    id: 'run',
    sessionId: 'session',
    inputId: 'input',
    profile: ModelProfile(model: 'fixture'),
    history: [
      {'role': 'user', 'content': '核对工作分类中今天的高优先级周会备注，然后完成待办'},
    ],
  );
  for (final permission in ['auto', 'askOnChange', 'askAll']) {
    test(
      'query discovery and full note read use real SQLite with $permission write policy',
      () async {
        final preferences = SqliteAppPreferencesStore(db);
        final old = await preferences.loadOrCreate();
        await preferences.update({
          'permission': permission,
        }, expectedVersion: old.version);
        final model = ScriptedQueryModel();
        final runner = AgentRunner(
          gateway: model,
          store: SqliteAgentRunStore(db),
          tools: SqliteAgentToolExecutor(db),
        );
        var result = await runner.start(
          initial(),
          apiKey: 'synthetic-query-key',
        );
        if (permission == 'askAll') {
          expect(result.status, AgentRunStatus.awaitingConfirmation);
          expect(result.round, 5);
          expect(result.receipts, isEmpty);
          expect(await db.select(db.workspaceOperations).get(), hasLength(1));
          expect(
            (result.proposal!['calls']! as List).single['name'],
            'todo_complete',
          );
          result = await runner.resume(
            result.id,
            apiKey: 'synthetic-query-key',
            approval: AgentApproval(
              runRevision: result.revision,
              proposalId: result.proposal!['id']! as String,
              digest: result.proposal!['digest']! as String,
            ),
          );
        }
        expect(result.status, AgentRunStatus.succeeded);
        expect(model.note.toString(), queryNote);
        expect(model.requests, hasLength(6));
        expect(result.receipts, hasLength(1));
        final snapshot = await SqliteWorkspaceCommandStore(db).load();
        expect(
          snapshot.find(WorkspaceEntityKind.todo, 'target')!.data['status'],
          'done',
        );
        expect(
          snapshot.find(WorkspaceEntityKind.todo, 'same-title')!.data['status'],
          'pending',
        );
        expect(
          snapshot.find(WorkspaceEntityKind.todo, 'target')!.data['note'],
          queryNote,
        );
        final saved = await SqliteAgentRunStore(db).read(result.id);
        expect(saved.history.where((m) => m['role'] == 'tool'), hasLength(5));
      },
    );
  }
  test('invalid query in mixed read/write batch rejects entire proposal without effects', () async {
    final store = SqliteAgentRunStore(db);
    final queued = await store.create(initial());
    final generating = await store.save(
      queued.next(AgentRunStatus.generating, round: 1),
      expectedRevision: queued.revision,
    );
    final completion = ModelCompleted(
      assistantMessage: {
        'role': 'assistant',
        'tool_calls': [
          {
            'id': 'write',
            'type': 'function',
            'function': {
              'name': 'todo_complete',
              'arguments': jsonEncode({'id': 'target', 'expected_version': 1}),
            },
          },
          {
            'id': 'read',
            'type': 'function',
            'function': {
              'name': 'todo_list',
              'arguments': jsonEncode({
                'category_id': 'missing',
                'page_token': 'invalid',
              }),
            },
          },
        ],
      },
      finishReason: 'tool_calls',
    );
    await expectLater(
      SqliteAgentToolExecutor(db).propose(generating, completion),
      throwsA(isA<WorkspaceFailure>()),
    );
    expect(
      (await SqliteWorkspaceCommandStore(
        db,
      ).load()).find(WorkspaceEntityKind.todo, 'target')!.data['status'],
      'pending',
    );
    expect(await db.select(db.workspaceOperations).get(), hasLength(1));
  });
}
