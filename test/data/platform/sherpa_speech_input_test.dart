import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/data/platform/offline_asr_decoder.dart';
import 'package:towork/data/platform/offline_asr_model_store.dart';
import 'package:towork/data/platform/sherpa_speech_input.dart';
import 'package:towork/data/platform/vad_streaming_transcriber.dart';
import 'package:towork/domain/speech/speech_input.dart';

class _Store extends OfflineAsrModelStore {
  _Store() : super(Dio(), root: Directory.systemTemp);
  @override
  bool get isReady => true;
}

class _Recorder implements AsrRecorder {
  final chunks = StreamController<Uint8List>.broadcast();
  final permissions = <bool>[];
  int stops = 0, disposals = 0;
  bool closeOnStop = false;
  @override
  Future<bool> hasPermission({bool request = true}) async {
    permissions.add(request);
    return true;
  }

  @override
  Future<Stream<Uint8List>> startPcm() async => chunks.stream;
  @override
  Future<void> stopPcm() async {
    stops++;
    if (closeOnStop) await chunks.close();
  }

  @override
  Future<void> dispose() async {
    disposals++;
  }
}

class _Decoder implements AsrDecoder {
  int decodes = 0, feeds = 0, finishes = 0;
  Completer<String>? gate;

  /// Simulates a loaded VAD: each feed returns the scripted stream state.
  bool streaming = false;
  final fedSamples = <int>[];
  final states = <AsrStreamState>[];
  Completer<void>? feedGate;
  String finished = '明天开会。';
  bool feedError = false;
  @override
  Future<void> warmUp(AsrEngineConfig config) async {}
  @override
  Future<String> decode(Float32List samples) async {
    decodes++;
    return gate == null ? '明天开会' : gate!.future;
  }

  @override
  Future<bool> beginStream() async => streaming;
  @override
  Future<AsrStreamState> feedStream(Float32List samples) async {
    feeds++;
    if (feedError) throw StateError('native feed failed');
    fedSamples.add(samples.length);
    await feedGate?.future;
    return states.isEmpty ? AsrStreamState.empty : states.removeAt(0);
  }

  @override
  Future<String> finishStream() async {
    finishes++;
    return finished;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  late _Recorder recorder;
  late _Decoder decoder;
  late SherpaSpeechInput input;
  late List<SpeechEvent> events;
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    recorder = _Recorder();
    decoder = _Decoder();
    input = SherpaSpeechInput(
      store: _Store(),
      recorderFactory: () async => recorder,
      decoder: decoder,
    );
    events = [];
    input.events
        .where((event) => event.kind != SpeechEventKind.level)
        .listen(events.add);
  });
  tearDown(() async {
    await input.dispose();
    await recorder.chunks.close();
  });
  Future<void> record() async {
    await input.start('one', locale: 'zh-CN', onDevice: true);
    recorder.chunks.add(Uint8List(32000));
    await Future<void>.delayed(Duration.zero);
  }

  test('Linux reports the offline recognizer unavailable without opening a recorder', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final caps = await input.inspect('zh-CN');
    expect(caps.available, isFalse);
    expect(recorder.permissions, isEmpty);
  });

  test(
    'inspection never requests permission and disposes its temporary recorder',
    () async {
      await input.inspect('zh-CN');
      expect(recorder.permissions, [false]);
      expect(recorder.disposals, 1);
    },
  );
  test(
    'stop without stream done still decodes and releases the microphone',
    () async {
      await record();
      await input.stop('one');
      expect(events.map((e) => e.kind), [
        SpeechEventKind.listening,
        SpeechEventKind.finalResult,
        SpeechEventKind.ended,
      ]);
      expect(events[1].text, '明天开会');
      expect(decoder.decodes, 1);
      expect(recorder.stops, 1);
      expect(recorder.disposals, 1);
    },
  );
  test('stream done racing stop decodes once', () async {
    recorder.closeOnStop = true;
    await record();
    await input.stop('one');
    await Future<void>.delayed(Duration.zero);
    expect(decoder.decodes, 1);
    expect(
      events.where((e) => e.kind == SpeechEventKind.finalResult),
      hasLength(1),
    );
  });
  test('cancel during inference suppresses the late transcript', () async {
    decoder.gate = Completer();
    await record();
    final stopping = input.stop('one');
    await Future<void>.delayed(Duration.zero);
    expect(decoder.decodes, 1);
    await input.cancel('one');
    decoder.gate!.complete('不能发送');
    await stopping;
    expect(events.where((e) => e.kind == SpeechEventKind.finalResult), isEmpty);
    expect(recorder.disposals, 1);
  });
  test(
    'audio error releases the microphone and emits only one failure',
    () async {
      await record();
      recorder.chunks.addError(StateError('microphone lost'));
      await Future<void>.delayed(Duration.zero);
      expect(
        events.where((e) => e.kind == SpeechEventKind.error),
        hasLength(1),
      );
      expect(recorder.disposals, 1);
      expect(decoder.decodes, 0);
    },
  );
  test('empty audio ends as noResult without invoking the model', () async {
    await input.start('one', locale: 'zh-CN', onDevice: true);
    await input.stop('one');
    expect(events.last.error, SpeechFailureCode.noResult);
    expect(decoder.decodes, 0);
  });
  test(
    'dispose while recording releases native recorder exactly once',
    () async {
      await record();
      await input.dispose();
      await input.dispose();
      expect(recorder.disposals, 1);
      expect(recorder.stops, 1);
    },
  );

  test('a listener can start the next capture right after the final', () async {
    final next = Completer<void>();
    input.events.listen((event) {
      if (event.captureId == 'one' &&
          event.kind == SpeechEventKind.finalResult) {
        next.complete(input.start('two', locale: 'zh-CN', onDevice: true));
      }
    });
    await record();
    await input.stop('one');
    await next.future;
    expect(events.last.captureId, 'two');
    expect(events.last.kind, SpeechEventKind.listening);
  });

  group('VAD streaming', () {
    setUp(() => decoder.streaming = true);
    Future<void> settle() async {
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    test('emits live partials and finishes from the stream', () async {
      decoder.states
        ..add(const AsrStreamState('', '明天'))
        ..add(const AsrStreamState('明天开会。', ''));
      await input.start('one', locale: 'zh-CN', onDevice: true);
      recorder.chunks.add(Uint8List(3200));
      await settle();
      recorder.chunks.add(Uint8List(3200));
      await settle();
      await input.stop('one');
      expect(events.map((e) => e.kind), [
        SpeechEventKind.listening,
        SpeechEventKind.partial,
        SpeechEventKind.partial,
        SpeechEventKind.finalResult,
        SpeechEventKind.ended,
      ]);
      expect(events[1].text, '明天');
      expect(events[2].text, '明天开会。');
      expect(events[3].text, '明天开会。');
      expect(decoder.finishes, 1);
      expect(decoder.decodes, 0, reason: '流式会话已出字，松开后不再整段重解');
    });

    test(
      'audio arriving during a slow feed coalesces into one request',
      () async {
        decoder.feedGate = Completer();
        await input.start('one', locale: 'zh-CN', onDevice: true);
        recorder.chunks.add(Uint8List(1600));
        await settle();
        for (var i = 0; i < 4; i++) {
          recorder.chunks.add(Uint8List(1600));
        }
        await settle();
        expect(decoder.feeds, 1);
        decoder.feedGate!.complete();
        await settle();
        expect(decoder.fedSamples, [800, 3200]);
        await input.stop('one');
      },
    );

    test('VAD hearing no speech ends as noResult, no full decode', () async {
      decoder.finished = '';
      await record();
      await input.stop('one');
      expect(decoder.finishes, 1);
      expect(decoder.decodes, 0, reason: '整段解码近乎静音会臆造文字');
      expect(events.last.error, SpeechFailureCode.noResult);
    });

    test('a failed stream falls back to one full decode', () async {
      decoder.feedError = true;
      await record();
      await input.stop('one');
      expect(decoder.finishes, 0);
      expect(decoder.decodes, 1);
      expect(
        events.firstWhere((e) => e.kind == SpeechEventKind.finalResult).text,
        '明天开会',
      );
    });

    test('cancel while a feed is in flight emits nothing more', () async {
      decoder.feedGate = Completer();
      decoder.states.add(const AsrStreamState('', '不能出现'));
      await record();
      await input.cancel('one');
      decoder.feedGate!.complete();
      await settle();
      expect(events.map((e) => e.kind), [SpeechEventKind.listening]);
      expect(recorder.disposals, 1);
    });
  });
}
