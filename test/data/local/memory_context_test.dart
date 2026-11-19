import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/chat_persistence.dart';
import 'package:towork/data/local/memory_persistence.dart';
import 'package:towork/domain/ai/model_gateway.dart';

void main() {
  late Directory dir;
  late AppDatabase db;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('towork-memory-ctx-');
    db = AppDatabase.background(File('${dir.path}/db.sqlite'));
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  final profile = ModelProfile(
    model: 'ctx-fixture',
    product: ProviderKind.kimiCode,
    revision: 1,
  );

  test(
    'agent turns inject keyword-matched memories; others stay clean',
    () async {
      final persistence = SqliteMemoryPersistence(db);
      await persistence.remember(content: '用户偏好拿铁不加糖', kindId: 'preference');
      await persistence.remember(content: '用户每周三健身', kindId: 'event');
      final chat = ChatPersistence(db);

      final matched = await chat.prepare(
        inputId: 'input_match',
        content: '按我的拿铁习惯建个提醒',
        profile: profile,
        agentEnabled: true,
      );
      final matchedHistory = matched.run.history;
      final memoryMessage = matchedHistory
          .where(
            (m) =>
                m['role'] == 'system' &&
                (m['content']! as String).contains('已记忆的用户信息'),
          )
          .toList();
      expect(memoryMessage, hasLength(1));
      final injected = memoryMessage.single['content']! as String;
      expect(injected, contains('用户偏好拿铁不加糖'));
      expect(injected, contains('不代表当前事实'));
      // 无关关键词不注入。
      final other = await chat.prepare(
        inputId: 'input_other',
        content: '帮我整理明天的高铁票信息',
        profile: profile,
        agentEnabled: true,
      );
      expect(
        other.run.history.where(
          (m) =>
              m['role'] == 'system' &&
              (m['content']! as String).contains('已记忆的用户信息'),
        ),
        isEmpty,
      );
      // 纯对话轮不注入。
      final chatOnly = await chat.prepare(
        inputId: 'input_chat',
        content: '聊聊拿铁',
        profile: profile,
        agentEnabled: false,
      );
      expect(
        chatOnly.run.history.where(
          (m) =>
              m['role'] == 'system' &&
              (m['content']! as String).contains('已记忆的用户信息'),
        ),
        isEmpty,
      );
    },
  );

  test(
    'paused memory does not break conversation; deleted stays unsearched',
    () async {
      final persistence = SqliteMemoryPersistence(db);
      final write = await persistence.remember(content: '机密偏好', kindId: 'fact');
      await persistence.setPaused(true);
      final chat = ChatPersistence(db);
      final turn = await chat.prepare(
        inputId: 'input_paused',
        content: '还记得我的机密偏好吗',
        profile: profile,
        agentEnabled: true,
      );
      expect(turn.run.status.name, isNot('failed'));
      // 读取不受暂停影响，但删除后的内容不可检索。
      await persistence.setPaused(false);
      await persistence.delete(write.memoryId);
      final after = await chat.prepare(
        inputId: 'input_deleted',
        content: '机密偏好',
        profile: profile,
        agentEnabled: true,
      );
      expect(
        after.run.history.where(
          (m) =>
              m['role'] == 'system' &&
              (m['content']! as String).contains('已记忆的用户信息'),
        ),
        isEmpty,
      );
    },
  );
}
