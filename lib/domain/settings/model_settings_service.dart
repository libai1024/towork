import 'dart:async';
import 'dart:math';

import '../ai/model_gateway.dart';
import 'model_settings.dart';

/// One foreground writer owns settings. Workers may read a frozen profile but
/// never rotate credentials. Queueing makes save/delete/recovery deterministic.
class ModelSettingsService {
  ModelSettingsService(this.store, this.vault, this.gateway);
  final ModelConfigurationStore store;
  final KeyVault vault;
  final ModelGateway gateway;
  Future<void>? _tail;

  Future<T> _serial<T>(Future<T> Function() work) {
    final pending = _tail;
    final result = pending == null ? work() : pending.then((_) => work());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<T> _safe<T>(Future<T> Function() work) async {
    try {
      return await work();
    } on SettingsFailure {
      rethrow;
    } catch (_) {
      throw const SettingsFailure(SettingsFailureCode.storage);
    }
  }

  /// 与设置写入共用同一个串行队列，账户服务借此保持「单一前台写者」。
  Future<T> exclusive<T>(Future<T> Function() work) =>
      _serial(() => _safe(work));

  /// 清理已不再被引用的 Key；返回是否还有待重试的清理。
  Future<bool> sweepCredentials() => _cleanup();

  /// 生成新的 Key 引用。引用是不透明的随机串，不含服务商或账户信息。
  static String newCredentialReference() {
    final random = Random.secure();
    return 'towork.kimi.${List.generate(24, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
  }

  /// Key 的基本形状检查：非空、无空白、长度有限。
  static bool isPlausibleKey(String key) =>
      key.isNotEmpty && key.length <= 4096 && !RegExp(r'\s').hasMatch(key);

  Future<bool> _cleanup() async {
    final active = (await store.readConfiguration()).credentialRef;
    var pending = false;
    for (final ref in await store.pendingCleanup()) {
      if (ref == active) continue;
      try {
        await vault.delete(ref);
        await store.finishCleanup(ref);
      } catch (_) {
        pending = true;
      }
    }
    return pending;
  }

  Future<ModelSettingsSnapshot> _snapshot() async {
    final pending = await _cleanup();
    final config = await store.readConfiguration();
    final ref = config.credentialRef;
    return ModelSettingsSnapshot(
      config,
      hasKey: ref != null && (await vault.read(ref))?.isNotEmpty == true,
      cleanupPending: pending,
    );
  }

  Future<ModelSettingsSnapshot> load() => _serial(() => _safe(_snapshot));

  Future<ModelRuntimeCredential> runtimeCredential({int? expectedVersion}) =>
      _serial(
        () => _safe(() async {
          final config = await store.readConfiguration();
          if (expectedVersion != null && config.version != expectedVersion) {
            throw const SettingsFailure(SettingsFailureCode.conflict);
          }
          final reference = config.credentialRef;
          if (reference == null) {
            throw const SettingsFailure(SettingsFailureCode.missingKey);
          }
          final secret = await vault.read(reference);
          if (secret == null || secret.isEmpty) {
            throw const SettingsFailure(SettingsFailureCode.missingKey);
          }
          final current = await store.readConfiguration();
          if (current.version != config.version ||
              current.credentialRef != reference) {
            throw const SettingsFailure(SettingsFailureCode.conflict);
          }
          return ModelRuntimeCredential(config, secret);
        }),
      );

  Future<ModelSettingsSnapshot> save({
    required ModelProfile profile,
    required int expectedVersion,
    String? newKey,
  }) => _serial(
    () => _safe(() async {
      final old = await store.readConfiguration();
      if (old.version != expectedVersion) {
        throw const SettingsFailure(SettingsFailureCode.conflict);
      }
      final key = newKey?.trim();
      if (key != null &&
          (key.isEmpty || key.length > 4096 || RegExp(r'\s').hasMatch(key))) {
        throw const SettingsFailure(SettingsFailureCode.validation);
      }
      // A key never silently follows a switch to another product/region.
      final endpointChanged =
          old.profile.product != profile.product ||
          old.profile.region != profile.region;
      if (endpointChanged && key == null && old.credentialRef != null) {
        throw const SettingsFailure(SettingsFailureCode.missingKey);
      }
      var reference = old.credentialRef;
      if (key != null) {
        reference = newCredentialReference();
        // Queue orphan recovery before crossing the non-transactional vault.
        await store.stageCredential(reference);
        try {
          await vault.write(reference, key);
        } catch (_) {
          await _cleanup();
          rethrow;
        }
      }
      final next = ModelConfiguration(
        profile: profile.copyWith(revision: expectedVersion + 1),
        credentialRef: reference,
        version: expectedVersion + 1,
      );
      try {
        await store.commit(next, expectedVersion: expectedVersion);
      } catch (_) {
        await _cleanup();
        rethrow;
      }
      return _snapshot();
    }),
  );

  Future<ModelSettingsSnapshot> deleteKey({required int expectedVersion}) =>
      _serial(
        () => _safe(() async {
          final old = await store.readConfiguration();
          await store.commit(
            ModelConfiguration(
              profile: old.profile,
              version: expectedVersion + 1,
            ),
            expectedVersion: expectedVersion,
          );
          return _snapshot();
        }),
      );

  Future<ModelCompleted> testDraft({
    required ModelProfile profile,
    required ModelCancellation cancellation,
    String? key,
    ModelConfiguration? savedConfiguration,
  }) async {
    var secret = key?.trim();
    if (secret == null || secret.isEmpty) {
      final saved = savedConfiguration;
      if (saved == null ||
          saved.profile.product != profile.product ||
          saved.profile.region != profile.region) {
        throw const SettingsFailure(SettingsFailureCode.missingKey);
      }
      secret = await _serial(
        () => _safe(() async {
          final current = await store.readConfiguration();
          if (current.version != saved.version) {
            throw const SettingsFailure(SettingsFailureCode.conflict);
          }
          final reference = current.credentialRef;
          return reference == null ? null : await vault.read(reference);
        }),
      );
    }
    if (secret == null ||
        secret.isEmpty ||
        secret.length > 4096 ||
        RegExp(r'\s').hasMatch(secret)) {
      throw const SettingsFailure(SettingsFailureCode.missingKey);
    }
    if (cancellation.isCancelled) {
      throw const ModelFailure(ModelFailureCode.cancelled);
    }
    await for (final event in gateway.stream(
      ModelRequest(
        profile: profile,
        messages: const [
          {'role': 'user', 'content': 'Reply with OK only.'},
        ],
        maxTokens: profile.disableThinking ? 128 : 2048,
      ),
      apiKey: secret,
      cancellation: cancellation,
    )) {
      if (event is ModelCompleted) {
        if (cancellation.isCancelled) {
          throw const ModelFailure(ModelFailureCode.cancelled);
        }
        return event;
      }
    }
    throw const ModelFailure(ModelFailureCode.truncated);
  }

  Future<ModelCompleted> testConnection(
    ModelConfiguration config,
    ModelCancellation cancellation,
  ) async {
    final key = await _serial(
      () => _safe(() async {
        final current = await store.readConfiguration();
        if (current.version != config.version) {
          throw const SettingsFailure(SettingsFailureCode.conflict);
        }
        final ref = current.credentialRef;
        final key = ref == null ? null : await vault.read(ref);
        if (key == null || key.isEmpty) {
          throw const SettingsFailure(SettingsFailureCode.missingKey);
        }
        return key;
      }),
    );
    await for (final event in gateway.stream(
      ModelRequest(
        profile: config.profile,
        messages: const [
          {'role': 'user', 'content': 'Reply with OK only.'},
        ],
        maxTokens: config.profile.disableThinking ? 128 : 2048,
      ),
      apiKey: key,
      cancellation: cancellation,
    )) {
      if (event is ModelCompleted) {
        if (cancellation.isCancelled) {
          throw const ModelFailure(ModelFailureCode.cancelled);
        }
        final current = await store.readConfiguration();
        if (current.version != config.version) {
          throw const SettingsFailure(SettingsFailureCode.conflict);
        }
        return event;
      }
    }
    throw const ModelFailure(ModelFailureCode.truncated);
  }
}
