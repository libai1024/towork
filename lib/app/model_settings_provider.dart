import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ai/openai_compatible_gateway.dart';
import '../data/ai/provider_quota_gateway.dart';
import '../data/local/model_account_store.dart';
import '../data/platform/system_key_vault.dart';
import '../domain/ai/quota.dart';
import '../domain/settings/model_account_service.dart';
import '../domain/settings/model_accounts.dart';
import '../domain/settings/model_settings_service.dart';
import 'local_chat_runtime.dart';
import 'local_database_provider.dart';

final modelSettingsServiceProvider = FutureProvider<ModelSettingsService>((
  ref,
) async {
  final db = await ref.watch(localDatabaseProvider.future);
  final gateway = OpenAiCompatibleGateway();
  ref.onDispose(() {
    gateway.close();
  });
  return ModelSettingsService(db, SystemKeyVault(), gateway);
});

/// 额度查询。测试用假实现覆盖，避免真实网络。
final quotaGatewayProvider = Provider<QuotaGateway>((ref) {
  final gateway = ProviderQuotaGateway();
  ref.onDispose(gateway.close);
  return gateway;
});

/// 多账户、路由与额度的唯一入口。和设置服务共用同一个串行写队列。
final modelAccountServiceProvider = FutureProvider<ModelAccountService>((
  ref,
) async {
  final db = await ref.watch(localDatabaseProvider.future);
  final settings = await ref.watch(modelSettingsServiceProvider.future);
  return ModelAccountService(
    settings,
    SqliteModelAccountStore(db),
    quotas: ref.watch(quotaGatewayProvider),
  );
});

/// 已保存的模型账户、当前账户、额度与冷却状态（设置页、模型选择器、侧栏共用）。
final modelAccountsProvider = StreamProvider<ModelAccountsSnapshot>((
  ref,
) async* {
  final service = await ref.watch(modelAccountServiceProvider.future);
  yield await service.load();
  yield* service.watch();
});

/// 界面读取用：演示模式（没有本地运行时）下返回 null，不触碰数据库。
final liveModelAccountsProvider = Provider<ModelAccountsSnapshot?>((ref) {
  if (ref.watch(localChatRuntimeProvider) == null) return null;
  return ref.watch(modelAccountsProvider).valueOrNull;
});
