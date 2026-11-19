import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// 资产字节加载器（app 层注入 rootBundle.load，data 层不依赖 services）。
typedef AssetByteLoader = Future<ByteData> Function(String assetPath);

/// 流式把资产复制到目标路径（Android 原生 AssetManager 流），避免把
/// 两百多 MB 的模型整体读进内存。由 app 层注入；缺省时退回 [AssetByteLoader]。
typedef AssetFileCopier = Future<void> Function(
  String assetPath,
  String targetPath,
);

enum AsrModelFamily { senseVoice, sileroVad }

/// 一个离线模型的文件清单与来源。字节数取自官方 HF 元数据，不匹配即判损坏。
class AsrModelSpec {
  const AsrModelSpec({
    required this.id,
    required this.family,
    required this.files,
    required this.modelFile,
    this.tokensFile,
    this.repo,
    this.assetDir,
  });

  /// 本地目录名（`<root>/asr-model/<id>`）。
  final String id;
  final AsrModelFamily family;
  final Map<String, int> files;
  final String modelFile;
  final String? tokensFile;

  /// HF 仓库；null 表示只随包提供、不支持联网下载。
  final String? repo;

  /// pubspec 注册的内置资产目录；null 表示只能下载。
  final String? assetDir;

  int get totalBytes => files.values.reduce((a, b) => a + b);

  /// 内置 SenseVoiceSmall int8（中英日韩粤，开启 ITN 后带标点与数字
  /// 规整，Apache-2.0 等见 sherpa-onnx 发布页）。约 228MB，随包提供。
  /// 注意：2025-09-09 版是粤语微调、官方明确不支持标点，故选 2024-07-17。
  /// HF 仓库仅作资产损坏时的联网兜底。
  static const senseVoiceInt8 = AsrModelSpec(
    id: 'sense-voice-int8-2024-07-17',
    family: AsrModelFamily.senseVoice,
    repo: 'csukuangfj/sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17',
    assetDir: 'assets/asr/sense-voice-int8',
    modelFile: 'model.int8.onnx',
    tokensFile: 'tokens.txt',
    files: {'model.int8.onnx': 239233841, 'tokens.txt': 315894},
  );

  /// 早期版本随包的 Paraformer 安装目录；升级后清理以回收约 78MB。
  static const retiredIds = ['paraformer-zh-small'];

  /// 随包 Silero VAD（约 0.6MB），用于分句与实时预览。
  static const sileroVad = AsrModelSpec(
    id: 'silero-vad',
    family: AsrModelFamily.sileroVad,
    assetDir: 'assets/asr/silero-vad',
    modelFile: 'silero_vad.onnx',
    files: {'silero_vad.onnx': 643854},
  );
}

/// 离线模型的本地安装：随包资产首启复制到本地，或从 HF（失败切镜像）
/// 逐文件下载，文件级断点续传。默认是内置 SenseVoice。
class OfflineAsrModelStore {
  OfflineAsrModelStore(
    this._dio, {
    required this.root,
    this.spec = AsrModelSpec.senseVoiceInt8,
  });

  final Dio _dio;
  final Directory root;
  final AsrModelSpec spec;

  List<String> get _mirrors => [
    if (spec.repo case final repo?) ...[
      'https://huggingface.co/$repo/resolve/main',
      // 大陆可达镜像；内容与 HF 同源。
      'https://hf-mirror.com/$repo/resolve/main',
    ],
  ];

  /// 内置识别模型的资产目录、总量与清单。
  static final assetDir = AsrModelSpec.senseVoiceInt8.assetDir!;
  static int get totalBytes => AsrModelSpec.senseVoiceInt8.totalBytes;
  static Map<String, int> get expectedBytes =>
      Map.unmodifiable(AsrModelSpec.senseVoiceInt8.files);

  /// 删除已退役模型的安装目录（升级后回收空间）。
  static Future<void> removeRetired(Directory root) async {
    for (final id in AsrModelSpec.retiredIds) {
      final dir = Directory('${root.path}/asr-model/$id');
      if (await dir.exists()) await dir.delete(recursive: true);
    }
  }

  Map<String, int> get _expectedBytes => spec.files;

  Directory get _dir => Directory('${root.path}/asr-model/${spec.id}');
  String get modelPath => '${_dir.path}/${spec.modelFile}';
  String get tokensPath =>
      spec.tokensFile == null ? '' : '${_dir.path}/${spec.tokensFile}';

  bool get isReady {
    if (kIsWeb) return false;
    for (final entry in _expectedBytes.entries) {
      final file = File('${_dir.path}/${entry.key}');
      if (!file.existsSync() || file.lengthSync() != entry.value) return false;
    }
    return true;
  }

  Future<void> delete() async {
    if (await _dir.exists()) await _dir.delete(recursive: true);
  }

  Future<void>? _installing;

  /// 把随包内置的模型资产安装到本地；已就绪时为空操作，并发调用共享同一
  /// 次安装。有 [copy] 时流式复制（内存恒定），否则经 [load] 整体读入。
  /// 写入 `.part` 后校验字节数再改名，中途被杀不会留下“就绪”的半成品。
  /// 失败抛错且允许重试；联网下载可作兜底。
  Future<void> installFromAssets(
    AssetByteLoader load, {
    AssetFileCopier? copy,
    void Function(int installedBytes)? onProgress,
  }) {
    if (kIsWeb) return Future.value();
    if (spec.assetDir == null) {
      return Future.error(StateError('${spec.id} is not bundled'));
    }
    if (isReady) {
      onProgress?.call(spec.totalBytes);
      return Future.value();
    }
    return _installing ??= _installFromAssets(load, copy, onProgress);
  }

  Future<void> _installFromAssets(
    AssetByteLoader load,
    AssetFileCopier? copy,
    void Function(int installedBytes)? onProgress,
  ) async {
    try {
      await _dir.create(recursive: true);
      var done = 0;
      for (final entry in _expectedBytes.entries) {
        final name = entry.key;
        if (_fileComplete(name)) {
          done += entry.value;
          onProgress?.call(done);
          continue;
        }
        final assetPath = '${spec.assetDir}/$name';
        final target = File('${_dir.path}/$name');
        final part = File('${target.path}.part');
        if (copy != null) {
          await copy(assetPath, part.path);
          if (!await part.exists() || await part.length() != entry.value) {
            if (await part.exists()) await part.delete();
            throw StateError('asset size mismatch: $name');
          }
        } else {
          final asset = await load(assetPath);
          if (asset.lengthInBytes != entry.value) {
            throw StateError('asset size mismatch: $name');
          }
          await part.writeAsBytes(
            asset.buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes),
            flush: true,
          );
        }
        await part.rename(target.path);
        done += entry.value;
        onProgress?.call(done);
      }
      assert(isReady, 'asset install completed but verification failed');
    } finally {
      _installing = null;
    }
  }

  /// 逐文件下载（HF 失败自动切镜像），进度按总字节折算。
  /// 已完整的文件跳过——中断后重试即断点级续传（文件级）。
  Future<void> download({
    void Function(int downloadedBytes)? onProgress,
    CancelToken? cancelToken,
  }) async {
    if (_mirrors.isEmpty) {
      throw StateError('${spec.id} has no download source');
    }
    await _dir.create(recursive: true);
    var done = _expectedBytes.entries
        .where((e) => _fileComplete(e.key))
        .fold<int>(0, (sum, e) => sum + e.value);
    onProgress?.call(done);
    for (final entry in _expectedBytes.entries) {
      final name = entry.key;
      if (_fileComplete(name)) continue;
      final target = File('${_dir.path}/$name');
      final part = File('${target.path}.part');
      Object? lastError;
      for (final base in _mirrors) {
        try {
          await _dio.download(
            '$base/$name',
            part.path,
            cancelToken: cancelToken,
            options: Options(
              headers: const {'Accept': 'application/octet-stream'},
            ),
            onReceiveProgress: (count, _) => onProgress?.call(done + count),
          );
          if (part.lengthSync() != entry.value) {
            throw const FileSystemException('size mismatch');
          }
          await part.rename(target.path);
          done += entry.value;
          onProgress?.call(done);
          lastError = null;
          break;
        } on DioException catch (error) {
          if (CancelToken.isCancel(error)) rethrow;
          lastError = error;
        } catch (error) {
          lastError = error;
        }
      }
      if (lastError != null) {
        throw StateError('model download failed: $name ($lastError)');
      }
    }
    assert(isReady, 'download completed but verification failed');
  }

  bool _fileComplete(String name) {
    final file = File('${_dir.path}/$name');
    return file.existsSync() && file.lengthSync() == _expectedBytes[name];
  }
}
