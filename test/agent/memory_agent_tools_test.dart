import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/agent/agent_runner.dart';
import 'package:towork/agent/memory_agent_tools.dart';
import 'package:towork/data/local/agent_run_store.dart';
import 'package:towork/data/local/agent_tool_executor.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/memory_persistence.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/repositories/memory_persistence.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';

import '../support/free/scripted_business_model.dart';

void main() {
  late Directory dir;
  late AppDatabase db;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('towork-memory-tool-');
    db = AppDatabase.background(File('${dir.path}/db.sqlite'));
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  // The remember tool validates that its chat-turn source still exists.
  Future<void> seedTurn(String inputId, {String content = '请记住我的偏好'}) async {
    await db
        .into(db.chatConversations)
        .insert(
          ChatConversationsCompanion.insert(
            id: 'conv_$inputId',
            title: '会话',
            revision: 1,
            createdAt: 0,
            updatedAt: 0,
          ),
        );
    await db
        .into(db.chatTurns)
        .insert(
          ChatTurnsCompanion.insert(
            inputId: inputId,
            sessionId: 'conv_$inputId',
            runId: 'run_$inputId',
            content: content,
            position: 0,
            historyStart: 0,
            createdAt: 0,
            agentEnabled: true,
          ),
        );
  }

  (AgentRunner, _ScriptedGateway) buildRunner(
    List<ModelEvent> script,
    List<String> toolResults,
  ) {
    final gateway = _ScriptedGateway(script, toolResults);
    return (
      AgentRunner(
        gateway: gateway,
        store: SqliteAgentRunStore(db),
        tools: SqliteAgentToolExecutor(db),
        maxRounds: 3,
        maxTokens: 2048,
      ),
      gateway,
    );
  }

  Future<AgentRun> start(
    AgentRunner runner,
    String inputId, {
    String content = '请记住这些信息',
  }) => runner.start(
    AgentRun(
      id: 'run_$inputId',
      sessionId: 'conv_$inputId',
      inputId: inputId,
      profile: _profile,
      history: [
        {'role': 'user', 'content': content},
      ],
    ),
    apiKey: 'synthetic-memory',
  );

  test(
    'explicit remember persists with chat provenance and reports to model',
    () async {
      await seedTurn('input_ok');
      final results = <String>[];
      final (runner, _) = buildRunner([
        businessCalls([
          {
            'id': 'm1',
            'type': 'function',
            'function': {
              'name': 'memory_create',
              'arguments': jsonEncode({
                'content': '用户偏好拿铁，不加糖',
                'kind': 'preference',
              }),
            },
          },
        ]),
        ModelCompleted(
          assistantMessage: {'role': 'assistant', 'content': '已记住。'},
          finishReason: 'stop',
        ),
      ], results);
      final run = await start(runner, 'input_ok');
      expect(run.status, AgentRunStatus.succeeded);
      expect(run.receipts, isEmpty);

      final memories = await SqliteMemoryPersistence(db).list();
      expect(memories, hasLength(1));
      expect(memories.single.content, '用户偏好拿铁，不加糖');
      expect(memories.single.kindId, 'preference');
      expect(memories.single.source, MemoryPersistSource.ai);
      expect(memories.single.sourceMessageId, 'input_ok');

      final result = jsonDecode(results.single) as Map;
      expect(result['memory_id'], memories.single.id);
      expect(result['epoch'], 0);
    },
  );

  test(
    'paused memory refuses with a readable result and nothing written',
    () async {
      await seedTurn('input_paused');
      final persistence = SqliteMemoryPersistence(db);
      await persistence.setPaused(true);
      final results = <String>[];
      final (runner, _) = buildRunner([
        businessCalls([
          {
            'id': 'm1',
            'type': 'function',
            'function': {
              'name': 'memory_create',
              'arguments': jsonEncode({'content': '不该被记住'}),
            },
          },
        ]),
        ModelCompleted(
          assistantMessage: {'role': 'assistant', 'content': '记忆功能已暂停。'},
          finishReason: 'stop',
        ),
      ], results);
      final run = await start(runner, 'input_paused');
      expect(run.status, AgentRunStatus.succeeded);
      expect(await persistence.list(), isEmpty);
      expect(jsonDecode(results.single), {'error': 'memory_paused'});
    },
  );

  test('invalid content returns invalid_content and commits nothing', () async {
    await seedTurn('input_bad');
    final results = <String>[];
    final (runner, _) = buildRunner([
      businessCalls([
        {
          'id': 'm1',
          'type': 'function',
          'function': {
            'name': 'memory_create',
            'arguments': jsonEncode({'content': '   '}),
          },
        },
      ]),
      ModelCompleted(
        assistantMessage: {'role': 'assistant', 'content': '内容无效。'},
        finishReason: 'stop',
      ),
    ], results);
    final run = await start(runner, 'input_bad');
    expect(run.status, AgentRunStatus.succeeded);
    expect(await SqliteMemoryPersistence(db).list(), isEmpty);
    expect(jsonDecode(results.single), {'error': 'invalid_content'});
  });

  test('missing chat-turn source rejects with a readable result', () async {
    // No seedTurn: the executor's run references an input that never existed.
    final results = <String>[];
    final (runner, _) = buildRunner([
      businessCalls([
        {
          'id': 'm1',
          'type': 'function',
          'function': {
            'name': 'memory_create',
            'arguments': jsonEncode({'content': '孤儿来源'}),
          },
        },
      ]),
      ModelCompleted(
        assistantMessage: {'role': 'assistant', 'content': '未记住。'},
        finishReason: 'stop',
      ),
    ], results);
    final run = await start(runner, 'input_ghost');
    expect(run.status, AgentRunStatus.succeeded);
    expect(jsonDecode(results.single), {'error': 'invalid_content'});
  });

  JsonObject call(String id, String name, JsonObject args) => {
    'id': id,
    'type': 'function',
    'function': {'name': name, 'arguments': jsonEncode(args)},
  };
  final done = ModelCompleted(
    assistantMessage: {'role': 'assistant', 'content': '好的。'},
    finishReason: 'stop',
  );

  test(
    'ordinary preference can be searched then remembered without a command',
    () async {
      const text = '我每周的工作报告都按项目分组。';
      await seedTurn('weekly_format', content: text);
      final results = <String>[];
      final (runner, _) = buildRunner([
        businessCalls([
          call('lookup', 'memory_search', {'query': '工作报告'}),
        ]),
        businessCalls([
          call('save', 'memory_create', {
            'content': text,
            'kind': 'preference',
          }),
        ]),
        done,
      ], results);
      final run = await start(runner, 'weekly_format', content: text);
      expect(run.status, AgentRunStatus.succeeded);
      final item = (await SqliteMemoryPersistence(db).list()).single;
      expect(item.content, text);
      expect(item.sourceMessageId, 'weekly_format');
    },
  );

  test('search ranks by matched terms, hides expired, and lists recent for an empty query', () async {
    await seedTurn('input_search');
    final persistence = SqliteMemoryPersistence(db);
    await persistence.remember(content: '用户喜欢喝茶', kindId: 'preference');
    final best = await persistence.remember(
      content: '用户喝咖啡只要拿铁，不加糖',
      kindId: 'preference',
    );
    await persistence.remember(
      content: '上个月的拿铁优惠券',
      kindId: 'fact',
      expiresAt: DateTime.now().toUtc().subtract(const Duration(days: 1)),
    );
    final results = <String>[];
    final (runner, _) = buildRunner([
      businessCalls([
        call('s1', 'memory_search', {'query': '拿铁咖啡'}),
        call('s2', 'memory_search', {}),
        call('s3', 'memory_search', {'query': '高铁票'}),
      ]),
      done,
    ], results);
    final run = await start(runner, 'input_search');
    expect(run.status, AgentRunStatus.succeeded);
    final decoded = results.map((r) => jsonDecode(r) as Map).toList();
    final keyword = decoded[0]['items'] as List;
    expect(decoded[0]['match'], 'keyword');
    expect(keyword, hasLength(1));
    expect(keyword.single['id'], best.memoryId);
    expect(keyword.single['version'], 1);
    expect(keyword.single['kind'], 'preference');
    expect(keyword.single['content'], '用户喝咖啡只要拿铁，不加糖');
    // 空查询列出最近的记忆，同样不含已过期的。
    expect(decoded[1]['match'], 'recent');
    expect((decoded[1]['items'] as List).map((m) => m['content']), [
      '用户喝咖啡只要拿铁，不加糖',
      '用户喜欢喝茶',
    ]);
    expect(decoded[2]['items'], isEmpty);
  });

  test('update replaces content in place and bumps the version', () async {
    await seedTurn('input_update');
    final persistence = SqliteMemoryPersistence(db);
    final original = await persistence.remember(
      content: '用户在上海工作',
      kindId: 'fact',
    );
    final results = <String>[];
    final (runner, _) = buildRunner([
      businessCalls([
        call('u1', 'memory_update', {
          'id': original.memoryId,
          'expected_version': 1,
          'content': '用户搬到深圳工作了',
        }),
      ]),
      done,
    ], results);
    final run = await start(runner, 'input_update');
    expect(run.status, AgentRunStatus.succeeded);
    final memories = await persistence.list();
    expect(memories.single.id, original.memoryId);
    expect(memories.single.content, '用户搬到深圳工作了');
    expect(memories.single.kindId, 'fact');
    expect(memories.single.version, 2);
    expect(jsonDecode(results.single), {
      'memory_id': original.memoryId,
      'version': 2,
      'epoch': 0,
    });
  });

  test(
    'stale version, missing target and paused memory return readable results',
    () async {
      await seedTurn('input_stale');
      final persistence = SqliteMemoryPersistence(db);
      final original = await persistence.remember(
        content: '用户早上八点起床',
        kindId: 'event',
      );
      final results = <String>[];
      final (runner, _) = buildRunner([
        businessCalls([
          call('u1', 'memory_update', {
            'id': original.memoryId,
            'expected_version': 7,
            'content': '用户早上七点起床',
          }),
          call('u2', 'memory_update', {
            'id': 'mem_missing',
            'expected_version': 1,
            'content': '不存在的记忆',
          }),
        ]),
        done,
      ], results);
      final run = await start(runner, 'input_stale');
      expect(run.status, AgentRunStatus.succeeded);
      expect(
        (jsonDecode(results[0]) as Map)['error'],
        'memory_version_changed',
      );
      expect(jsonDecode(results[1]), {'error': 'memory_not_found'});
      expect((await persistence.list()).single.content, '用户早上八点起床');

      await seedTurn('input_paused_update');
      await persistence.setPaused(true);
      final pausedResults = <String>[];
      final (pausedRunner, _) = buildRunner([
        businessCalls([
          call('u3', 'memory_update', {
            'id': original.memoryId,
            'expected_version': 1,
            'content': '暂停时不能改',
          }),
        ]),
        done,
      ], pausedResults);
      await start(pausedRunner, 'input_paused_update');
      expect(jsonDecode(pausedResults.single), {'error': 'memory_paused'});
      expect((await persistence.list()).single.content, '用户早上八点起床');
    },
  );

  test('malformed memory calls are rejected before anything runs', () {
    for (final (name, args) in <(String, JsonObject)>[
      ('memory_search', {'query': 12}),
      ('memory_search', {'query': 'x', 'limit': 0}),
      ('memory_search', {'query': 'x', 'limit': 21}),
      ('memory_search', {'query': 'x' * 201}),
      ('memory_search', {'query': 'x', 'scope': 'all'}),
      ('memory_update', {'id': 'm1', 'expected_version': 1}),
      ('memory_update', {'id': 'm1', 'content': '缺版本号'}),
      (
        'memory_update',
        {'id': 'bad id', 'expected_version': 1, 'content': 'x'},
      ),
      ('memory_update', {'id': 'm1', 'expected_version': 0, 'content': 'x'}),
      ('memory_update', {'id': 'm1', 'expected_version': 1, 'kind': 'secret'}),
      ('memory_delete', {'id': 'm1'}),
    ]) {
      expect(
        () => MemoryAgentTools.validateCall(name, args),
        throwsA(isA<WorkspaceFailure>()),
        reason: '$name $args',
      );
    }
    MemoryAgentTools.validateCall('memory_search', {});
    MemoryAgentTools.validateCall('memory_search', {
      'query': '拿铁',
      'limit': 20,
    });
    MemoryAgentTools.validateCall('memory_update', {
      'id': 'm1',
      'expected_version': 3,
      'kind': 'preference',
    });
    expect(MemoryAgentTools.names, {
      'memory_create',
      'memory_search',
      'memory_update',
    });
  });
}

final _profile = ModelProfile(
  model: 'memory-fixture',
  product: ProviderKind.kimiCode,
  revision: 1,
);

class _ScriptedGateway implements ModelGateway {
  _ScriptedGateway(this._script, this.results);
  final List<ModelEvent> _script;
  final List<String> results;
  var _step = 0;

  @override
  Stream<ModelEvent> stream(
    ModelRequest request, {
    required String apiKey,
    ModelCancellation? cancellation,
  }) async* {
    // 本轮新到的全部工具结果：最后一条助手消息之后的 tool 消息。
    final messages = request.messages;
    final from = messages.lastIndexWhere((m) => m['role'] == 'assistant') + 1;
    for (final message in messages.skip(from)) {
      if (message['tool_call_id'] is String) {
        results.add(message['content']! as String);
      }
    }
    yield _script[_step++];
  }
}
