import '../ai/model_gateway.dart';

enum SettingsFailureCode {
  validation,
  storage,
  credentials,
  conflict,
  missingKey,
}

class SettingsFailure implements Exception {
  const SettingsFailure(this.code);
  final SettingsFailureCode code;
  @override
  String toString() => 'SettingsFailure(${code.name})';
}

class ModelConfiguration {
  const ModelConfiguration({
    required this.profile,
    this.credentialRef,
    this.version = 0,
  });
  final ModelProfile profile;
  final String? credentialRef;
  final int version;

  factory ModelConfiguration.empty() => ModelConfiguration(
    profile: ModelProfile(model: 'kimi-k2.6', disableThinking: true),
  );
}

class ModelSettingsSnapshot {
  const ModelSettingsSnapshot(
    this.configuration, {
    required this.hasKey,
    this.cleanupPending = false,
  });
  final ModelConfiguration configuration;
  final bool hasKey;
  final bool cleanupPending;
}

abstract interface class KeyVault {
  Future<String?> read(String reference);
  Future<void> write(String reference, String secret);
  Future<void> delete(String reference);
}

/// Short-lived, non-serializable lease. Never log its secret or put it in state.
class ModelRuntimeCredential {
  const ModelRuntimeCredential(this.configuration, this.secret);
  final ModelConfiguration configuration;
  final String secret;
  @override
  String toString() => 'ModelRuntimeCredential(redacted)';
}

/// The database never receives the secret itself.
abstract interface class ModelConfigurationStore {
  Future<ModelConfiguration> readConfiguration();
  Future<void> stageCredential(String reference);
  Future<List<String>> pendingCleanup();
  Future<void> finishCleanup(String reference);
  Future<void> commit(ModelConfiguration next, {required int expectedVersion});
}
