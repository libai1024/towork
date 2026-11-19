import 'dart:async';

import 'package:towork/domain/update/app_update.dart';

final updateFixtureRelease = AppRelease(
  versionName: '1.1.2',
  versionCode: 4,
  url: Uri.parse('https://zhaozhaoyue.top/dl/towork/android/fixture.apk'),
  sha256: 'a' * 64,
  size: 1024 * 1024,
  certSha256: 'b' * 64,
  abi: 'arm64-v8a',
  notes: ['应用内下载与安装'],
);

class FakeUpdatePlatform implements UpdatePlatform {
  InstalledApp info = const InstalledApp(
    versionName: '1.1.1',
    versionCode: 3,
    canUpdate: true,
    availableBytes: 1000000000,
  );
  bool allowed = true;
  int permissionRequests = 0;
  int installs = 0;
  int confirmations = 0;
  Object? installError;
  Completer<void>? installation;
  InstallStatus status = InstallStatus.waiting;
  Future<void> Function(String, String, AppRelease)? patcher;
  @override
  Future<void> applyPatch(
    String patchPath,
    String outputPath,
    AppRelease release,
  ) async {
    if (patcher == null) throw const UpdateFailure('patch');
    await patcher!(patchPath, outputPath, release);
  }

  @override
  Future<InstalledApp> installed() async => info;
  @override
  Future<bool> canInstall() async => allowed;
  @override
  Future<void> requestInstallPermission() async {
    permissionRequests++;
  }

  @override
  Future<void> install(String path, AppRelease release) async {
    installs++;
    if (installError case final error?) throw error;
    await installation?.future;
  }

  @override
  Future<InstallStatus> installStatus() async => status;
  @override
  Future<void> confirmInstall() async {
    confirmations++;
    status = InstallStatus.waiting;
  }
}

class FakeUpdateGateway implements UpdateGateway {
  AppRelease? release = updateFixtureRelease;
  Object? checkError;
  Completer<String>? transfer;
  void Function(int)? progress;
  void Function()? verifying;
  void Function()? applying;
  void Function()? fallback;
  int checks = 0;
  int downloads = 0;
  @override
  Future<AppRelease?> check(InstalledApp installed) async {
    checks++;
    if (checkError case final error?) throw error;
    return release;
  }

  @override
  Future<String> download(
    AppRelease release, {
    required int availableBytes,
    required void Function(int bytes) onProgress,
    required void Function() onVerifying,
    void Function()? onApplying,
    void Function()? onFallback,
  }) async {
    downloads++;
    progress = onProgress;
    verifying = onVerifying;
    applying = onApplying;
    fallback = onFallback;
    onProgress(release.downloadSize ~/ 2);
    if (transfer != null) return transfer!.future;
    onVerifying();
    return '/private/updates/fixture.apk';
  }

  @override
  void cancel() {
    final current = transfer;
    if (current != null && !current.isCompleted) {
      current.completeError(const UpdateFailure('cancelled'));
    }
  }
}
