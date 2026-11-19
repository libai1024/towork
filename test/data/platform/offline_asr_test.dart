import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/data/platform/native_speech_input.dart';
import 'package:towork/data/platform/offline_asr_model_store.dart';
import 'package:towork/data/platform/sherpa_speech_input.dart';
import 'package:towork/data/platform/speech_input_selector.dart';
import 'package:towork/domain/speech/speech_input.dart';
import 'package:towork/core/widgets/ai_markdown.dart';
import 'package:towork/theme/app_theme.dart';

/// 可编程 dio 适配器：按 URL 片段返回字节或抛错。
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.routes);
  final Map<String, Object> routes;
  final requests = <String>[];
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final url = options.uri.toString();
    requests.add(url);
    for (final entry in routes.entries) {
      if (!url.contains(entry.key)) continue;
      final value = entry.value;
      if (value is List<int>) {
        return ResponseBody(
          Stream.value(Uint8List.fromList(value)),
          200,
          headers: {
            'content-length': ['${value.length}'],
          },
        );
      }
      throw value as DioException;
    }
    throw DioException(requestOptions: options, error: StateError('no route'));
  }
}

/// HF 全部 503，hf-mirror 成功。
class _MirrorAdapter implements HttpClientAdapter {
  _MirrorAdapter({required this.goodBytes});
  final Map<String, List<int>> goodBytes;
  int hfFailures = 0;
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final url = options.uri.toString();
    if (url.contains('huggingface.co')) {
      hfFailures++;
      throw DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 503),
      );
    }
    final name = url.split('/').last;
    final bytes = goodBytes[name]!;
    return ResponseBody(
      Stream.value(Uint8List.fromList(bytes)),
      200,
      headers: {
        'content-length': ['${bytes.length}'],
      },
    );
  }
}

Uint8List _bytes(int size) => Uint8List.fromList(List.filled(size, 7));

/// Tiny stand-in so store tests don't allocate the real 228 MB model.
const _tiny = AsrModelSpec(
  id: 'tiny',
  family: AsrModelFamily.senseVoice,
  repo: 'org/tiny',
  assetDir: 'assets/asr/tiny',
  modelFile: 'model.int8.onnx',
  tokensFile: 'tokens.txt',
  files: {'model.int8.onnx': 4096, 'tokens.txt': 64},
);

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('asr-store-');
  });
  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test('download writes files, verifies sizes and reports progress', () async {
    final entries = _tiny.files;
    final store = OfflineAsrModelStore(
      Dio()
        ..httpClientAdapter = _FakeAdapter({
          for (final e in entries.entries) e.key: _bytes(e.value),
        }),
      root: dir,
      spec: _tiny,
    );
    final progress = <int>[];
    await store.download(onProgress: progress.add);
    expect(store.isReady, isTrue);
    expect(progress.last, entries.values.reduce((a, b) => a + b));
    // 已完整文件跳过：再次下载进度立即到达总量。
    final again = <int>[];
    await store.download(onProgress: again.add);
    expect(again.first, entries.values.reduce((a, b) => a + b));
  });

  test('huggingface failure falls back to hf-mirror', () async {
    final entries = _tiny.files;
    final adapter = _MirrorAdapter(
      goodBytes: {for (final e in entries.entries) e.key: _bytes(e.value)},
    );
    final store = OfflineAsrModelStore(
      Dio()..httpClientAdapter = adapter,
      root: dir,
      spec: _tiny,
    );
    await store.download();
    expect(store.isReady, isTrue);
    expect(adapter.hfFailures, greaterThanOrEqualTo(2));
  });

  test('size mismatch keeps store not ready', () async {
    final entries = _tiny.files;
    final store = OfflineAsrModelStore(
      Dio()
        ..httpClientAdapter = _FakeAdapter({
          for (final e in entries.entries) e.key: _bytes(e.value - 1),
        }),
      root: dir,
      spec: _tiny,
    );
    await expectLater(store.download(), throwsA(isA<StateError>()));
    expect(store.isReady, isFalse);
  });

  test('installFromAssets copies verified bundled assets', () async {
    final entries = _tiny.files;
    final loads = <String>[];
    final progress = <int>[];
    final store = OfflineAsrModelStore(Dio(), root: dir, spec: _tiny);
    await store.installFromAssets((path) {
      loads.add(path);
      return Future.value(
        ByteData.sublistView(_bytes(entries[path.split('/').last]!)),
      );
    }, onProgress: progress.add);
    expect(store.isReady, isTrue);
    expect(loads, [
      for (final e in entries.entries) '${_tiny.assetDir}/${e.key}',
    ]);
    expect(progress.last, entries.values.reduce((a, b) => a + b));
    // 已就绪时再次安装为空操作，不再读取资产。
    loads.clear();
    await store.installFromAssets((path) async {
      loads.add(path);
      return ByteData.sublistView(_bytes(1));
    });
    expect(loads, isEmpty);
  });

  test('installFromAssets rejects wrong-size assets and can retry', () async {
    final entries = _tiny.files;
    final store = OfflineAsrModelStore(Dio(), root: dir, spec: _tiny);
    // 资产尺寸不符：拒绝且不落盘完整文件。
    await expectLater(
      store.installFromAssets(
        (path) async =>
            ByteData.sublistView(_bytes(entries[path.split('/').last]! - 1)),
      ),
      throwsA(isA<StateError>()),
    );
    expect(store.isReady, isFalse);
    // 修正后重试成功。
    await store.installFromAssets(
      (path) async =>
          ByteData.sublistView(_bytes(entries[path.split('/').last]!)),
    );
    expect(store.isReady, isTrue);
  });

  testWidgets('AiMarkdown renders bold, list and code blocks', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: AiMarkdown(
            text: '**重点** 待办\n\n- 第一项\n- 第二项\n\n```\nblock\n```',
          ),
        ),
      ),
    );
    expect(find.text('重点 待办'), findsOneWidget);
    expect(find.text('第一项'), findsOneWidget);
    expect(find.text('第二项'), findsOneWidget);
    expect(find.text('block'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('SenseVoice is the bundled default and matches its asset', () {
    final store = OfflineAsrModelStore(Dio(), root: dir);
    expect(store.spec, AsrModelSpec.senseVoiceInt8);
    expect(OfflineAsrModelStore.assetDir, 'assets/asr/sense-voice-int8');
    expect(
      store.modelPath,
      endsWith('sense-voice-int8-2024-07-17/model.int8.onnx'),
    );
    for (final e in AsrModelSpec.senseVoiceInt8.files.entries) {
      final file = File('assets/asr/sense-voice-int8/${e.key}');
      expect(
        file.lengthSync(),
        e.value,
        reason: '${e.key}: run tool/fetch_asr_models.sh',
      );
    }
  });

  test('streaming copier installs without loading bytes into memory', () async {
    final copies = <String>[];
    final store = OfflineAsrModelStore(Dio(), root: dir, spec: _tiny);
    await store.installFromAssets(
      (_) => throw StateError('must not load whole assets'),
      copy: (asset, target) async {
        copies.add(asset);
        await File(target)
            .writeAsBytes(_bytes(_tiny.files[asset.split('/').last]!));
      },
    );
    expect(store.isReady, isTrue);
    expect(copies, [
      'assets/asr/tiny/model.int8.onnx',
      'assets/asr/tiny/tokens.txt',
    ]);
    expect(
      dir.listSync(recursive: true).where((f) => f.path.endsWith('.part')),
      isEmpty,
    );
  });

  test(
    'truncated streaming copy is rejected and leaves no part file',
    () async {
      final store = OfflineAsrModelStore(Dio(), root: dir, spec: _tiny);
      await expectLater(
        store.installFromAssets(
          (_) => throw StateError('unused'),
          copy: (asset, target) => File(target).writeAsBytes(_bytes(10)),
        ),
        throwsStateError,
      );
      expect(store.isReady, isFalse);
      expect(
        dir.listSync(recursive: true).where((f) => f.path.endsWith('.part')),
        isEmpty,
      );
    },
  );

  test('retired Paraformer install is removed on upgrade', () async {
    final old = Directory('${dir.path}/asr-model/paraformer-zh-small')
      ..createSync(recursive: true);
    File('${old.path}/model.int8.onnx').writeAsBytesSync(_bytes(8));
    final vad = Directory('${dir.path}/asr-model/silero-vad')
      ..createSync(recursive: true);
    await OfflineAsrModelStore.removeRetired(dir);
    expect(old.existsSync(), isFalse);
    expect(vad.existsSync(), isTrue);
  });

  test('VAD is bundle-only and installs from assets', () async {
    const spec = AsrModelSpec.sileroVad;
    final store = OfflineAsrModelStore(Dio(), root: dir, spec: spec);
    await expectLater(store.download(), throwsStateError);
    await store.installFromAssets((path) async {
      expect(path, 'assets/asr/silero-vad/silero_vad.onnx');
      return ByteData(spec.files.values.single);
    });
    expect(store.isReady, isTrue);
    expect(store.tokensPath, isEmpty);
  });

  test('bundled VAD asset matches the pinned size', () {
    final file = File('assets/asr/silero-vad/silero_vad.onnx');
    expect(file.lengthSync(), AsrModelSpec.sileroVad.files['silero_vad.onnx']);
  });

  test(
    'selector routes to offline when native bridge is unavailable',
    () async {
      // 伪就绪模型目录。
      final modelDir = Directory('${dir.path}/asr-model/tiny')
        ..createSync(recursive: true);
      for (final e in _tiny.files.entries) {
        File('${modelDir.path}/${e.key}').writeAsBytesSync(_bytes(e.value));
      }
      final store = OfflineAsrModelStore(Dio(), root: dir, spec: _tiny);
      expect(store.isReady, isTrue);

      final offline = SherpaSpeechInput(
        store: store,
        recorderFactory: () async => _DenyRecorder(),
      );
      // 测试环境无原生桥 → native.prepare 抛错，选择器必须回退到离线输入。
      final selector = SpeechInputSelector(NativeSpeechInput(), offline);
      addTearDown(offline.dispose);
      addTearDown(selector.dispose);

      final caps = await selector.prepare('zh-CN');
      expect(caps.available, isTrue, reason: '模型就绪时离线可用');

      await expectLater(
        selector.start('cap1', locale: 'zh-CN', onDevice: false),
        throwsA(
          isA<SpeechFailure>().having(
            (f) => f.code,
            'code',
            SpeechFailureCode.permissionDenied,
          ),
        ),
        reason: '无麦克风权限的失败必须来自离线输入（证明路由正确）',
      );
    },
  );
}

class _DenyRecorder implements AsrRecorder {
  @override
  Future<bool> hasPermission({bool request = true}) async => false;
  @override
  Future<Stream<Uint8List>> startPcm() => throw StateError('no');
  @override
  Future<void> stopPcm() async {}
  @override
  Future<void> dispose() async {}
}
