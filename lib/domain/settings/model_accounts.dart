import '../ai/model_gateway.dart';
import '../ai/quota.dart';
import 'model_settings.dart';

/// 一个已保存的模型账户：服务商 + 模型 + 自己的 Key（只存引用）。
/// 可以保存多个，其中一个是当前使用的。
class ModelAccount {
  ModelAccount({
    required this.id,
    required this.profile,
    this.credentialRef,
    this.position = 0,
    this.autoRoute = true,
    this.cooldownUntil,
    this.cooldownReason,
    this.quota,
  }) {
    if (id.isEmpty || id.length > 80 || position < 0) {
      throw const SettingsFailure(SettingsFailureCode.validation);
    }
  }

  final String id;

  /// 这里的 revision 没有意义；激活时由当前配置版本重新赋值。
  final ModelProfile profile;
  final String? credentialRef;

  /// 路由优先级，越小越优先。
  final int position;

  /// 是否参与自动路由。关闭后只能手动选用。
  final bool autoRoute;

  /// 冷却到这个时间之前，路由不会选它（额度用尽、Key 失效等）。
  final DateTime? cooldownUntil;
  final String? cooldownReason;

  /// 最近一次查询到的额度，启动时先显示它再刷新。
  final QuotaSnapshot? quota;

  bool get hasCredential => credentialRef != null;
  ProviderDescriptor get descriptor => profile.descriptor;

  bool coolingAt(DateTime now) =>
      cooldownUntil != null && cooldownUntil!.isAfter(now);

  ModelAccount copyWith({
    ModelProfile? profile,
    String? credentialRef,
    bool clearCredential = false,
    int? position,
    bool? autoRoute,
    DateTime? cooldownUntil,
    String? cooldownReason,
    bool clearCooldown = false,
    QuotaSnapshot? quota,
  }) => ModelAccount(
    id: id,
    profile: profile ?? this.profile,
    credentialRef: clearCredential ? null : credentialRef ?? this.credentialRef,
    position: position ?? this.position,
    autoRoute: autoRoute ?? this.autoRoute,
    cooldownUntil: clearCooldown ? null : cooldownUntil ?? this.cooldownUntil,
    cooldownReason: clearCooldown
        ? null
        : cooldownReason ?? this.cooldownReason,
    quota: quota ?? this.quota,
  );
}

/// 账户列表 + 当前配置的一致快照。
class ModelAccountsSnapshot {
  ModelAccountsSnapshot({
    required this.configuration,
    required List<ModelAccount> accounts,
    this.activeId,
  }) : accounts = List.unmodifiable(accounts);

  final ModelConfiguration configuration;
  final List<ModelAccount> accounts;
  final String? activeId;

  ModelAccount? get active {
    for (final account in accounts) {
      if (account.id == activeId) return account;
    }
    return null;
  }

  ModelAccount? byId(String id) {
    for (final account in accounts) {
      if (account.id == id) return account;
    }
    return null;
  }
}

/// 账户的持久化。每个写操作在一个事务里同时维护「当前配置」的版本，
/// 所以正在执行的对话能察觉配置已变化。Key 本身不经过这里。
abstract interface class ModelAccountStore {
  Future<ModelAccountsSnapshot> readAccounts();

  /// 账户、当前配置、额度或冷却任何一项变化都推送一次新快照。
  Stream<ModelAccountsSnapshot> watch();

  /// 新建或更新账户。[activate] 为真时把它设为当前配置。
  Future<ModelAccountsSnapshot> saveAccount(
    ModelAccount account, {
    required bool activate,
    required int expectedVersion,
  });

  /// 删除账户。删的是当前账户时，当前配置变为未配置 Key。
  Future<ModelAccountsSnapshot> removeAccount(
    String id, {
    required int expectedVersion,
  });

  /// 冷却与额度是观测数据，不改变配置版本。
  Future<void> recordCooldown(String id, {DateTime? until, String? reason});
  Future<void> recordQuota(String id, QuotaSnapshot quota);
}
