import 'dart:async';

import 'package:towork/domain/speech/speech_input.dart';

class FakeSpeechInput implements SpeechInput {
  final bus = StreamController<SpeechEvent>.broadcast(sync: true);
  final starts = <String>[], stops = <String>[], cancels = <String>[];
  bool startListening = true;
  int inspections = 0, preparations = 0;
  Completer<SpeechCapabilities>? prepareGate;
  SpeechCapabilities capabilities = SpeechCapabilities(
    available: true,
    authorized: true,
    locales: ['zh-CN', 'en-US'],
    onDeviceSupported: true,
  );
  @override
  Stream<SpeechEvent> get events => bus.stream;
  void emit(
    String id,
    SpeechEventKind kind, {
    String text = '',
    SpeechFailureCode? error,
  }) => bus.add(SpeechEvent(id, kind, text: text, error: error));
  @override
  Future<SpeechCapabilities> inspect(String locale) async {
    inspections++;
    return capabilities;
  }

  @override
  Future<SpeechCapabilities> prepare(String locale) async {
    preparations++;
    return prepareGate == null ? capabilities : await prepareGate!.future;
  }

  @override
  Future<void> start(
    String id, {
    required String locale,
    required bool onDevice,
  }) async {
    starts.add(id);
    if (startListening) emit(id, SpeechEventKind.listening);
  }

  @override
  Future<void> stop(String id) async {
    stops.add(id);
  }

  @override
  Future<void> cancel(String id) async {
    cancels.add(id);
  }

  @override
  Future<void> openSettings() async {}
}
