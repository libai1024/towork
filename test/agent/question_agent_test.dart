import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/agent/agent_runner.dart';
import 'package:towork/agent/agent_tool_registry.dart';
import 'package:towork/agent/tools/question_tool.dart';
import 'package:towork/app/local_chat_runtime.dart';
import 'package:towork/data/local/agent_run_store.dart';
import 'package:towork/data/local/agent_tool_executor.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/chat_persistence.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/chat/chat_question.dart';
import 'package:towork/domain/chat/local_chat.dart';
import 'package:towork/domain/models/chat.dart';
import 'package:towork/domain/settings/model_settings_service.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';

import '../support/free/fake_model_gateway.dart';

final question = ChatQuestion(question: '先看哪个范围？', options: ['今日待办', '紧急待办']);
ModelCompleted ask() => ModelCompleted(
  assistantMessage: {
    'role': 'assistant',
    'tool_calls': [
      {
        'id': 'ask-range',
        'type': 'function',
        'function': {
          'name': 'show_question',
          'arguments': jsonEncode({
            'question': question.question,
            'options': question.options,
          }),
        },
      },
    ],
  },
  finishReason: 'tool_calls',
);

class _Model extends FakeKimiGateway {
  final requests = <ModelRequest>[];
  @override
  Stream<ModelEvent> stream(
    ModelRequest request, {
    required String apiKey,
    ModelCancellation? cancellation,
  }) async* {
    requests.add(request);
    if (request.messages.last['content'] == '开始') {
      yield ask();
    } else {
      yield ModelCompleted(
        assistantMessage: {'role': 'assistant', 'content': '收到你的选择。'},
        finishReason: 'stop',
      );
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('question tool validates schema and bounded choices', () {
    final context = AgentToolContext(
      snapshot: WorkspaceSnapshot([]),
      now: DateTime.utc(2026),
      localOffset: Duration.zero,
    );
    final good = {'question': question.question, 'options': question.options};
    final result = const QuestionTool().call(good, context)! as Map;
    expect(ChatQuestion.decode(result['ui'])!.options, question.options);
    for (final bad in <Map<String, Object?>>[
      {...good, 'question': ''},
      {...good, 'question': 'a\nb'},
      {
        ...good,
        'options': ['one'],
      },
      {
        ...good,
        'options': ['x', 'x'],
      },
      {...good, 'multiple': 'true'},
      {...good, 'unknown': true},
    ]) {
      expect(
        () => const QuestionTool().call(bad, context),
        throwsA(isA<AgentFailure>()),
      );
    }
    expect(question.selectedFrom(question.answerText(['今日待办'])), {'今日待办'});
    expect(ChatQuestion.answerInputId('a' * 200), hasLength(71));
  });

  test('display stops model, persisted answer continues once and rejects stale replies', () async {
    final dir = await Directory.systemTemp.createTemp('question-agent-');
    var db = AppDatabase.background(File('${dir.path}/test.sqlite'));
    final model = _Model();
    try {
      final persistence = ChatPersistence(db);
      final first = await persistence.prepare(
        inputId: 'first',
        content: '开始',
        profile: ModelProfile(model: 'fixture'),
        agentEnabled: true,
      );
      final runner = AgentRunner(
        gateway: model,
        store: SqliteAgentRunStore(db),
        tools: SqliteAgentToolExecutor(db),
      );
      final ended = await runner.resume(first.run.id, apiKey: 'synthetic-key');
      expect(ended.status, AgentRunStatus.succeeded);
      expect(model.requests, hasLength(1));
      final message = (await persistence.load()).turns.single.messages
          .singleWhere((m) => m.type == ChatMessageType.question);
      expect(message.question!.question, question.question);
      final id = ChatQuestion.answerInputId(message.id);
      Future<LocalChatTurn> answer(String inputId) => persistence.prepare(
        inputId: inputId,
        content: question.answerText(['今日待办']),
        profile: first.run.profile,
        agentEnabled: true,
        sessionId: first.sessionId,
        replyToInputId: first.inputId,
      );
      final second = await answer(id);
      expect((await answer(id)).run.id, second.run.id);
      await runner.resume(second.run.id, apiKey: 'synthetic-key');
      expect(model.requests, hasLength(2));
      expect(
        model.requests.last.messages.last['content'],
        question.answerText(['今日待办']),
      );
      await expectLater(answer('another-answer'), throwsA(isA<AgentFailure>()));
      expect(await db.select(db.workspaceOperations).get(), isEmpty);
      await db.close();
      db = AppDatabase.background(File('${dir.path}/test.sqlite'));
      final reopened = await ChatPersistence(db).load();
      expect(reopened.turns, hasLength(2));
      expect(
        reopened.turns.first.messages.where((m) => m.question != null),
        hasLength(1),
      );
      expect(reopened.turns.last.inputId, id);
    } finally {
      await db.close();
      await dir.delete(recursive: true);
    }
  });

  test(
    'interrupted run with a committed question still waits for the user',
    () async {
      final dir = await Directory.systemTemp.createTemp('question-recover-');
      final db = AppDatabase.background(File('${dir.path}/test.sqlite'));
      try {
        final first = await ChatPersistence(db).prepare(
          inputId: 'recover',
          content: '开始',
          profile: ModelProfile(model: 'fixture'),
          agentEnabled: true,
        );
        final store = SqliteAgentRunStore(db);
        final tools = SqliteAgentToolExecutor(db);
        var run = await store.save(
          first.run.next(AgentRunStatus.generating, round: 1),
          expectedRevision: first.run.revision,
        );
        run = await tools.propose(run, ask());
        run = await tools.execute(run);
        run = await store.save(
          run.next(AgentRunStatus.interrupted),
          expectedRevision: run.revision,
        );
        final model = _Model();
        final ended = await AgentRunner(
          gateway: model,
          store: store,
          tools: tools,
        ).resume(run.id, apiKey: 'synthetic-key');
        expect(ended.status, AgentRunStatus.succeeded);
        expect(model.requests, isEmpty);
      } finally {
        await db.close();
        await dir.delete(recursive: true);
      }
    },
  );

  test(
    'chat-only mode exposes question buttons while restricting workspace tools',
    () async {
      final dir = await Directory.systemTemp.createTemp('question-chat-only-');
      final db = AppDatabase.background(File('${dir.path}/test.sqlite'));
      LocalChatRuntime? runtime;
      try {
        final model = _Model();
        final settings = ModelSettingsService(db, FakeKeyVault(), model);
        await settings.save(
          profile: ModelProfile(model: 'fixture'),
          newKey: 'synthetic-key',
          expectedVersion: (await db.readConfiguration()).version,
        );
        final config = await db.readConfiguration();
        runtime = LocalChatRuntime(
          db,
          settings,
          LocalChatSnapshot([], []),
          config,
        );
        final first = await runtime.persistence.prepare(
          inputId: 'chat-only',
          content: '开始',
          profile: config.profile,
          agentEnabled: false,
        );
        final ended = await runtime
            .runner(false)
            .resume(first.run.id, apiKey: 'synthetic-key');
        expect(ended.status, AgentRunStatus.succeeded);
        expect(
          model.requests.single.tools.map(
            (s) => (s['function']! as Map)['name'],
          ),
          ['show_question'],
        );
        expect(await db.select(db.workspaceOperations).get(), isEmpty);
      } finally {
        await runtime?.dispose();
        await db.close();
        await dir.delete(recursive: true);
      }
    },
  );
}
