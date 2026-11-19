import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/agent/agent_reminders.dart';
import 'package:towork/agent/agent_runner.dart';
import 'package:towork/agent/todo_agent_tools.dart';
import 'package:towork/data/local/agent_run_store.dart';
import 'package:towork/data/local/agent_tool_executor.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/app_preferences_store.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/ai/permission_policy.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';

const _key = 'synthetic-test-credential';
final _now = DateTime.utc(2026, 11, 14, 6, 30);

JsonObject _call(String id, String name, Object? args) => {
  'id': id,
  'type': 'function',
  'function': {
    'name': name,
    'arguments': args is String ? args : jsonEncode(args),
  },
};
ModelCompleted _tools(List<JsonObject> calls) => ModelCompleted(
  assistantMessage: {'role': 'assistant', 'content': null, 'tool_calls': calls},
  finishReason: 'tool_calls',
  usage: {'total_tokens': 7},
);
ModelCompleted _answer([String content = '好了']) => ModelCompleted(
  assistantMessage: {'role': 'assistant', 'content': content},
  finishReason: 'stop',
);
AgentRun _initial({String id = 'run1', JsonObject? user}) => AgentRun(
  id: id,
  sessionId: 'session1',
  inputId: 'input_$id',
  profile: ModelProfile(model: 'fixture', product: ProviderKind.kimiCode),
  history: [
    user ?? {'role': 'user', 'content': '帮我处理一下'},
  ],
);

class _Gateway implements ModelGateway {
  _Gateway(this.responses);
  final List<ModelEvent> responses;
  final requests = <ModelRequest>[];

  /// 每一轮请求里新出现的工具结果，按 tool_call_id 解码。
  Map<String, JsonObject> results(int request) => {
    for (final message in requests[request].messages)
      if (message['role'] == 'tool')
        message['tool_call_id']! as String: (jsonDecode(
          message['content']! as String,
        ) as Map).cast<String, Object?>(),
  };

  @override
  Stream<ModelEvent> stream(
    ModelRequest request, {
    required String apiKey,
    ModelCancellation? cancellation,
  }) async* {
    requests.add(request);
    yield responses[requests.length - 1];
  }
}

void main() {
  late Directory directory;
  late AppDatabase db;
  late SqliteAgentRunStore runs;
  late SqliteAgentToolExecutor tools;
  late SqliteWorkspaceCommandStore workspace;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('agent-capability');
    db = AppDatabase.background(File('${directory.path}/db.sqlite'));
    runs = SqliteAgentRunStore(db);
    tools = SqliteAgentToolExecutor(db, clock: () => _now);
    workspace = SqliteWorkspaceCommandStore(db, clock: () => _now);
    final preferences = SqliteAppPreferencesStore(db);
    final current = await preferences.loadOrCreate();
    await preferences.update({
      'permission': AiWritePermission.auto.name,
    }, expectedVersion: current.version);
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  Future<void> seed(WorkspaceEntityKind kind, String id, JsonObject patch) =>
      workspace
          .execute(
            WorkspaceCommand(
              operationId: 'seed_$id',
              actions: [
                WorkspaceMutation(
                  actionId: 'seed_action_$id',
                  kind: kind,
                  entityId: id,
                  mutation: WorkspaceMutationKind.create,
                  patch: patch,
                ),
              ],
            ),
          )
          .then((_) {});
  Future<void> todo(String id, JsonObject patch) =>
      seed(WorkspaceEntityKind.todo, id, {'title': id, ...patch});

  Future<(AgentRun, _Gateway)> run(
    List<ModelEvent> script, {
    int maxCorrections = 2,
    AgentRun? initial,
  }) async {
    final gateway = _Gateway(script);
    final result = await AgentRunner(
      gateway: gateway,
      store: runs,
      tools: tools,
      maxCorrections: maxCorrections,
    ).start(initial ?? _initial(), apiKey: _key);
    return (result, gateway);
  }

  group('时间与提醒', () {
    test('本地时刻 + 提醒：库里是 UTC 与真正会响的提醒规则', () async {
      final (result, gateway) = await run([
        _tools([
          _call('c1', 'todo_create', {
            'title': '交周报',
            'due_at': '2026-11-15T15:00:00+08:00',
            'reminders': [
              {'minutes_before': 0},
              {'minutes_before': 30},
              {'minutes_before': 30},
              {'at': '2026-11-15T09:00:00+08:00'},
            ],
          }),
        ]),
        _answer(),
      ]);
      expect(result.status, AgentRunStatus.succeeded);
      final created = (await workspace.load()).todos.single.data;
      expect(created['due_at'], '2026-11-15T07:00:00.000Z');
      expect(created['remind_rules'], [
        {'id': 'ag_1', 'offset_minutes': 0, 'absolute_at': null},
        {'id': 'ag_2', 'offset_minutes': 30, 'absolute_at': null},
        {
          'id': 'ag_3',
          'offset_minutes': null,
          'absolute_at': '2026-11-15T01:00:00.000Z',
        },
      ]);
      expect(created['source'], 'ai');
      expect(gateway.results(1)['c1']!['status'], isNot('not_executed'));
    });

    test('相对提醒没有截止时间可依附：整批不执行并回灌，模型补上后成功', () async {
      final (result, gateway) = await run([
        _tools([
          _call('c1', 'todo_create', {
            'title': '吃药',
            'reminders': [
              {'minutes_before': 10},
            ],
          }),
        ]),
        _tools([
          _call('c2', 'todo_create', {
            'title': '吃药',
            'due_at': '2026-11-14T20:00:00+08:00',
            'reminders': [
              {'minutes_before': 10},
            ],
          }),
        ]),
        _answer(),
      ]);
      expect(result.status, AgentRunStatus.succeeded);
      final feedback = gateway.results(1)['c1']!;
      expect(feedback['status'], 'not_executed');
      expect(feedback['error'], 'invalid_arguments');
      expect(feedback['hint'], isA<String>());
      final todos = (await workspace.load()).todos;
      expect(todos.single.data['due_at'], '2026-11-14T12:00:00.000Z');
      expect(todos.single.data['remind_rules'], [
        {'id': 'ag_1', 'offset_minutes': 10, 'absolute_at': null},
      ]);
      // 被拒绝的那一轮也记入用量，历史符合工具协议（每个调用都有回执）。
      expect(result.usage, hasLength(3));
      expect(
        result.history
            .where((m) => m['role'] == 'tool')
            .map((m) => m['tool_call_id']),
        ['c1', 'c2'],
      );
    });

    test('清空截止时间会让相对提醒悬空，必须一并清掉提醒', () async {
      await todo('t1', {
        'due_at': '2026-11-15T07:00:00.000Z',
        'remind_rules': [
          {'id': 'r1', 'offset_minutes': 0},
        ],
      });
      final (failed, _) = await run([
        _tools([
          _call('c1', 'todo_update', {
            'id': 't1',
            'expected_version': 1,
            'patch': {'due_at': null},
          }),
        ]),
      ], maxCorrections: 0);
      expect(failed.status, AgentRunStatus.failed);
      expect(
        (await workspace.load()).todos.single.data['due_at'],
        '2026-11-15T07:00:00.000Z',
      );
      final (done, _) = await run([
        _tools([
          _call('c1', 'todo_update', {
            'id': 't1',
            'expected_version': 1,
            'patch': {'due_at': null, 'reminders': <Object?>[]},
          }),
        ]),
        _answer(),
      ], initial: _initial(id: 'run2'));
      expect(done.status, AgentRunStatus.succeeded);
      final after = (await workspace.load()).todos.single.data;
      expect(after['due_at'], isNull);
      expect(after['remind_rules'], isEmpty);
    });

    test('只改标题不触碰提醒：已有的手动提醒原样保留', () async {
      await todo('t1', {
        'due_at': '2026-11-15T07:00:00.000Z',
        'remind_rules': [
          {'id': 'manual_rule', 'offset_minutes': 15},
        ],
      });
      final (done, _) = await run([
        _tools([
          _call('c1', 'todo_update', {
            'id': 't1',
            'expected_version': 1,
            'patch': {'title': '改个名字'},
          }),
        ]),
        _answer(),
      ]);
      expect(done.status, AgentRunStatus.succeeded);
      final after = (await workspace.load()).todos.single.data;
      expect(after['title'], '改个名字');
      expect(after['remind_rules'], [
        {'id': 'manual_rule', 'offset_minutes': 15, 'absolute_at': null},
      ]);
    });

    test('模型不能直接提交库内字段 remind_rules / remind_at', () {
      for (final args in <JsonObject>[
        {
          'title': 'x',
          'remind_rules': [
            {'id': 'evil', 'offset_minutes': 0},
          ],
        },
        {'title': 'x', 'remind_at': '2026-11-15T07:00:00.000Z'},
        {
          'id': 't1',
          'patch': <String, Object?>{'remind_rules': <Object?>[]},
        },
      ]) {
        expect(
          () => AgentReminders.translate(args),
          throwsA(isA<AgentFailure>()),
          reason: '$args',
        );
      }
    });

    test('提醒条目的形状逐项校验', () {
      for (final reminders in <Object?>[
        '提前十分钟',
        [
          {'minutes_before': -1},
        ],
        [
          {'minutes_before': 1.5},
        ],
        [
          {'minutes_before': 5, 'at': '2026-11-15T09:00:00+08:00'},
        ],
        [<String, Object?>{}],
        [
          {'at': 20261115},
        ],
        [
          for (var i = 0; i < 6; i++) {'minutes_before': i},
        ],
      ]) {
        expect(
          () =>
              AgentReminders.translate({'title': 'x', 'reminders': reminders}),
          throwsA(isA<AgentFailure>()),
          reason: '$reminders',
        );
      }
      expect(AgentReminders.translate({'title': 'x'}), {'title': 'x'});
      expect(
        AgentReminders.translate({'title': 'x', 'reminders': <Object?>[]}),
        {'title': 'x', 'remind_rules': <Object?>[]},
      );
    });

    test('查询结果补本地时刻，筛选条件按本地时刻换算', () async {
      await todo('today', {'due_at': '2026-11-14T10:00:00.000Z'});
      await todo('tomorrow', {'due_at': '2026-11-15T10:00:00.000Z'});
      final (result, gateway) = await run([
        _tools([
          _call('q1', 'todo_list', {
            // 东八区的 11-15 全天 = UTC 11-14 16:00 至 11-15 16:00。
            'due_from': '2026-11-15T00:00:00+08:00',
            'due_before': '2026-11-16T00:00:00+08:00',
          }),
          _call('q2', 'todo_get', {'id': 'today'}),
        ]),
        _answer(),
      ]);
      expect(result.status, AgentRunStatus.succeeded);
      final listed = gateway.results(1)['q1']!['items']! as List;
      expect(listed.map((item) => (item as Map)['id']), ['tomorrow']);
      expect((listed.single as Map)['due_at'], '2026-11-15T10:00:00.000Z');
      // 测试时钟是 UTC，本地偏移为零。
      expect((listed.single as Map)['due_at_local'], '2026-11-15T10:00+00:00');
      final got = jsonEncode(gateway.results(1)['q2']);
      expect(got, contains('"due_at_local":"2026-11-14T10:00+00:00"'));
    });
  });

  group('状态', () {
    test('「不做了」是取消而不是删除；完成仍然只能走 todo_complete', () async {
      await todo('t1', {});
      final (cancelled, _) = await run([
        _tools([
          _call('c1', 'todo_update', {
            'id': 't1',
            'expected_version': 1,
            'patch': {'status': 'cancelled'},
          }),
        ]),
        _answer(),
      ]);
      expect(cancelled.status, AgentRunStatus.succeeded);
      final after = (await workspace.load()).todos.single;
      expect(after.isDeleted, isFalse);
      expect(after.data['status'], 'cancelled');

      final (rejected, gateway) = await run([
        _tools([
          _call('c2', 'todo_update', {
            'id': 't1',
            'expected_version': 2,
            'patch': {'status': 'done'},
          }),
        ]),
        _answer('请用完成操作'),
      ], initial: _initial(id: 'run2'));
      expect(rejected.status, AgentRunStatus.succeeded);
      expect(gateway.results(1)['c2']!['error'], 'invalid_arguments');
      expect((await workspace.load()).todos.single.data['status'], 'cancelled');
    });
  });

  group('错误回灌', () {
    test('默认不开启：参数错误直接失败，行为与此前一致', () async {
      final (result, gateway) = await run([
        _tools([
          _call('c1', 'todo_create', {'title': ''}),
        ]),
      ], maxCorrections: 0);
      expect(result.status, AgentRunStatus.failed);
      expect(gateway.requests, hasLength(1));
      expect((await workspace.load()).todos, isEmpty);
    });

    test('逐条指出问题：出错的调用给原因，其余标为被连带拒绝', () async {
      await todo('t1', {});
      final (result, gateway) = await run([
        _tools([
          _call('ok', 'todo_create', {'title': '没问题的一条'}),
          _call('stale', 'todo_update', {
            'id': 't1',
            'expected_version': 9,
            'patch': {'title': '新标题'},
          }),
          _call('ghost', 'todo_complete', {
            'id': 'missing',
            'expected_version': 1,
          }),
          _call('unknown', 'todo_archive', {'id': 't1'}),
          _call('broken', 'todo_create', '{"title": '),
        ]),
        _answer('我再确认一下'),
      ]);
      expect(result.status, AgentRunStatus.succeeded);
      final feedback = gateway.results(1);
      expect(feedback.values.map((r) => r['status']).toSet(), {'not_executed'});
      expect(feedback['ok']!['error'], 'batch_rejected');
      expect(feedback['stale']!['error'], 'version_conflict');
      // 目标不存在与版本过期对外是同一种情况：都要重新查询。
      expect(feedback['ghost']!['error'], 'version_conflict');
      expect(feedback['unknown']!['error'], 'unknown_tool');
      expect(feedback['broken']!['error'], 'invalid_arguments');
      // 整批原子：没问题的那条也没有写入。
      final todos = (await workspace.load()).todos;
      expect(todos.single.id, 't1');
      expect(todos.single.data['title'], 't1');
    });

    test('每条单独合法、合在一起冲突：标为批次冲突', () async {
      await todo('t1', {});
      final (result, gateway) = await run([
        _tools([
          _call('a', 'todo_update', {
            'id': 't1',
            'expected_version': 1,
            'patch': {'title': '甲'},
          }),
          _call('b', 'todo_update', {
            'id': 't1',
            'expected_version': 1,
            'patch': {'note': '乙'},
          }),
        ]),
        _tools([
          _call('c', 'todo_update', {
            'id': 't1',
            'expected_version': 1,
            'patch': {'title': '甲', 'note': '乙'},
          }),
        ]),
        _answer(),
      ]);
      expect(result.status, AgentRunStatus.succeeded);
      expect(gateway.results(1)['a']!['error'], 'batch_conflict');
      expect(gateway.results(1)['b']!['error'], 'batch_conflict');
      final after = (await workspace.load()).todos.single.data;
      expect(after['title'], '甲');
      expect(after['note'], '乙');
    });

    test('改正机会用完后失败，已经落地的写入保留', () async {
      JsonObject bad(String id) => _call(id, 'todo_create', {'title': ''});
      final (result, gateway) = await run([
        _tools([
          _call('good', 'todo_create', {'title': '先建一条'}),
        ]),
        _tools([bad('b1')]),
        _tools([bad('b2')]),
        _tools([bad('b3')]),
      ]);
      expect(result.status, AgentRunStatus.failed);
      expect(gateway.requests, hasLength(4));
      expect((await workspace.load()).todos.single.data['title'], '先建一条');
      expect(result.receipts, hasLength(1));
    });

    test('图片导入的运行不给第二次机会', () async {
      final (result, gateway) = await run(
        [
          _tools([
            _call('c1', 'todo_create', {'title': ''}),
          ]),
          _answer(),
        ],
        initial: _initial(
          user: {
            'role': 'user',
            'content': '导入这张图',
            '_towork_attachment_id': 'att_1',
          },
        ),
      );
      expect(result.status, AgentRunStatus.failed);
      expect(gateway.requests, hasLength(1));
    });

    test('超过单批上限的调用一条都不写入', () async {
      final (result, gateway) = await run([
        _tools([
          for (var i = 0; i < 21; i++)
            _call('c$i', 'todo_create', {'title': '第 $i 条'}),
        ]),
        _answer(),
      ]);
      expect(result.status, AgentRunStatus.succeeded);
      expect(gateway.requests, hasLength(2));
      expect(gateway.results(1).values.map((r) => r['error']).toSet(), {
        'batch_too_large',
      });
      expect((await workspace.load()).todos, isEmpty);
    });
  });

  group('todo_stats', () {
    JsonObject stats(WorkspaceSnapshot snapshot, [JsonObject args = const {}]) {
      final proposal = TodoAgentTools.prepare(
        _initial(),
        _tools([_call('s', 'todo_stats', args)]),
        snapshot,
        _now,
        localOffset: const Duration(hours: 8),
      );
      return (((proposal['calls']! as List).single as Map)['result']! as Map)
          .cast<String, Object?>();
    }

    test('按本地日期划分：逾期、今天、七天内、完成情况', () async {
      await seed(WorkspaceEntityKind.category, 'work', {'name': '工作'});
      await seed(WorkspaceEntityKind.category, 'weekly', {
        'name': '周会',
        'parent_id': 'work',
      });
      // 本地此刻：2026-11-14 14:30（+08:00）。
      await todo('overdue', {
        'due_at': '2026-11-14T03:00:00.000Z',
        'priority': 'high',
        'category_id': 'work',
      });
      // 本地 23:30，仍是今天。
      await todo('tonight', {
        'due_at': '2026-11-14T15:30:00.000Z',
        'status': 'inProgress',
        'category_id': 'weekly',
      });
      // 本地 11-15 00:30：UTC 仍是 11-14，但已经是明天。
      await todo('after_midnight', {'due_at': '2026-11-14T16:30:00.000Z'});
      await todo('next_month', {'due_at': '2026-12-20T02:00:00.000Z'});
      await todo('someday', {'priority': 'low'});
      await todo('dropped', {'status': 'cancelled'});
      await todo('on_time', {
        'status': 'done',
        'due_at': '2026-11-13T10:00:00.000Z',
        'completed_at': '2026-11-13T08:00:00.000Z',
      });
      await todo('late', {
        'status': 'done',
        'due_at': '2026-11-10T10:00:00.000Z',
        'completed_at': '2026-11-12T08:00:00.000Z',
        'category_id': 'work',
      });
      await todo('long_ago', {
        'status': 'done',
        'completed_at': '2026-10-01T08:00:00.000Z',
      });
      final snapshot = await workspace.load();
      final result = stats(snapshot);
      expect(result['as_of_local'], '2026-11-14T14:30+08:00');
      final open = result['open']! as Map;
      expect(open['total'], 5);
      expect(open['in_progress'], 1);
      expect(open['overdue'], 1);
      expect(open['due_rest_of_today'], 1);
      expect(open['due_within_7_days'], 2);
      expect(open['no_due_date'], 1);
      expect(open['by_priority'], {'high': 1, 'low': 1, 'none': 3});
      final completed = result['completed']! as Map;
      expect(completed['from_local'], '2026-11-08T00:00+08:00');
      expect(completed['before_local'], '2026-11-15T00:00+08:00');
      expect(completed['count'], 2);
      expect(completed['on_time'], 1);
      expect(completed['late'], 1);
      expect(result['totals_by_status'], {
        'pending': 4,
        'inProgress': 1,
        'done': 3,
        'cancelled': 1,
      });

      // 分类范围包含直接子分类。
      final scoped = stats(snapshot, {'category_id': 'work'});
      expect((scoped['open']! as Map)['total'], 2);
      expect((scoped['completed']! as Map)['count'], 1);
      // 自定义窗口用本地时刻表达。
      final october = stats(snapshot, {
        'completed_from': '2026-10-01T00:00:00+08:00',
        'completed_before': '2026-11-01T00:00:00+08:00',
      });
      expect((october['completed']! as Map)['count'], 1);
      expect(stats(snapshot, {'category_id': 'nope'}), {
        'error': 'category_not_found',
        'category_id': 'nope',
      });
    });

    test('空工作区与错误参数', () async {
      final snapshot = await workspace.load();
      final result = stats(snapshot);
      expect((result['open']! as Map)['total'], 0);
      expect((result['completed']! as Map)['count'], 0);
      expect(
        () => stats(snapshot, {
          'completed_from': '2026-11-10T00:00:00+08:00',
          'completed_before': '2026-11-01T00:00:00+08:00',
        }),
        throwsA(isA<AgentFailure>()),
      );
      expect(
        () => stats(snapshot, {'completed_from': '上周'}),
        throwsA(isA<AgentFailure>()),
      );
      expect(
        () => stats(snapshot, {'status': 'done'}),
        throwsA(isA<AgentFailure>()),
      );
    });
  });

  test('只读工具与写入同批：计算和日历结果随回执一起返回', () async {
    final (result, gateway) = await run([
      _tools([
        _call('calc', 'calculate', {'expression': '1280 * 15%'}),
        _call('cal', 'calendar_lookup', {'op': 'find_festival', 'name': '中秋'}),
        _call('new', 'todo_create', {'title': '订月饼'}),
      ]),
      _answer(),
    ]);
    expect(result.status, AgentRunStatus.succeeded);
    final results = gateway.results(1);
    expect(jsonEncode(results['calc']), contains('"result":"192"'));
    expect(jsonEncode(results['cal']), contains('2026-09-25'));
    expect((await workspace.load()).todos.single.data['title'], '订月饼');
  });
}
