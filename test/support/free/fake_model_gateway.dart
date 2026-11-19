import 'dart:async';

import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/ai/quota.dart';
import 'package:towork/domain/settings/model_accounts.dart';
import 'package:towork/domain/settings/model_settings.dart';

class FakeKeyVault implements KeyVault {
  final values = <String, String>{};
  bool failWrite = false;
  bool failDelete = false;
  bool failRead = false;
  @override
  Future<String?> read(String reference) async {
    if (failRead) throw const SettingsFailure(SettingsFailureCode.credentials);
    return values[reference];
  }

  @override
  Future<void> write(String reference, String secret) async {
    if (failWrite) throw const SettingsFailure(SettingsFailureCode.credentials);
    values[reference] = secret;
  }

  @override
  Future<void> delete(String reference) async {
    if (failDelete) {
      throw const SettingsFailure(SettingsFailureCode.credentials);
    }
    values.remove(reference);
  }
}

class FakeKimiGateway implements ModelGateway, ModelDirectory {
  Uri? directoryUri;
  int directoryCalls = 0;
  @override
  Future<List<String>> listModels(
    Uri endpoint, {
    required String apiKey,
    required ModelCancellation cancellation,
  }) async {
    directoryUri = endpoint;
    directoryCalls++;
    if (failure != null) throw failure!;
    return ['first-model', 'second-model'];
  }

  ModelRequest? request;
  int calls = 0;
  ModelFailure? failure;
  Completer<void>? waitForResponse;
  @override
  Stream<ModelEvent> stream(
    ModelRequest request, {
    required String apiKey,
    ModelCancellation? cancellation,
  }) async* {
    this.request = request;
    calls++;
    // Deliberately ignores cancellation to test stale-result protection.
    await waitForResponse?.future;
    if (failure != null) throw failure!;
    yield ModelCompleted(
      assistantMessage: {'role': 'assistant', 'content': 'OK'},
      finishReason: 'stop',
      usage: {'total_tokens': 9},
    );
  }
}

/// Widget tests use an in-memory contract fake; file persistence is separately
/// verified against real SQLite outside Flutter's virtual animation clock.
/// It mirrors the SQLite store: the active configuration row is always the
/// projection of one account.
class FakeKimiConfigurationStore
    implements ModelConfigurationStore, ModelAccountStore {
  ModelConfiguration configuration = ModelConfiguration.empty();
  final cleanup = <String>{};
  final accounts = <String, ModelAccount>{};
  String? activeId;
  final _changes = StreamController<ModelAccountsSnapshot>.broadcast();

  ModelAccountsSnapshot get _snapshot => ModelAccountsSnapshot(
    configuration: configuration,
    accounts: accounts.values.toList()
      ..sort((a, b) => a.position.compareTo(b.position)),
    activeId: activeId,
  );
  void _notify() => _changes.add(_snapshot);
  bool _referenced(String? reference) =>
      reference != null &&
      (configuration.credentialRef == reference ||
          accounts.values.any((a) => a.credentialRef == reference));
  void _release(String? reference) {
    if (reference != null && !_referenced(reference)) cleanup.add(reference);
  }

  @override
  Future<ModelConfiguration> readConfiguration() async => configuration;
  @override
  Future<void> stageCredential(String reference) async {
    cleanup.add(reference);
  }

  @override
  Future<List<String>> pendingCleanup() async => cleanup.toList();
  @override
  Future<void> finishCleanup(String reference) async {
    cleanup.remove(reference);
  }

  @override
  Future<void> commit(
    ModelConfiguration next, {
    required int expectedVersion,
  }) async {
    if (configuration.version != expectedVersion) {
      throw const SettingsFailure(SettingsFailureCode.conflict);
    }
    final old = configuration.credentialRef;
    configuration = next;
    final id = activeId ?? 'acct_primary';
    activeId = id;
    accounts[id] = ModelAccount(
      id: id,
      profile: next.profile,
      credentialRef: next.credentialRef,
      position: accounts[id]?.position ?? accounts.length,
      autoRoute: accounts[id]?.autoRoute ?? true,
    );
    cleanup.remove(next.credentialRef);
    if (old != next.credentialRef) _release(old);
    _notify();
  }

  @override
  Future<ModelAccountsSnapshot> readAccounts() async => _snapshot;
  @override
  Stream<ModelAccountsSnapshot> watch() => _changes.stream;

  @override
  Future<ModelAccountsSnapshot> saveAccount(
    ModelAccount account, {
    required bool activate,
    required int expectedVersion,
  }) async {
    if (configuration.version != expectedVersion) {
      throw const SettingsFailure(SettingsFailureCode.conflict);
    }
    final previous = accounts[account.id]?.credentialRef;
    final old = configuration.credentialRef;
    accounts[account.id] = account;
    if (activate || activeId == account.id) {
      final next = expectedVersion + 1;
      activeId = account.id;
      configuration = ModelConfiguration(
        profile: account.profile.copyWith(revision: next),
        credentialRef: account.credentialRef,
        version: next,
      );
    }
    cleanup.remove(account.credentialRef);
    _release(previous);
    _release(old);
    _notify();
    return _snapshot;
  }

  @override
  Future<ModelAccountsSnapshot> removeAccount(
    String id, {
    required int expectedVersion,
  }) async {
    if (configuration.version != expectedVersion) {
      throw const SettingsFailure(SettingsFailureCode.conflict);
    }
    final removed = accounts.remove(id);
    if (removed == null) return _snapshot;
    if (activeId == id) {
      final next = expectedVersion + 1;
      activeId = null;
      configuration = ModelConfiguration(
        profile: configuration.profile.copyWith(revision: next),
        version: next,
      );
    }
    _release(removed.credentialRef);
    _notify();
    return _snapshot;
  }

  @override
  Future<void> recordCooldown(
    String id, {
    DateTime? until,
    String? reason,
  }) async {
    final account = accounts[id];
    if (account == null) return;
    accounts[id] = until == null
        ? account.copyWith(clearCooldown: true)
        : account.copyWith(cooldownUntil: until, cooldownReason: reason);
    _notify();
  }

  @override
  Future<void> recordQuota(String id, QuotaSnapshot quota) async {
    final account = accounts[id];
    if (account == null) return;
    accounts[id] = account.copyWith(quota: quota);
    _notify();
  }
}
