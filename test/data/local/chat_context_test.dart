import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/data/local/agent_run_store.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/chat_persistence.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/ai/context_window.dart';
import 'package:towork/domain/ai/model_gateway.dart';

void main() {
  late Directory dir;
  late AppDatabase db;
  late File file;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('chat-context');
    file = File('${dir.path}/chat.sqlite');
    db = AppDatabase.background(file);
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  test('rolling context keeps complete local history, historyStart and input idempotency after reopen', () async {
    // 预算要容得下固定规则（约 5K 字节）和最新一轮，又装不下全部六轮。
    final persistence = ChatPersistence(
      db,
      contextWindow: const ContextWindow(tokenBudget: 11000),
    );
    final runs = SqliteAgentRunStore(db);
    String? session;
    final originals = <String, Map<String, Object?>>{};
    for (var i = 0; i < 6; i++) {
      final turn = await persistence.prepare(
        inputId: 'input$i',
        content: '第$i轮${'内容' * 300}',
        profile: ModelProfile(model: 'fixture'),
        agentEnabled: false,
        sessionId: session,
      );
      session = turn.sessionId;
      expect(turn.run.history[turn.historyStart]['content'], turn.content);
      final running = await runs.save(
        turn.run.next(AgentRunStatus.generating, round: 1),
        expectedRevision: turn.run.revision,
      );
      final done = await runs.save(
        running.next(
          AgentRunStatus.succeeded,
          history: [
            ...running.history,
            {'role': 'assistant', 'content': 'reply$i'},
          ],
        ),
        expectedRevision: running.revision,
      );
      originals[done.id] = done.toJson();
    }
    final snapshot = await persistence.load();
    final last = snapshot.turns.last;
    expect(last.run.historyOmittedTurns, greaterThan(0));
    expect(
      last.run.history.where((m) => m['role'] == 'user').length,
      lessThan(6),
    );
    final duplicate = await persistence.prepare(
      inputId: last.inputId,
      content: last.content,
      profile: ModelProfile(model: 'fixture'),
      agentEnabled: false,
      sessionId: session,
    );
    expect(duplicate.run.id, last.run.id);
    await db.close();
    db = AppDatabase.background(file);
    final reopened = await ChatPersistence(db).load();
    expect(reopened.turns, hasLength(6));
    for (var i = 0; i < 6; i++) {
      final turn = reopened.turns[i];
      expect(turn.run.toJson(), originals[turn.run.id]);
      expect(turn.messages.where((m) => m.content == 'reply$i'), hasLength(1));
      expect(turn.messages.first.content, startsWith('第$i轮'));
    }
  });

  test('oversized current input fails before creating a conversation or clearing its draft', () async {
    final persistence = ChatPersistence(
      db,
      contextWindow: const ContextWindow(tokenBudget: 500),
    );
    await expectLater(
      persistence.prepare(
        inputId: 'oversized',
        content: '中文' * 100,
        profile: ModelProfile(model: 'fixture'),
        agentEnabled: true,
      ),
      throwsA(
        isA<ModelFailure>().having(
          (e) => e.code,
          'code',
          ModelFailureCode.contextBudget,
        ),
      ),
    );
    final empty = await persistence.load();
    expect(empty.conversations, isEmpty);
    expect(empty.turns, isEmpty);
    expect(await db.select(db.agentRunRows).get(), isEmpty);
  });
}
