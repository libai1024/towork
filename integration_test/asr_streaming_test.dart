import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show MethodChannel, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:towork/data/platform/offline_asr_decoder.dart';
import 'package:towork/data/platform/offline_asr_model_store.dart';
import 'package:towork/data/platform/sherpa_speech_input.dart';
import 'package:towork/domain/speech/speech_input.dart';

import 'fixtures/paced_audio.dart';
import 'fixtures/zh_en_sample_wav.dart';
import 'fixtures/zh_sample_wav.dart';

/// Real-FFI acceptance of the bundled SenseVoice + VAD streaming recognizer.
///
/// Models are installed exactly as in production: streamed from the APK by
/// the native `towork/assets` bridge. Audio is replayed through the capture
/// path in 100 ms chunks at real-time pace, as the microphone delivers it,
/// so partial timings mean what they would on a phone (emulator CPU, not a
/// device benchmark).
///
///     flutter test integration_test/asr_streaming_test.dart -d emulator-5554
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late OfflineAsrModelStore senseVoice, vad;
  setUpAll(() async {
    final support = await getApplicationSupportDirectory();
    senseVoice = OfflineAsrModelStore(Dio(), root: support);
    vad = OfflineAsrModelStore(
      Dio(),
      root: support,
      spec: AsrModelSpec.sileroVad,
    );
    final copy = Platform.isAndroid ? _nativeCopy : null;
    final clock = Stopwatch()..start();
    await senseVoice.installFromAssets(rootBundle.load, copy: copy);
    await vad.installFromAssets(rootBundle.load, copy: copy);
    // ignore: avoid_print
    print('Bundled model install: ${clock.elapsedMilliseconds} ms');
  });

  testWidgets('bundled SenseVoice + VAD previews Chinese with punctuation', (
    tester,
  ) async {
    expect(senseVoice.isReady, isTrue, reason: '随包 SenseVoice 应安装成功');
    expect(vad.isReady, isTrue, reason: '随包 VAD 应安装成功');
    final engine = SherpaSpeechInput.engineOf(
      senseVoice,
      vadPath: vad.modelPath,
    )!;
    final run = await _stream(engine, pcm16FromWav(zhSampleWavBytes()));
    run.report('SenseVoice+VAD zh');
    expect(run.peak, greaterThan(0));
    expect(run.partials, isNotEmpty, reason: '说话过程中应有实时预览');
    expect(run.firstPartialMs, lessThan(run.audioMs), reason: '首个预览须在音频结束前出现');
    expect(run.finalText, startsWith('重点'), reason: '首字不能被 VAD 切掉');
    expect(run.finalText, contains('三个问题'));
    expect(run.finalText, contains('金融'));
    expect(run.finalText, matches(RegExp(r'[，。？！]')), reason: 'ITN 应带标点');
  });

  testWidgets('mixed Chinese/English streams both scripts', (tester) async {
    final engine = SherpaSpeechInput.engineOf(
      senseVoice,
      vadPath: vad.modelPath,
    )!;
    final run = await _stream(engine, pcm16FromWav(zhEnSampleWavBytes()));
    run.report('SenseVoice+VAD zh-en');
    expect(run.partials, isNotEmpty);
    expect(run.finalText.toLowerCase(), contains('yesterday'));
    expect(run.finalText, contains('星期'));
  });

  testWidgets('without VAD the final still comes from one full decode', (
    tester,
  ) async {
    final engine = SherpaSpeechInput.engineOf(senseVoice)!;
    final run = await _stream(engine, pcm16FromWav(zhSampleWavBytes()));
    run.report('SenseVoice no-VAD');
    expect(run.partials, isEmpty);
    expect(run.finalText, contains('金融'));
  });

  testWidgets('a new capture can start right after the previous final', (
    tester,
  ) async {
    final input = SherpaSpeechInput(
      loadEngine: () async =>
          SherpaSpeechInput.engineOf(senseVoice, vadPath: vad.modelPath),
      recorderFactory: () async =>
          PacedRecorder(pcm16FromWav(zhSampleWavBytes())),
    );
    addTearDown(input.dispose);
    final first = await _capture(input, 'a');
    final second = await _capture(input, 'b');
    expect(second, first, reason: '同一输入、同一音频，结果应一致');
  });
}

const _assets = MethodChannel('towork/assets');
Future<void> _nativeCopy(String asset, String target) =>
    _assets.invokeMethod<void>('copyAsset', {'asset': asset, 'target': target});

class _Run {
  double peak = 0;
  _Run(this.audioMs);
  final int audioMs;
  final partials = <(int, String)>[];
  late String finalText;
  late int finalMs, releaseMs;
  int get firstPartialMs => partials.first.$1;

  void report(String label) {
    // ignore: avoid_print
    print(
      '$label: audio ${audioMs}ms, ${partials.length} partials, '
      'first at ${partials.isEmpty ? '-' : firstPartialMs}ms, '
      'release→final ${finalMs - releaseMs}ms',
    );
    for (final (ms, text) in partials) {
      // ignore: avoid_print
      print('  [$ms ms] $text');
    }
    // ignore: avoid_print
    print('  final: $finalText');
  }
}

Future<_Run> _stream(AsrEngineConfig engine, Uint8List pcm) async {
  final recorder = PacedRecorder(pcm);
  final input = SherpaSpeechInput(
    loadEngine: () async => engine,
    recorderFactory: () async => recorder,
  );
  try {
    // Load the model first: the measurement is about streaming, not cold IO.
    await input.warmUp();
    final run = _Run(pcm.length * 1000 ~/ 32000);
    final clock = Stopwatch()..start();
    final done = Completer<void>();
    final sub = input.events.listen((event) {
      switch (event.kind) {
        case SpeechEventKind.partial:
          run.partials.add((clock.elapsedMilliseconds, event.text));
        case SpeechEventKind.finalResult:
          run.finalText = event.text;
          run.finalMs = clock.elapsedMilliseconds;
        case SpeechEventKind.ended:
          done.complete();
        case SpeechEventKind.error:
          done.completeError(SpeechFailure(event.error!));
        case SpeechEventKind.level:
          run.peak = math.max(run.peak, event.level);
        case SpeechEventKind.listening:
      }
    });
    try {
      await input.start('run', locale: 'zh-CN', onDevice: true);
      await recorder.drained;
      run.releaseMs = clock.elapsedMilliseconds;
      await input.stop('run');
      await done.future.timeout(const Duration(seconds: 60));
      return run;
    } finally {
      await sub.cancel();
    }
  } finally {
    await input.dispose();
  }
}

Future<String> _capture(SherpaSpeechInput input, String id) async {
  final result = input.events.firstWhere(
    (e) => e.captureId == id && e.kind == SpeechEventKind.finalResult,
  );
  await input.start(id, locale: 'zh-CN', onDevice: true);
  await Future<void>.delayed(const Duration(seconds: 6));
  await input.stop(id);
  final text = (await result.timeout(const Duration(seconds: 60))).text;
  // ignore: avoid_print
  print('Capture $id: $text');
  return text;
}
