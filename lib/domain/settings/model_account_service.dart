import 'dart:math';

import '../ai/model_gateway.dart';
import '../ai/model_router.dart';
import '../ai/quota.dart';
import 'model_accounts.dart';
import 'model_settings.dart';
import 'model_settings_service.dart';

/// 路由换用账户后的结果：换到了谁、原来那个为什么被跳过。
class RouteSwitch {
  const RouteSwitch(this.account, this.credential);
  final ModelAccount account;
  final ModelRuntimeCredential credential;
}

/// 多账户管理：保存、切换、删除、额度刷新、冷却与路由。
///
/// 所有写入都借用 [ModelSettingsService] 的串行队列，保持「同一时刻只有
/// 一个前台写者」。Key 只进系统安全存储，这里只传引用。
class ModelAccountService {
  ModelAccountService(
    this.settings,
    this.store, {
    this.quotas,
    DateTime Function()? clock,
  }) : _clock = clock ?? (() => DateTime.now().toUtc());

  final ModelSettingsService settings;
  final ModelAccountStore store;
  final QuotaGateway? quotas;
  final DateTime Function() _clock;

  static String _newId() {
    final random = Random.secure();
    return 'acct_${List.generate(12, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
  }

  Stream<ModelAccountsSnapshot> watch() => store.watch();

  Future<ModelAccountsSnapshot> load() => settings.exclusive(() async {
    await settings.sweepCredentials();
    return store.readAccounts();
  });

  /// 新建（[id] 为空）或修改账户。
  ///
  /// 换了服务商或区域必须重新填 Key：Key 不会悄悄跟到另一个端点。
  Future<ModelAccountsSnapshot> save({
    String? id,
    required ModelProfile profile,
    String? newKey,
    bool activate = false,
    bool? autoRoute,
  }) => settings.exclusive(() async {
    final before = await store.readAccounts();
    final existing = id == null ? null : before.byId(id);
    if (id != null && existing == null) {
      throw const SettingsFailure(SettingsFailureCode.conflict);
    }
    final key = newKey?.trim();
    if (key != null && !ModelSettingsService.isPlausibleKey(key)) {
      throw const SettingsFailure(SettingsFailureCode.validation);
    }
    final endpointChanged =
        existing != null &&
        (existing.profile.product != profile.product ||
            existing.profile.region != profile.region ||
            existing.profile.baseUrl != profile.baseUrl);
    if (key == null && (existing == null || endpointChanged)) {
      throw const SettingsFailure(SettingsFailureCode.missingKey);
    }
    var reference = existing?.credentialRef;
    if (key != null) {
      reference = ModelSettingsService.newCredentialReference();
      // 先登记待清理，再跨越非事务的安全存储：中途崩溃也不会留下孤儿 Key。
      await settings.store.stageCredential(reference);
      try {
        await settings.vault.write(reference, key);
      } catch (_) {
        await settings.sweepCredentials();
        rethrow;
      }
    }
    final account = ModelAccount(
      id: existing?.id ?? _newId(),
      profile: profile,
      credentialRef: reference,
      position: existing?.position ?? before.accounts.length,
      autoRoute: autoRoute ?? existing?.autoRoute ?? true,
      // 换了 Key 或端点，旧的冷却与额度不再适用。
      cooldownUntil: key == null ? existing?.cooldownUntil : null,
      cooldownReason: key == null ? existing?.cooldownReason : null,
      quota: key == null && !endpointChanged ? existing?.quota : null,
    );
    try {
      await store.saveAccount(
        account,
        // 第一个账户自动成为当前账户。
        activate: activate || before.accounts.isEmpty || before.active == null,
        expectedVersion: before.configuration.version,
      );
    } catch (_) {
      await settings.sweepCredentials();
      rethrow;
    }
    await settings.sweepCredentials();
    return store.readAccounts();
  });

  /// 切换当前账户，可同时换模型。已经是当前且模型未变时不做任何事。
  Future<ModelAccountsSnapshot> activate(String id, {String? model}) =>
      settings.exclusive(() => _activate(id, model: model));

  Future<ModelAccountsSnapshot> _activate(String id, {String? model}) async {
    final before = await store.readAccounts();
    final account = before.byId(id);
    if (account == null) {
      throw const SettingsFailure(SettingsFailureCode.conflict);
    }
    if (!account.hasCredential) {
      throw const SettingsFailure(SettingsFailureCode.missingKey);
    }
    final nextModel = model?.trim();
    final changed = nextModel != null && nextModel != account.profile.model;
    if (before.activeId == id && !changed) return before;
    return store.saveAccount(
      changed
          ? account.copyWith(
              profile: account.profile.copyWith(model: nextModel),
            )
          : account,
      activate: true,
      expectedVersion: before.configuration.version,
    );
  }

  Future<ModelAccountsSnapshot> setAutoRoute(String id, bool enabled) =>
      settings.exclusive(() async {
        final before = await store.readAccounts();
        final account = before.byId(id);
        if (account == null) {
          throw const SettingsFailure(SettingsFailureCode.conflict);
        }
        return store.saveAccount(
          account.copyWith(autoRoute: enabled),
          activate: false,
          expectedVersion: before.configuration.version,
        );
      });

  /// 按给定顺序重排优先级。未列出的账户保持相对顺序排在后面。
  Future<ModelAccountsSnapshot> reorder(List<String> ids) =>
      settings.exclusive(() async {
        var snapshot = await store.readAccounts();
        final ordered = [
          for (final id in ids) ?snapshot.byId(id),
          for (final account in snapshot.accounts)
            if (!ids.contains(account.id)) account,
        ];
        for (var index = 0; index < ordered.length; index++) {
          if (ordered[index].position == index) continue;
          snapshot = await store.saveAccount(
            ordered[index].copyWith(position: index),
            activate: false,
            expectedVersion: snapshot.configuration.version,
          );
        }
        return snapshot;
      });

  /// 删除账户及其 Key。删掉当前账户后，自动改用下一个有 Key 的账户。
  Future<ModelAccountsSnapshot> remove(String id) =>
      settings.exclusive(() async {
        final before = await store.readAccounts();
        var after = await store.removeAccount(
          id,
          expectedVersion: before.configuration.version,
        );
        if (after.active == null) {
          final fallback = after.accounts
              .where((account) => account.hasCredential)
              .firstOrNull;
          if (fallback != null) after = await _activate(fallback.id);
        }
        await settings.sweepCredentials();
        return after;
      });

  Future<String> _secret(ModelAccount account) async {
    final reference = account.credentialRef;
    final secret = reference == null
        ? null
        : await settings.vault.read(reference);
    if (secret == null || secret.isEmpty) {
      throw const SettingsFailure(SettingsFailureCode.missingKey);
    }
    return secret;
  }

  /// 用已保存的 Key 发一次最小请求，确认账户可用。
  Future<ModelCompleted> test(String id, ModelCancellation cancellation) async {
    final (account, secret) = await settings.exclusive(() async {
      final account = (await store.readAccounts()).byId(id);
      if (account == null) {
        throw const SettingsFailure(SettingsFailureCode.conflict);
      }
      return (account, await _secret(account));
    });
    return settings.testDraft(
      profile: account.profile,
      cancellation: cancellation,
      key: secret,
    );
  }

  /// 测试尚未保存的草稿。没填新 Key 时，只有端点没变才沿用账户已存的 Key。
  Future<ModelCompleted> testDraft({
    String? id,
    required ModelProfile profile,
    required ModelCancellation cancellation,
    String? key,
  }) async {
    final secret = await _draftKey(
      id,
      profile.product,
      profile.region,
      profile.baseUrl,
      key,
    );
    return settings.testDraft(
      profile: profile,
      cancellation: cancellation,
      key: secret,
    );
  }

  Future<String> _draftKey(
    String? id,
    ProviderKind product,
    ProviderRegion region,
    String? baseUrl,
    String? key,
  ) async {
    var secret = key?.trim();
    if (secret == null || secret.isEmpty) {
      secret = await settings.exclusive<String>(() async {
        final account = id == null
            ? null
            : (await store.readAccounts()).byId(id);
        if (account == null ||
            account.profile.product != product ||
            account.profile.region != region ||
            account.profile.baseUrl != baseUrl) {
          throw const SettingsFailure(SettingsFailureCode.missingKey);
        }
        return _secret(account);
      });
    }
    if (!ModelSettingsService.isPlausibleKey(secret)) {
      throw const SettingsFailure(SettingsFailureCode.validation);
    }
    return secret;
  }

  Future<List<String>> availableModels({
    String? id,
    required ProviderKind product,
    required ProviderRegion region,
    String? baseUrl,
    String? key,
    required ModelCancellation cancellation,
  }) async {
    final descriptor = ProviderCatalog.of(product);
    final base = Uri.tryParse(
      descriptor.baseFor(region, customBase: baseUrl) ?? '',
    );
    final directory = settings.gateway;
    if (base == null ||
        base.scheme != 'https' ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        directory is! ModelDirectory) {
      throw const ModelFailure(ModelFailureCode.configuration);
    }
    final secret = await _draftKey(id, product, region, baseUrl, key);
    if (cancellation.isCancelled) {
      throw const ModelFailure(ModelFailureCode.cancelled);
    }
    return (directory as ModelDirectory).listModels(
      descriptor.resolve(region, 'models', customBase: baseUrl),
      apiKey: secret,
      cancellation: cancellation,
    );
  }

  /// 向服务商查询额度并缓存。没有额度接口的服务商抛 configuration。
  Future<QuotaSnapshot> refreshQuota(String id) async {
    final gateway = quotas;
    if (gateway == null) {
      throw const ModelFailure(ModelFailureCode.configuration);
    }
    final (account, secret) = await settings.exclusive(() async {
      final account = (await store.readAccounts()).byId(id);
      if (account == null) {
        throw const SettingsFailure(SettingsFailureCode.conflict);
      }
      return (account, await _secret(account));
    });
    final now = _clock();
    final quota = await gateway.fetch(
      account.profile,
      apiKey: secret,
      now: now,
    );
    await store.recordQuota(id, quota);
    // 额度有余量说明之前的「额度用尽」冷却已经过期。
    if (!quota.exhausted && account.coolingAt(now)) {
      await store.recordCooldown(id);
    }
    return quota;
  }

  /// 一次失败后让账户暂停。有额度缓存且给出重置时间时，冷却到重置为止。
  Future<void> penalize(String id, FailoverAdvice advice) async {
    final now = _clock();
    final account = (await store.readAccounts()).byId(id);
    if (account == null) return;
    var until = now.add(advice.cooldown);
    final recovers = account.quota?.recoversAt;
    if (recovers != null && recovers.isAfter(now)) until = recovers;
    await store.recordCooldown(id, until: until, reason: advice.reason);
  }

  Future<void> clearCooldown(String id) => store.recordCooldown(id);

  /// 路由：挑一个能用的账户并切换过去，返回它的运行凭据。
  ///
  /// [exclude] 是本轮已经试过的账户。没有候选时返回 null，由调用方
  /// 如实报告失败，绝不假装成功。
  Future<RouteSwitch?> route({
    bool needsVision = false,
    Set<String> exclude = const {},
  }) => settings.exclusive(() async {
    final snapshot = await store.readAccounts();
    final ranked = ModelRouter.candidates(
      snapshot.accounts,
      now: _clock(),
      needsVision: needsVision,
      exclude: exclude,
    );
    for (final account in ranked) {
      final String secret;
      try {
        secret = await _secret(account);
      } on SettingsFailure {
        continue;
      }
      final after = await _activate(account.id);
      return RouteSwitch(
        after.byId(account.id)!,
        ModelRuntimeCredential(after.configuration, secret),
      );
    }
    return null;
  });
}
