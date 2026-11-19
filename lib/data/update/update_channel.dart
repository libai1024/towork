import 'package:flutter/services.dart';

import '../../domain/update/app_update.dart';

class UpdateChannel implements UpdatePlatform {
  const UpdateChannel({this.channel = const MethodChannel('towork/update')});
  final MethodChannel channel;

  @override
  Future<InstalledApp> installed() async {
    try {
      final raw = await channel.invokeMapMethod<String, Object?>('info');
      if (raw == null) throw const UpdateFailure('platform');
      return InstalledApp(
        versionName: raw['versionName'] as String? ?? '',
        versionCode: raw['versionCode'] as int? ?? 0,
        canUpdate: raw['supported'] == true,
        certSha256: raw['certSha256'] as String? ?? '',
        abis: List<String>.from(raw['abis'] as List<Object?>? ?? []),
        availableBytes: raw['availableBytes'] as int? ?? 0,
        apkSha256: raw['apkSha256'] as String? ?? '',
      );
    } on MissingPluginException {
      return const InstalledApp();
    } on PlatformException {
      throw const UpdateFailure('platform');
    }
  }

  Future<T?> _invoke<T>(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    try {
      return await channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (error) {
      throw UpdateFailure(error.code);
    } on MissingPluginException {
      throw const UpdateFailure('platform');
    }
  }

  @override
  Future<bool> canInstall() async => await _invoke<bool>('canInstall') ?? false;
  @override
  Future<void> requestInstallPermission() => _invoke<void>('permission');
  @override
  Future<void> confirmInstall() => _invoke<void>('confirm');
  @override
  Future<void> applyPatch(
    String patchPath,
    String outputPath,
    AppRelease release,
  ) => _invoke<void>('patch', {
    'patchPath': patchPath,
    'outputPath': outputPath,
    'fromSha256': release.patch!.fromSha256,
    'patchSha256': release.patch!.sha256,
    'patchSize': release.patch!.size,
    'versionCode': release.versionCode,
    'sha256': release.sha256,
    'size': release.size,
  });
  @override
  Future<void> install(String path, AppRelease release) =>
      _invoke<void>('install', {
        'path': path,
        'versionName': release.versionName,
        'versionCode': release.versionCode,
        'sha256': release.sha256,
        'size': release.size,
      });
  @override
  Future<InstallStatus> installStatus() async {
    final status = await _invoke<String>('status');
    return InstallStatus.values.firstWhere(
      (value) => value.name == status,
      orElse: () => InstallStatus.failed,
    );
  }
}
