import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/model_account_store.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/ai/model_router.dart';
import 'package:towork/domain/ai/quota.dart';
import 'package:towork/domain/settings/model_account_service.dart';
import 'package:towork/domain/settings/model_settings.dart';
import 'package:towork/domain/settings/model_settings_service.dart';

import '../../support/free/fake_model_gateway.dart';

class _Quotas implements QuotaGateway {
  QuotaSnapshot? next;
  ModelFailure? failure;
  final seen = <String>[];
  @override
  Future<QuotaSnapshot> fetch(
    ModelProfile profile, {
    required String apiKey,
    required DateTime now,
  }) async {
    seen.add('${profile.product.wireId}:$apiKey');
    if (failure != null) throw failure!;
    return next ??
        QuotaSnapshot(fetchedAt: now, balance: 12.5, currency: 'CNY');
  }
}

void main() {
  late Directory dir;
  late File file;
  late AppDatabase db;
  late FakeKeyVault vault;
  late _Quotas quotas;
  late ModelAccountService service;
  var now = DateTime.utc(2026, 11, 13, 8);

  final kimi = ModelProfile(
    model: 'kimi-for-coding',
    product: ProviderKind.kimiCode,
    disableThinking: true,
  );
  final glm = ModelProfile(
    model: 'glm-5.3',
    product: ProviderKind.zhipuCoding,
    disableThinking: true,
  );
  final deepseek = ModelProfile(
    model: 'deepseek-flash',
    product: ProviderKind.deepseek,
    disableThinking: true,
  );

  ModelAccountService open() => ModelAccountService(
    ModelSettingsService(db, vault, FakeKimiGateway()),
    SqliteModelAccountStore(db),
    quotas: quotas,
    clock: () => now,
  );

  setUp(() async {
    now = DateTime.utc(2026, 11, 13, 8);
    dir = await Directory.systemTemp.createTemp('towork-accounts-test-');
    file = File('${dir.path}/app.sqlite');
    db = AppDatabase.background(file);
    vault = FakeKeyVault();
    quotas = _Quotas();
    service = open();
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  test('first account becomes active; keys stay out of SQLite', () async {
    final first = await service.save(profile: kimi, newKey: 'kimi-secret');
    expect(first.accounts, hasLength(1));
    expect(first.activeId, first.accounts.single.id);
    expect(first.configuration.version, 1);
    expect(first.configuration.profile.product, ProviderKind.kimiCode);
    expect(first.configuration.credentialRef, isNotNull);

    final second = await service.save(profile: glm, newKey: 'glm-secret');
    expect(second.accounts, hasLength(2));
    // 新增账户不抢占当前账户，也不让进行中的对话失效。
    expect(second.activeId, first.activeId);
    expect(second.configuration.version, 1);
    expect(vault.values.values, unorderedEquals(['kimi-secret', 'glm-secret']));
    expect(await db.pendingCleanup(), isEmpty);

    await db.close();
    final bytes = await file
        .readAsString(encoding: const SystemEncoding())
        .catchError((_) => String.fromCharCodes(file.readAsBytesSync()));
    expect(bytes, isNot(contains('kimi-secret')));
    expect(bytes, isNot(contains('glm-secret')));
    db = AppDatabase.background(file);
    service = open();
    expect((await service.load()).accounts, hasLength(2));
  });

  test('switching accounts keeps both keys and bumps the version', () async {
    await service.save(profile: kimi, newKey: 'kimi-secret');
    final added = await service.save(profile: glm, newKey: 'glm-secret');
    final glmId = added.accounts.last.id;

    final switched = await service.activate(glmId);
    expect(switched.activeId, glmId);
    expect(switched.configuration.version, 2);
    expect(switched.configuration.profile.model, 'glm-5.3');
    expect(switched.configuration.profile.revision, 2);
    // 切走不等于删除：原账户的 Key 仍在，随时可以切回。
    expect(vault.values.values, unorderedEquals(['kimi-secret', 'glm-secret']));
    expect(await db.pendingCleanup(), isEmpty);

    // 已经是当前账户且模型未变：不产生新版本。
    expect((await service.activate(glmId)).configuration.version, 2);
    final model = await service.activate(glmId, model: 'glm-5.3-flash');
    expect(model.configuration.version, 3);
    expect(model.byId(glmId)!.profile.model, 'glm-5.3-flash');
  });

  test('a new endpoint requires its own key', () async {
    final saved = await service.save(profile: kimi, newKey: 'kimi-secret');
    await expectLater(
      service.save(id: saved.activeId, profile: deepseek),
      throwsA(
        isA<SettingsFailure>().having(
          (f) => f.code,
          'code',
          SettingsFailureCode.missingKey,
        ),
      ),
    );
    await expectLater(
      service.save(profile: deepseek),
      throwsA(isA<SettingsFailure>()),
    );
    await expectLater(
      service.save(profile: deepseek, newKey: 'has space'),
      throwsA(
        isA<SettingsFailure>().having(
          (f) => f.code,
          'code',
          SettingsFailureCode.validation,
        ),
      ),
    );
    expect((await service.load()).accounts, hasLength(1));
    expect(vault.values.values, ['kimi-secret']);
  });

  test('rotating a key deletes only the replaced secret', () async {
    final saved = await service.save(profile: kimi, newKey: 'old-secret');
    await service.save(profile: glm, newKey: 'glm-secret');
    final rotated = await service.save(
      id: saved.activeId,
      profile: kimi,
      newKey: 'new-secret',
    );
    expect(rotated.configuration.version, 2);
    expect(vault.values.values, unorderedEquals(['new-secret', 'glm-secret']));
    expect(await db.pendingCleanup(), isEmpty);
  });

  test('failed vault write leaves accounts untouched', () async {
    await service.save(profile: kimi, newKey: 'kimi-secret');
    vault.failWrite = true;
    await expectLater(
      service.save(profile: glm, newKey: 'glm-secret'),
      throwsA(isA<SettingsFailure>()),
    );
    vault.failWrite = false;
    final after = await service.load();
    expect(after.accounts, hasLength(1));
    expect(after.configuration.version, 1);
    expect(await db.pendingCleanup(), isEmpty);
  });

  test('removing the active account falls back to the next one', () async {
    final first = await service.save(profile: kimi, newKey: 'kimi-secret');
    await service.save(profile: glm, newKey: 'glm-secret');
    final after = await service.remove(first.activeId!);
    expect(after.accounts, hasLength(1));
    expect(after.active!.profile.product, ProviderKind.zhipuCoding);
    expect(after.configuration.credentialRef, after.active!.credentialRef);
    expect(vault.values.values, ['glm-secret']);

    final empty = await service.remove(after.activeId!);
    expect(empty.accounts, isEmpty);
    expect(empty.configuration.credentialRef, isNull);
    expect(vault.values, isEmpty);
  });

  test('legacy single-configuration save keeps the account in sync', () async {
    final settings = service.settings;
    final saved = await settings.save(
      profile: kimi,
      expectedVersion: 0,
      newKey: 'legacy-secret',
    );
    var accounts = await service.load();
    expect(accounts.accounts, hasLength(1));
    expect(accounts.active!.credentialRef, saved.configuration.credentialRef);

    await settings.save(
      profile: ModelProfile(
        model: 'kimi-for-coding-highspeed',
        product: ProviderKind.kimiCode,
        disableThinking: true,
      ),
      expectedVersion: 1,
    );
    accounts = await service.load();
    expect(accounts.accounts, hasLength(1));
    expect(accounts.active!.profile.model, 'kimi-for-coding-highspeed');

    await settings.deleteKey(expectedVersion: 2);
    accounts = await service.load();
    expect(accounts.active!.hasCredential, isFalse);
    expect(vault.values, isEmpty);
  });

  test('custom base URL survives save, activation and reload', () async {
    final custom = ModelProfile(
      model: 'gpt-x',
      product: ProviderKind.custom,
      baseUrl: 'https://relay.example.com/v1',
    );
    final saved = await service.save(profile: custom, newKey: 'relay-secret');
    expect(
      saved.configuration.profile.completionsUri.toString(),
      'https://relay.example.com/v1/chat/completions',
    );
    await db.close();
    db = AppDatabase.background(file);
    service = open();
    final restored = await service.load();
    expect(restored.active!.profile.baseUrl, 'https://relay.example.com/v1');
    expect(
      restored.configuration.profile.baseUrl,
      'https://relay.example.com/v1',
    );
  });

  test('quota refresh is cached and clears an expired cooldown', () async {
    final saved = await service.save(profile: deepseek, newKey: 'ds-secret');
    final id = saved.activeId!;
    await service.penalize(id, ModelRouter.adviceFor(ModelFailureCode.quota)!);
    expect((await service.load()).byId(id)!.coolingAt(now), isTrue);

    final quota = await service.refreshQuota(id);
    expect(quota.balance, 12.5);
    expect(quotas.seen.single, 'deepseek:ds-secret');
    final after = (await service.load()).byId(id)!;
    expect(after.quota!.balance, 12.5);
    expect(after.coolingAt(now), isFalse);
    // 额度与冷却是观测数据，不让进行中的对话失效。
    expect((await service.load()).configuration.version, 1);
  });

  test('routing skips exhausted accounts and follows priority', () async {
    final first = await service.save(profile: kimi, newKey: 'kimi-secret');
    final kimiId = first.activeId!;
    final second = await service.save(profile: glm, newKey: 'glm-secret');
    final glmId = second.accounts.last.id;
    final third = await service.save(profile: deepseek, newKey: 'ds-secret');
    final dsId = third.accounts.last.id;

    // 都可用：按优先级选第一个，已经是当前账户则不产生新版本。
    var routed = await service.route();
    expect(routed!.account.id, kimiId);
    expect(routed.credential.secret, 'kimi-secret');
    expect(routed.credential.configuration.version, 1);

    // 第一个额度用尽：换到第二个，并冷却到额度重置。
    final reset = now.add(const Duration(hours: 3));
    quotas.next = QuotaSnapshot(
      fetchedAt: now,
      windows: [QuotaWindow(label: '5 小时', usedRatio: 1, resetAt: reset)],
    );
    await service.refreshQuota(kimiId);
    await service.penalize(
      kimiId,
      ModelRouter.adviceFor(ModelFailureCode.quota)!,
    );
    expect((await service.load()).byId(kimiId)!.cooldownUntil, reset);
    routed = await service.route(exclude: {kimiId});
    expect(routed!.account.id, glmId);
    expect(routed.credential.secret, 'glm-secret');
    expect(routed.credential.configuration.version, 2);
    expect(routed.credential.configuration.profile.revision, 2);

    // 要看图：GLM-5.3 不支持图片，跳到 DeepSeek Flash。
    routed = await service.route(needsVision: true);
    expect(routed!.account.id, dsId);

    // 冷却过期且额度缓存的重置时间已过：第一个重新可用。
    now = reset.add(const Duration(minutes: 1));
    routed = await service.route();
    expect(routed!.account.id, kimiId);

    // 不参与路由的账户永远不会被自动选中。
    await service.setAutoRoute(kimiId, false);
    await service.setAutoRoute(glmId, false);
    await service.setAutoRoute(dsId, false);
    expect(await service.route(), isNull);
  });

  test('v12 upgrade turns the single configuration into an account', () async {
    final migration = File('${dir.path}/migration.sqlite');
    final raw = sqlite3.sqlite3.open(migration.path);
    raw.execute(File('test/fixtures/local/schema_v12.sql').readAsStringSync());
    raw.execute('PRAGMA user_version = 12');
    raw.execute(
      "INSERT INTO provider_configurations VALUES(1,'code','china',"
      "'kimi-for-coding',1,7,'towork.kimi.abc')",
    );
    raw.close();
    vault.values['towork.kimi.abc'] = 'kept-secret';
    final upgraded = AppDatabase.background(migration);
    addTearDown(upgraded.close);
    final accounts = ModelAccountService(
      ModelSettingsService(upgraded, vault, FakeKimiGateway()),
      SqliteModelAccountStore(upgraded),
    );
    final snapshot = await accounts.load();
    expect(
      (await upgraded.customSelect('PRAGMA user_version').getSingle())
          .read<int>('user_version'),
      13,
    );
    expect(snapshot.accounts.single.id, AppDatabase.migratedAccountId);
    expect(snapshot.activeId, AppDatabase.migratedAccountId);
    expect(snapshot.active!.profile.product, ProviderKind.kimiCode);
    expect(snapshot.active!.credentialRef, 'towork.kimi.abc');
    // 升级不动版本号与 Key：用户无需重新填写，旧对话仍可继续。
    expect(snapshot.configuration.version, 7);
    expect(vault.values['towork.kimi.abc'], 'kept-secret');
    expect((await accounts.route())!.credential.secret, 'kept-secret');
  });

  test('v12 upgrade without a configuration creates no account', () async {
    final migration = File('${dir.path}/empty.sqlite');
    final raw = sqlite3.sqlite3.open(migration.path);
    raw.execute(File('test/fixtures/local/schema_v12.sql').readAsStringSync());
    raw.execute('PRAGMA user_version = 12');
    raw.close();
    final upgraded = AppDatabase.background(migration);
    addTearDown(upgraded.close);
    final snapshot = await SqliteModelAccountStore(upgraded).readAccounts();
    expect(snapshot.accounts, isEmpty);
    expect(snapshot.activeId, isNull);
  });
}
