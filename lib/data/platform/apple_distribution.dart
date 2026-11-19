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

  static Future<void> authorize(ModelProfile profile) async {
    if (!usesStoreDistribution) return;
    final accepted = await _channel.invokeMethod<bool>('authorizeModel', {
      'origin': profile.completionsUri.origin,
      'provider': profile.descriptor.label,
    });
    if (accepted != true) throw const ModelFailure(ModelFailureCode.cancelled);
  }

  static Future<void> resetModelConsent() =>
      _channel.invokeMethod<void>('resetModelConsent');

  static Future<bool> openPrivacyPolicy() async =>
      await _channel.invokeMethod<bool>('openPrivacyPolicy') ?? false;
}
