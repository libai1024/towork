/// Installed package metadata comes from the platform, including its signer.
class InstalledApp {
  const InstalledApp({
    this.versionName = '',
    this.versionCode = 0,
    this.canUpdate = false,
    this.certSha256 = '',
    this.abis = const [],
    this.availableBytes = 0,
    this.apkSha256 = '',
  });

  final String versionName;
  final int versionCode;
  final bool canUpdate;
  final String certSha256;
  final List<String> abis;
  final int availableBytes;
  final String apkSha256;

  String get label =>
      versionName.isEmpty ? '未知版本' : '$versionName ($versionCode)';
}

class AppPatch {
  const AppPatch({
    required this.fromVersionCode,
    required this.fromSha256,
    required this.url,
    required this.sha256,
    required this.size,
  });

  final int fromVersionCode;
  final String fromSha256;
  final Uri url;
  final String sha256;
  final int size;
}

class AppRelease {
  AppRelease({
    required this.versionName,
    required this.versionCode,
    required this.url,
    required this.sha256,
    required this.size,
    required this.certSha256,
    required this.abi,
    required List<String> notes,
    List<AppPatch> patches = const [],
    this.patch,
  }) : notes = List.unmodifiable(notes),
       patches = List.unmodifiable(patches);

  final String versionName;
  final int versionCode;
  final Uri url;
  final String sha256;
  final int size;
  final String certSha256;
  final String abi;
  final List<String> notes;
  final List<AppPatch> patches;
  final AppPatch? patch;

  int get downloadSize => patch?.size ?? size;

  AppRelease selectPatch(AppPatch selected) => AppRelease(
    versionName: versionName,
    versionCode: versionCode,
    url: url,
    sha256: sha256,
    size: size,
    certSha256: certSha256,
    abi: abi,
    notes: notes,
    patches: patches,
    patch: selected,
  );
}

class UpdateFailure implements Exception {
  const UpdateFailure(this.code);
  final String code;
}

enum InstallStatus { waiting, confirmation, success, cancelled, failed }

abstract interface class UpdatePlatform {
  Future<InstalledApp> installed();
  Future<bool> canInstall();
  Future<void> requestInstallPermission();
  Future<void> install(String path, AppRelease release);
  Future<InstallStatus> installStatus();
  Future<void> confirmInstall();
  Future<void> applyPatch(
    String patchPath,
    String outputPath,
    AppRelease release,
  );
}

abstract interface class UpdateGateway {
  Future<AppRelease?> check(InstalledApp installed);
  Future<String> download(
    AppRelease release, {
    required int availableBytes,
    required void Function(int bytes) onProgress,
    required void Function() onVerifying,
    void Function()? onApplying,
    void Function()? onFallback,
  });
  void cancel();
}
