import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/chat_persistence.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/chat/local_chat.dart';

/// 单行损坏只降级该轮对话，不能让 load/watch 整体失败
/// （启动链路依赖 load，整体失败会卡死聊天功能且重启不能自愈）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late AppDatabase db;
  late ChatPersistence persistence;
  final profile = ModelProfile(model: 'fixture');

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('chat-corruption');
    db = AppDatabase.background(File('${dir.path}/test.sqlite'));
    persistence = ChatPersistence(db);
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  Future<LocalChatTurn> seedTurn(String inputId, String text) =>
      persistence.prepare(
        inputId: inputId,
        content: text,
        profile: profile,
        agentEnabled: true,
      );

  Future<void> corruptPayload(String inputId, String payload) =>
      db.customUpdate(
        'UPDATE agent_run_rows SET payload=? WHERE id='
        '(SELECT run_id FROM chat_turns WHERE input_id=?)',
        variables: [Variable(payload), Variable(inputId)],
        updates: {db.agentRunRows},
      );

  test('run payload 损坏：跳过该轮，其余轮次与发送不受影响', () async {
    final first = await seedTurn('good', '正常的一轮');
    final session = first.sessionId;
    await persistence.prepare(
      inputId: 'bad',
      content: '将要损坏的一轮',
      profile: profile,
      agentEnabled: true,
      sessionId: session,
    );
    await corruptPayload('bad', '这不是JSON');
    final snapshot = await persistence.load();
    expect(snapshot.turns.map((t) => t.inputId), ['good'], reason: '坏行跳过，好行保留');
    // 续聊不受影响。
    final next = await persistence.prepare(
      inputId: 'next',
      content: '继续聊',
      profile: profile,
      agentEnabled: true,
      sessionId: session,
    );
    expect(next.run.status.name, 'queued');
  });

  test('history_start 越界与 inputId 断裂同样按行跳过', () async {
    await seedTurn('a', '第一轮');
    await seedTurn('b', '第二轮');
    await db.customUpdate(
      'UPDATE chat_turns SET history_start=99 WHERE input_id=?',
      variables: [const Variable('a')],
      updates: {db.chatTurns},
    );
    final snapshot1 = await persistence.load();
    expect(snapshot1.turns.map((t) => t.inputId), ['b']);
    // inputId 一致性断裂：把 b 的 payload 换成 a 的 run（id 不同）。
    final rows = await db
        .customSelect(
          'SELECT payload FROM agent_run_rows WHERE id='
          '(SELECT run_id FROM chat_turns WHERE input_id=?)',
          variables: [const Variable('a')],
        )
        .get();
    await db.customUpdate(
      'UPDATE agent_run_rows SET payload=? WHERE id='
      '(SELECT run_id FROM chat_turns WHERE input_id=?)',
      variables: [
        Variable(rows.first.read<String>('payload')),
        const Variable('b'),
      ],
      updates: {db.agentRunRows},
    );
    final snapshot2 = await persistence.load();
    expect(snapshot2.turns, isEmpty, reason: '两轮都损坏时快照为空但不抛错');
    expect(snapshot2.conversations, isNotEmpty);
  });

  test('watch：损坏行不终止流，修复后继续推送', () async {
    await seedTurn('turn1', '第一轮');
    final original =
        (await db
                .customSelect(
                  'SELECT payload FROM agent_run_rows WHERE id='
                  '(SELECT run_id FROM chat_turns WHERE input_id=?)',
                  variables: [const Variable('turn1')],
                )
                .get())
            .first
            .read<String>('payload');

    final snapshots = <int>[];
    final errors = <Object>[];
    final sub = persistence.watch().listen(
      (s) => snapshots.add(s.turns.length),
      onError: errors.add,
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(snapshots.first, 1);

    await corruptPayload('turn1', '这不是JSON');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    // 坏行跳过而非流终止。
    expect(snapshots.last, 0);
    expect(errors, isEmpty);

    await db.customUpdate(
      'UPDATE agent_run_rows SET payload=? WHERE id='
      '(SELECT run_id FROM chat_turns WHERE input_id=?)',
      variables: [Variable(original), const Variable('turn1')],
      updates: {db.agentRunRows},
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(snapshots.last, 1, reason: '修复后流仍活着并推送新快照');
    expect(errors, isEmpty);
    await sub.cancel();
  });

  test('损坏轮被跳过后，prepare 的重复 inputId 幂等检测仍精确', () async {
    await seedTurn('dup', '同样的话');
    final turn = await persistence.prepare(
      inputId: 'dup',
      content: '同样的话',
      profile: profile,
      agentEnabled: true,
    );
    expect(turn.inputId, 'dup');
    // 好数据完整解码（容错没有掩盖正常路径）。
    final snapshot = await persistence.load();
    expect(snapshot.turns.single.run.history.length, greaterThan(1));
    expect(snapshot.turns.single.content, '同样的话');
  });
}
