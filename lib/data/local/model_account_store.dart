import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/ai/model_gateway.dart';
import '../../domain/ai/quota.dart';
import '../../domain/settings/model_accounts.dart';
import '../../domain/settings/model_settings.dart';
import 'app_database.dart';

/// 账户表的读写。凡是影响「当前配置」的写入都和版本递增放在同一个事务里。
class SqliteModelAccountStore implements ModelAccountStore {
  SqliteModelAccountStore(this.db);
  final AppDatabase db;

  ModelAccount _decode(ProviderAccountRow row) {
    QuotaSnapshot? quota;
    final payload = row.quotaPayload;
    if (payload != null) {
      // 额度缓存损坏不影响账户本身，丢弃后下次刷新重建。
      try {
        quota = QuotaSnapshot.fromJson(
          (jsonDecode(payload) as Map).cast<String, Object?>(),
        );
      } catch (_) {
        quota = null;
      }
    }
    return ModelAccount(
      id: row.id,
      profile: ModelProfile(
        model: row.model,
        product: ProviderKind.fromWire(row.product),
        region: ProviderRegion.values.byName(row.region),
        disableThinking: row.disableThinking,
        baseUrl: row.baseUrl,
      ),
      credentialRef: row.credentialRef,
      position: row.position,
      autoRoute: row.autoRoute,
      cooldownUntil: row.cooldownUntil == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              row.cooldownUntil!,
              isUtc: true,
            ),
      cooldownReason: row.cooldownReason,
      quota: quota,
    );
  }

  Future<ProviderAccountRow?> _row(String id) => (db.select(
    db.providerAccounts,
  )..where((r) => r.id.equals(id))).getSingleOrNull();

  @override
  Future<ModelAccountsSnapshot> readAccounts() async {
    final rows =
        await (db.select(db.providerAccounts)..orderBy([
              (r) => OrderingTerm.asc(r.position),
              (r) => OrderingTerm.asc(r.id),
            ]))
            .get();
    return ModelAccountsSnapshot(
      configuration: await db.readConfiguration(),
      accounts: rows.map(_decode).toList(),
      activeId: await db.activeAccountId(),
    );
  }

  @override
  Future<ModelAccountsSnapshot> saveAccount(
    ModelAccount account, {
    required bool activate,
    required int expectedVersion,
  }) => db.transaction(() async {
    final config = await db.readConfiguration();
    if (config.version != expectedVersion) {
      throw const SettingsFailure(SettingsFailureCode.conflict);
    }
    final previous = await _row(account.id);
    final activeId = await db.activeAccountId();
    final profile = account.profile;
    await db
        .into(db.providerAccounts)
        .insertOnConflictUpdate(
          ProviderAccountsCompanion.insert(
            id: account.id,
            product: profile.product.wireId,
            region: profile.region.name,
            model: profile.model,
            baseUrl: Value(
              profile.descriptor.needsBaseUrl ? profile.baseUrl : null,
            ),
            disableThinking: profile.disableThinking,
            credentialRef: Value(account.credentialRef),
            position: account.position,
            autoRoute: account.autoRoute,
            cooldownUntil: Value(
              account.cooldownUntil?.toUtc().millisecondsSinceEpoch,
            ),
            cooldownReason: Value(account.cooldownReason),
            quotaPayload: Value(
              account.quota == null
                  ? null
                  : jsonEncode(account.quota!.toJson()),
            ),
          ),
        );
    // 当前账户被修改，或要求切换到它：当前配置跟着变，版本 +1，
    // 正在执行的对话据此发现配置已变化。
    if (activate || activeId == account.id) {
      final next = expectedVersion + 1;
      await db.writeActiveConfiguration(
        ModelConfiguration(
          profile: ModelProfile(
            model: profile.model,
            product: profile.product,
            region: profile.region,
            revision: next,
            disableThinking: profile.disableThinking,
            baseUrl: profile.baseUrl,
          ),
          credentialRef: account.credentialRef,
          version: next,
        ),
        accountId: account.id,
      );
    }
    if (account.credentialRef != null) {
      await db.finishCleanup(account.credentialRef!);
    }
    if (previous?.credentialRef != account.credentialRef) {
      await db.releaseCredential(previous?.credentialRef);
    }
    if (config.credentialRef != account.credentialRef) {
      await db.releaseCredential(config.credentialRef);
    }
    return readAccounts();
  });

  @override
  Future<ModelAccountsSnapshot> removeAccount(
    String id, {
    required int expectedVersion,
  }) => db.transaction(() async {
    final config = await db.readConfiguration();
    if (config.version != expectedVersion) {
      throw const SettingsFailure(SettingsFailureCode.conflict);
    }
    final row = await _row(id);
    if (row == null) return readAccounts();
    await (db.delete(db.providerAccounts)..where((r) => r.id.equals(id))).go();
    if (await db.activeAccountId() == id) {
      final next = expectedVersion + 1;
      await db.writeActiveConfiguration(
        ModelConfiguration(
          profile: ModelProfile(
            model: config.profile.model,
            product: config.profile.product,
            region: config.profile.region,
            revision: next,
            disableThinking: config.profile.disableThinking,
            baseUrl: config.profile.baseUrl,
          ),
          version: next,
        ),
        accountId: null,
      );
    }
    await db.releaseCredential(row.credentialRef);
    return readAccounts();
  });

  @override
  Future<void> recordCooldown(
    String id, {
    DateTime? until,
    String? reason,
  }) async {
    await (db.update(db.providerAccounts)..where((r) => r.id.equals(id))).write(
      ProviderAccountsCompanion(
        cooldownUntil: Value(until?.toUtc().millisecondsSinceEpoch),
        cooldownReason: Value(until == null ? null : reason),
      ),
    );
  }

  @override
  Future<void> recordQuota(String id, QuotaSnapshot quota) async {
    await (db.update(db.providerAccounts)..where((r) => r.id.equals(id))).write(
      ProviderAccountsCompanion(
        quotaPayload: Value(jsonEncode(quota.toJson())),
      ),
    );
  }

  /// 账户表任何变化都推送一次新快照（额度刷新、冷却、增删改）。
  @override
  Stream<ModelAccountsSnapshot> watch() {
    final changes = db
        .customSelect(
          'SELECT 1',
          readsFrom: {db.providerAccounts, db.providerConfigurations},
        )
        .watch();
    return changes.asyncMap((_) => readAccounts());
  }
}
