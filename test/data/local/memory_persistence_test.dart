import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/memory_persistence.dart';
import 'package:towork/domain/repositories/memory_persistence.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';
import 'package:towork/data/local/workspace_command_store.dart';

void main() {
  late Directory dir;
  late AppDatabase db;
  late SqliteMemoryPersistence store;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('towork-memory-');
    db = AppDatabase.background(File('${dir.path}/db.sqlite'));
    store = SqliteMemoryPersistence(db);
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  group('search', () {
    Future<List<String>> found(String query, {int limit = 5}) async =>
        (await store.search(
          query,
          limit: limit,
        )).map((m) => m.content).toList();

    test('命中的词越多越靠前，同分按最近更新', () async {
      await store.remember(content: '用户喜欢拿铁', kindId: 'preference');
      await store.remember(content: '用户的咖啡要拿铁，不加糖', kindId: 'preference');
      await store.remember(content: '周三下午健身', kindId: 'event');
      expect(await found('咖啡要拿铁不加糖'), ['用户的咖啡要拿铁，不加糖', '用户喜欢拿铁']);
      expect(await found('拿铁', limit: 1), hasLength(1));
    });

    test('口语里的高频词不参与匹配：无关记忆不会被带出来', () async {
      await store.remember(content: '明天提醒我的待办要早点做', kindId: 'fact');
      await store.remember(content: '帮我记住这个什么时候可以', kindId: 'fact');
      expect(await found('帮我看一下明天还有什么待办'), isEmpty);
      expect(await found('提醒我一下'), isEmpty);
    });

    test('已过期和已删除的记忆不返回', () async {
      await store.remember(
        content: '临时车牌到期日',
        kindId: 'fact',
        expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      );
      final kept = await store.remember(
        content: '车牌号是沪A12345',
        kindId: 'fact',
        expiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
      );
      final removed = await store.remember(content: '旧车牌记录', kindId: 'fact');
      await store.delete(removed.memoryId);
      expect(await found('车牌'), ['车牌号是沪A12345']);
      expect((await store.search('车牌')).single.id, kept.memoryId);
    });

    test('中英混说：夹在中文里的英文词和型号单独成词', () async {
      await store.remember(content: 'ToWork 的发布日是每周五', kindId: 'fact');
      await store.remember(content: '手机是 Mate80 Pro', kindId: 'fact');
      expect(await found('我们towork什么时候发版来着'), ['ToWork 的发布日是每周五']);
      expect(await found('我那台mate80还能用吗'), ['手机是 Mate80 Pro']);
    });

    test('通配符按字面匹配，空查询与无词查询返回空', () async {
      await store.remember(content: '折扣是 50%_off', kindId: 'fact');
      await store.remember(content: '完全无关的内容', kindId: 'fact');
      expect(await found('50%_off'), ['折扣是 50%_off']);
      // 单独的 % 只匹配字面百分号，不会当成「任意内容」。
      expect(await found('%'), ['折扣是 50%_off']);
      expect(await found(''), isEmpty);
      expect(await found('   '), isEmpty);
      expect(await found('我的'), isEmpty);
    });
  });

  test('update 的 expiresAt 哨兵语义：缺省保留、显式替换、显式清除', () async {
    final expiry = DateTime.utc(2027, 1, 1);
    final write = await store.remember(
      content: '偏好安静的环境',
      kindId: 'fact',
      expiresAt: expiry,
    );
    // 只改内容：过期时间保留。
    var record = await store.update(write.memoryId, content: '偏好安静的书房');
    expect(record.expiresAt, expiry);
    // 只传新过期时间：替换生效。
    final later = DateTime.utc(2028, 6, 1);
    record = await store.update(write.memoryId, expiresAt: later);
    expect(record.expiresAt, later);
    // 显式 null：清除。
    record = await store.update(write.memoryId, expiresAt: null);
    expect(record.expiresAt, isNull);
    // 重开数据库后落库值一致。
    await db.close();
    db = AppDatabase.background(File('${dir.path}/db.sqlite'));
    store = SqliteMemoryPersistence(db);
    final reopened = await store.list();
    expect(reopened.single.expiresAt, isNull);
  });

  test(
    'manual remember, edit, delete survive restart with version checks',
    () async {
      final write = await store.remember(
        content: ' 用户偏好安静的环境 ',
        kindId: 'fact',
      );
      expect(write.epoch, 0);
      expect(write.version, 1);
      final listed = await store.list();
      expect(listed, hasLength(1));
      expect(listed.single.content, '用户偏好安静的环境');
      expect(listed.single.source, MemoryPersistSource.manual);

      // Stale version cannot edit.
      await expectLater(
        store.update(write.memoryId, content: '新内容', expectedVersion: 5),
        throwsA(isA<MemoryPersistenceFailure>()),
      );
      final edited = await store.update(
        write.memoryId,
        content: '用户偏好安静、昏暗的环境',
        expectedVersion: 1,
      );
      expect(edited.version, 2);

      await db.close();
      db = AppDatabase.background(File('${dir.path}/db.sqlite'));
      store = SqliteMemoryPersistence(db);
      final reopened = await store.list();
      expect(reopened.single.content, '用户偏好安静、昏暗的环境');
      expect(reopened.single.epoch, 0);

      await store.delete(write.memoryId, expectedVersion: 2);
      expect(await store.list(), isEmpty);
      expect((await store.list(includeDeleted: true)), hasLength(1));
      expect(await store.epoch(), 1);
    },
  );

  test('pause rejects every write including explicit remember; epoch only moves on pause', () async {
    await store.remember(content: '一条记忆', kindId: 'fact');
    await store.setPaused(true);
    expect(await store.paused(), isTrue);
    expect(await store.epoch(), 1);
    await expectLater(
      store.remember(content: '显式记住', kindId: 'fact'),
      throwsA(
        isA<MemoryPersistenceFailure>().having(
          (f) => f.code,
          'code',
          MemoryPersistenceFailureCode.paused,
        ),
      ),
    );
    // While paused, the pause reason wins over the stale epoch.
    await expectLater(
      store.remember(content: '迟到提取', kindId: 'fact', expectedEpoch: 0),
      throwsA(
        isA<MemoryPersistenceFailure>().having(
          (f) => f.code,
          'code',
          MemoryPersistenceFailureCode.paused,
        ),
      ),
    );
    await store.setPaused(false);
    expect(await store.epoch(), 1);
    final write = await store.remember(content: '恢复后写入', kindId: 'fact');
    expect(write.epoch, 1);
  });

  test(
    'clearAll bumps epoch; stale clears and late writes are rejected',
    () async {
      await store.remember(content: 'A', kindId: 'event');
      await store.remember(content: 'B', kindId: 'event');
      await store.clearAll();
      expect(await store.list(), isEmpty);
      expect((await store.list(includeDeleted: true)).length, 2);
      expect(await store.epoch(), 1);
      await expectLater(
        store.remember(content: '迟到', kindId: 'event', expectedEpoch: 0),
        throwsA(isA<MemoryPersistenceFailure>()),
      );
      await expectLater(
        store.clearAll(expectedEpoch: 0),
        throwsA(isA<MemoryPersistenceFailure>()),
      );
      // A current-epoch write still succeeds.
      expect((await store.remember(content: '新纪元', kindId: 'event')).epoch, 1);
    },
  );

  test('referenced sources must still exist when the write lands', () async {
    await expectLater(
      store.remember(
        content: '来自不存在的消息',
        kindId: 'fact',
        sourceMessageId: 'missing_input',
      ),
      throwsA(isA<MemoryPersistenceFailure>()),
    );

    // A live chat turn authors memory; a wrong session pairing is rejected.
    await (db.into(db.chatConversations)).insert(
      ChatConversationsCompanion.insert(
        id: 'conv1',
        title: '会话',
        revision: 1,
        createdAt: 0,
        updatedAt: 0,
      ),
    );
    await (db.into(db.chatTurns)).insert(
      ChatTurnsCompanion.insert(
        inputId: 'input1',
        sessionId: 'conv1',
        runId: 'run1',
        content: '用户说他每周三健身',
        position: 0,
        historyStart: 0,
        createdAt: 0,
        agentEnabled: true,
      ),
    );
    final fromChat = await store.remember(
      content: '用户每周三健身',
      kindId: 'fact',
      sourceMessageId: 'input1',
      sourceSessionId: 'conv1',
    );
    expect(fromChat.epoch, 0);
    await expectLater(
      store.remember(
        content: '会话不匹配',
        kindId: 'fact',
        sourceMessageId: 'input1',
        sourceSessionId: 'other',
      ),
      throwsA(isA<MemoryPersistenceFailure>()),
    );

    // Business-record sources: live row passes, deleted row fails.
    final commands = SqliteWorkspaceCommandStore(db);
    await commands.execute(
      WorkspaceCommand(
        operationId: 'op_row',
        actions: [
          WorkspaceMutation(
            actionId: 'dataTable_t1',
            kind: WorkspaceEntityKind.dataTable,
            entityId: 't1',
            mutation: WorkspaceMutationKind.create,
            patch: {
              'name': '表',
              'fields': [
                {
                  'id': 'f1',
                  'name': '名称',
                  'type': 'text',
                  'required': true,
                  'options': <Object?>[],
                },
              ],
            },
          ),
          WorkspaceMutation(
            actionId: 'row_r1',
            kind: WorkspaceEntityKind.dataRow,
            entityId: 'r1',
            mutation: WorkspaceMutationKind.create,
            patch: {
              'table_id': 't1',
              'values': {'f1': '记录'},
            },
          ),
        ],
      ),
    );
    expect(
      (await store.remember(
        content: '来源是业务行',
        kindId: 'event',
        sourceRecordId: 'r1',
      )).epoch,
      0,
    );
    await commands.execute(
      WorkspaceCommand(
        operationId: 'op_del',
        actions: [
          WorkspaceMutation(
            actionId: 'row_r1',
            kind: WorkspaceEntityKind.dataRow,
            entityId: 'r1',
            mutation: WorkspaceMutationKind.delete,
            expectedVersion: 1,
            patch: {},
          ),
        ],
      ),
    );
    await expectLater(
      store.remember(content: '行已删除', kindId: 'event', sourceRecordId: 'r1'),
      throwsA(isA<MemoryPersistenceFailure>()),
    );
  });

  test('content, kind and confidence validation guards', () async {
    Future<void> reject(Future<Object?> Function() call) => expectLater(
      call(),
      throwsA(
        isA<MemoryPersistenceFailure>().having(
          (f) => f.code,
          'code',
          MemoryPersistenceFailureCode.validation,
        ),
      ),
    );
    await reject(() => store.remember(content: '  ', kindId: 'fact'));
    await reject(() => store.remember(content: 'a' * 10001, kindId: 'fact'));
    await reject(() => store.remember(content: 'ok', kindId: '不存在 的类型'));
    await reject(
      () => store.remember(content: 'ok', kindId: 'fact', confidence: 1.5),
    );
  });

  test('v10 upgrade keeps data and creates memory tables; foreign tables roll back', () async {
    await db.close();
    final migrationFile = File('${dir.path}/migration.sqlite');
    var raw = sqlite3.sqlite3.open(migrationFile.path);
    raw.execute(File('test/fixtures/local/schema_v10.sql').readAsStringSync());
    raw.execute("PRAGMA user_version = 10");
    raw.execute(
      "INSERT INTO local_profiles VALUES(1,'old-user','保留姓名',1,1700000000)",
    );
    raw.close();
    db = AppDatabase.background(migrationFile);
    final upgraded = SqliteMemoryPersistence(db);
    expect(await upgraded.list(), isEmpty);
    expect(await upgraded.epoch(), 0);
    expect(await upgraded.paused(), isFalse);
    expect((await db.loadOrCreateProfile()).nickname, '保留姓名');
    expect(
      (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
        'user_version',
      ),
      13,
    );
    await db.close();

    // A pre-existing foreign memory table aborts the migration atomically.
    final foreign = File('${dir.path}/foreign.sqlite');
    raw = sqlite3.sqlite3.open(foreign.path);
    raw.execute(File('test/fixtures/local/schema_v10.sql').readAsStringSync());
    raw.execute("PRAGMA user_version = 10");
    raw.execute(
      "INSERT INTO local_profiles VALUES(1,'old-user','保留姓名',1,1700000000)",
    );
    raw.execute('CREATE TABLE local_memories(alien TEXT)');
    raw.close();
    db = AppDatabase.background(foreign);
    await expectLater(db.select(db.localMemories).get(), throwsA(anything));
    await db.close();
    raw = sqlite3.sqlite3.open(foreign.path);
    expect(raw.select('PRAGMA user_version').single['user_version'], 10);
    expect(
      raw.select('SELECT nickname FROM local_profiles').single['nickname'],
      '保留姓名',
    );
    raw.close();
  });

  test(
    'keyword search: OR terms, recency rank, deleted excluded, bounded',
    () async {
      await store.remember(content: '用户偏好拿铁不加糖', kindId: 'preference');
      await store.remember(content: '用户每周三健身', kindId: 'event');
      final late = await store.remember(content: '拿铁相关的另类记录', kindId: 'fact');
      await store.delete(late.memoryId);

      final both = await store.search('拿铁 健身');
      expect(
        both.map((m) => m.content),
        unorderedEquals(['用户偏好拿铁不加糖', '用户每周三健身']),
      );

      final single = await store.search('拿铁');
      expect(single, hasLength(1));
      expect(single.single.content, '用户偏好拿铁不加糖');

      // bigram 命中活记忆是合法的；只断言已删除内容本身不出现。
      expect(
        (await store.search('拿铁相关的另类记录')).map((m) => m.content),
        isNot(contains('拿铁相关的另类记录')),
        reason: '已删除记忆不可被检索',
      );
      expect(await store.search('   '), isEmpty);
      final capped = await store.search('用户', limit: 1);
      // 超过 24 个 CJK bigram 的长句不得因占位符/参数数量不匹配而抛错。
      final long = await store.search('明天下午三点去公司开会然后整理季度报表顺便联系供应商确认发货时间安排');
      expect(long, isA<List<Object?>>());
      expect(capped, hasLength(1));
    },
  );
}
