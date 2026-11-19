import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'offline_asr_model_store.dart';
import 'vad_streaming_transcriber.dart';

/// What the worker should load. Equality decides whether a warm-up reloads.
class AsrEngineConfig {
  const AsrEngineConfig({
    required this.family,
    required this.modelPath,
    required this.tokensPath,
    this.vadPath,
  });

  final AsrModelFamily family;
  final String modelPath, tokensPath;

  /// Silero VAD model; null disables live preview (final-only decoding).
  final String? vadPath;

  @override
  bool operator ==(Object other) =>
      other is AsrEngineConfig &&
      other.family == family &&
      other.modelPath == modelPath &&
      other.tokensPath == tokensPath &&
      other.vadPath == vadPath;
  @override
  int get hashCode => Object.hash(family, modelPath, tokensPath, vadPath);
}

abstract interface class AsrDecoder {
  /// Loads [config]; a different config replaces the loaded engine.
  Future<void> warmUp(AsrEngineConfig config);

  /// One-shot decode of a whole utterance.
  Future<String> decode(Float32List samples);

  /// Resets the streaming session. False when no VAD is loaded.
  Future<bool> beginStream();
  Future<AsrStreamState> feedStream(Float32List samples);

  /// Flushes the VAD and returns the committed transcript.
  Future<String> finishStream();
  Future<void> dispose();
}

/// The worker owns every FFI pointer. Model loading and inference never block UI.
class OfflineAsrDecoder implements AsrDecoder {
  final _replies = ReceivePort();
  final _pending = <int, Completer<Object?>>{};
  Future<SendPort>? _spawning;
  SendPort? _commands;
  Future<void>? _loading;
  AsrEngineConfig? _config;
  int _sequence = 0;
  bool _disposed = false;

  OfflineAsrDecoder() {
    _replies.listen((message) {
      final (id, result, error) = message as (int, Object?, String?);
      final pending = _pending.remove(id);
      if (error != null) {
        pending?.completeError(StateError(error));
      } else {
        pending?.complete(result);
      }
    });
  }

  @override
  Future<void> warmUp(AsrEngineConfig config) {
    if (_disposed) return Future.error(StateError('Decoder disposed'));
    if (_loading != null && _config == config) return _loading!;
    _config = config;
    final loading = _load(config);
    _loading = loading;
    return loading;
  }

  Future<void> _load(AsrEngineConfig config) async {
    try {
      await (_spawning ??= _spawn());
      await _request(('load', config));
    } catch (_) {
      if (_config == config) {
        _loading = null;
        _config = null;
      }
      rethrow;
    }
  }

  Future<SendPort> _spawn() async {
    final ready = ReceivePort();
    try {
      await Isolate.spawn(_worker, ready.sendPort);
      final commands = await ready.first as SendPort;
      if (_disposed) {
        commands.send(null);
        throw StateError('Decoder disposed');
      }
      return _commands = commands;
    } catch (_) {
      _spawning = null;
      rethrow;
    } finally {
      ready.close();
    }
  }

  Future<Object?> _request(Object payload) {
    if (_disposed) return Future.error(StateError('Decoder disposed'));
    final completer = Completer<Object?>();
    final id = ++_sequence;
    _pending[id] = completer;
    _commands!.send((id, _replies.sendPort, payload));
    return completer.future;
  }

  Future<Object?> _loaded(Object payload) async {
    final loading = _loading;
    if (loading == null) throw StateError('Decoder not warmed up');
    await loading;
    return _request(payload);
  }

  @override
  Future<String> decode(Float32List samples) async =>
      await _loaded(('decode', TransferableTypedData.fromList([samples])))
          as String;

  @override
  Future<bool> beginStream() async => await _loaded(('begin', null)) as bool;

  @override
  Future<AsrStreamState> feedStream(Float32List samples) async {
    final (committed, tentative) = await _loaded((
      'feed',
      TransferableTypedData.fromList([samples]),
    )) as (String, String);
    return AsrStreamState(committed, tentative);
  }

  @override
  Future<String> finishStream() async =>
      await _loaded(('finish', null)) as String;

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    // Queue cleanup after any inference, never free native memory mid-decode.
    _commands?.send(null);
    for (final pending in _pending.values) {
      pending.completeError(StateError('Decoder disposed'));
    }
    _pending.clear();
    _replies.close();
  }

  static void _worker(SendPort ready) {
    final commands = ReceivePort();
    final engine = _WorkerEngine();
    ready.send(commands.sendPort);
    commands.listen((message) {
      if (message == null) {
        engine.free();
        commands.close();
        return;
      }
      final (id, reply, (command, payload)) =
          message as (int, SendPort, (String, Object?));
      try {
        reply.send((id, engine.handle(command, payload), null));
      } catch (error) {
        reply.send((id, null, error.toString()));
      }
    });
  }
}

class _WorkerEngine {
  sherpa.OfflineRecognizer? _recognizer;
  sherpa.VoiceActivityDetector? _vad;
  VadStreamingTranscriber? _stream;
  bool _bound = false;

  Object? handle(String command, Object? payload) => switch (command) {
    'load' => _load(payload! as AsrEngineConfig),
    'decode' => _decode(_samples(payload)),
    'begin' => _begin(),
    'feed' => _feed(_samples(payload)),
    'finish' => _stream?.finish() ?? '',
    _ => throw ArgumentError('unknown command $command'),
  };

  static Float32List _samples(Object? payload) =>
      (payload! as TransferableTypedData).materialize().asFloat32List();

  Object? _load(AsrEngineConfig config) {
    if (!_bound) {
      sherpa.initBindings();
      _bound = true;
    }
    free();
    final model = switch (config.family) {
      AsrModelFamily.senseVoice => sherpa.OfflineModelConfig(
        senseVoice: sherpa.OfflineSenseVoiceModelConfig(
          model: config.modelPath,
          language: 'auto',
          useInverseTextNormalization: true,
        ),
        tokens: config.tokensPath,
        numThreads: 2,
        provider: 'cpu',
      ),
      AsrModelFamily.sileroVad => throw ArgumentError('VAD is not an ASR'),
    };
    _recognizer = sherpa.OfflineRecognizer(
      sherpa.OfflineRecognizerConfig(model: model),
    );
    if (config.vadPath case final vadPath?) {
      final vad = sherpa.VoiceActivityDetector(
        config: sherpa.VadModelConfig(
          sileroVad: sherpa.SileroVadModelConfig(
            model: vadPath,
            threshold: 0.5,
            // Short pauses inside one command stay in one sentence. 0.6s
            // was tried: longer trailing silence made SenseVoice stutter
            // ("Yesesterday") on the zh-en fixture.
            minSilenceDuration: 0.4,
            minSpeechDuration: 0.25,
            // Long monologues are cut so each decode stays bounded.
            maxSpeechDuration: 12,
          ),
          sampleRate: 16000,
          numThreads: 1,
          provider: 'cpu',
          debug: false,
        ),
        bufferSizeInSeconds: 70,
      );
      _vad = vad;
      _stream = VadStreamingTranscriber(_SherpaVad(vad), _decode);
    }
    return null;
  }

  String _decode(Float32List samples) {
    final recognizer = _recognizer!;
    final stream = recognizer.createStream();
    try {
      stream.acceptWaveform(samples: samples, sampleRate: 16000);
      recognizer.decode(stream);
      return recognizer.getResult(stream).text.trim();
    } finally {
      stream.free();
    }
  }

  bool _begin() {
    _stream?.reset();
    return _stream != null;
  }

  (String, String) _feed(Float32List samples) {
    final state = _stream!.accept(samples);
    return (state.committed, state.tentative);
  }

  void free() {
    _stream = null;
    _vad?.free();
    _vad = null;
    _recognizer?.free();
    _recognizer = null;
  }
}

class _SherpaVad implements VadPort {
  _SherpaVad(this._vad);
  final sherpa.VoiceActivityDetector _vad;
  @override
  int get windowSize => 512;
  @override
  void acceptWaveform(Float32List window) => _vad.acceptWaveform(window);
  @override
  bool isDetected() => _vad.isDetected();
  @override
  bool isEmpty() => _vad.isEmpty();
  @override
  Float32List front() => _vad.front().samples;
  @override
  void pop() => _vad.pop();
  @override
  void flush() => _vad.flush();
  @override
  void reset() => _vad.reset();
}
