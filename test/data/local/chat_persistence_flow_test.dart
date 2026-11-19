import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/agent/agent_prompt.dart';
import 'package:towork/data/local/agent_run_store.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/app_preferences_store.dart';
import 'package:towork/data/local/chat_persistence.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/chat/local_chat.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';

import '../../support/free/business_agent_fixture.dart';

/// prepare 的落库、幂等、搁置与投影增强（createdTodoIds）全流程。
/// 悬挂提案通过手工推进 run 状态机构造，不依赖模型网关。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late AppDatabase db;
  late ChatPersistence persistence;
  late SqliteAgentRunStore runs;
  final profile = ModelProfile(model: 'fixture');

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('chat-persistence-flow');
    db = AppDatabase.background(File('${dir.path}/test.sqlite'));
    await SqliteWorkspaceCommandStore(db).execute(businessAgentFixture());
    persistence = ChatPersistence(db);
    runs = SqliteAgentRunStore(db);
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  Future<LocalChatTurn> firstTurn(String inputId, [String text = '第一轮']) =>
      persistence.prepare(
        inputId: inputId,
        content: text,
        profile: profile,
        agentEnabled: true,
      );

  /// 续聊必须带原会话 id，否则会开新会话。
  Future<LocalChatTurn> followUp(
    String inputId,
    String sessionId,
    String text,
  ) => persistence.prepare(
    inputId: inputId,
    content: text,
    profile: profile,
    agentEnabled: true,
    sessionId: sessionId,
  );

  /// 手工把 run 推到指定状态（queued→generating→…）。
  Future<AgentRun> advance(
    AgentRun run,
    List<AgentRunStatus> path, {
    JsonObject? proposal,
    List<String>? receipts,
  }) async {
    for (var i = 0; i < path.length; i++) {
      run = await runs.save(
        run.next(
          path[i],
          proposal: i == path.length - 1 ? proposal : null,
          receipts: i == path.length - 1 ? receipts : null,
        ),
        expectedRevision: run.revision,
      );
    }
    return run;
  }

  test('首轮 prepare 创建会话并截断标题', () async {
    final turn = await firstTurn('i1', '这是一个特别长的开场白要被截断成十六个字符');
    expect(turn.sessionId, isNotEmpty);
    final conversation = (await persistence.load()).conversations.single;
    expect(conversation.title, '这是一个特别长的开场白要被截断成…');
    expect(turn.run.status, AgentRunStatus.queued);
  });

  test('同 inputId 同参数重放幂等；内容不同则冲突', () async {
    final turn = await firstTurn('i1', '同样的话');
    final replay = await firstTurn('i1', '同样的话');
    expect(replay.inputId, turn.inputId);
    await expectLater(firstTurn('i1', '不一样的话'), throwsA(isA<AgentFailure>()));
    expect((await persistence.load()).turns, hasLength(1));
  });

  test('空文本与超长文本都被拒绝', () async {
    await expectLater(
      persistence.prepare(
        inputId: 'i1',
        content: '   ',
        profile: profile,
        agentEnabled: true,
      ),
      throwsA(isA<AgentFailure>()),
    );
    await expectLater(
      persistence.prepare(
        inputId: 'i2',
        content: 'x' * 20001,
        profile: profile,
        agentEnabled: true,
      ),
      throwsA(isA<AgentFailure>()),
    );
    expect((await persistence.load()).turns, isEmpty);
  });

  test('附件 id 不存在或与 inputId 不匹配都拒绝', () async {
    await expectLater(
      persistence.prepare(
        inputId: 'i1',
        content: '文本',
        profile: profile,
        agentEnabled: true,
        attachmentId: 'image_missing',
      ),
      throwsA(isA<AgentFailure>()),
    );
  });

  test('生成中的上一轮拒绝续聊', () async {
    final turn = await firstTurn('i1');
    await advance(turn.run, [AgentRunStatus.generating]);
    await expectLater(
      followUp('i2', turn.sessionId, '第二条'),
      throwsA(
        isA<AgentFailure>().having(
          (e) => e.code,
          'code',
          AgentFailureCode.conflict,
        ),
      ),
    );
  });

  test('待确认提案被续聊自动搁置为 cancelled', () async {
    final turn = await firstTurn('i1');
    await advance(turn.run, [
      AgentRunStatus.generating,
      AgentRunStatus.ready,
      AgentRunStatus.awaitingConfirmation,
    ]);
    final second = await followUp('i2', turn.sessionId, '继续聊');
    final turns = await persistence.load();
    final shelved = turns.turns.where((t) => t.inputId == 'i1').single;
    expect(shelved.run.status, AgentRunStatus.cancelled);
    expect(second.run.status, AgentRunStatus.queued);
    expect(turns.turns, hasLength(2));
  });

  test('queued 与 ready 的上一轮同样被搁置放行', () async {
    final a = await firstTurn('i1');
    await advance(a.run, [AgentRunStatus.generating, AgentRunStatus.ready]);
    final b = await followUp('i2', a.sessionId, '第二条');
    expect(b.run.status, AgentRunStatus.queued);
    final c = await followUp('i3', a.sessionId, '第三条不推进状态（queued 搁置）');
    expect(c.run.status, AgentRunStatus.queued);
    final turns = await persistence.load();
    expect(
      turns.turns.map((t) => t.run.status),
      containsAll([AgentRunStatus.cancelled, AgentRunStatus.queued]),
    );
  });

  Future<void> seedReceipt(String operationId, String changes) async {
    await db
        .into(db.workspaceOperations)
        .insert(
          WorkspaceOperationsCompanion.insert(
            operationId: operationId,
            requestDigest: 'digest-$operationId',
            source: 'agent',
            receipt: '{}',
            changes: changes,
            committedAt: 1,
          ),
        );
  }

  test('createdTodoIds 只提取本轮创建的待办', () async {
    final turn = await firstTurn('i1');
    final withReceipt = await advance(
      turn.run,
      [AgentRunStatus.generating, AgentRunStatus.succeeded],
      receipts: ['op_1', 'op_2'],
    );
    expect(withReceipt.receipts, ['op_1', 'op_2']);
    await seedReceipt(
      'op_1',
      jsonEncode([
        {
          'before': null,
          'after': {'kind': 'todo', 'id': 'todo_a'},
        },
        {
          'before': {'kind': 'todo', 'id': 'todo_old'},
          'after': {'kind': 'todo', 'id': 'todo_old'},
        },
      ]),
    );
    await seedReceipt(
      'op_2',
      jsonEncode([
        {
          'before': null,
          'after': {'kind': 'dataRow', 'id': 'row_b'},
        },
      ]),
    );
    final loaded = (await persistence.load()).turns.single;
    expect(loaded.createdTodoIds, ['todo_a'], reason: '创建的待办计入；编辑与业务行不计入');
  });

  test('completion results use net receipt state, deduplicate and disappear after undo', () async {
    final turn = await firstTurn('i1');
    await advance(
      turn.run,
      [AgentRunStatus.generating, AgentRunStatus.succeeded],
      receipts: ['op_1', 'op_2'],
    );
    Map<String, Object?> todo(
      String id,
      String status, {
      bool deleted = false,
    }) => {
      'kind': 'todo',
      'id': id,
      'data': {'status': status},
      'deleted_at': deleted ? '2026-11-16T00:00:00Z' : null,
    };
    await seedReceipt(
      'op_1',
      jsonEncode([
        {'before': todo('done', 'pending'), 'after': todo('done', 'done')},
        {
          'before': todo('restored', 'pending'),
          'after': todo('restored', 'done'),
        },
        {
          'before': todo('deleted', 'pending'),
          'after': todo('deleted', 'done'),
        },
        {'before': null, 'after': todo('created', 'pending')},
        {'before': todo('old', 'done'), 'after': todo('old', 'done')},
      ]),
    );
    await seedReceipt(
      'op_2',
      jsonEncode([
        {'before': todo('done', 'done'), 'after': todo('done', 'done')},
        {
          'before': todo('restored', 'done'),
          'after': todo('restored', 'pending'),
        },
        {
          'before': todo('deleted', 'done'),
          'after': todo('deleted', 'done', deleted: true),
        },
        {
          'before': todo('created', 'pending'),
          'after': todo('created', 'done'),
        },
      ]),
    );
    final loaded = (await persistence.load()).turns.single;
    expect(loaded.completedTodoIds, ['done', 'created']);
    expect(loaded.createdTodoIds, ['created']);
    await (db.update(db.chatTurns)
          ..where((row) => row.inputId.equals(turn.inputId)))
        .write(const ChatTurnsCompanion(undoneAt: Value(1)));
    final undone = (await persistence.load()).turns.single;
    expect(undone.completedTodoIds, isEmpty);
    expect(undone.createdTodoIds, isEmpty);
  });

  test('损坏的 operation 行不阻塞加载与发送', () async {
    final turn = await firstTurn('i1');
    await advance(
      turn.run,
      [AgentRunStatus.generating, AgentRunStatus.succeeded],
      receipts: ['op_bad', 'op_bad_items', 'op_bad_shape'],
    );
    await db
        .into(db.workspaceOperations)
        .insert(
          WorkspaceOperationsCompanion.insert(
            operationId: 'op_bad',
            requestDigest: 'd',
            source: 'agent',
            receipt: '{}',
            changes: '这不是JSON',
            committedAt: 1,
          ),
        );
    await seedReceipt('op_bad_items', '[null, 7, "invalid"]');
    await seedReceipt('op_bad_shape', '{}');
    final loaded = await persistence.load();
    expect(loaded.turns.single.createdTodoIds, isEmpty, reason: '坏行跳过而非抛错');
    expect(loaded.turns.single.completedTodoIds, isEmpty);
    // 续聊不受影响。
    final second = await followUp('i2', turn.sessionId, '继续');
    expect(second.run.status, AgentRunStatus.queued);
  });

  test('软删除的会话不能续聊', () async {
    final turn = await firstTurn('i1');
    await (db.update(db.chatConversations)
          ..where((c) => c.id.equals(turn.sessionId)))
        .write(const ChatConversationsCompanion(deletedAt: Value(1)));
    await expectLater(
      persistence.prepare(
        inputId: 'i2',
        content: '第二条',
        profile: profile,
        agentEnabled: true,
        sessionId: turn.sessionId,
      ),
      throwsA(isA<AgentFailure>()),
    );
  });

  test('多会话互不影响且各自递增 position', () async {
    final a1 = await firstTurn('a1');
    final b1 = await firstTurn('b1', 'B 会话第一条');
    await advance(a1.run, [
      AgentRunStatus.generating,
      AgentRunStatus.succeeded,
    ]);
    final a2 = await followUp('a2', a1.sessionId, 'A 会话第二条');
    final snapshot = await persistence.load();
    final aTurns =
        snapshot.turns.where((t) => t.sessionId == a1.sessionId).toList()
          ..sort((x, y) => x.position.compareTo(y.position));
    final bTurns = snapshot.turns.where((t) => t.sessionId == b1.sessionId);
    expect(aTurns, hasLength(2));
    expect(aTurns.last.position, greaterThan(aTurns.first.position));
    expect(bTurns, hasLength(1));
    expect(a2.sessionId, a1.sessionId);
  });

  test('系统提示写入常识默认与时间基准', () async {
    final turn = await firstTurn('i1');
    final system = turn.run.history.first['content']! as String;
    expect(system, contains('一次性待办'), reason: '未说重复默认一次性');
    expect(system, contains('留空'), reason: '未提到的属性不用默认值填充');
    expect(system, contains('本次设备时间为基准'));
    // 每轮时间行同样携带基准与默认（上下文裁剪后仍生效）。
    final timeLine = turn.run.history[1]['content']! as String;
    expect(timeLine, contains('设备时间为基准'));
    expect(timeLine, contains('一次性待办'));
    expect(timeLine, contains('时区'));
  });
  group('提示词上下文', () {
    final clock = DateTime.utc(2026, 11, 14, 6, 30);

    Future<void> create(
      WorkspaceEntityKind kind,
      String id,
      JsonObject patch,
    ) => SqliteWorkspaceCommandStore(db)
        .execute(
          WorkspaceCommand(
            operationId: 'ctx_$id',
            actions: [
              WorkspaceMutation(
                actionId: 'ctx_action_$id',
                kind: kind,
                entityId: id,
                mutation: WorkspaceMutationKind.create,
                patch: patch,
              ),
            ],
          ),
        )
        .then((_) {});

    String situation(LocalChatTurn turn) =>
        turn.run.history.lastWhere(
              (m) =>
                  m['role'] == 'system' &&
                  (m['content']! as String).startsWith(AgentPrompt.turnMarker),
            )['content']!
            as String;

    test('称呼、偏好、分类与进行中的待办进入每轮的「当前情况」', () async {
      final profileRow = await db.loadOrCreateProfile();
      await db.renameProfile('小王', expectedVersion: profileRow.version);
      final preferences = SqliteAppPreferencesStore(db);
      final current = await preferences.loadOrCreate();
      await preferences.update({
        'custom_instructions': '回答简短一点',
        'speech_vocabulary': ['ToWork', '嘉立创'],
      }, expectedVersion: current.version);
      await create(WorkspaceEntityKind.category, 'work', {'name': '工作'});
      await create(WorkspaceEntityKind.category, 'weekly', {
        'name': '周会',
        'parent_id': 'work',
      });
      await create(WorkspaceEntityKind.category, 'old', {
        'name': '已归档',
        'archived': true,
      });
      await create(WorkspaceEntityKind.todo, 'later', {
        'title': '下周的事',
        'due_at': '2026-11-20T02:00:00.000Z',
      });
      await create(WorkspaceEntityKind.todo, 'soon', {
        'title': '交周报',
        'due_at': '2026-11-14T10:00:00.000Z',
        'priority': 'high',
        'category_id': 'weekly',
      });
      await create(WorkspaceEntityKind.todo, 'someday', {'title': '没有截止的事'});
      await create(WorkspaceEntityKind.todo, 'finished', {
        'title': '已经做完的事',
        'status': 'done',
      });
      await create(WorkspaceEntityKind.todo, 'dropped', {
        'title': '不做了的事',
        'status': 'cancelled',
      });

      final turn = await ChatPersistence(db, clock: () => clock).prepare(
        inputId: 'ctx1',
        content: '看看我手上的事',
        profile: profile,
        agentEnabled: true,
        voice: true,
      );
      final text = situation(turn);
      expect(text, contains('用户称呼：小王'));
      // 按路径排序：父分类在子分类之前。
      expect(text, contains('分类（名称 → ID）：工作 → work；工作/周会 → weekly'));
      expect(text, isNot(contains('已归档')));
      // 夹具里另有一条进行中的待办「核对账本」。
      expect(text, contains('进行中的待办（共 4 条，已全部列出'));
      // 有截止的按时间先后，没有截止的排在后面；已完成与已取消的不列。
      final listed = text
          .split('\n')
          .where((line) => line.startsWith('- '))
          .map((line) => line.substring(2).split('（').first)
          .toList();
      expect(listed, ['soon', 'later', 'someday', 'todo']);
      expect(text, contains('- soon（版本 1）｜交周报｜截止 '));
      expect(text, contains('优先级 high'));
      expect(text, isNot(contains('已经做完的事')));
      expect(text, isNot(contains('不做了的事')));
      expect(text, contains('常用词（转写里读音相近的词按这些理解）：ToWork、嘉立创'));
      expect(text, contains('本条输入来自语音转写'));
      expect(text, contains('回答简短一点'));
      expect(text, contains('写入权限：智能确认'));
      // 「当前情况」紧挨在用户消息之前，随这一轮一起被上下文窗口取舍。
      final history = turn.run.history;
      expect(history[turn.historyStart]['content'], '看看我手上的事');
      expect(history[turn.historyStart - 1]['content'], text);
    });

    test('默认占位称呼不当作用户的名字；仅对话不带业务现状', () async {
      await db.loadOrCreateProfile();
      await create(WorkspaceEntityKind.todo, 'secret', {'title': '不该出现的待办'});
      final turn = await ChatPersistence(db, clock: () => clock).prepare(
        inputId: 'ctx2',
        content: '随便聊聊',
        profile: profile,
        agentEnabled: false,
      );
      final text = situation(turn);
      expect(text, isNot(contains('用户称呼')));
      expect(text, isNot(contains('不该出现的待办')));
      expect(text, contains('本次仅对话，可用 show_question 提问'));
      expect(text, isNot(contains('语音转写')));
    });

    test('续聊：固定规则始终只有一份且在最前，上一轮的快照压成一行', () async {
      await create(WorkspaceEntityKind.todo, 'first', {'title': '第一轮时的待办'});
      final chat = ChatPersistence(db, clock: () => clock);
      final first = await chat.prepare(
        inputId: 'ctx3',
        content: '第一轮',
        profile: profile,
        agentEnabled: true,
      );
      await advance(first.run, [
        AgentRunStatus.generating,
        AgentRunStatus.succeeded,
      ]);
      await create(WorkspaceEntityKind.todo, 'second', {'title': '第二轮新增的待办'});
      final second =
          await ChatPersistence(
            db,
            clock: () => clock.add(const Duration(hours: 1)),
          ).prepare(
            inputId: 'ctx4',
            content: '第二轮',
            profile: profile,
            agentEnabled: true,
            sessionId: first.sessionId,
          );
      final history = second.run.history;
      final systems = [
        for (final message in history)
          if (message['role'] == 'system') message['content']! as String,
      ];
      expect(history.first['content'], AgentPrompt.policy());
      expect(systems.where((c) => c == AgentPrompt.policy()), hasLength(1));
      // 只有最新一轮带完整快照。
      final snapshots = systems.where(
        (c) => c.startsWith(AgentPrompt.turnMarker),
      );
      expect(snapshots, hasLength(1));
      expect(snapshots.single, contains('第一轮时的待办'));
      expect(snapshots.single, contains('第二轮新增的待办'));
      final compacted = systems.where((c) => c.startsWith('（较早一轮'));
      expect(compacted, hasLength(1));
      expect(compacted.single, isNot(contains('第一轮时的待办')));
      expect(
        history.where((m) => m['role'] == 'user').map((m) => m['content']),
        ['第一轮', '第二轮'],
      );
      // 已落库的上一轮历史不被改写。
      final stored = (await chat.load()).turns.first.run.history;
      expect(
        stored.where(
          (m) =>
              m['role'] == 'system' &&
              (m['content']! as String).startsWith(AgentPrompt.turnMarker),
        ),
        hasLength(1),
      );
    });
  });

  test('搁置后的提案在历史中保留 not_executed 回执语境', () async {
    final turn = await firstTurn('i1');
    final proposed = await advance(turn.run, [
      AgentRunStatus.generating,
      AgentRunStatus.ready,
      AgentRunStatus.awaitingConfirmation,
    ]);
    final second = await followUp('i2', turn.sessionId, '继续');
    expect(
      second.run.history.length,
      greaterThan(proposed.history.length),
      reason: '续聊历史包含上一轮上下文',
    );
    final loaded = (await persistence.load()).turns;
    expect(
      loaded.where((t) => t.run.status == AgentRunStatus.cancelled),
      hasLength(1),
    );
  });
}
