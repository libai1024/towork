import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show MethodChannel, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:towork/data/platform/offline_asr_model_store.dart';
import 'package:towork/data/platform/sherpa_speech_input.dart';
import 'package:towork/data/platform/speech_input_selector.dart';
import 'package:towork/features/chat/view_models/speech_capture_controller.dart';

import '../test/support/free/fake_speech.dart';
import 'fixtures/zh_sample_wav.dart';

/// 真实识别管线验收：随包 SenseVoice 资产 → 原生流式安装到本地 → sherpa FFI 装载 →
/// 解码一段真实中文语音（模型仓库官方测试样本，16k/mono/PCM16，与
/// record 采集格式一致）。跑在 Android / macOS；不涉及麦克风权限。
/// 语音样本以 gzip+base64 常量内嵌在测试源码（fixtures/zh_sample_wav.dart），
/// 只随测试构建编译；pubspec 不再声明它为资产，正式包不含测试样本。
///
///     flutter test integration_test/asr_pipeline_test.dart -d macos
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (const bool.fromEnvironment('ASR_MIC_SMOKE')) {
    testWidgets(
      'Android microphone delivers 16k mono PCM and releases cleanly',
      (tester) async {
        final recorder = RecordPcmRecorder();
        try {
          expect(await recorder.hasPermission(request: false), isTrue);
          final stream = await recorder.startPcm();
          var bytes = 0;
          final received = Completer<void>();
          final subscription = stream.listen((chunk) {
            bytes += chunk.length;
            if (bytes >= 8000 && !received.isCompleted) received.complete();
          });
          try {
            await received.future.timeout(const Duration(seconds: 5));
            await recorder.stopPcm();
            expect(bytes, greaterThanOrEqualTo(8000));
            // ignore: avoid_print
            print('Android AudioRecord PCM bytes: $bytes');
          } finally {
            await subscription.cancel();
          }
        } finally {
          await recorder.dispose();
        }
      },
    );
  }

  testWidgets('bundled model installs and decodes real Chinese speech', (
    tester,
  ) async {
    final support = await getApplicationSupportDirectory();
    final store = OfflineAsrModelStore(Dio(), root: support);
    await store.installFromAssets(rootBundle.load, copy: _copy);
    expect(store.isReady, isTrue, reason: '内置模型资产应安装成功');

    final pcm = _pcm16FromWav(zhSampleWavBytes(), 'zh-sample.wav');
    expect(pcm.lengthInBytes, greaterThan(16000 * 2), reason: '样本应长于 1 秒');

    final input = SherpaSpeechInput(store: store);
    addTearDown(input.dispose);
    var uiTicks = 0;
    final ticker = Timer.periodic(
      const Duration(milliseconds: 10),
      (_) => uiTicks++,
    );
    final stopwatch = Stopwatch()..start();
    late String text;
    try {
      text = await input.decodePcm16(pcm);
    } finally {
      ticker.cancel();
    }
    // ignore: avoid_print
    print('Cold ASR: ${stopwatch.elapsedMilliseconds} ms; UI ticks: $uiTicks');
    expect(uiTicks, greaterThan(0), reason: '模型装载/推理不能阻塞主 isolate');
    // ignore: avoid_print
    print('ASR transcript: "$text"');
    expect(text, isNotEmpty, reason: '离线解码应产出非空转写');
    // 离线模型对固定输入的转写是确定性的；样本为中文金融评论开头。
    expect(text, contains('三个问题'));
    expect(text, contains('金融'));
  });
  testWidgets(
    'PCM capture through Android selector reaches final and submission once',
    (tester) async {
      final support = await getApplicationSupportDirectory();
      final store = OfflineAsrModelStore(Dio(), root: support);
      await store.installFromAssets(rootBundle.load, copy: _copy);
      final pcm = _pcm16FromWav(zhSampleWavBytes(), 'zh-sample.wav');
      final native =
          FakeSpeechInput(); // Available native must still be bypassed.
      final offline = SherpaSpeechInput(
        store: store,
        recorderFactory: () async => _FixtureRecorder(pcm),
      );
      final selector = SpeechInputSelector(
        native,
        offline,
        preferOffline: true,
      );
      final submitted = Completer<String>();
      var submissions = 0;
      final capture = SpeechCaptureController(
        input: selector,
        hasNetworkRoute: () async => true,
        waitForRelease: true,
        autoSendDelay: Duration.zero,
        finalTimeout: const Duration(seconds: 30),
        submit: (text, id) async {
          submissions++;
          submitted.complete(text);
          return true;
        },
        cancelSubmission: () {},
      );
      try {
        await capture.start();
        expect(
          capture.snapshot.phase,
          SpeechPhase.recording,
          reason: '同步 listening 事件必须抵达控制器',
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await capture.stop();
        final text = await submitted.future.timeout(
          const Duration(seconds: 30),
        );
        expect(text, contains('三个问题'));
        expect(submissions, 1);
        expect(native.starts, isEmpty);
        // ignore: avoid_print
        print('Full capture transcript: "$text"');
      } finally {
        capture.dispose();
        await selector.dispose();
        await offline.dispose();
        await native.bus.close();
      }
    },
  );
}

/// Production install path: the native bridge streams assets on Android.
Future<void> Function(String, String)? get _copy => Platform.isAndroid
    ? (asset, target) => const MethodChannel('towork/assets')
          .invokeMethod<void>('copyAsset', {'asset': asset, 'target': target})
    : null;

/// 校验 RIFF/WAVE（PCM16 mono 16k）样本并抽出 PCM 字节。样本字节来自
/// 内嵌常量：桌面/移动实机的测试进程被沙盒限制在 app 容器内，文件系统
/// 读不到仓库目录；而若把样本声明为 pubspec 资产，它会进入正式发布包。
/// 内嵌进测试源码两头都满足（见 fixtures/zh_sample_wav.dart）。
Uint8List _pcm16FromWav(Uint8List wav, String name) {
  expect(wav.sublist(0, 4), equals('RIFF'.codeUnits), reason: '$name 非 WAV');
  var pos = 12;
  int? channels;
  int? sampleRate;
  int? bits;
  Uint8List? data;
  while (pos + 8 <= wav.length) {
    final view = ByteData.sublistView(wav);
    final id = String.fromCharCodes(wav.sublist(pos, pos + 4));
    final size = view.getUint32(pos + 4, Endian.little);
    if (id == 'fmt ') {
      channels = view.getUint16(pos + 10, Endian.little);
      sampleRate = view.getUint32(pos + 12, Endian.little);
      bits = view.getUint16(pos + 22, Endian.little);
    } else if (id == 'data') {
      data = Uint8List.sublistView(wav, pos + 8, pos + 8 + size);
      break;
    }
    pos += 8 + size + (size % 2);
  }
  expect(data, isNotNull, reason: '$name 缺 data 块');
  expect(bits, 16, reason: '$name 应为 16bit PCM');
  expect(channels, 1, reason: '$name 应为单声道');
  expect(sampleRate, 16000, reason: '$name 应为 16kHz');
  return data!;
}

class _FixtureRecorder implements AsrRecorder {
  _FixtureRecorder(this.pcm);
  final Uint8List pcm;
  final chunks = StreamController<Uint8List>();
  bool started = false;
  @override
  Future<bool> hasPermission({bool request = true}) async => true;
  @override
  Future<Stream<Uint8List>> startPcm() async {
    started = true;
    chunks.add(pcm);
    return chunks.stream;
  }

  @override
  Future<void> stopPcm() async {
    await chunks.close();
  }

  @override
  Future<void> dispose() async {
    if (started) {
      await chunks.close();
    } else {
      unawaited(chunks.close());
    }
  }
}
