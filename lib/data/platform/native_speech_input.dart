import 'dart:async';

import 'package:flutter/services.dart';

import '../../domain/speech/speech_input.dart';

/// Both native implementations attach the originating capture ID before crossing
/// the channel. A late native callback cannot be relabelled as a new capture.
class NativeSpeechInput implements SpeechInput {
  NativeSpeechInput({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('towork/speech') {
    _channel.setMethodCallHandler(_onEvent);
  }
  final MethodChannel _channel;
  final _events = StreamController<SpeechEvent>.broadcast(sync: true);
  @override
  Stream<SpeechEvent> get events => _events.stream;
  Future<void> _onEvent(MethodCall call) async {
    if (call.method != 'event' || call.arguments is! Map) return;
    final map = (call.arguments as Map).cast<String, Object?>();
    final id = map['id'];
    if (id is! String) return;
    final kind = SpeechEventKind.values
        .where((k) => k.name == map['kind'])
        .firstOrNull;
    if (kind == null) return;
    _events.add(
      SpeechEvent(
        id,
        kind,
        text: map['text'] is String ? map['text']! as String : '',
        error: kind == SpeechEventKind.error ? _code(map['error']) : null,
      ),
    );
  }

  SpeechFailureCode _code(Object? value) =>
      SpeechFailureCode.values.where((c) => c.name == value).firstOrNull ??
      SpeechFailureCode.unavailable;
  Future<T?> _invoke<T>(String method, Map<String, Object?> args) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      throw SpeechFailure(_code(e.code));
    } on MissingPluginException {
      throw const SpeechFailure(SpeechFailureCode.unavailable);
    }
  }

  Future<SpeechCapabilities> _capabilities(String method, String locale) async {
    final map = await _invoke<Map<Object?, Object?>>(method, {
      'locale': locale,
    });
    if (map == null) throw const SpeechFailure(SpeechFailureCode.unavailable);
    return SpeechCapabilities(
      available: map['available'] == true,
      authorized: map['authorized'] == true,
      locales: (map['locales'] as List? ?? []).whereType<String>(),
      onDeviceSupported: map['onDeviceSupported'] == true,
    );
  }

  @override
  Future<SpeechCapabilities> inspect(String locale) =>
      _capabilities('inspect', locale);
  @override
  Future<SpeechCapabilities> prepare(String locale) =>
      _capabilities('prepare', locale);
  @override
  Future<void> start(
    String captureId, {
    required String locale,
    required bool onDevice,
  }) async {
    await _invoke<void>('start', {
      'id': captureId,
      'locale': locale,
      'onDevice': onDevice,
    });
  }

  @override
  Future<void> stop(String captureId) async {
    await _invoke<void>('stop', {'id': captureId});
  }

  @override
  Future<void> cancel(String captureId) async {
    await _invoke<void>('cancel', {'id': captureId});
  }

  @override
  Future<void> openSettings() async {
    await _invoke<void>('openSettings', {});
  }

  Future<void> dispose() async {
    _channel.setMethodCallHandler(null);
    await _events.close();
  }
}
