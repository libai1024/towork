import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:towork/agent/agent_runner.dart';
import 'package:towork/agent/todo_agent_tools.dart';
import 'package:towork/data/local/agent_run_store.dart';
import 'package:towork/data/local/agent_tool_executor.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/app_preferences_store.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/ai/context_window.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/ai/permission_policy.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';

const _key = 'synthetic-test-credential';
JsonObject _call(String name, JsonObject args, {String id = 'call1'}) => {
  'id': id,
  'type': 'function',
  'function': {'name': name, 'arguments': jsonEncode(args)},
};
ModelCompleted _tools(List<JsonObject> calls) => ModelCompleted(
  assistantMessage: {
    'role': 'assistant',
    'content': null,
    'reasoning_content': 'internal reasoning',
    'tool_calls': calls,
  },
  finishReason: 'tool_calls',
  usage: {'total_tokens': 19},
);
ModelCompleted _answer([String content = '已处理']) => ModelCompleted(
  assistantMessage: {'role': 'assistant', 'content': content},
  finishReason: 'stop',
);
AgentRun _initial({
  String id = 'run1',
  String input = 'input1',
  String text = '帮我准备周会',
}) => AgentRun(
  id: id,
  sessionId: 'session1',
  inputId: input,
  profile: ModelProfile(model: 'fixture', product: ProviderKind.kimiCode),
  history: [
    {'role': 'user', 'content': text},
  ],
);
AgentApproval _approve(AgentRun run) => AgentApproval(
  runRevision: run.revision,
  proposalId: run.proposal!['id']! as String,
  digest: run.proposal!['digest']! as String,
);

class _Gateway implements ModelGateway {
  _Gateway(this.responses);
  final List<List<ModelEvent>> responses;
  final requests = <ModelRequest>[];
  void Function(int)? beforeResponse;
  @override
  Stream<ModelEvent> stream(
    ModelRequest request, {
    required String apiKey,
    ModelCancellation? cancellation,
  }) async* {
    expect(apiKey, _key);
    requests.add(request);
    beforeResponse?.call(requests.length);
    for (final event in responses[requests.length - 1]) {
      yield event;
    }
  }
}

class _HangingGateway implements ModelGateway {
  final started = Completer<void>();
  bool transportCancelled = false;
  @override
  Stream<ModelEvent> stream(
    ModelRequest request, {
    required String apiKey,
    ModelCancellation? cancellation,
  }) {
    final controller = StreamController<ModelEvent>();
    cancellation!.onCancel(() {
      transportCancelled = true;
    });
    started.complete();
    return controller.stream;
  }
}

void main() {
  late Directory directory;
  late File file;
  late AppDatabase db;
  late SqliteAgentRunStore runs;
  late SqliteAgentToolExecutor tools;
  late SqliteWorkspaceCommandStore workspace;
  Future<void> reopen() async {
    await db.close();
    db = AppDatabase.background(file);
    runs = SqliteAgentRunStore(db);
    tools = SqliteAgentToolExecutor(db);
    workspace = SqliteWorkspaceCommandStore(db);
  }

  Future<void> policy(AiWritePermission permission) async {
    final store = SqliteAppPreferencesStore(db);
    final old = await store.loadOrCreate();
    await store.update({
      'permission': permission.name,
    }, expectedVersion: old.version);
  }

  Future<AgentRun> proposal(
    List<JsonObject> calls, {
    String id = 'run1',
    String input = 'input1',
  }) async {
    final queued = await runs.create(_initial(id: id, input: input));
    final generating = await runs.save(
      queued.next(AgentRunStatus.generating, round: 1),
      expectedRevision: queued.revision,
    );
    return tools.propose(generating, _tools(calls));
  }

  Future<void> seed() => workspace
      .execute(
        WorkspaceCommand(
          operationId: 'seed',
          actions: [
            WorkspaceMutation(
              actionId: 'seed1',
              kind: WorkspaceEntityKind.todo,
              entityId: 'todo1',
              mutation: WorkspaceMutationKind.create,
              patch: {'title': '原任务'},
            ),
          ],
        ),
      )
      .then((_) {});
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('agent-run-test');
    file = File('${directory.path}/runs.sqlite');
    db = AppDatabase.background(file);
    runs = SqliteAgentRunStore(db);
    tools = SqliteAgentToolExecutor(db);
    workspace = SqliteWorkspaceCommandStore(db);
    await SqliteAppPreferencesStore(db).loadOrCreate();
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  AgentApproval choose(AgentRun run, List<String> ids, {bool reject = false}) =>
      AgentApproval(
        runRevision: run.revision,
        proposalId: run.proposal!['id']! as String,
        digest: run.proposal!['digest']! as String,
        selectedToolCallIds: ids,
        reject: reject,
      );

  test('request window omits old exchanges without rewriting durable history or receipts', () async {
    final initial = AgentRun(
      id: 'window-run',
      sessionId: 'window-session',
      inputId: 'window-input',
      profile: ModelProfile(model: 'fixture', product: ProviderKind.kimiCode),
      history: [
        {'role': 'system', 'content': 'App policy'},
        {'role': 'user', 'content': '旧内容' * 10000},
        {'role': 'assistant', 'content': '旧回答'},
        {'role': 'user', 'content': '创建待办'},
      ],
    );
    final budget =
        ContextWindow.estimateInput([
          initial.history.first,
          initial.history.last,
        ], tools.schemas) +
        4096 +
        5000;
    final gateway = _Gateway([
      [
        _tools([
          _call('todo_create', {'title': '窗口后的真实写入'}),
        ]),
      ],
      [_answer()],
    ]);
    final result = await AgentRunner(
      gateway: gateway,
      store: runs,
      tools: tools,
      contextWindow: ContextWindow(tokenBudget: budget),
    ).start(initial, apiKey: _key);
    expect(result.status, AgentRunStatus.succeeded);
    expect(result.requestOmittedTurns, 1);
    expect(result.history.take(initial.history.length), initial.history);
    expect(result.receipts, hasLength(1));
    expect(gateway.requests, hasLength(2));
    for (final request in gateway.requests) {
      expect(request.messages.where((m) => m['role'] == 'user'), hasLength(1));
      expect(request.messages, contains(equals(ContextWindow.notice)));
      expect(
        ContextWindow.estimateInput(request.messages, request.tools) +
            request.maxTokens,
        lessThanOrEqualTo(budget),
      );
    }
    expect(gateway.requests.last.messages.last['role'], 'tool');
    expect(result.usage.first['usage'], {'total_tokens': 19});
    expect((await workspace.load()).todos.single.data['title'], '窗口后的真实写入');
    final reopened = await runs.read(result.id);
    expect(reopened.contextOmittedTurns, 1);
    expect(reopened.estimatedInputTokens, result.estimatedInputTokens);
  });

  test('oversized current tool exchange stops further requests but preserves committed effects', () async {
    final initial = _initial();
    final budget =
        ContextWindow.estimateInput(initial.history, tools.schemas) +
        4096 +
        500;
    final gateway = _Gateway([
      [
        _tools([
          _call('todo_create', {'title': '已提交', 'note': '完整备注' * 1000}),
        ]),
      ],
    ]);
    final runner = AgentRunner(
      gateway: gateway,
      store: runs,
      tools: tools,
      contextWindow: ContextWindow(tokenBudget: budget),
    );
    final result = await runner.start(initial, apiKey: _key);
    expect(result.failureCode, 'model_contextBudget');
    expect(result.receipts, hasLength(1));
    expect(gateway.requests, hasLength(1));
    expect((await workspace.load()).todos.single.data['note'], '完整备注' * 1000);
    await expectLater(
      runner.retry(result.id, expectedRevision: result.revision, apiKey: _key),
      throwsA(
        isA<AgentFailure>().having(
          (e) => e.code,
          'code',
          AgentFailureCode.budget,
        ),
      ),
    );
    expect(gateway.requests, hasLength(1));
  });

  test('partial acceptance survives reopen, deduplicates exact decision and waits for remaining calls', () async {
    await policy(AiWritePermission.askAll);
    final gateway = _Gateway([
      [
        _tools([
          _call('todo_create', {'title': '第一项'}, id: 'a'),
          _call('todo_create', {'title': '第二项'}, id: 'b'),
        ]),
      ],
      [_answer()],
    ]);
    final runner = AgentRunner(gateway: gateway, store: runs, tools: tools);
    final waiting = await runner.start(_initial(), apiKey: _key);
    final partial = await runner.resume(
      waiting.id,
      apiKey: _key,
      approval: choose(waiting, ['a']),
    );
    expect(partial.status, AgentRunStatus.awaitingConfirmation);
    expect(gateway.requests, hasLength(1));
    expect((await workspace.load()).todos.single.data['title'], '第一项');
    expect((partial.proposal!['calls'] as List).single['tool_call_id'], 'b');
    expect(
      (await tools.execute(waiting, approval: choose(waiting, ['a']))).toJson(),
      partial.toJson(),
    );
    await expectLater(
      tools.execute(waiting, approval: choose(waiting, ['b'])),
      throwsA(isA<AgentFailure>()),
    );
    await reopen();
    final loaded = await runs.read(waiting.id);
    final done = await AgentRunner(
      gateway: gateway,
      store: runs,
      tools: tools,
    ).resume(loaded.id, apiKey: _key, approval: choose(loaded, ['b']));
    expect(done.status, AgentRunStatus.succeeded);
    expect(done.receipts, hasLength(2));
    expect((await workspace.load()).todos, hasLength(2));
    expect(
      gateway.requests.last.messages
          .where((m) => m['role'] == 'tool')
          .map((m) => m['tool_call_id']),
      ['a', 'b'],
    );
  });

  test('selected rejection is durable, unselected actions stay pending and no write occurs', () async {
    await policy(AiWritePermission.askAll);
    final waiting = await tools.execute(
      await proposal([
        _call('todo_create', {'title': '拒绝'}, id: 'a'),
        _call('todo_create', {'title': '保留'}, id: 'b'),
      ]),
    );
    final rejected = await tools.execute(
      waiting,
      approval: choose(waiting, ['a'], reject: true),
    );
    expect((await workspace.load()).todos, isEmpty);
    expect(rejected.receipts, isEmpty);
    expect(
      jsonDecode(rejected.history.last['content']! as String)['reason'],
      'user_rejected',
    );
    await policy(AiWritePermission.auto);
    expect((await tools.execute(rejected)).revision, rejected.revision);
    expect(
      (await tools.execute(
        waiting,
        approval: choose(waiting, ['a'], reject: true),
      )).revision,
      rejected.revision,
    );
    await tools.execute(rejected, approval: choose(rejected, ['b']));
    expect((await workspace.load()).todos.single.data['title'], '保留');
  });

  test(
    'smart mode executes creates and queries while deletion alone waits',
    () async {
      await seed();
      await policy(AiWritePermission.askOnChange);
      final waiting = await tools.execute(
        await proposal([
          _call('todo_create', {'title': '自动新增'}, id: 'a'),
          _call('todo_delete', {'id': 'todo1', 'expected_version': 1}, id: 'b'),
          _call('todo_list', {}, id: 'q'),
        ]),
      );
      expect(waiting.status, AgentRunStatus.awaitingConfirmation);
      expect((await workspace.load()).todos, hasLength(2));
      expect((waiting.proposal!['calls'] as List).single['tool_call_id'], 'b');
      expect(
        waiting.history
            .where((m) => m['role'] == 'tool')
            .map((m) => m['tool_call_id']),
        ['a', 'q'],
      );
    },
  );

  test(
    'empty, repeated and unknown selections are rejected without writes',
    () async {
      await policy(AiWritePermission.askAll);
      final waiting = await tools.execute(
        await proposal([
          _call('todo_create', {'title': '原子'}),
        ]),
      );
      for (final ids in [
        <String>[],
        ['missing'],
        ['call1', 'call1'],
      ]) {
        await expectLater(
          tools.execute(waiting, approval: choose(waiting, ids)),
          throwsA(isA<AgentFailure>()),
        );
      }
      expect((await workspace.load()).todos, isEmpty);
      expect((await runs.read(waiting.id)).revision, waiting.revision);
    },
  );

  test(
    'partial decision rolls back business and event if journal commit fails',
    () async {
      await policy(AiWritePermission.askAll);
      final waiting = await tools.execute(
        await proposal([
          _call('todo_create', {'title': '甲'}, id: 'a'),
          _call('todo_create', {'title': '乙'}, id: 'b'),
        ]),
      );
      await expectLater(
        SqliteAgentToolExecutor(
          db,
          beforeJournal: () => throw StateError('fault'),
        ).execute(waiting, approval: choose(waiting, ['a'])),
        throwsA(isA<AgentFailure>()),
      );
      expect((await workspace.load()).todos, isEmpty);
      expect((await runs.read(waiting.id)).toJson(), waiting.toJson());
      expect(await db.select(db.workspaceOperations).get(), isEmpty);
    },
  );

  test('refresh rebases intended fields only, preserves manual changes and invalidates old approvals', () async {
    await seed();
    await policy(AiWritePermission.askAll);
    final waiting = await tools.execute(
      await proposal([
        _call('todo_update', {
          'id': 'todo1',
          'expected_version': 1,
          'patch': {'title': '意图标题'},
        }),
      ]),
    );
    await workspace.execute(
      WorkspaceCommand(
        operationId: 'manual',
        actions: [
          WorkspaceMutation(
            actionId: 'manual',
            kind: WorkspaceEntityKind.todo,
            entityId: 'todo1',
            mutation: WorkspaceMutationKind.update,
            expectedVersion: 1,
            patch: {'note': '人工新备注'},
          ),
        ],
      ),
    );
    final refreshed = await tools.refreshProposal(
      waiting.id,
      expectedRevision: waiting.revision,
    );
    expect(refreshed.status, AgentRunStatus.awaitingConfirmation);
    expect((await workspace.load()).todos.single.data['title'], '原任务');
    final call = (refreshed.proposal!['calls'] as List).single;
    expect(call['before']['version'], 2);
    expect(call['after']['note'], '人工新备注');
    await expectLater(
      tools.execute(refreshed, approval: _approve(waiting)),
      throwsA(isA<AgentFailure>()),
    );
    await tools.execute(refreshed, approval: _approve(refreshed));
    final todo = (await workspace.load()).todos.single;
    expect(todo.data['title'], '意图标题');
    expect(todo.data['note'], '人工新备注');
    expect(todo.version, 3);
  });

  test('failed approval refreshes only remaining calls and preserves earlier receipts', () async {
    await seed();
    await policy(AiWritePermission.askAll);
    var waiting = await tools.execute(
      await proposal([
        _call('todo_create', {'title': '已接受'}, id: 'a'),
        _call('todo_update', {
          'id': 'todo1',
          'expected_version': 1,
          'patch': {'title': '剩余修改'},
        }, id: 'b'),
      ]),
    );
    waiting = await tools.execute(waiting, approval: choose(waiting, ['a']));
    await workspace.execute(
      WorkspaceCommand(
        operationId: 'manual',
        actions: [
          WorkspaceMutation(
            actionId: 'note',
            kind: WorkspaceEntityKind.todo,
            entityId: 'todo1',
            mutation: WorkspaceMutationKind.update,
            expectedVersion: 1,
            patch: {'note': '人工备注'},
          ),
        ],
      ),
    );
    final gateway = _Gateway([
      [_answer()],
    ]);
    final runner = AgentRunner(gateway: gateway, store: runs, tools: tools);
    final failed = await runner.resume(
      waiting.id,
      apiKey: _key,
      approval: _approve(waiting),
    );
    expect(failed.status, AgentRunStatus.failed);
    expect(failed.receipts, hasLength(1));
    final refreshed = await tools.refreshProposal(
      failed.id,
      expectedRevision: failed.revision,
    );
    expect((refreshed.proposal!['calls'] as List).single['tool_call_id'], 'b');
    final result = await runner.resume(
      refreshed.id,
      apiKey: _key,
      approval: _approve(refreshed),
    );
    expect(result.status, AgentRunStatus.succeeded);
    expect(result.receipts, hasLength(2));
    expect(
      (await workspace.load())
          .find(WorkspaceEntityKind.todo, 'todo1')!
          .data['note'],
      '人工备注',
    );
    await workspace.undoMany(result.receipts, operationId: 'undo-all');
    expect((await workspace.load()).todos.single.data['title'], '原任务');
    expect((await workspace.load()).todos.single.data['note'], '人工备注');
  });

  test('legacy mixed pending proposal resolves queries when only its write is rejected', () async {
    final planned = await proposal([
      _call('todo_create', {'title': '不新增'}, id: 'a'),
      _call('todo_list', {}, id: 'q'),
    ]);
    // Pre-partial-approval versions persisted the entire mixed batch as waiting.
    final waiting = await runs.save(
      planned.next(AgentRunStatus.awaitingConfirmation),
      expectedRevision: planned.revision,
    );
    final result = await tools.execute(
      waiting,
      approval: choose(waiting, ['a'], reject: true),
    );
    expect(result.status, AgentRunStatus.generating);
    expect(result.proposal, isNull);
    expect(result.receipts, isEmpty);
    final query = jsonDecode(result.history.last['content']! as String) as Map;
    expect(query['items'], isEmpty);
    expect(query.containsKey('reason'), isFalse);
  });

  test('real SQLite tool loop preserves protocol, receipts, usage and restart history', () async {
    final gateway = _Gateway([
      [
        _tools([
          _call('todo_create', {'title': '准备中文周会'}),
        ]),
      ],
      [const ModelTextDelta('完成'), _answer()],
    ]);
    final texts = <String>[];
    final runner = AgentRunner(gateway: gateway, store: runs, tools: tools);
    final result = await runner.start(
      _initial(),
      apiKey: _key,
      onText: texts.add,
    );
    expect(result.status, AgentRunStatus.succeeded);
    expect(result.round, 2);
    expect(texts, ['完成']);
    expect(result.receipts, hasLength(1));
    final task = (await workspace.load()).todos.single;
    expect(task.data['title'], '准备中文周会');
    expect(task.data['source_message_id'], 'input1');
    final requestHistory = gateway.requests.last.messages;
    expect(requestHistory[1]['reasoning_content'], 'internal reasoning');
    expect(requestHistory[2]['tool_call_id'], 'call1');
    expect(
      jsonDecode(requestHistory[2]['content']! as String)['entity']['id'],
      task.id,
    );
    expect(result.usage.last['usage'], isNull);
    expect(jsonEncode(result.toJson()), isNot(contains(_key)));
    await reopen();
    expect((await runs.read('run1')).toJson(), result.toJson());
    final events = await db
        .customSelect('SELECT sequence FROM agent_run_events ORDER BY sequence')
        .get();
    expect(
      events.map((e) => e.read<int>('sequence')),
      List.generate(result.revision, (i) => i + 1),
    );
    final duplicate = await AgentRunner(
      gateway: gateway,
      store: runs,
      tools: tools,
    ).start(_initial(id: 'another-id'), apiKey: _key);
    expect(duplicate.id, 'run1');
    expect(gateway.requests, hasLength(2));
    expect((await workspace.load()).todos, hasLength(1));
    await expectLater(
      runs.create(_initial(text: 'changed')),
      throwsA(isA<AgentFailure>()),
    );
  });

  for (final permission in AiWritePermission.values) {
    for (final name in [
      'todo_list',
      'todo_create',
      'todo_update',
      'todo_complete',
      'todo_delete',
    ]) {
      test(
        '${permission.name} × $name uses current persisted permission',
        () async {
          await policy(permission);
          await seed();
          final args = switch (name) {
            'todo_list' => <String, Object?>{},
            'todo_create' => <String, Object?>{'title': '新任务'},
            'todo_update' => <String, Object?>{
              'id': 'todo1',
              'expected_version': 1,
              'patch': {'title': '新标题'},
            },
            _ => <String, Object?>{'id': 'todo1', 'expected_version': 1},
          };
          final planned = await proposal([_call(name, args)]);
          final requiresApproval =
              name != 'todo_list' &&
              (permission == AiWritePermission.askAll ||
                  permission == AiWritePermission.askOnChange &&
                      name == 'todo_delete');
          var result = await tools.execute(planned);
          expect(
            result.status,
            requiresApproval
                ? AgentRunStatus.awaitingConfirmation
                : AgentRunStatus.generating,
          );
          if (requiresApproval) {
            expect((await workspace.load()).todos.single.version, 1);
            result = await tools.execute(result, approval: _approve(result));
          }
          expect(result.status, AgentRunStatus.generating);
          expect(
            (await SqliteAppPreferencesStore(db).loadOrCreate()).permission,
            permission,
          );
          final todos = (await workspace.load()).todos.toList();
          switch (name) {
            case 'todo_list':
              expect(todos.single.version, 1);
            case 'todo_create':
              expect(todos, hasLength(2));
            case 'todo_update':
              expect(todos.single.data['title'], '新标题');
            case 'todo_complete':
              expect(todos.single.data['status'], 'done');
            case 'todo_delete':
              expect(todos, isEmpty);
          }
        },
      );
    }
  }

  test('permission tightening after proposal forces confirmation; approval survives reopening', () async {
    final planned = await proposal([
      _call('todo_create', {'title': '需要确认'}),
    ]);
    await policy(AiWritePermission.askAll);
    final waiting = await tools.execute(planned);
    expect(waiting.status, AgentRunStatus.awaitingConfirmation);
    await reopen();
    final loaded = await runs.read(waiting.id);
    await expectLater(
      tools.execute(
        loaded,
        approval: AgentApproval(
          runRevision: loaded.revision,
          proposalId: loaded.proposal!['id']! as String,
          digest: 'wrong',
        ),
      ),
      throwsA(isA<AgentFailure>()),
    );
    expect((await workspace.load()).todos, isEmpty);
    final committed = await tools.execute(loaded, approval: _approve(loaded));
    final repeated = await tools.execute(loaded, approval: _approve(loaded));
    expect(repeated.toJson(), committed.toJson());
    expect((await workspace.load()).todos, hasLength(1));
  });

  test('conflicting member rejects entire approved batch without creating another todo', () async {
    await seed();
    await policy(AiWritePermission.askAll);
    final planned = await proposal([
      _call('todo_create', {'title': '不得部分创建'}),
      _call('todo_update', {
        'id': 'todo1',
        'expected_version': 1,
        'patch': {'title': '过期覆盖'},
      }, id: 'call2'),
    ]);
    final waiting = await tools.execute(planned);
    await workspace.execute(
      WorkspaceCommand(
        operationId: 'manual-edit',
        actions: [
          WorkspaceMutation(
            actionId: 'edit1',
            kind: WorkspaceEntityKind.todo,
            entityId: 'todo1',
            mutation: WorkspaceMutationKind.update,
            expectedVersion: 1,
            patch: {'title': '较新编辑'},
          ),
        ],
      ),
    );
    await expectLater(
      tools.execute(waiting, approval: _approve(waiting)),
      throwsA(isA<WorkspaceFailure>()),
    );
    final task = (await workspace.load()).todos.single;
    expect(task.data['title'], '较新编辑');
    expect((await runs.read(waiting.id)).revision, waiting.revision);
  });

  test('failure after business write rolls back business, audit, messages and events', () async {
    final planned = await proposal([
      _call('todo_create', {'title': '原子提交'}),
    ]);
    final failing = SqliteAgentToolExecutor(
      db,
      beforeJournal: () => throw StateError('injected'),
    );
    await expectLater(
      failing.execute(planned),
      throwsA(
        isA<AgentFailure>().having(
          (e) => e.code,
          'code',
          AgentFailureCode.storage,
        ),
      ),
    );
    expect((await workspace.load()).todos, isEmpty);
    expect(await db.select(db.workspaceOperations).get(), isEmpty);
    expect((await runs.read(planned.id)).revision, planned.revision);
    expect(
      await db.select(db.agentRunEvents).get(),
      hasLength(planned.revision),
    );
    await reopen();
    final committed = await tools.execute(await runs.read(planned.id));
    expect(committed.receipts, hasLength(1));
    expect((await workspace.load()).todos, hasLength(1));
  });

  test(
    'restart after commit resumes with receipts rather than replaying writes',
    () async {
      final planned = await proposal([
        _call('todo_create', {'title': '已提交任务'}),
      ]);
      final committed = await tools.execute(planned);
      await reopen();
      expect(await runs.interruptAbandonedGenerations(), 1);
      final gateway = _Gateway([
        [_answer('根据已保存回执完成')],
      ]);
      final result = await AgentRunner(
        gateway: gateway,
        store: runs,
        tools: tools,
      ).resume(committed.id, apiKey: _key);
      expect(result.status, AgentRunStatus.succeeded);
      expect(result.receipts, committed.receipts);
      expect(gateway.requests.single.messages.last['role'], 'tool');
      expect((await workspace.load()).todos, hasLength(1));
      expect(await db.select(db.workspaceOperations).get(), hasLength(1));
    },
  );

  test(
    'unrecognized or malformed member prevents every write in the model batch',
    () async {
      for (final bad in [
        _call('shell', {'command': 'anything'}, id: 'call2'),
        _call('todo_create', {
          'title': 'bad',
          'permission': 'auto',
        }, id: 'call2'),
        _call('todo_create', {'title': 'bad'}, id: 'call1'),
        {
          'id': 'call2',
          'type': 'function',
          'function': {'name': 'todo_create', 'arguments': '{partial'},
        },
      ]) {
        final id = 'bad${DateTime.now().microsecondsSinceEpoch}';
        final gateway = _Gateway([
          [
            _tools([
              _call('todo_create', {'title': '不能部分执行'}),
              bad,
            ]),
          ],
        ]);
        final result =
            await AgentRunner(
              gateway: gateway,
              store: runs,
              tools: tools,
            ).start(
              _initial(id: id, input: id),
              apiKey: _key,
            );
        expect(result.status, AgentRunStatus.failed);
        expect(result.usage.single['usage'], {'total_tokens': 19});
        expect((await workspace.load()).todos, isEmpty);
      }
    },
  );

  test('truncated stream and completion followed by more events cannot execute tools', () async {
    var index = 0;
    for (final events in <List<ModelEvent>>[
      [const ModelTextDelta('已经创建')],
      [
        _tools([
          _call('todo_create', {'title': '不完整'}),
        ]),
        const ModelTextDelta('unexpected'),
      ],
      [
        ModelCompleted(
          assistantMessage: {'role': 'assistant', 'content': 'truncated'},
          finishReason: 'length',
        ),
      ],
    ]) {
      final id = 'truncated${index++}';
      final result =
          await AgentRunner(
            gateway: _Gateway([events]),
            store: runs,
            tools: tools,
          ).start(
            _initial(id: id, input: id),
            apiKey: _key,
          );
      expect(result.status, AgentRunStatus.failed);
      expect((await workspace.load()).todos, isEmpty);
    }
  });

  test(
    'cancellation before first frame closes transport and records cancelled',
    () async {
      final gateway = _HangingGateway();
      final cancellation = ModelCancellation();
      final pending = AgentRunner(
        gateway: gateway,
        store: runs,
        tools: tools,
      ).start(_initial(), apiKey: _key, cancellation: cancellation);
      await gateway.started.future;
      cancellation.cancel();
      final run = await pending;
      expect(run.status, AgentRunStatus.cancelled);
      expect(gateway.transportCancelled, isTrue);
      expect(run.receipts, isEmpty);
    },
  );

  test(
    'deadline closes transport and records timeout, not user cancellation',
    () async {
      final gateway = _HangingGateway();
      final result = await AgentRunner(
        gateway: gateway,
        store: runs,
        tools: tools,
        activeTimeout: const Duration(milliseconds: 80),
      ).start(_initial(), apiKey: _key);
      expect(result.status, AgentRunStatus.failed);
      expect(result.failureCode, 'model_timeout');
      expect(gateway.transportCancelled, isTrue);
    },
  );

  test(
    'cancelling after a commit preserves real effects and receipt',
    () async {
      final cancellation = ModelCancellation();
      final gateway =
          _Gateway([
              [
                _tools([
                  _call('todo_create', {'title': '不能冒充回滚'}),
                ]),
              ],
              [_answer()],
            ])
            ..beforeResponse = (round) {
              if (round == 2) cancellation.cancel();
            };
      final result = await AgentRunner(
        gateway: gateway,
        store: runs,
        tools: tools,
      ).start(_initial(), apiKey: _key, cancellation: cancellation);
      expect(result.status, AgentRunStatus.cancelled);
      expect(result.receipts, hasLength(1));
      expect((await workspace.load()).todos, hasLength(1));
    },
  );

  test(
    'round limit stops loops with accurate already committed receipts',
    () async {
      final gateway = _Gateway([
        [
          _tools([
            _call('todo_create', {'title': '一次'}),
          ]),
        ],
      ]);
      final result = await AgentRunner(
        gateway: gateway,
        store: runs,
        tools: tools,
        maxRounds: 1,
      ).start(_initial(), apiKey: _key);
      expect(result.status, AgentRunStatus.failed);
      expect(result.failureCode, 'model_budget');
      expect(result.receipts, hasLength(1));
      expect(gateway.requests, hasLength(1));
    },
  );

  test(
    'cancel waiting proposal cannot later be approved or executed',
    () async {
      await policy(AiWritePermission.askAll);
      final waiting = await tools.execute(
        await proposal([
          _call('todo_create', {'title': '取消'}),
        ]),
      );
      final runner = AgentRunner(
        gateway: _Gateway([]),
        store: runs,
        tools: tools,
      );
      await runner.cancelWaiting(waiting.id);
      await expectLater(
        tools.execute(waiting, approval: _approve(waiting)),
        throwsA(isA<AgentFailure>()),
      );
      expect((await workspace.load()).todos, isEmpty);
    },
  );

  test(
    'same revision and recomputed hash cannot replace the persisted preview',
    () async {
      await policy(AiWritePermission.askAll);
      final waiting = await tools.execute(
        await proposal([
          _call('todo_create', {'title': '用户看到的内容'}),
        ]),
      );
      final json = jsonDecode(jsonEncode(waiting.toJson())) as JsonObject;
      final forged = json['proposal'] as JsonObject;
      final call = (forged['calls'] as List).single as JsonObject;
      (call['after'] as JsonObject)['title'] = '未展示的修改';
      ((call['mutation'] as JsonObject)['patch'] as JsonObject)['title'] =
          '未展示的修改';
      forged.remove('digest');
      forged['digest'] = TodoAgentTools.digest(forged);
      final altered = AgentRun.fromJson(json);
      await expectLater(
        tools.execute(altered, approval: _approve(altered)),
        throwsA(isA<AgentFailure>()),
      );
      expect((await workspace.load()).todos, isEmpty);
      expect((await runs.read(waiting.id)).toJson(), waiting.toJson());
      await tools.execute(waiting, approval: _approve(waiting));
      // A forged retry must not acknowledge different arguments after commit.
      await expectLater(
        tools.execute(altered, approval: _approve(altered)),
        throwsA(isA<AgentFailure>()),
      );
    },
  );

  test(
    'two database connections cannot commit the same approved batch twice',
    () async {
      await policy(AiWritePermission.askAll);
      final waiting = await tools.execute(
        await proposal([
          _call('todo_create', {'title': '并发确认'}),
        ]),
      );
      final other = AppDatabase.background(file);
      try {
        await SqliteAgentRunStore(other).read(waiting.id);
        final outcomes = await Future.wait([
          tools
              .execute(waiting, approval: _approve(waiting))
              .then<Object>((value) => value, onError: (Object e) => e),
          SqliteAgentToolExecutor(other)
              .execute(waiting, approval: _approve(waiting))
              .then<Object>((value) => value, onError: (Object e) => e),
        ]);
        expect(outcomes.whereType<AgentRun>(), isNotEmpty);
        for (final outcome in outcomes) {
          expect(outcome is AgentRun || outcome is AgentFailure, isTrue);
        }
        expect((await workspace.load()).todos, hasLength(1));
        expect(await db.select(db.workspaceOperations).get(), hasLength(1));
        final committed = await SqliteAgentToolExecutor(other)
            .execute(waiting, approval: _approve(waiting));
        expect(committed.receipts, hasLength(1));
      } finally {
        await other.close();
      }
    },
  );

  test('queries paginate exact IDs and return bounded note previews', () async {
    await workspace.execute(
      WorkspaceCommand(
        operationId: 'many',
        actions: [
          for (var i = 1; i <= 3; i++)
            WorkspaceMutation(
              actionId: 'a$i',
              kind: WorkspaceEntityKind.todo,
              entityId: 't$i',
              mutation: WorkspaceMutationKind.create,
              patch: {'title': '周会 $i', 'note': List.filled(3000, '中').join()},
            ),
        ],
      ),
    );
    final first = await tools.execute(
      await proposal([
        _call('todo_list', {'query': '周会', 'limit': 2}),
      ]),
    );
    final page = jsonDecode(first.history.last['content']! as String) as Map;
    expect((page['items'] as List).map((e) => e['id']), ['t1', 't2']);
    expect(page['next_cursor'], 't2');
    expect(
      ((page['items'] as List).first['note_preview'] as String).runes.length,
      2000,
    );
    final second = await tools.execute(
      await proposal(
        [
          _call('todo_list', {'after_id': 't2', 'limit': 2}),
        ],
        id: 'run2',
        input: 'input2',
      ),
    );
    final end = jsonDecode(second.history.last['content']! as String) as Map;
    expect((end['items'] as List).single['id'], 't3');
    expect(end['next_cursor'], isNull);
    expect(first.receipts, isEmpty);
    expect(second.receipts, isEmpty);
  });

  test('cancel inside the commit window rolls back writes and records cancellation', () async {
    final signal = ModelCancellation();
    final gateway = _Gateway([
      [
        _tools([
          _call('todo_create', {'title': '事务中停止'}),
        ]),
      ],
    ]);
    final result = await AgentRunner(
      gateway: gateway,
      store: runs,
      tools: SqliteAgentToolExecutor(db, beforeJournal: signal.cancel),
    ).start(_initial(), apiKey: _key, cancellation: signal);
    expect(result.status, AgentRunStatus.cancelled);
    expect(result.receipts, isEmpty);
    expect((await workspace.load()).todos, isEmpty);
    expect(await db.select(db.workspaceOperations).get(), isEmpty);
  });

  test('v4 upgrade preserves prior preferences; malformed journal migration rolls back', () async {
    await db.close();
    await file.delete();
    var raw = sqlite.sqlite3.open(file.path);
    raw.execute(File('test/fixtures/local/schema_v4.sql').readAsStringSync());
    raw.execute('INSERT INTO app_preference_rows VALUES (1, 1, ?)', [
      jsonEncode({
        'theme': 'system',
        'input_mode': 'voice',
        'permission': 'askOnChange',
        'memory_paused': false,
        'notify_due': true,
        'notify_morning': true,
        'morning_hour': 8,
        'morning_minute': 30,
        'notify_report': true,
      }),
    ]);
    raw.execute('CREATE TABLE agent_run_events (wrong TEXT)');
    raw.close();
    db = AppDatabase.background(file);
    await expectLater(db.customSelect('SELECT 1').get(), throwsA(anything));
    await db.close();
    raw = sqlite.sqlite3.open(file.path);
    expect(raw.select('PRAGMA user_version').single['user_version'], 4);
    expect(
      raw.select("SELECT name FROM sqlite_master WHERE name='agent_run_rows'"),
      isEmpty,
    );
    expect(
      raw.select('SELECT payload FROM app_preference_rows').single['payload'],
      contains('askOnChange'),
    );
    raw.execute('DROP TABLE agent_run_events');
    raw.close();
    db = AppDatabase.background(file);
    expect(
      (await SqliteAppPreferencesStore(db).loadOrCreate()).permission,
      AiWritePermission.askOnChange,
    );
    expect(await db.select(db.agentRunEvents).get(), isEmpty);
    expect(
      (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
        'user_version',
      ),
      13,
    );
  });
}
