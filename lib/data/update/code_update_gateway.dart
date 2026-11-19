import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_patcher/flutter_patcher.dart';

import '../../domain/update/app_update.dart';
import '../../domain/update/code_update.dart';

/// Captured once per engine before any update is committed in this process.
CodeUpdateStatus? _bootStatus;

Future<void> initializeCodeUpdates() async {
  _bootStatus ??= await _initialize();
}

Future<CodeUpdateStatus> _initialize() async {
  if (kIsWeb ||
      !kReleaseMode ||
      defaultTargetPlatform != TargetPlatform.android) {
    return const CodeUpdateStatus();
  }
  try {
    final strategy = await const MethodChannel('flutter_patcher')
        .invokeMethod<String>('hostStrategy');
    if (strategy == null) return const CodeUpdateStatus();
    await FlutterPatcher.init();
    return CodeUpdateStatus(
      supported: true,
      activeVersion: await FlutterPatcher.currentVersion,
    );
  } on MissingPluginException {
    return const CodeUpdateStatus();
  } on PlatformException {
    // API 24–27 run the base app. The native authenticated host requires 28+.
    return const CodeUpdateStatus();
  }
}

class SignedCodeUpdateGateway implements CodeUpdateGateway {
  SignedCodeUpdateGateway(this.dio);
  final Dio dio;
  static final base = Uri.parse('https://zhaozhaoyue.top/dl/towork/patches/');
  CancelToken? _cancel;

  @override
  Future<CodeUpdateStatus> status() async {
    await initializeCodeUpdates();
    final boot = _bootStatus!;
    return CodeUpdateStatus(
      supported: boot.supported,
      activeVersion: boot.activeVersion,
      pending:
          boot.supported &&
          await FlutterPatcher.currentVersion != boot.activeVersion,
    );
  }

  @override
  Future<CodeUpdate?> check() async {
    final result = await FlutterPatcher.checkUpdate(url: base.toString());
    final patch = result.patch;
    if (!result.hasUpdate || patch == null) return null;
    final wire = patch.raw['signed_manifest'] as String;
    final fields = SignedManifest.parse(wire).fields;
    if (fields['action'] == 'withdraw') {
      return CodeUpdate(version: patch.version, manifest: wire, size: 0);
    }
    final path = fields['path']!;
    final size = int.parse(fields['size']!);
    if (!RegExp(r'^objects/[a-f0-9]{32}/[a-f0-9]{64}\.fptc$').hasMatch(path) ||
        size <= 0 ||
        size > 128 * 1024 * 1024) {
      throw const UpdateFailure('manifest');
    }
    return CodeUpdate(
      version: patch.version,
      manifest: wire,
      size: size,
      url: base.resolve(path),
    );
  }

  @override
  Future<void> apply(
    CodeUpdate update, {
    required void Function(int bytes) onProgress,
    required void Function() onVerifying,
  }) async {
    final token = _cancel = CancelToken();
    final bytes = BytesBuilder(copy: false);
    try {
      if (update.url case final url?) {
        final response = await dio.get<ResponseBody>(
          url.toString(),
          cancelToken: token,
          options: Options(
            responseType: ResponseType.stream,
            followRedirects: false,
          ),
        );
        if (response.statusCode != 200 || response.data == null) {
          throw const UpdateFailure('network');
        }
        await for (final chunk in response.data!.stream.timeout(
          const Duration(seconds: 30),
        )) {
          if (token.isCancelled) throw const UpdateFailure('code_cancelled');
          bytes.add(chunk);
          if (bytes.length > update.size) throw const UpdateFailure('size');
          onProgress(bytes.length);
        }
        if (bytes.length != update.size) throw const UpdateFailure('size');
      }
      if (token.isCancelled) throw const UpdateFailure('code_cancelled');
      onVerifying();
      final result = await FlutterPatcher.applySignedManifest(
        SignedManifest.parse(update.manifest),
        payload: bytes.takeBytes(),
      );
      if (!result.result.ok) throw const UpdateFailure('code_signature');
    } on DioException catch (error) {
      throw UpdateFailure(
        CancelToken.isCancel(error) ? 'code_cancelled' : 'network',
      );
    } finally {
      if (identical(_cancel, token)) _cancel = null;
    }
  }

  @override
  Future<void> restart() async {
    try {
      await const MethodChannel('towork/code_update')
          .invokeMethod<void>('restart');
    } on PlatformException catch (error) {
      throw UpdateFailure(error.code);
    }
  }

  @override
  void cancel() => _cancel?.cancel();
}
