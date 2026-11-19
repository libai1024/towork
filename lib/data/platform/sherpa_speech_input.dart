import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart' as record;

import '../../domain/speech/speech_input.dart';
import 'offline_asr_decoder.dart';
import 'offline_asr_model_store.dart';

/// Resolves the engine to load now; null means no recognizer is installed.
typedef AsrEngineLoader = Future<AsrEngineConfig?> Function();

/// 16k mono PCM capture with a reusable, isolated local recognizer.
///
/// With a VAD in the engine config, audio streams into the worker while the
/// user speaks: closed sentences are committed, the open one is re-decoded
/// as a live preview, and release only has to decode the trailing sentence.
class SherpaSpeechInput implements SpeechInput {
  SherpaSpeechInput({
    OfflineAsrModelStore? store,
    Future<OfflineAsrModelStore> Function()? loadStore,
    AsrEngineLoader? loadEngine,
    RecorderFactory? recorderFactory,
    AsrDecoder? decoder,
  }) : assert(store != null || loadStore != null || loadEngine != null),
       _loadEngine =
           loadEngine ??
           (() async => engineOf(await (loadStore ?? (() async => store!))())),
       _recorderFactory = recorderFactory ?? (() async => RecordPcmRecorder()),
       _decoder = decoder ?? OfflineAsrDecoder();

  /// Final-only engine for a single recognizer store (no VAD preview).
  static AsrEngineConfig? engineOf(
    OfflineAsrModelStore store, {
    String? vadPath,
  }) => store.isReady
      ? AsrEngineConfig(
          family: store.spec.family,
          modelPath: store.modelPath,
          tokensPath: store.tokensPath,
          vadPath: vadPath,
        )
      : null;

  final AsrEngineLoader _loadEngine;
  final RecorderFactory _recorderFactory;
  final AsrDecoder _decoder;
  final _events = StreamController<SpeechEvent>.broadcast(sync: true);
  _ActiveCapture? _active;
  bool _disposed = false;
  bool _starting = false;

  @override
  Stream<SpeechEvent> get events => _events.stream;

  Future<void> warmUp() async {
    final engine = await _loadEngine();
    if (_disposed) return;
    if (engine == null) {
      throw const SpeechFailure(SpeechFailureCode.unavailable);
    }
    await _decoder.warmUp(engine);
  }

  Future<SpeechCapabilities> _capabilities({required bool request}) async {
    final supported =
        !kIsWeb &&
        const {
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        }.contains(defaultTargetPlatform);
    final ready = supported && await _loadEngine() != null;
    if (!ready || _disposed) {
      return SpeechCapabilities(
        available: false,
        authorized: false,
        locales: const ['zh-CN', 'en-US'],
        onDeviceSupported: false,
      );
    }
    final recorder = await _recorderFactory();
    try {
      return SpeechCapabilities(
        available: true,
        authorized: await recorder.hasPermission(request: request),
        locales: const ['zh-CN', 'en-US'],
        onDeviceSupported: true,
      );
    } finally {
      await recorder.dispose();
    }
  }

  @override
  Future<SpeechCapabilities> inspect(String locale) =>
      _capabilities(request: false);
  @override
  Future<SpeechCapabilities> prepare(String locale) =>
      _capabilities(request: true);

  @override
  Future<void> start(
    String captureId, {
    required String locale,
    required bool onDevice,
  }) async {
    if (_disposed) throw const SpeechFailure(SpeechFailureCode.unavailable);
    if (_active != null || _starting) {
      throw const SpeechFailure(SpeechFailureCode.busy);
    }
    _starting = true;
    AsrRecorder? recorder;
    _ActiveCapture? capture;
    try {
      final engine = await _loadEngine();
      if (_disposed || engine == null) {
        throw const SpeechFailure(SpeechFailureCode.unavailable);
      }
      recorder = await _recorderFactory();
      if (!await recorder.hasPermission(request: false)) {
        throw const SpeechFailure(SpeechFailureCode.permissionDenied);
      }
      if (_disposed) throw const SpeechFailure(SpeechFailureCode.interrupted);
      final current = _ActiveCapture(captureId, recorder);
      capture = current;
      _active = current;
      final chunks = await recorder.startPcm();
      if (!_current(current)) {
        await _release(current);
        return;
      }
      current.subscription = chunks.listen(
        (chunk) {
          if (current.meterClock.elapsedMilliseconds >= 90 &&
              chunk.length >= 2 &&
              _current(current) &&
              !current.finishing) {
            current.meterClock.reset();
            final pcm = ByteData.sublistView(chunk);
            var sum = 0.0;
            final count = chunk.length ~/ 2;
            for (var i = 0; i < count; i++) {
              final sample = pcm.getInt16(i * 2, Endian.little) / 32768;
              sum += sample * sample;
            }
            // Scale -60 to -6 dBFS into the on-screen meter.
            final db = 10 * math.log(math.max(sum / count, 1e-6)) / math.ln10;
            _events.add(
              SpeechEvent(
                current.id,
                SpeechEventKind.level,
                level: ((db + 60) / 54).clamp(0, 1),
              ),
            );
          }
          current.samples.add(chunk);
          current.pending.add(chunk);
          current.pump ??= _pump(current);
        },
        onDone: () => unawaited(_finish(current)),
        onError: (Object _) =>
            unawaited(_fail(current, SpeechFailureCode.interrupted)),
      );
      _emit(current, SpeechEventKind.listening);
      current.limit = Timer(
        const Duration(seconds: 60),
        () => unawaited(stop(captureId)),
      );
      // Loading can overlap recording; handle failures even before release.
      unawaited(
        warmUp().catchError((Object _) async {
          await _fail(current, SpeechFailureCode.startFailed);
        }),
      );
    } catch (error) {
      if (capture != null) {
        if (_current(capture)) _active = null;
        await _release(capture);
      } else {
        await recorder?.dispose();
      }
      if (error is SpeechFailure) rethrow;
      throw const SpeechFailure(SpeechFailureCode.startFailed);
    } finally {
      _starting = false;
    }
  }

  bool _current(_ActiveCapture capture) =>
      !_disposed && identical(_active, capture);

  /// Streams queued audio into the VAD session, one request in flight.
  /// Audio arriving during a slow decode (or the first model load) coalesces
  /// into the next request instead of queueing one decode per chunk.
  Future<void> _pump(_ActiveCapture capture) async {
    try {
      final streaming = await (capture.streaming ??= _beginStream());
      while (streaming && capture.pending.length > 0 && _current(capture)) {
        final samples = capture.pending.toFloat32();
        final state = await _decoder.feedStream(samples);
        capture.streamed = true;
        if (!_current(capture) || capture.finishing) continue;
        final text = state.text;
        if (text.isNotEmpty && text != capture.preview) {
          capture.preview = text;
          _emit(capture, SpeechEventKind.partial, text: text);
        }
      }
      if (!streaming) capture.pending.takeBytes();
    } catch (_) {
      // Preview is best effort; release falls back to one full decode.
      capture.streamFailed = true;
      capture.pending.takeBytes();
    } finally {
      capture.pump = null;
    }
  }

  Future<bool> _beginStream() async {
    await warmUp();
    if (_disposed) return false;
    return _decoder.beginStream();
  }

  void _emit(
    _ActiveCapture capture,
    SpeechEventKind kind, {
    String text = '',
    SpeechFailureCode? error,
  }) {
    if (_current(capture)) {
      _events.add(SpeechEvent(capture.id, kind, text: text, error: error));
    }
  }

  Future<void> _fail(_ActiveCapture capture, SpeechFailureCode error) async {
    if (!_current(capture)) return;
    _emit(capture, SpeechEventKind.error, error: error);
    if (identical(_active, capture)) _active = null;
    await _release(capture);
  }

  Future<void> _finish(_ActiveCapture capture) async {
    if (!_current(capture) || capture.finishing) return;
    capture.finishing = true;
    capture.limit?.cancel();
    try {
      await _release(capture);
      if (!_current(capture)) return;
      final samples = capture.samples.toFloat32();
      if (samples.length < 1600) {
        await _fail(capture, SpeechFailureCode.noResult);
        return;
      }
      final text = await _finalText(capture, samples);
      if (!_current(capture)) return; // cancelled while inference was running
      if (text.isEmpty) {
        await _fail(capture, SpeechFailureCode.noResult);
        return;
      }
      // Free the slot before emitting: a listener that awaits the final
      // result may start the next capture synchronously.
      _active = null;
      _events
        ..add(SpeechEvent(capture.id, SpeechEventKind.finalResult, text: text))
        ..add(SpeechEvent(capture.id, SpeechEventKind.ended));
    } catch (_) {
      await _fail(capture, SpeechFailureCode.interrupted);
    }
  }

  /// Drains the stream and commits the trailing sentence. If the VAD session
  /// ran and heard no speech, the result is empty (→ noResult): decoding
  /// near-silence makes SenseVoice invent words ("我."), which auto-send
  /// would push to the model. Only when streaming never ran or failed is
  /// the whole recording decoded once instead.
  Future<String> _finalText(_ActiveCapture capture, Float32List all) async {
    while (capture.pump != null) {
      await capture.pump;
      if (!_current(capture)) return '';
      if (capture.pending.length > 0 && !capture.streamFailed) {
        capture.pump ??= _pump(capture);
      }
    }
    if (!_current(capture)) return '';
    if (capture.streamed && !capture.streamFailed) {
      try {
        return await _decoder.finishStream();
      } catch (_) {
        // Fall through to the full decode below.
      }
      if (!_current(capture)) return '';
    }
    return decodeFloat32(all);
  }

  Future<String> decodePcm16(Uint8List pcm16) =>
      decodeFloat32((PcmBuffer()..add(pcm16)).toFloat32());

  Future<String> decodeFloat32(Float32List samples) async {
    await warmUp();
    if (_disposed) throw StateError('Speech input disposed');
    return _decoder.decode(samples);
  }

  @override
  Future<void> stop(String captureId) async {
    final capture = _active;
    if (capture == null || capture.id != captureId) return;
    // onDone isn't guaranteed by every recorder. Explicitly finalize after stop.
    // Both paths share the finishing guard so only one decode can happen.
    try {
      await (capture.stopping ??= capture.recorder.stopPcm());
      await _finish(capture);
    } catch (_) {
      await _fail(capture, SpeechFailureCode.interrupted);
    }
  }

  @override
  Future<void> cancel(String captureId) async {
    final capture = _active;
    if (capture == null || capture.id != captureId) return;
    _active = null;
    await _release(capture);
  }

  Future<void> _release(_ActiveCapture capture) =>
      capture.releasing ??= _releaseResources(capture);

  Future<void> _releaseResources(_ActiveCapture capture) async {
    capture.limit?.cancel();
    await capture.subscription?.cancel();
    capture.subscription = null;
    try {
      await (capture.stopping ??= capture.recorder.stopPcm());
    } catch (_) {
      // Disposal must still release the native AudioRecord on stop failure.
    } finally {
      await capture.recorder.dispose();
    }
  }

  @override
  Future<void> openSettings() async {}

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final capture = _active;
    _active = null;
    if (capture != null) await _release(capture);
    await _decoder.dispose();
    await _events.close();
  }
}

abstract interface class AsrRecorder {
  Future<bool> hasPermission({bool request = true});
  Future<Stream<Uint8List>> startPcm();
  Future<void> stopPcm();
  Future<void> dispose();
}

typedef RecorderFactory = Future<AsrRecorder> Function();

class RecordPcmRecorder implements AsrRecorder {
  final _recorder = record.AudioRecorder();
  @override
  Future<bool> hasPermission({bool request = true}) =>
      _recorder.hasPermission(request: request);
  @override
  Future<Stream<Uint8List>> startPcm() => _recorder.startStream(
    const record.RecordConfig(
      encoder: record.AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
    ),
  );
  @override
  Future<void> stopPcm() async {
    await _recorder.stop();
  }

  @override
  Future<void> dispose() => _recorder.dispose();
}

class _ActiveCapture {
  _ActiveCapture(this.id, this.recorder);
  final String id;
  final AsrRecorder recorder;
  final samples = PcmBuffer();
  final meterClock = Stopwatch()..start();

  /// Audio not yet sent to the VAD stream, the single in-flight feed, and the
  /// last preview text emitted.
  final pending = PcmBuffer();
  Future<void>? pump;
  Future<bool>? streaming;
  bool streamed = false, streamFailed = false;
  String preview = '';
  StreamSubscription<Uint8List>? subscription;
  Timer? limit;
  Future<void>? stopping, releasing;
  bool finishing = false;
}

/// 16-bit PCM → float32（/32768）增量缓冲；60 秒上限约 3.7MB。
class PcmBuffer {
  final _bytes = BytesBuilder(copy: false);
  void add(Uint8List chunk) => _bytes.add(chunk);
  int get length => _bytes.length;
  Uint8List takeBytes() => _bytes.takeBytes();
  Float32List toFloat32() => PcmBuffer.float32Of(takeBytes());

  static Float32List float32Of(Uint8List data) {
    final count = data.length ~/ 2;
    final result = Float32List(count);
    final view = ByteData.sublistView(data);
    for (var i = 0; i < count; i++) {
      result[i] = view.getInt16(i * 2, Endian.little) / 32768.0;
    }
    return result;
  }
}
