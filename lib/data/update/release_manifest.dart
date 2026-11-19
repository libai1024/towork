import '../../domain/update/app_update.dart';

/// The current publisher emits immutable, same-origin APKs and schema 1.
AppRelease parseReleaseManifest(Object? raw, Uri manifestUrl) {
  if (raw is! Map<String, dynamic> ||
      raw['schema'] != 1 ||
      raw['channel'] != 'stable' ||
      raw['rolloutPercent'] != 100) {
    throw const UpdateFailure('manifest');
  }
  final android = raw['android'];
  if (android is! Map<String, dynamic>) {
    throw const UpdateFailure('manifest');
  }
  final full = android['full'];
  final version = raw['versionName'];
  final code = raw['versionCode'];
  final notes = raw['releaseNotes'];
  if (full is! Map<String, dynamic> ||
      version is! String ||
      !RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version) ||
      code is! int ||
      code <= 0 ||
      notes is! List ||
      notes.length > 100 ||
      notes.any((note) => note is! String || note.length > 2000)) {
    throw const UpdateFailure('manifest');
  }
  final hash = full['sha256'];
  final cert = android['certSha256'];
  final size = full['size'];
  final path = full['url'];
  final abi = android['abi'];
  final hex = RegExp(r'^[a-fA-F0-9]{64}$');
  if (hash is! String ||
      !hex.hasMatch(hash) ||
      cert is! String ||
      !hex.hasMatch(cert) ||
      size is! int ||
      size <= 0 ||
      size > 1024 * 1024 * 1024 ||
      path is! String ||
      abi != 'arm64-v8a') {
    throw const UpdateFailure('manifest');
  }
  final url = manifestUrl.resolve(path);
  final directory = manifestUrl.resolve('android/');
  if (url.scheme != 'https' ||
      url.origin != manifestUrl.origin ||
      url.userInfo.isNotEmpty ||
      url.hasFragment ||
      url.hasQuery ||
      !url.path.startsWith(directory.path) ||
      !url.path.endsWith('.apk')) {
    throw const UpdateFailure('manifest');
  }
  final patches = <AppPatch>[];
  final candidates = android['patches'];
  if (candidates is List && candidates.length <= 3) {
    for (final candidate in candidates) {
      if (candidate is! Map<String, dynamic> ||
          candidate['format'] != 'hdiffpatch' ||
          candidate['fromVersionCode'] is! int ||
          (candidate['fromVersionCode'] as int) <= 0 ||
          (candidate['fromVersionCode'] as int) >= code ||
          candidate['fromSha256'] is! String ||
          !hex.hasMatch(candidate['fromSha256'] as String) ||
          candidate['sha256'] is! String ||
          !hex.hasMatch(candidate['sha256'] as String) ||
          candidate['size'] is! int ||
          (candidate['size'] as int) <= 0 ||
          (candidate['size'] as int) >= size ||
          candidate['url'] is! String) {
        continue;
      }
      final patchUrl = manifestUrl.resolve(candidate['url'] as String);
      if (patchUrl.scheme != 'https' ||
          patchUrl.origin != manifestUrl.origin ||
          patchUrl.userInfo.isNotEmpty ||
          patchUrl.hasFragment ||
          patchUrl.hasQuery ||
          !patchUrl.path.startsWith(directory.path) ||
          !patchUrl.path.endsWith('.hpatch')) {
        continue;
      }
      patches.add(
        AppPatch(
          fromVersionCode: candidate['fromVersionCode'] as int,
          fromSha256: (candidate['fromSha256'] as String).toLowerCase(),
          url: patchUrl,
          sha256: (candidate['sha256'] as String).toLowerCase(),
          size: candidate['size'] as int,
        ),
      );
    }
  }
  return AppRelease(
    versionName: version,
    versionCode: code,
    url: url,
    sha256: hash.toLowerCase(),
    size: size,
    certSha256: cert.toLowerCase(),
    abi: abi as String,
    notes: notes.cast<String>(),
    patches: patches,
  );
}
