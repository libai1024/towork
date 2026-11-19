import 'dart:async';

import '../../domain/speech/speech_input.dart';
import 'native_speech_input.dart';

/// Android 固定走本地模型；其他平台系统识别优先、离线回退。
/// 每个 capture 在 start 时路由；事件按 captureId 的归属放行。
class SpeechInputSelector implements SpeechInput {
  SpeechInputSelector(this.native, this.offline, {this.preferOffline = false}) {
    _subscription
      ..add(
        native.events.listen(
          (event) => _forward(event, native),
          onError: (Object _) {},
        ),
      )
      ..add(
        offline.events.listen(
          (event) => _forward(event, offline),
          onError: (Object _) {},
        ),
      );
  }

  final SpeechInput native;
  final SpeechInput offline;
  final bool preferOffline;
  final _mode = <String, SpeechInput>{};
  final _events = StreamController<SpeechEvent>.broadcast(sync: true);
  final _subscription = <StreamSubscription<SpeechEvent>>[];

  void _forward(SpeechEvent event, SpeechInput source) {
    if (!identical(_mode[event.captureId], source)) return;
    _events.add(event);
    // `ended` may precede the final transcript. Retain ownership until cancel
    // so late finals and cleanup still reach the same backend.
  }

  @override
  Stream<SpeechEvent> get events => _events.stream;

  /// 原生桥缺失/抛错同样视为不可用（回退到离线模型）。
  Future<SpeechCapabilities?> _nativeCaps(String locale, bool request) async {
    try {
      return request
          ? await native.prepare(locale)
          : await native.inspect(locale);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<SpeechCapabilities> inspect(String locale) async {
    if (preferOffline) return offline.inspect(locale);
    final caps = await _nativeCaps(locale, false);
    if (caps != null && caps.available) return caps;
    return offline.inspect(locale);
  }

  @override
  Future<SpeechCapabilities> prepare(String locale) async {
    if (preferOffline) return offline.prepare(locale);
    final caps = await _nativeCaps(locale, true);
    if (caps != null && caps.available) return caps;
    return offline.prepare(locale);
  }

  @override
  Future<void> start(
    String captureId, {
    required String locale,
    required bool onDevice,
  }) async {
    if (_mode.containsKey(captureId)) {
      throw const SpeechFailure(SpeechFailureCode.busy);
    }
    final caps = preferOffline ? null : await _nativeCaps(locale, false);
    final input =
        caps != null && caps.available && (!onDevice || caps.onDeviceSupported)
        ? native
        : offline;
    // start() is allowed to emit synchronously, before its Future completes.
    _mode[captureId] = input;
    try {
      await input.start(captureId, locale: locale, onDevice: onDevice);
    } catch (_) {
      _mode.remove(captureId);
      await input.cancel(captureId);
      rethrow;
    }
  }

  @override
  Future<void> stop(String captureId) =>
      _mode[captureId]?.stop(captureId) ?? Future.value();

  @override
  Future<void> cancel(String captureId) {
    final input = _mode.remove(captureId);
    return input?.cancel(captureId) ?? Future.value();
  }

  @override
  Future<void> openSettings() => native.openSettings();

  Future<void> dispose() async {
    for (final subscription in _subscription) {
      await subscription.cancel();
    }
    _subscription.clear();
    for (final entry in _mode.entries.toList()) {
      await entry.value.cancel(entry.key);
    }
    _mode.clear();
    if (native is NativeSpeechInput) {
      await (native as NativeSpeechInput).dispose();
    }
    await _events.close();
  }
}
