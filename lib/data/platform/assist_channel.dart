import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../../domain/assist/quick_assist.dart';

/// 与 Android 侧 `AssistBridge` 对接的唯一通道。
///
/// 其他平台没有快捷面板：所有查询返回「没有」，不发起任何通道调用，
/// 因此纯 Dart 测试和桌面端不需要注册处理器。
class AssistChannel implements AssistHost, AssistEntries, EnginePeers {
  AssistChannel({
    this._channel = const MethodChannel('towork/assist'),
    bool? supported,
  }) : _supported = supported ?? Platform.isAndroid {
    if (_supported) _channel.setMethodCallHandler(_incoming);
  }

  final MethodChannel _channel;
  final bool _supported;
  final _relaunches = StreamController<AssistLaunch>.broadcast();

  Future<Object?> _incoming(MethodCall call) async {
    if (call.method == 'relaunch' && !_relaunches.isClosed) {
      _relaunches.add(_launch(call.arguments));
    }
    return null;
  }

  /// 原生侧没有这个方法、或调用失败时返回空，由调用方按「没有」处理。
  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    if (!_supported) return null;
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  static AssistLaunch _launch(Object? raw) {
    if (raw is! Map) return const AssistLaunch();
    final name = raw['source'];
    final text = raw['text'];
    final trimmed = text is String ? text.trim() : '';
    return AssistLaunch(
      source: AssistSource.values.firstWhere(
        (source) => source.name == name,
        orElse: () => AssistSource.app,
      ),
      text: trimmed.length > AssistLaunch.maxText
          ? trimmed.substring(0, AssistLaunch.maxText)
          : trimmed,
      voice: raw['voice'] == true,
    );
  }

  @override
  Future<AssistLaunch> launch() async => _launch(await _invoke('launch'));

  @override
  Stream<AssistLaunch> get relaunches => _relaunches.stream;

  @override
  Future<void> close() => _invoke<void>('close');

  @override
  Future<void> hide(String notice) => _invoke<void>('hide', {'notice': notice});

  @override
  Future<void> openApp(AssistHandoff handoff, {bool keepPanel = false}) =>
      _invoke<void>('openApp', {
        'sessionId': handoff.sessionId,
        'location': handoff.location,
        'keepPanel': keepPanel,
      });

  @override
  Future<AssistEntryStatus> status() async {
    final raw = await _invoke<Map<Object?, Object?>>('entryStatus');
    if (raw == null) return const AssistEntryStatus();
    final assistant = raw['defaultAssistant'];
    return AssistEntryStatus(
      supported: true,
      defaultAssistant: assistant is bool ? assistant : null,
      canPin: raw['canPin'] == true,
    );
  }

  @override
  Future<bool> openAssistantSettings() async =>
      await _invoke<bool>('openAssistantSettings') ?? false;

  @override
  Future<bool> pinShortcut({bool voice = false}) async =>
      await _invoke<bool>('pinShortcut', {'voice': voice}) ?? false;

  @override
  Future<bool> openPanel() async => await _invoke<bool>('openPanel') ?? false;

  @override
  Future<bool> othersAlive() async => (await _invoke<int>('peers') ?? 0) > 0;

  @override
  Future<AssistHandoff?> takeHandoff() async {
    final raw = await _invoke<Map<Object?, Object?>>('takeHandoff');
    if (raw == null) return null;
    final session = raw['sessionId'];
    final location = raw['location'];
    return AssistHandoff(
      sessionId: session is String && session.isNotEmpty ? session : null,
      // 只接受应用内路径；这个值会直接交给路由器。
      location: location is String && location.startsWith('/')
          ? location
          : null,
    );
  }

  void dispose() {
    if (_supported) _channel.setMethodCallHandler(null);
    unawaited(_relaunches.close());
  }
}
