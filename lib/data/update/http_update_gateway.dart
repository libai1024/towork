import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import '../../domain/update/app_update.dart';
import 'release_manifest.dart';

Future<String> _fileHash(String path) async =>
    (await sha256.bind(File(path).openRead()).first).toString();

class HttpUpdateGateway implements UpdateGateway {
  HttpUpdateGateway(
    this.dio, {
    required this.directory,
    required this.manifest,
    this.platform,
  });

  final Dio dio;
  final Future<Directory> Function() directory;
  final Uri manifest;
  final UpdatePlatform? platform;
  CancelToken? _cancel;
  bool _busy = false;

  @override
  Future<AppRelease?> check(InstalledApp installed) async {
    try {
      final response = await dio.get<ResponseBody>(
        manifest.toString(),
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: false,
          headers: {'Cache-Control': 'no-cache'},
        ),
      );
      final bytes = <int>[];
      await for (final chunk in response.data!.stream) {
        if (bytes.length + chunk.length > 256 * 1024) {
          throw const UpdateFailure('manifest');
        }
        bytes.addAll(chunk);
      }
      final release = parseReleaseManifest(
        jsonDecode(utf8.decode(bytes)),
        manifest,
      );
      if (release.versionCode <= installed.versionCode) return null;
      if (!installed.abis.contains(release.abi)) {
        throw const UpdateFailure('abi');
      }
      if (release.certSha256 != installed.certSha256.toLowerCase()) {
        throw const UpdateFailure('signature');
      }
      AppPatch? selected;
      if (platform != null) {
        for (final patch in release.patches) {
          if (patch.fromVersionCode == installed.versionCode &&
              patch.fromSha256 == installed.apkSha256.toLowerCase() &&
              (selected == null || patch.size < selected.size)) {
            selected = patch;
          }
        }
      }
      return selected == null ? release : release.selectPatch(selected);
    } on DioException {
      throw const UpdateFailure('network');
    } on FormatException {
      throw const UpdateFailure('manifest');
    }
  }

  @override
  void cancel() => _cancel?.cancel();

  @override
  Future<String> download(
    AppRelease release, {
    required int availableBytes,
    required void Function(int bytes) onProgress,
    required void Function() onVerifying,
    void Function()? onApplying,
    void Function()? onFallback,
  }) async {
    if (_busy) throw const UpdateFailure('busy');
    _busy = true;
    final cancel = _cancel = CancelToken();
    RandomAccessFile? lock;
    try {
      final root = await directory();
      await root.create(recursive: true);
      lock = await File('${root.path}/download.lock')
          .open(mode: FileMode.append);
      await lock.lock(FileLock.exclusive);
      if (cancel.isCancelled) throw const UpdateFailure('cancelled');
      final name = '${release.versionCode}-${release.sha256}.apk';
      final target = File('${root.path}/$name');
      final part = File('${target.path}.part');
      final patchName =
          '${release.versionCode}-${release.patch?.sha256}.hpatch';
      var reclaimedBytes = 0;
      // Retain only the selected release. Never touch another app directory.
      await for (final entry in root.list()) {
        if (entry is File &&
            RegExp(r'/\d+-[a-f0-9]{64}\.(?:apk|hpatch)(?:\.part)?$')
                .hasMatch(entry.path) &&
            entry.path != target.path &&
            entry.path != part.path &&
            entry.path != '${root.path}/$patchName' &&
            entry.path != '${root.path}/$patchName.part') {
          final length = await entry.length();
          await entry.delete();
          reclaimedBytes += length;
        }
      }
      if (await target.exists()) {
        onVerifying();
        if (await _valid(target, release.size, release.sha256)) {
          if (cancel.isCancelled) throw const UpdateFailure('cancelled');
          return target.path;
        }
        final length = await target.length();
        await target.delete();
        reclaimedBytes += length;
      }
      var offset = await part.exists() ? await part.length() : 0;
      if (offset > release.size) {
        await part.delete();
        reclaimedBytes += offset;
        offset = 0;
      }
      if (availableBytes + reclaimedBytes < release.size * 2 - offset) {
        throw const UpdateFailure('space');
      }
      if (release.patch != null && offset == 0) {
        final applied = await _applyDelta(
          release,
          root,
          part,
          cancel,
          availableBytes + reclaimedBytes,
          onProgress,
          onApplying,
          onVerifying,
        );
        if (applied) return (await part.rename(target.path)).path;
        onFallback?.call();
      } else if (release.patch != null && offset < release.size) {
        // Resume an earlier full-package fallback after a pause or restart.
        onFallback?.call();
      }
      onProgress(offset);
      if (offset < release.size) {
        await _receive(
          release.url,
          release.size,
          part,
          offset,
          cancel,
          onProgress,
        );
      }
      if (cancel.isCancelled) throw const UpdateFailure('cancelled');
      onVerifying();
      if (!await _valid(part, release.size, release.sha256)) {
        await part.delete();
        throw const UpdateFailure('checksum');
      }
      if (cancel.isCancelled) throw const UpdateFailure('cancelled');
      return (await part.rename(target.path)).path;
    } on DioException catch (error) {
      throw UpdateFailure(
        CancelToken.isCancel(error) ? 'cancelled' : 'network',
      );
    } on FileSystemException {
      throw const UpdateFailure('storage');
    } finally {
      if (lock != null) await lock.close();
      _cancel = null;
      _busy = false;
    }
  }

  Future<bool> _applyDelta(
    AppRelease release,
    Directory root,
    File output,
    CancelToken cancel,
    int availableBytes,
    void Function(int) onProgress,
    void Function()? onApplying,
    void Function() onVerifying,
  ) async {
    final patch = release.patch!;
    if (platform == null) return false;
    final target = File(
      '${root.path}/${release.versionCode}-${patch.sha256}.hpatch',
    );
    final part = File('${target.path}.part');
    try {
      if (await target.exists() &&
          !await _valid(target, patch.size, patch.sha256)) {
        await target.delete();
      }
      if (!await target.exists()) {
        var offset = await part.exists() ? await part.length() : 0;
        if (offset > patch.size) {
          await part.delete();
          offset = 0;
        }
        if (availableBytes < release.size * 2 + patch.size - offset) {
          throw const UpdateFailure('space');
        }
        onProgress(offset);
        if (offset < patch.size) {
          await _receive(
            patch.url,
            patch.size,
            part,
            offset,
            cancel,
            onProgress,
          );
        }
        onVerifying();
        if (!await _valid(part, patch.size, patch.sha256)) {
          await part.delete();
          throw const UpdateFailure('checksum');
        }
        await part.rename(target.path);
      }
      if (cancel.isCancelled) throw const UpdateFailure('cancelled');
      onApplying?.call();
      await platform!.applyPatch(target.path, output.path, release);
      if (cancel.isCancelled) throw const UpdateFailure('cancelled');
      onVerifying();
      if (!await output.exists() ||
          !await _valid(output, release.size, release.sha256)) {
        throw const UpdateFailure('checksum');
      }
      if (cancel.isCancelled) throw const UpdateFailure('cancelled');
      await target.delete();
      return true;
    } catch (error) {
      if (cancel.isCancelled ||
          error is UpdateFailure && error.code == 'cancelled') {
        throw const UpdateFailure('cancelled');
      }
      if (await output.exists()) await output.delete();
      return false;
    }
  }

  Future<bool> _valid(File file, int size, String hash) async {
    if (await file.length() != size) return false;
    final path = file.path;
    return await Isolate.run(() => _fileHash(path)) == hash;
  }

  Future<void> _receive(
    Uri url,
    int size,
    File part,
    int offset,
    CancelToken cancel,
    void Function(int) onProgress,
  ) async {
    final response = await dio.get<ResponseBody>(
      url.toString(),
      cancelToken: cancel,
      options: Options(
        responseType: ResponseType.stream,
        followRedirects: false,
        validateStatus: (status) => status == 200 || status == 206,
        headers: {
          'Accept-Encoding': 'identity',
          if (offset > 0) 'Range': 'bytes=$offset-',
        },
      ),
    );
    final body = response.data!;
    if (response.statusCode == 206) {
      final expected = 'bytes $offset-${size - 1}/$size';
      if (response.headers.value('content-range') != expected) {
        await body.stream.listen(null).cancel();
        throw const UpdateFailure('range');
      }
    } else {
      // A server may ignore Range. Truncate before writing its full response.
      offset = 0;
    }
    final output = await part.open(
      mode: offset > 0 ? FileMode.append : FileMode.write,
    );
    var received = offset;
    try {
      await for (final chunk in body.stream) {
        if (cancel.isCancelled) throw const UpdateFailure('cancelled');
        if (received + chunk.length > size) {
          throw const UpdateFailure('size');
        }
        await output.writeFrom(chunk);
        received += chunk.length;
        onProgress(received);
      }
      await output.flush();
    } finally {
      await output.close();
    }
    if (received != size) throw const UpdateFailure('network');
  }
}
