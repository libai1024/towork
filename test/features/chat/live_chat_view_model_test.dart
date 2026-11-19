import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:towork/app/local_chat_runtime.dart';
import 'package:towork/app/local_workspace_session.dart';
import 'package:towork/data/local/agent_run_store.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/app_preferences_store.dart';
import 'package:towork/data/local/chat_persistence.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/data/repositories/todo_repository.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/ai/context_window.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/chat/local_chat.dart';
import 'package:towork/domain/models/chat.dart';
import 'package:towork/domain/settings/model_settings.dart';
import 'package:towork/domain/settings/model_settings_service.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';
import 'package:towork/app/chat/live_chat_view_model.dart';

import '../../support/free/fake_model_gateway.dart';

class _ChatModel implements ModelGateway {
  final requests = <ModelRequest>[];
  bool failOnce = false;
  bool failAfterToolOnce = false;
  bool plain = false;
  String reply = '回复完成';
  bool completeAfterCreate = false;
  Completer<void>? responseGate;
  @override
  Stream<ModelEvent> stream(
    ModelRequest request, {
    required String apiKey,
    ModelCancellation? cancellation,
  }) async* {
    expect(apiKey, startsWith('synthetic-'));
    requests.add(request);
    await responseGate?.future;
    if (failAfterToolOnce && request.messages.last['role'] == 'tool') {
      failAfterToolOnce = false;
      throw const ModelFailure(ModelFailureCode.network);
    }
    if (failOnce) {
      failOnce = false;
      throw const ModelFailure(ModelFailureCode.network);
    }
    if (completeAfterCreate && request.messages.last['role'] == 'tool') {
      final entity =
          (jsonDecode(request.messages.last['content']! as String)
                  as Map)['entity']
              as Map?;
      if (entity?['data']['status'] == 'pending') {
        yield ModelCompleted(
          assistantMessage: {
            'role': 'assistant',
            'content': null,
            'tool_calls': [
              {
                'id': 'complete-1',
                'type': 'function',
                'function': {
                  'name': 'todo_complete',
                  'arguments': jsonEncode({
                    'id': entity!['id'],
                    'expected_version': entity['version'],
                  }),
                },
              },
            ],
          },
          finishReason: 'tool_calls',
        );
        return;
      }
    }
    if (plain ||
        !request.tools.any(
          (tool) => (tool['function']! as Map)['name'] == 'todo_create',
        ) ||
        request.messages.last['role'] == 'tool') {
      yield const ModelTextDelta('回复');
      yield ModelCompleted(
        assistantMessage: {
          'role': 'assistant',
          'content': reply,
          'reasoning_content': 'never show this internal reasoning',
        },
        finishReason: 'stop',
      );
    } else {
      yield ModelCompleted(
        assistantMessage: {
          'role': 'assistant',
          'content': null,
          'reasoning_content': 'hidden planning',
          'tool_calls': [
            {
              'id': 'create-1',
              'type': 'function',
              'function': {
                'name': 'todo_create',
                'arguments': jsonEncode({'title': '真实本地任务'}),
              },
            },
          ],
        },
        finishReason: 'tool_calls',
      );
    }
  }
}

Future<void> _idle(LiveChatViewModel vm) async {
  for (var i = 0; i < 400 && vm.snapshot.isGenerating; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(vm.snapshot.isGenerating, isFalse);
  if (vm.snapshot.error != null) throw vm.snapshot.error!;
}

void main() {
  late Directory directory;
  late File file;
  late AppDatabase db;
  late FakeKeyVault vault;
  late _ChatModel model;
  late ModelSettingsService settings;
  late LocalChatRuntime runtime;
  late LiveChatViewModel vm;
  late TodoRepository todos;
  late LocalWorkspaceSession workspaceSession;
  var elapsed = Duration.zero;
  String? selected;
  Future<void> attach() async {
    settings = ModelSettingsService(db, vault, model);
    runtime = LocalChatRuntime(
      db,
      settings,
      await ChatPersistence(db).load(),
      await db.readConfiguration(),
    );
    final store = SqliteWorkspaceCommandStore(db);
    workspaceSession = LocalWorkspaceSession(
      store,
      await store.load(),
      elapsed: () => elapsed,
    );
    todos = TodoRepository(initial: []);
    vm = LiveChatViewModel(
      runtime: runtime,
      localWorkspace: workspaceSession,
      todos: todos,
      currentSession: () => selected,
      selectSession: (id) => selected = id,
    );
  }

  Future<void> detach() async {
    vm.dispose();
    todos.dispose();
    await workspaceSession.dispose();
    workspaceSession.todos.dispose();
    workspaceSession.categories.dispose();
    await runtime.dispose();
    runtime.projection.dispose();
    await db.close();
  }

  Future<void> reopen() async {
    await detach();
    db = AppDatabase.background(file);
    await SqliteAgentRunStore(db).interruptAbandonedGenerations();
    await attach();
  }

  Future<void> permission(String value) async {
    final store = SqliteAppPreferencesStore(db);
    final prefs = await store.loadOrCreate();
    await store.update({'permission': value}, expectedVersion: prefs.version);
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('live-chat-test');
    file = File('${directory.path}/chat.sqlite');
    db = AppDatabase.background(file);
    vault = FakeKeyVault();
    model = _ChatModel();
    selected = null;
    elapsed = Duration.zero;
    settings = ModelSettingsService(db, vault, model);
    await settings.save(
      profile: ModelProfile(model: 'fixture', product: ProviderKind.kimiCode),
      expectedVersion: 0,
      newKey: 'synthetic-key',
    );
    await SqliteAppPreferencesStore(db).loadOrCreate();
    await attach();
  });
  tearDown(() async {
    await detach();
    await directory.delete(recursive: true);
  });

  test('pending proposals do not block the next message; they are shelved as cancelled', () async {
    // 总是询问：第一轮 fake 模型的 todo_create 提案停在待确认。
    await permission('askAll');
    expect(await vm.sendPersisted('帮我记一件事', model: 'fixture'), isTrue);
    await _idle(vm);
    expect(
      runtime.projection.data.turns.last.run.status,
      AgentRunStatus.awaitingConfirmation,
    );

    // 第二条消息不再被待确认提案挡住，可直接续聊。
    model.plain = true;
    expect(await vm.sendPersisted('再聊点别的', model: 'fixture'), isTrue);
    await _idle(vm);
    final turns = [...runtime.projection.data.turns]
      ..sort((a, b) => a.position.compareTo(b.position));
    expect(turns, hasLength(2));
    expect(
      turns.first.run.status,
      AgentRunStatus.cancelled,
      reason: '待确认提案被自动搁置（同「取消本次」）',
    );
    expect(turns.last.run.status, AgentRunStatus.succeeded);

    // 续聊请求里，上一轮未执行的提案带 not_executed 工具回执。
    final history = model.requests.last.messages;
    final toolIndex = history.indexWhere((m) => m['role'] == 'tool');
    expect(toolIndex, greaterThan(0), reason: '应补工具回执');
    expect(history[toolIndex]['content'], contains('not_executed'));
    // 被搁置（cancelled）的运行不产出待办内容卡 id。
    expect(turns.first.createdTodoIds, isEmpty);
  });

  test('production chat continues after context rollover and retains full history after restart', () async {
    model.plain = true;
    model.reply = '长回复' * 4000;
    for (var i = 0; i < 5; i++) {
      expect(await vm.sendPersisted('第$i轮说明', model: 'fixture'), isTrue);
      await _idle(vm);
    }
    expect(runtime.projection.data.turns, hasLength(5));
    expect(
      runtime.projection.data.turns.last.run.historyOmittedTurns,
      greaterThan(0),
    );
    expect(
      model.requests.last.messages,
      contains(equals(ContextWindow.notice)),
    );
    final sessionId = selected!;
    model.plain = false;
    model.reply = '回复完成';
    expect(await vm.sendPersisted('现在创建待办', model: 'fixture'), isTrue);
    await _idle(vm);
    final created = (await SqliteWorkspaceCommandStore(db).load()).todos;
    expect(created, hasLength(1));
    final last = runtime.projection.data.turns.last;
    expect(last.run.status, AgentRunStatus.succeeded);
    expect(last.run.receipts, hasLength(1));
    // 成功创建的待办由投影精确携带（供聊天页追加内容卡）。
    expect(last.createdTodoIds, [created.single.id]);
    await reopen();
    final reopened = runtime.projection.data.turns;
    expect(reopened, hasLength(6));
    expect(
      runtime.projection
          .messagesOf(sessionId)
          .where((m) => m.content == '长回复' * 4000),
      hasLength(5),
    );
    expect(reopened.last.run.contextOmittedTurns, greaterThan(0));
    expect(reopened.last.run.receipts, last.run.receipts);
  });

  test('active Agent holds generation, waiting releases it, undo extends quiet interval', () async {
    await permission('askAll');
    model.responseGate = Completer<void>();
    await vm.sendPersisted('新增待办', model: 'fixture');
    expect(workspaceSession.automaticWorkHeld, isTrue);
    model.responseGate!.complete();
    await _idle(vm);
    expect(
      runtime.projection.data.turns.single.run.status,
      AgentRunStatus.awaitingConfirmation,
    );
    expect(workspaceSession.automaticWorkHeld, isFalse);
    expect(workspaceSession.automaticWorkDelay, const Duration(seconds: 15));
    elapsed += const Duration(seconds: 16);
    expect(workspaceSession.automaticWorkDelay, Duration.zero);
    final run = runtime.projection.data.turns.single.run;
    await vm.resumeRun(
      run.id,
      approval: AgentApproval(
        runRevision: run.revision,
        proposalId: run.proposal!['id']! as String,
        digest: run.proposal!['digest']! as String,
      ),
    );
    expect(workspaceSession.automaticWorkHeld, isFalse);
    elapsed += const Duration(seconds: 10);
    await vm.undoRun(run.id);
    expect(workspaceSession.automaticWorkDelay, const Duration(seconds: 15));
  });

  test('cancelled transport releases automatic generation lease', () async {
    model.responseGate = Completer<void>();
    await vm.sendPersisted('新增待办', model: 'fixture');
    expect(workspaceSession.automaticWorkHeld, isTrue);
    vm.cancel();
    model.responseGate!.complete();
    await _idle(vm);
    expect(workspaceSession.automaticWorkHeld, isFalse);
    expect(workspaceSession.automaticWorkDelay, const Duration(seconds: 15));
  });

  test('multi-batch compensation and chat marker roll back together, then reopen idempotently', () async {
    model.completeAfterCreate = true;
    expect(await vm.sendPersisted('创建并完成', model: 'fixture'), isTrue);
    await _idle(vm);
    final turn = runtime.projection.data.turns.single;
    expect(turn.run.receipts, hasLength(2));
    await db.customStatement(
      "CREATE TRIGGER reject_undo_marker BEFORE UPDATE OF undone_at ON chat_turns BEGIN SELECT RAISE(ABORT, 'injected'); END",
    );
    await expectLater(vm.undoRun(turn.run.id), throwsA(isA<AgentFailure>()));
    expect(
      (await SqliteWorkspaceCommandStore(
        db,
      ).load()).todos.single.data['status'],
      'done',
    );
    expect((await runtime.persistence.load()).turns.single.undoneAt, isNull);
    expect(await db.select(db.workspaceOperations).get(), hasLength(2));
    await db.customStatement('DROP TRIGGER reject_undo_marker');
    await vm.undoRun(turn.run.id);
    await reopen();
    await vm.undoRun(turn.run.id);
    expect((await SqliteWorkspaceCommandStore(db).load()).todos, isEmpty);
    expect(runtime.projection.data.turns.single.undoneAt, isNotNull);
    expect(await db.select(db.workspaceOperations).get(), hasLength(3));
  });

  test(
    'stable speech input ID cannot duplicate a completed run after reopen',
    () async {
      expect(
        await vm.sendPersisted(
          '新增语音任务',
          inputId: 'speech-stable',
          model: 'fixture',
        ),
        isTrue,
      );
      await _idle(vm);
      final first = runtime.projection.data.turns.single;
      final calls = model.requests.length;
      await reopen();
      expect(
        await vm.sendPersisted(
          '新增语音任务',
          inputId: 'speech-stable',
          model: 'fixture',
        ),
        isTrue,
      );
      await _idle(vm);
      expect(runtime.projection.data.turns, hasLength(1));
      expect(runtime.projection.data.turns.single.run.id, first.run.id);
      expect(model.requests, hasLength(calls));
      expect(
        (await SqliteWorkspaceCommandStore(db).load()).todos,
        hasLength(1),
      );
    },
  );

  test('send commits input and run, streams model reply and reopens without seeds or reasoning', () async {
    expect(runtime.projection.snapshot, isEmpty);
    expect(
      await vm.sendPersisted('创建一个待办', model: 'ignored-display-label'),
      isTrue,
    );
    await _idle(vm);
    final id = selected!;
    final turn = runtime.projection.data.turns.single;
    expect(turn.run.status, AgentRunStatus.succeeded);
    expect(turn.run.profile.model, 'fixture');
    expect(turn.messages.where((m) => m.role == ChatRole.user), hasLength(1));
    expect(
      turn.messages
          .where((m) => m.type == ChatMessageType.text)
          .map((m) => m.content)
          .join(),
      isNot(contains('hidden')),
    );
    expect(
      turn.messages.map((m) => m.content).join(),
      isNot(contains('internal reasoning')),
    );
    expect(
      turn.run.history.any((m) => m['reasoning_content'] == 'hidden planning'),
      isTrue,
    );
    expect(
      (await SqliteWorkspaceCommandStore(
        db,
      ).load()).todos.single.data['source_message_id'],
      turn.inputId,
    );
    await reopen();
    expect(runtime.projection.snapshot.single.id, id);
    expect(
      runtime.projection.messagesOf(id).map((m) => m.content),
      turn.messages.map((m) => m.content),
    );
    expect(model.requests, hasLength(2));
  });

  test('approval is restored after reopening and does not change the persisted policy', () async {
    await permission('askAll');
    await vm.sendPersisted('等待确认', model: '');
    await _idle(vm);
    final original = runtime.projection.data.turns.single.run;
    expect(original.status, AgentRunStatus.awaitingConfirmation);
    expect((await SqliteWorkspaceCommandStore(db).load()).todos, isEmpty);
    await reopen();
    final restored = runtime.projection.data.turns.single.run;
    await vm.resumeRun(
      restored.id,
      approval: AgentApproval(
        runRevision: restored.revision,
        proposalId: restored.proposal!['id']! as String,
        digest: restored.proposal!['digest']! as String,
      ),
    );
    await _idle(vm);
    expect(
      runtime.projection.data.turns.single.run.status,
      AgentRunStatus.succeeded,
    );
    expect((await SqliteWorkspaceCommandStore(db).load()).todos, hasLength(1));
    expect(
      (await SqliteAppPreferencesStore(db).loadOrCreate()).permission.name,
      'askAll',
    );
  });

  test(
    'chat mode only offers questions and keeps one copy of each user input',
    () async {
      await vm.sendPersisted('第一轮只聊天', model: '', agentEnabled: false);
      await _idle(vm);
      await vm.sendPersisted('第二轮只聊天', model: '', agentEnabled: false);
      await _idle(vm);
      expect(
        model.requests.every(
          (r) =>
              r.tools.length == 1 &&
              (r.tools.single['function']! as Map)['name'] == 'show_question',
        ),
        isTrue,
      );
      expect(
        model.requests.last.messages
            .where((m) => m['role'] == 'user')
            .map((m) => m['content']),
        ['第一轮只聊天', '第二轮只聊天'],
      );
      expect(
        runtime.projection
            .messagesOf(selected!)
            .where((m) => m.role == ChatRole.user),
        hasLength(2),
      );
      expect((await SqliteWorkspaceCommandStore(db).load()).todos, isEmpty);
    },
  );

  test('missing key rejects acceptance before creating a session or clearing caller draft', () async {
    await settings.deleteKey(expectedVersion: 1);
    expect(await vm.sendPersisted('这段草稿要保留', model: ''), isFalse);
    expect(vm.snapshot.error, isA<SettingsFailure>());
    expect((await ChatPersistence(db).load()).conversations, isEmpty);
    expect(selected, isNull);
  });

  test(
    'network retry reuses persisted user input and completed replies',
    () async {
      model.failOnce = true;
      model.plain = true;
      await vm.sendPersisted('只发送一次', model: '');
      await _idle(vm);
      final failed = runtime.projection.data.turns.single;
      expect(failed.run.status, AgentRunStatus.failed);
      await vm.resumeRun(failed.run.id, retry: true);
      await _idle(vm);
      expect(runtime.projection.data.turns, hasLength(1));
      expect(
        runtime.projection.data.turns.single.run.status,
        AgentRunStatus.succeeded,
      );
      expect(
        runtime.projection
            .messagesOf(selected!)
            .where((m) => m.role == ChatRole.user),
        hasLength(1),
      );
      expect(model.requests, hasLength(2));
    },
  );

  test('changed credential cannot approve an old pending proposal', () async {
    await permission('askAll');
    await vm.sendPersisted('旧配置请求', model: '');
    await _idle(vm);
    final waiting = runtime.projection.data.turns.single.run;
    await settings.save(
      profile: waiting.profile,
      expectedVersion: 1,
      newKey: 'synthetic-new-key',
    );
    await vm.resumeRun(
      waiting.id,
      approval: AgentApproval(
        runRevision: waiting.revision,
        proposalId: waiting.proposal!['id']! as String,
        digest: waiting.proposal!['digest']! as String,
      ),
    );
    expect(vm.snapshot.error, isA<SettingsFailure>());
    expect((await SqliteWorkspaceCommandStore(db).load()).todos, isEmpty);
    await vm.cancelRun(waiting.id);
    expect(
      runtime.projection.data.turns.single.run.status,
      AgentRunStatus.cancelled,
    );
  });

  test(
    'failed input transaction retains draft acceptance and retries only once',
    () async {
      await db.customStatement('PRAGMA query_only = ON');
      expect(await vm.sendPersisted('必须保留的草稿', model: ''), isFalse);
      expect((await ChatPersistence(db).load()).turns, isEmpty);
      expect(await db.select(db.agentRunRows).get(), isEmpty);
      expect(selected, isNull);
      await db.customStatement('PRAGMA query_only = OFF');
      expect(await vm.sendPersisted('必须保留的草稿', model: ''), isTrue);
      await _idle(vm);
      expect(runtime.projection.data.turns, hasLength(1));
      expect(
        (await SqliteWorkspaceCommandStore(db).load()).todos,
        hasLength(1),
      );
    },
  );

  test('credential rotation cancels an in-flight response before any business write', () async {
    final gate = Completer<void>();
    model.responseGate = gate;
    await vm.sendPersisted('等待中的请求', model: '');
    for (var i = 0; i < 400 && model.requests.isEmpty; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(model.requests, hasLength(1));
    await settings.save(
      profile: model.requests.single.profile,
      expectedVersion: 1,
      newKey: 'synthetic-rotated-key',
    );
    gate.complete();
    await _idle(vm);
    expect((await SqliteWorkspaceCommandStore(db).load()).todos, isEmpty);
    expect(runtime.projection.data.turns.single.run.isTerminal, isTrue);
    expect(runtime.projection.data.turns.single.run.receipts, isEmpty);
    expect(model.requests, hasLength(1));
  });

  test(
    'retry after a committed tool receipt does not create the todo again',
    () async {
      model.failAfterToolOnce = true;
      await vm.sendPersisted('写入后回复失败', model: '');
      await _idle(vm);
      final failed = runtime.projection.data.turns.single.run;
      expect(failed.status, AgentRunStatus.failed);
      expect(failed.receipts, hasLength(1));
      final original = (await SqliteWorkspaceCommandStore(
        db,
      ).load()).todos.single;
      await vm.resumeRun(failed.id, retry: true);
      await _idle(vm);
      final result = runtime.projection.data.turns.single.run;
      expect(result.status, AgentRunStatus.succeeded);
      expect(result.receipts, failed.receipts);
      final todos = (await SqliteWorkspaceCommandStore(db).load()).todos;
      expect(todos, hasLength(1));
      expect(todos.single.id, original.id);
      expect(todos.single.version, original.version);
      expect(model.requests, hasLength(3));
    },
  );

  test('rename, one-batch undo and deletion survive reopening while retaining audit', () async {
    await vm.sendPersisted('创建并管理会话', model: '');
    await _idle(vm);
    final id = selected!;
    final run = runtime.projection.data.turns.single.run;
    await vm.renameSessionPersisted(id, '真实历史');
    await vm.undoRun(run.id);
    await vm.undoRun(run.id);
    expect((await SqliteWorkspaceCommandStore(db).load()).todos, isEmpty);
    await reopen();
    expect(runtime.projection.snapshot.single.title, '真实历史');
    expect(runtime.projection.data.turns.single.undoneAt, isNotNull);
    await vm.deleteSessionPersisted(id);
    await reopen();
    expect(runtime.projection.snapshot, isEmpty);
    expect(runtime.projection.messagesOf(id), isEmpty);
    expect((await SqliteAgentRunStore(db).read(run.id)).receipts, hasLength(1));
  });

  test('undo cannot overwrite later manual edits', () async {
    await vm.sendPersisted('创建', model: '');
    await _idle(vm);
    final workspace = SqliteWorkspaceCommandStore(db);
    final task = (await workspace.load()).todos.single;
    await workspace.execute(
      WorkspaceCommand(
        operationId: 'manual-edit',
        actions: [
          WorkspaceMutation(
            actionId: 'edit',
            kind: WorkspaceEntityKind.todo,
            entityId: task.id,
            mutation: WorkspaceMutationKind.update,
            expectedVersion: task.version,
            patch: {'title': '人工已修改'},
          ),
        ],
      ),
    );
    await expectLater(
      vm.undoRun(runtime.projection.data.turns.single.run.id),
      throwsA(isA<WorkspaceFailure>()),
    );
    expect((await workspace.load()).todos.single.data['title'], '人工已修改');
    expect((await ChatPersistence(db).load()).turns.single.undoneAt, isNull);
  });

  test('stale rename and read-only writes keep original history', () async {
    model.plain = true;
    await vm.sendPersisted('历史记录', model: '');
    await _idle(vm);
    final old = runtime.projection.conversation(selected!)!;
    await runtime.persistence.rename(
      old.id,
      '较新标题',
      expectedRevision: old.revision,
    );
    await expectLater(
      runtime.persistence.rename(old.id, '旧标题', expectedRevision: old.revision),
      throwsA(isA<AgentFailure>()),
    );
    await runtime.refresh();
    await db.customStatement('PRAGMA query_only = ON');
    await expectLater(
      vm.renameSessionPersisted(old.id, '不得假保存'),
      throwsA(isA<AgentFailure>()),
    );
    await db.customStatement('PRAGMA query_only = OFF');
    await reopen();
    expect(runtime.projection.snapshot.single.title, '较新标题');
    expect(
      runtime.projection
          .messagesOf(old.id)
          .where((m) => m.role == ChatRole.user),
      hasLength(1),
    );
  });

  test('cancelled proposal is represented as unexecuted tools in the next turn context', () async {
    await permission('askAll');
    await vm.sendPersisted('先提出建议', model: '');
    await _idle(vm);
    await vm.cancelRun(runtime.projection.data.turns.single.run.id);
    model.plain = true;
    await vm.sendPersisted('不用执行，继续聊天', model: '');
    await _idle(vm);
    final history = model.requests.last.messages;
    expect(
      history.where((m) => m['role'] == 'tool').single['content'],
      contains('not_executed'),
    );
    expect((await SqliteWorkspaceCommandStore(db).load()).todos, isEmpty);
  });

  test('v5 schema migrates without fabricating history; malformed chat table rolls back', () async {
    await detach();
    await file.delete();
    var raw = sqlite.sqlite3.open(file.path);
    raw.execute(File('test/fixtures/local/schema_v5.sql').readAsStringSync());
    raw.execute(
      "INSERT INTO local_profiles VALUES(1,'existing-user','原资料',1,1700000000)",
    );
    raw.execute('CREATE TABLE chat_turns (unexpected TEXT)');
    raw.close();
    db = AppDatabase.background(file);
    await expectLater(ChatPersistence(db).load(), throwsA(isA<AgentFailure>()));
    await db.close();
    raw = sqlite.sqlite3.open(file.path);
    expect(raw.select('PRAGMA user_version').single['user_version'], 5);
    expect(
      raw.select('SELECT nickname FROM local_profiles').single['nickname'],
      '原资料',
    );
    raw.execute('DROP TABLE chat_turns');
    raw.close();
    db = AppDatabase.background(file);
    await attach();
    expect(runtime.projection.snapshot, isEmpty);
    expect((await db.loadOrCreateProfile()).nickname, '原资料');
    expect(
      (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
        'user_version',
      ),
      13,
    );
  });

  test(
    'E2E chain: proposal approval, todo card source, undo, then continue',
    () async {
      await permission('askAll');
      model.reply = '先确认这条待办';
      expect(await vm.sendPersisted('帮我建一条测试待办', model: 'fixture'), isTrue);
      await _idle(vm);
      final first = runtime.projection.data.turns.last;
      expect(first.run.status, AgentRunStatus.awaitingConfirmation);
      final calls = (first.run.proposal!['calls']! as List).cast<JsonObject>();
      await vm.resumeRun(
        first.run.id,
        approval: AgentApproval(
          runRevision: first.run.revision,
          proposalId: first.run.proposal!['id']! as String,
          digest: first.run.proposal!['digest']! as String,
          selectedToolCallIds: [
            for (final call in calls) call['tool_call_id']! as String,
          ],
        ),
      );
      await _idle(vm);
      final executed = [...runtime.projection.data.turns]
        ..sort((a, b) => a.position.compareTo(b.position));
      expect(executed.first.run.status, AgentRunStatus.succeeded);
      final created = (await SqliteWorkspaceCommandStore(db).load()).todos;
      expect(created, hasLength(1));
      expect(executed.first.createdTodoIds, [
        created.single.id,
      ], reason: '聊天页据此渲染待办内容卡');

      await vm.undoRun(first.run.id);
      expect(
        (await SqliteWorkspaceCommandStore(db).load()).todos,
        isEmpty,
        reason: 'run 级撤销回收本批写入',
      );

      model.plain = true;
      model.reply = '好的';
      expect(await vm.sendPersisted('撤销了，继续聊点别的', model: 'fixture'), isTrue);
      await _idle(vm);
      final turns = [...runtime.projection.data.turns]
        ..sort((a, b) => a.position.compareTo(b.position));
      expect(turns, hasLength(2));
      expect(
        turns.last.run.status,
        AgentRunStatus.succeeded,
        reason: '撤销后同一会话可继续对话',
      );
      expect(turns.first.undoneAt, isNotNull);
    },
  );

  test(
    'E2E chain: mixed rounds with failure and retry stay conversational',
    () async {
      List<LocalChatTurn> sorted() =>
          [...runtime.projection.data.turns]
            ..sort((a, b) => a.position.compareTo(b.position));

      model.plain = true;
      model.reply = '第一轮纯文本';
      expect(await vm.sendPersisted('第一轮', model: 'fixture'), isTrue);
      await _idle(vm);
      expect(sorted().single.run.status, AgentRunStatus.succeeded);

      model.plain = false;
      expect(await vm.sendPersisted('建个待办', model: 'fixture'), isTrue);
      await _idle(vm);
      final second = sorted()[1];
      expect(second.run.status, AgentRunStatus.succeeded);
      expect(
        (await SqliteWorkspaceCommandStore(db).load()).todos,
        hasLength(1),
      );

      model.plain = true;
      model.failOnce = true;
      model.reply = '第三轮';
      expect(await vm.sendPersisted('第三轮', model: 'fixture'), isTrue);
      await _idle(vm);
      expect(sorted()[2].run.status, AgentRunStatus.failed);

      model.failOnce = false;
      expect(vm.retry(), isTrue);
      await _idle(vm);
      expect(
        sorted()[2].run.status,
        AgentRunStatus.succeeded,
        reason: '原地重试不改写轮次数',
      );

      expect(await vm.sendPersisted('第四轮', model: 'fixture'), isTrue);
      await _idle(vm);
      expect(sorted(), hasLength(4));
      expect(sorted().last.run.status, AgentRunStatus.succeeded);
      expect(
        (await SqliteWorkspaceCommandStore(db).load()).todos,
        hasLength(1),
      );
    },
  );
}
