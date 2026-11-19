import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/local_chat_runtime.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/app_preferences_store.dart';
import 'package:towork/data/local/chat_persistence.dart';
import 'package:towork/data/repositories/todo_repository.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/settings/model_settings_service.dart';
import 'package:towork/app/chat/live_chat_view_model.dart';

import '../../support/free/fake_model_gateway.dart';

/// 按 Key 决定成败的假模型：模拟「这个账户额度用尽、那个账户正常」。
class _KeyedModel implements ModelGateway {
  final failures = <String, ModelFailureCode>{};
  final calls = <String>[];
  @override
  Stream<ModelEvent> stream(
    ModelRequest request, {
    required String apiKey,
    ModelCancellation? cancellation,
  }) async* {
    calls.add('$apiKey:${request.profile.model}');
    final failure = failures[apiKey];
    if (failure != null) throw ModelFailure(failure);
    yield ModelCompleted(
      assistantMessage: {
        'role': 'assistant',
        'content': '由 ${request.profile.model} 回答',
      },
      finishReason: 'stop',
    );
  }
}

Future<void> _idle(LiveChatViewModel vm) async {
  for (var i = 0; i < 400 && vm.snapshot.isGenerating; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(vm.snapshot.isGenerating, isFalse);
}

void main() {
  late Directory directory;
  late AppDatabase db;
  late FakeKeyVault vault;
  late _KeyedModel model;
  late LocalChatRuntime runtime;
  late LiveChatViewModel vm;
  late TodoRepository todos;
  var auto = true;
  String? selected;
  late String kimiId, glmId, dsId;

  setUp(() async {
    auto = true;
    selected = null;
    directory = await Directory.systemTemp.createTemp('failover-test');
    db = AppDatabase.background(File('${directory.path}/chat.sqlite'));
    vault = FakeKeyVault();
    model = _KeyedModel();
    final settings = ModelSettingsService(db, vault, model);
    await SqliteAppPreferencesStore(db).loadOrCreate();
    runtime = LocalChatRuntime(
      db,
      settings,
      await ChatPersistence(db).load(),
      await db.readConfiguration(),
    );
    final accounts = runtime.accounts;
    kimiId = (await accounts.save(
      profile: ModelProfile(
        model: 'kimi-for-coding',
        product: ProviderKind.kimiCode,
        disableThinking: true,
      ),
      newKey: 'kimi-key',
    )).activeId!;
    glmId = (await accounts.save(
      profile: ModelProfile(
        model: 'glm-5.3',
        product: ProviderKind.zhipuCoding,
        disableThinking: true,
      ),
      newKey: 'glm-key',
    )).accounts.last.id;
    dsId = (await accounts.save(
      profile: ModelProfile(
        model: 'deepseek-flash',
        product: ProviderKind.deepseek,
        disableThinking: true,
      ),
      newKey: 'ds-key',
    )).accounts.last.id;
    todos = TodoRepository(initial: []);
    vm = LiveChatViewModel(
      runtime: runtime,
      autoRoute: () => auto,
      todos: todos,
      currentSession: () => selected,
      selectSession: (id) => selected = id,
    );
  });
  tearDown(() async {
    vm.dispose();
    todos.dispose();
    await runtime.dispose();
    runtime.projection.dispose();
    await db.close();
    await directory.delete(recursive: true);
  });

  AgentRun lastRun() => runtime.projection.data.turns.last.run;

  test('exhausted account fails over to the next and tells the user', () async {
    model.failures['kimi-key'] = ModelFailureCode.quota;
    expect(
      await vm.sendPersisted('你好', model: 'auto', agentEnabled: false),
      isTrue,
    );
    await _idle(vm);

    expect(model.calls, ['kimi-key:kimi-for-coding', 'glm-key:glm-5.3']);
    final run = lastRun();
    expect(run.status, AgentRunStatus.succeeded);
    // 运行被改绑到真正回答的模型，记录如实反映是谁答的。
    expect(run.profile.model, 'glm-5.3');
    expect(run.profile.product, ProviderKind.zhipuCoding);
    expect(vm.snapshot.error, isNull);
    expect(vm.snapshot.notice, 'Kimi K2.8额度已用尽，已改用 GLM-5.3');

    final accounts = await runtime.accounts.load();
    expect(accounts.activeId, glmId);
    expect(accounts.byId(kimiId)!.cooldownReason, '额度已用尽');
    expect(accounts.byId(kimiId)!.coolingAt(DateTime.now().toUtc()), isTrue);

    // 冷却期内的下一条消息直接走备用账户，不再去撞用尽的那个。
    model.calls.clear();
    expect(
      await vm.sendPersisted('再问一句', model: 'auto', agentEnabled: false),
      isTrue,
    );
    await _idle(vm);
    expect(model.calls, ['glm-key:glm-5.3']);
    expect(vm.snapshot.notice, isNull);
  });

  test(
    'every account is tried at most once; the real failure is kept',
    () async {
      model.failures['kimi-key'] = ModelFailureCode.quota;
      model.failures['glm-key'] = ModelFailureCode.authentication;
      model.failures['ds-key'] = ModelFailureCode.rateLimited;
      expect(
        await vm.sendPersisted('你好', model: 'auto', agentEnabled: false),
        isTrue,
      );
      await _idle(vm);

      expect(model.calls, [
        'kimi-key:kimi-for-coding',
        'glm-key:glm-5.3',
        'ds-key:deepseek-flash',
      ]);
      final run = lastRun();
      expect(run.status, AgentRunStatus.failed);
      expect(run.failureCode, 'model_rateLimited');
      final accounts = await runtime.accounts.load();
      expect(accounts.byId(glmId)!.cooldownReason, 'Key 无效');
      expect(accounts.byId(dsId)!.cooldownReason, '请求过于频繁');
    },
  );

  test('network failures never switch accounts', () async {
    model.failures['kimi-key'] = ModelFailureCode.network;
    expect(
      await vm.sendPersisted('你好', model: 'auto', agentEnabled: false),
      isTrue,
    );
    await _idle(vm);
    expect(model.calls, ['kimi-key:kimi-for-coding']);
    expect(lastRun().failureCode, 'model_network');
    final accounts = await runtime.accounts.load();
    expect(accounts.activeId, kimiId);
    expect(accounts.byId(kimiId)!.cooldownUntil, isNull);
    expect(vm.snapshot.notice, isNull);
  });

  test(
    'manual mode never switches; retry follows the newly picked model',
    () async {
      auto = false;
      model.failures['kimi-key'] = ModelFailureCode.quota;
      expect(
        await vm.sendPersisted('你好', model: 'manual', agentEnabled: false),
        isTrue,
      );
      await _idle(vm);
      expect(model.calls, ['kimi-key:kimi-for-coding']);
      expect(lastRun().failureCode, 'model_quota');
      expect((await runtime.accounts.load()).activeId, kimiId);

      // 用户自己换到另一个账户后点「重试」：同一条输入由新模型回答。
      await runtime.accounts.activate(dsId);
      final failedRun = lastRun().id;
      await vm.resumeRun(failedRun, retry: true);
      await _idle(vm);
      expect(model.calls.last, 'ds-key:deepseek-flash');
      final run = lastRun();
      expect(run.id, failedRun);
      expect(run.status, AgentRunStatus.succeeded);
      expect(run.profile.model, 'deepseek-flash');
      expect(runtime.projection.data.turns, hasLength(1));
    },
  );

  test('only failed runs can be rebound to another model', () async {
    expect(
      await vm.sendPersisted('你好', model: 'auto', agentEnabled: false),
      isTrue,
    );
    await _idle(vm);
    final run = lastRun();
    expect(run.status, AgentRunStatus.succeeded);
    await expectLater(
      runtime.rebind(
        run,
        ModelProfile(model: 'deepseek-flash', product: ProviderKind.deepseek),
      ),
      throwsA(
        isA<AgentFailure>().having(
          (f) => f.code,
          'code',
          AgentFailureCode.conflict,
        ),
      ),
    );
    expect((await runtime.runs.read(run.id)).profile.model, 'kimi-for-coding');
  });
}
