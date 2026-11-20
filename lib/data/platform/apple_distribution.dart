import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/ai/model_gateway.dart';

class AppleDistribution {
  static const _channel = MethodChannel('towork/apple-distribution');
  static bool get usesStoreDistribution =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS &&
              const bool.fromEnvironment('TOWORK_MAC_APP_STORE'));

  static Future<bool> isTestFlight() async =>
      await _channel.invokeMethod<bool>('isTestFlight') ?? false;

  static Future<void> authorize(
    String origin,
    String provider, {
    String? language,
  }) async {
    Object? accepted;
    try {
      accepted = await _channel.invokeMethod<Object?>('authorizeModel', {
        'origin': origin,
        'provider': provider,
        'language': ?language,
      });
    } on MissingPluginException {
      throw const ModelFailure(ModelFailureCode.configuration);
    } on PlatformException {
      throw const ModelFailure(ModelFailureCode.configuration);
    }
    if (accepted is! bool) throw const ModelFailure(ModelFailureCode.protocol);
    if (!accepted) throw const ModelFailure(ModelFailureCode.cancelled);
  }

  static Future<void> resetModelConsent() =>
      _channel.invokeMethod<void>('resetModelConsent');

  static Future<bool> openPrivacyPolicy() async =>
      await _channel.invokeMethod<bool>('openPrivacyPolicy') ?? false;
}
