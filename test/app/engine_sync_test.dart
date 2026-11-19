import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/engine_sync.dart';
import 'package:towork/data/local/agent_run_store.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/app_preferences_store.dart';
import 'package:towork/data/local/chat_persistence.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/assist/quick_assist.dart';

class _Peers implements EnginePeers {
  bool others = false;
  AssistHandoff? handoff;
  int asked = 0;

  @override
  Future<bool> othersAlive() async {
    asked++;
    return others;
  }

  @override
  Future<AssistHandoff?> takeHandoff() async {
    final value = handoff;
    handoff = null;
    return value;
  }
}

/// 轮询到条件成立；这里的等待都跨越真实的数据库隔离区往返。
Future<void> _until(bool Function() done) async {
  final limit = DateTime.now().add(const Duration(seconds: 5));
  while (!done()) {
    if (DateTime.now().isAfter(limit)) fail('条件在 5 秒内没有成立');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  late Directory dir;
  late File file;

  /// 本引擎的连接，以及代表另一个引擎的第二条连接。
  late AppDatabase db;
  late AppDatabase other;
  late _Peers peers;
  late int refreshed;
  late bool busy;
  late List<AssistHandoff> handoffs;
  late EngineSync sync;

  // 两条连接各有自己的执行器，对应两个引擎各开一次库；drift 的提醒针对的是
  // 共用同一个执行器的情况，这里不适用。
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  tearDownAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('engine-sync');
    file = File('${dir.path}/db.sqlite');
    db = AppDatabase.background(file);
    other = AppDatabase.background(file);
    peers = _Peers();
    refreshed = 0;
    busy = false;
    handoffs = [];
    sync = EngineSync(
      db: db,
      peers: peers,
      refresh: () async => refreshed++,
      busy: () => busy,
      onHandoff: handoffs.add,
      interval: const Duration(milliseconds: 20),
    );
  });
  tearDown(() async {
    sync.dispose();
    await db.close();
    await other.close();
    await dir.delete(recursive: true);
  });

  Future<AgentRun> prepare(AppDatabase target, String input) async =>
      (await ChatPersistence(target).prepare(
        inputId: input,
        content: '内容 $input',
        profile: ModelProfile(model: 'fixture'),
        agentEnabled: false,
      )).run;

  Future<AgentRun> generating(AppDatabase target, String input) async {
    final run = await prepare(target, input);
    return SqliteAgentRunStore(target).save(
      run.next(AgentRunStatus.generating, round: 1),
      expectedRevision: run.revision,
    );
  }

  test('两个引擎同时首次建库、创建身份和偏好均成功且只有一份', () async {
    await Future.wait([
      db.customSelect('SELECT 1').get(),
      other.customSelect('SELECT 1').get(),
    ]);
    final profiles = await Future.wait([
      db.loadOrCreateProfile(),
      other.loadOrCreateProfile(),
    ]);
    expect(profiles.first.id, profiles.last.id);
    final preferences = await Future.wait([
      SqliteAppPreferencesStore(db).loadOrCreate(),
      SqliteAppPreferencesStore(other).loadOrCreate(),
    ]);
    expect(preferences.first.version, preferences.last.version);
    expect(await db.select(db.localProfiles).get(), hasLength(1));
    expect(await db.select(db.appPreferenceRows).get(), hasLength(1));
    expect(
      (await other.customSelect('PRAGMA user_version').getSingle())
          .data
          .values
          .single,
      13,
    );
  });

  test('另一条连接提交后，监听查询重跑并重读会话', () async {
    final counts = <int>[];
    final subscription = db
        .select(db.agentRunRows)
        .watch()
        .listen((rows) => counts.add(rows.length));
    addTearDown(subscription.cancel);
    await _until(() => counts.isNotEmpty);
    expect(counts, [0]);

    await sync.check();
    expect(refreshed, 0, reason: '第一次只记下基线');

    await prepare(other, 'from-panel');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(counts, [0], reason: '别的连接的提交不会自己唤醒监听查询');

    await sync.check();
    expect(refreshed, 1);
    await _until(() => counts.last == 1);

    await sync.check();
    expect(refreshed, 1, reason: '没有新的外部提交就不重读');
  });

  test('自己这条连接的提交不算外部变化', () async {
    await sync.check();
    await prepare(db, 'from-self');
    await sync.check();
    expect(refreshed, 0);
  });

  test('另一个引擎活着时不动「生成中」的运行', () async {
    final run = await generating(db, 'in-flight');
    peers.others = true;
    await sync.check();
    expect(
      (await SqliteAgentRunStore(db).read(run.id)).status,
      AgentRunStatus.generating,
    );
    sync.setActive(false);
  });

  test('自己正在生成时不动「生成中」的运行', () async {
    final run = await generating(db, 'mine');
    busy = true;
    await sync.check();
    expect(
      (await SqliteAgentRunStore(db).read(run.id)).status,
      AgentRunStatus.generating,
    );
  });

  test('没有别的引擎、自己也空闲时，遗留的「生成中」标为中断', () async {
    await sync.check();
    final run = await generating(other, 'abandoned');
    await sync.check();
    expect(
      (await SqliteAgentRunStore(db).read(run.id)).status,
      AgentRunStatus.interrupted,
    );
    expect(refreshed, 1);
  });

  test('交接只送达一次', () async {
    peers.handoff = const AssistHandoff(sessionId: 's1', location: '/todos');
    await sync.check();
    await sync.check();
    expect(handoffs, hasLength(1));
    expect(handoffs.single.sessionId, 's1');
    expect(handoffs.single.location, '/todos');
  });

  test('另一个引擎活着时按间隔继续比较，它退出后停止', () async {
    peers.others = true;
    sync.setActive(true);
    await _until(() => peers.asked >= 4);

    peers.others = false;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final settled = peers.asked;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(peers.asked, settled);
  });

  test('退到后台后不再比较', () async {
    peers.others = true;
    sync.setActive(true);
    await _until(() => peers.asked >= 2);
    sync.setActive(false);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final settled = peers.asked;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(peers.asked, settled);
  });

  test('同时触发的比较不并发执行，也不丢掉后来的那次', () async {
    await sync.check();
    await prepare(other, 'burst');
    await Future.wait([sync.check(), sync.check(), sync.check()]);
    expect(refreshed, 1);
  });

  test('数据库不可用时不抛出，留给下次再试', () async {
    final closed = AppDatabase.background(File('${dir.path}/closed.sqlite'));
    await closed.customSelect('SELECT 1').get();
    await closed.close();
    final broken = EngineSync(
      db: closed,
      peers: peers,
      refresh: () async => refreshed++,
      busy: () => false,
      onHandoff: handoffs.add,
    );
    addTearDown(broken.dispose);
    await broken.check();
    expect(refreshed, 0);
  });

  test('刷新失败后仍轮询同一次提交，成功后才送达交接', () async {
    var failRefresh = true;
    var attempts = 0;
    final retrying = EngineSync(
      db: db,
      peers: peers,
      refresh: () async {
        attempts++;
        if (failRefresh) throw StateError('transient refresh');
        refreshed++;
      },
      busy: () => false,
      onHandoff: handoffs.add,
      interval: const Duration(milliseconds: 20),
    );
    addTearDown(retrying.dispose);
    await retrying.check();
    await prepare(other, 'retry-refresh');
    peers.handoff = const AssistHandoff(sessionId: 'pending');
    retrying.setActive(true);
    await _until(() => attempts >= 2);
    expect(handoffs, isEmpty);
    failRefresh = false;
    await _until(() => handoffs.isNotEmpty);
    expect(refreshed, greaterThan(0));
    expect(handoffs.single.sessionId, 'pending');
  });

  test('首次交接刷新失败仍保留已经取走的交接', () async {
    var failRefresh = true;
    final retrying = EngineSync(
      db: db,
      peers: peers,
      refresh: () async {
        if (failRefresh) throw StateError('transient refresh');
        refreshed++;
      },
      busy: () => false,
      onHandoff: handoffs.add,
    );
    addTearDown(retrying.dispose);
    peers.handoff = const AssistHandoff(sessionId: 'cold-start');
    await retrying.check();
    expect(peers.handoff, isNull);
    expect(handoffs, isEmpty);
    failRefresh = false;
    await retrying.check();
    expect(refreshed, 1);
    expect(handoffs.single.sessionId, 'cold-start');
    await retrying.check();
    expect(handoffs, hasLength(1));
  });
}
