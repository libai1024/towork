import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/settings/model_settings.dart';

class SystemKeyVault implements KeyVault {
  SystemKeyVault({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(
              resetOnError: false,
              storageNamespace: 'towork_credentials_v1',
            ),
            // This app does not share credentials with other apps or iCloud. The login
            // Keychain supports standalone macOS builds without sharing entitlements.
            mOptions: MacOsOptions(
              usesDataProtectionKeychain: false,
              synchronizable: false,
            ),
            iOptions: IOSOptions(synchronizable: false),
          );
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String reference) async {
    try {
      return await _storage.read(key: reference);
    } catch (_) {
      throw const SettingsFailure(SettingsFailureCode.credentials);
    }
  }

  @override
  Future<void> write(String reference, String secret) async {
    try {
      await _storage.write(key: reference, value: secret);
      if (await _storage.read(key: reference) != secret) {
        throw const SettingsFailure(SettingsFailureCode.credentials);
      }
    } catch (_) {
      throw const SettingsFailure(SettingsFailureCode.credentials);
    }
  }

  @override
  Future<void> delete(String reference) async {
    try {
      await _storage.delete(key: reference);
      if (await _storage.read(key: reference) != null) {
        throw const SettingsFailure(SettingsFailureCode.credentials);
      }
    } catch (_) {
      throw const SettingsFailure(SettingsFailureCode.credentials);
    }
  }
}
