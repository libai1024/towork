import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/data/update/http_update_gateway.dart';
import 'package:towork/data/update/release_manifest.dart';
import 'package:towork/domain/update/app_update.dart';

import '../../support/update_fakes.dart';

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  late FutureOr<ResponseBody> Function(RequestOptions) respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  final manifest = Uri.parse('https://zhaozhaoyue.top/dl/towork/latest.json');
  final bytes = utf8.encode('signed fixture bytes');
  final hash = sha256.convert(bytes).toString();
  final cert = 'c' * 64;
  late Directory root;
  late _Adapter adapter;
  late Dio dio;
  late HttpUpdateGateway gateway;

  Map<String, dynamic> metadata() => {
    'schema': 1,
    'channel': 'stable',
    'rolloutPercent': 100,
    'versionName': '1.1.2',
    'versionCode': 4,
    'releaseNotes': ['更新'],
    'android': {
      'abi': 'arm64-v8a',
      'certSha256': cert,
      'full': {'url': 'android/app.apk', 'sha256': hash, 'size': bytes.length},
      'patches': <Object?>[],
    },
  };
  AppRelease release() => parseReleaseManifest(metadata(), manifest);
  InstalledApp installed({int code = 3, String? signer, List<String>? abis}) =>
      InstalledApp(
        versionName: '1.1.1',
        versionCode: code,
        canUpdate: true,
        certSha256: signer ?? cert,
        abis: abis ?? ['arm64-v8a'],
        availableBytes: 1000000,
      );
  File part() => File('${root.path}/4-$hash.apk.part');
  Matcher failure(String code) =>
      isA<UpdateFailure>().having((error) => error.code, 'code', code);
  Future<String> download({
    int space = 1000000,
    void Function(int)? progress,
  }) => gateway.download(
    release(),
    availableBytes: space,
    onProgress: progress ?? (_) {},
    onVerifying: () {},
  );
  setUp(() async {
    root = await Directory.systemTemp.createTemp('towork-update-test-');
    adapter = _Adapter();
    dio = Dio()..httpClientAdapter = adapter;
    gateway = HttpUpdateGateway(
      dio,
      directory: () async => root,
      manifest: manifest,
    );
  });
  tearDown(() async {
    dio.close(force: true);
    await root.delete(recursive: true);
  });

  test('strict manifest schema, immutable notes and same-origin HTTPS APK', () {
    final result = release();
    expect(
      result.url.toString(),
      'https://zhaozhaoyue.top/dl/towork/android/app.apk',
    );
    expect(() => result.notes.add('changed'), throwsUnsupportedError);
    for (final url in [
      'http://zhaozhaoyue.top/dl/towork/android/app.apk',
      'https://evil.test/app.apk',
      '../other.apk',
      '/dl/another/app.apk',
      'android/app.apk#bad',
    ]) {
      final raw = metadata();
      (raw['android']['full'] as Map<String, dynamic>)['url'] = url;
      expect(
        () => parseReleaseManifest(raw, manifest),
        throwsA(failure('manifest')),
      );
    }
    for (final change in [
      {'schema': 2},
      {'rolloutPercent': 50},
      {'versionCode': -1},
      {
        'releaseNotes': [42],
      },
    ]) {
      expect(
        () => parseReleaseManifest({...metadata(), ...change}, manifest),
        throwsA(failure('manifest')),
      );
    }
  });

  test('only newer, compatible and same-signer releases are offered', () async {
    adapter.respond = (_) =>
        ResponseBody.fromString(jsonEncode(metadata()), 200);
    expect((await gateway.check(installed()))?.versionCode, 4);
    expect(await gateway.check(installed(code: 4)), isNull);
    expect(await gateway.check(installed(code: 5)), isNull);
    await expectLater(
      gateway.check(installed(signer: 'd' * 64)),
      throwsA(failure('signature')),
    );
    await expectLater(
      gateway.check(installed(abis: ['x86_64'])),
      throwsA(failure('abi')),
    );
    expect(adapter.requests.first.followRedirects, isFalse);
  });

  test('malformed, oversized or redirected manifests fail closed', () async {
    adapter.respond = (_) => ResponseBody.fromString('{', 200);
    await expectLater(gateway.check(installed()), throwsA(failure('manifest')));
    adapter.respond = (_) =>
        ResponseBody.fromString(' ' * (256 * 1024 + 1), 200);
    await expectLater(gateway.check(installed()), throwsA(failure('manifest')));
    adapter.respond = (_) => ResponseBody.fromString('', 302);
    await expectLater(gateway.check(installed()), throwsA(failure('network')));
  });

  test(
    'verified full APK is atomically promoted and reused without a request',
    () async {
      adapter.respond = (_) => ResponseBody.fromBytes(bytes, 200);
      final path = await download();
      expect(await File(path).readAsBytes(), bytes);
      expect(await part().exists(), isFalse);
      expect(await download(), path);
      expect(adapter.requests, hasLength(1));
    },
  );

  test(
    'truncation preserves partial bytes and a new gateway resumes exact Range',
    () async {
      adapter.respond = (_) => ResponseBody.fromBytes(bytes.sublist(0, 6), 200);
      await expectLater(download(), throwsA(failure('network')));
      expect(await part().length(), 6);
      gateway = HttpUpdateGateway(
        dio,
        directory: () async => root,
        manifest: manifest,
      );
      adapter.respond = (request) {
        expect(request.headers['Range'], 'bytes=6-');
        return ResponseBody.fromBytes(
          bytes.sublist(6),
          206,
          headers: {
            'content-range': ['bytes 6-${bytes.length - 1}/${bytes.length}'],
          },
        );
      };
      expect(await File(await download()).readAsBytes(), bytes);
    },
  );

  test(
    'Range ignored by server truncates the partial before full download',
    () async {
      await part().writeAsBytes(bytes.sublist(0, 5));
      adapter.respond = (_) => ResponseBody.fromBytes(bytes, 200);
      expect(await File(await download()).readAsBytes(), bytes);
    },
  );

  test('wrong range and oversized bodies cannot become ready', () async {
    await part().writeAsBytes(bytes.sublist(0, 5));
    adapter.respond = (_) => ResponseBody.fromBytes(
      bytes.sublist(5),
      206,
      headers: {
        'content-range': ['bytes 0-3/4'],
      },
    );
    await expectLater(download(), throwsA(failure('range')));
    expect(await part().length(), 5);
    adapter.respond = (_) => ResponseBody.fromBytes([...bytes, 1], 200);
    await expectLater(download(), throwsA(failure('size')));
    expect(File('${root.path}/4-$hash.apk').existsSync(), isFalse);
  });

  test('checksum failure removes corruption and retry succeeds', () async {
    adapter.respond = (_) =>
        ResponseBody.fromBytes(List.filled(bytes.length, 1), 200);
    await expectLater(download(), throwsA(failure('checksum')));
    expect(await part().exists(), isFalse);
    adapter.respond = (_) => ResponseBody.fromBytes(bytes, 200);
    expect(await File(await download()).readAsBytes(), bytes);
  });

  test(
    'cancellation preserves bytes and concurrent download is rejected',
    () async {
      final stream = StreamController<Uint8List>();
      adapter.respond = (_) => ResponseBody(stream.stream, 200);
      final progress = Completer<void>();
      final pending = download(
        progress: (received) {
          if (received > 0 && !progress.isCompleted) progress.complete();
        },
      );
      final assertion = expectLater(pending, throwsA(failure('cancelled')));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await expectLater(download(), throwsA(failure('busy')));
      stream.add(Uint8List.fromList(bytes.sublist(0, 5)));
      await progress.future;
      gateway.cancel();
      await stream.close();
      await assertion;
      expect(await part().length(), 5);
    },
  );

  test(
    'space reclaimed from an old update counts toward the next download',
    () async {
      final old = File('${root.path}/3-${'a' * 64}.apk');
      await old.writeAsBytes(List<int>.filled(bytes.length * 2, 0));
      adapter.respond = (_) => ResponseBody.fromBytes(bytes, 200);
      expect(await File(await download(space: 0)).readAsBytes(), bytes);
      expect(await old.exists(), isFalse);
    },
  );

  test('space check occurs before network; stale cache stays within update directory', () async {
    adapter.respond = (_) => ResponseBody.fromBytes(bytes, 200);
    await expectLater(download(space: 0), throwsA(failure('space')));
    expect(adapter.requests, isEmpty);
    final old = File('${root.path}/3-${'a' * 64}.apk');
    final unrelated = File('${root.path}/notes.txt');
    await old.writeAsString('old');
    await unrelated.writeAsString('keep');
    await download();
    expect(await old.exists(), isFalse);
    expect(await unrelated.readAsString(), 'keep');
  });

  final patchBytes = utf8.encode('delta');
  final patchHash = sha256.convert(patchBytes).toString();
  Map<String, dynamic> deltaMetadata() {
    final raw = metadata();
    (raw['android'] as Map<String, dynamic>)['patches'] = [
      {
        'format': 'hdiffpatch',
        'fromVersionCode': 3,
        'fromSha256': 'a' * 64,
        'url': 'android/3-to-4.hpatch',
        'sha256': patchHash,
        'size': patchBytes.length,
      },
    ];
    return raw;
  }

  AppRelease deltaRelease() {
    final parsed = parseReleaseManifest(deltaMetadata(), manifest);
    return parsed.selectPatch(parsed.patches.single);
  }

  FakeUpdatePlatform enablePatching() {
    final platform = FakeUpdatePlatform();
    platform.patcher = (patch, output, _) async {
      expect(await File(patch).readAsBytes(), patchBytes);
      await File(output).writeAsBytes(bytes);
    };
    gateway = HttpUpdateGateway(
      dio,
      directory: () async => root,
      manifest: manifest,
      platform: platform,
    );
    return platform;
  }

  Future<String> downloadDelta({
    void Function()? fallback,
    void Function(int)? progress,
  }) => gateway.download(
    deltaRelease(),
    availableBytes: 1000000,
    onProgress: progress ?? (_) {},
    onVerifying: () {},
    onFallback: fallback,
  );

  test(
    'delta selection requires exact installed APK hash and version',
    () async {
      enablePatching();
      adapter.respond = (_) =>
          ResponseBody.fromString(jsonEncode(deltaMetadata()), 200);
      expect((await gateway.check(installed()))!.patch, isNull);
      final exact = InstalledApp(
        versionCode: 3,
        certSha256: cert,
        abis: ['arm64-v8a'],
        apkSha256: 'a' * 64,
      );
      expect((await gateway.check(exact))!.downloadSize, patchBytes.length);
      final wrongCode = InstalledApp(
        versionCode: 2,
        certSha256: cert,
        abis: ['arm64-v8a'],
        apkSha256: 'a' * 64,
      );
      expect((await gateway.check(wrongCode))!.patch, isNull);
      for (final change in [
        {'format': 'unknown'},
        {'url': 'https://evil.test/android/a.hpatch'},
        {'size': -1},
        {'fromSha256': 'bad'},
        {'fromVersionCode': 4},
      ]) {
        final raw = deltaMetadata();
        final patches = (raw['android'] as Map)['patches'] as List;
        patches[0] = <String, Object>{
          ...patches[0] as Map<String, Object>,
          ...change,
        };
        expect(parseReleaseManifest(raw, manifest).patches, isEmpty);
      }
    },
  );

  test(
    'verified patch reconstructs the exact APK without downloading full bytes',
    () async {
      enablePatching();
      adapter.respond = (request) {
        expect(request.uri.path.endsWith('.hpatch'), isTrue);
        return ResponseBody.fromBytes(patchBytes, 200);
      };
      var fallback = false;
      final path = await downloadDelta(fallback: () => fallback = true);
      expect(await File(path).readAsBytes(), bytes);
      expect(adapter.requests, hasLength(1));
      expect(fallback, isFalse);
      expect(await downloadDelta(), path);
      expect(adapter.requests, hasLength(1));
    },
  );

  test('bad patch hash falls back to a validated full APK', () async {
    final platform = enablePatching();
    platform.patcher = (_, _, _) async =>
        fail('corrupt patch reached native code');
    adapter.respond = (request) => ResponseBody.fromBytes(
      request.uri.path.endsWith('.hpatch')
          ? List.filled(patchBytes.length, 0)
          : bytes,
      200,
    );
    var fallbacks = 0;
    final path = await downloadDelta(fallback: () => fallbacks++);
    expect(await File(path).readAsBytes(), bytes);
    expect(fallbacks, 1);
    expect(adapter.requests, hasLength(2));
  });

  test(
    'incorrect reconstructed bytes and native failures use full fallback',
    () async {
      final platform = enablePatching();
      platform.patcher = (_, output, _) async =>
          File(output).writeAsString('bad');
      adapter.respond = (request) => ResponseBody.fromBytes(
        request.uri.path.endsWith('.hpatch') ? patchBytes : bytes,
        200,
      );
      final first = await downloadDelta();
      expect(await File(first).readAsBytes(), bytes);
      await File(first).delete();
      platform.patcher = (_, _, _) async => throw const UpdateFailure('patch');
      expect(await File(await downloadDelta()).readAsBytes(), bytes);
    },
  );

  test(
    'pausing a patch retains its Range offset and never falls back',
    () async {
      enablePatching();
      final stream = StreamController<Uint8List>();
      adapter.respond = (_) => ResponseBody(stream.stream, 200);
      final started = Completer<void>();
      final pending = downloadDelta(
        fallback: () => fail('pause must not download full APK'),
        progress: (count) {
          if (count > 0 && !started.isCompleted) started.complete();
        },
      );
      final assertion = expectLater(pending, throwsA(failure('cancelled')));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      stream.add(Uint8List.fromList(patchBytes.sublist(0, 2)));
      await started.future;
      gateway.cancel();
      await stream.close();
      await assertion;
      adapter.respond = (request) {
        expect(request.headers['Range'], 'bytes=2-');
        return ResponseBody.fromBytes(
          patchBytes.sublist(2),
          206,
          headers: {
            'content-range': [
              'bytes 2-${patchBytes.length - 1}/${patchBytes.length}',
            ],
          },
        );
      };
      expect(await File(await downloadDelta()).readAsBytes(), bytes);
    },
  );

  test('resuming a full fallback avoids fetching the patch again', () async {
    enablePatching();
    await part().writeAsBytes(bytes.sublist(0, 5));
    adapter.respond = (request) {
      expect(request.uri.path.endsWith('.apk'), isTrue);
      expect(request.headers['Range'], 'bytes=5-');
      return ResponseBody.fromBytes(
        bytes.sublist(5),
        206,
        headers: {
          'content-range': ['bytes 5-${bytes.length - 1}/${bytes.length}'],
        },
      );
    };
    var fallback = false;
    expect(
      await File(await downloadDelta(fallback: () => fallback = true))
          .readAsBytes(),
      bytes,
    );
    expect(fallback, isTrue);
  });
}
