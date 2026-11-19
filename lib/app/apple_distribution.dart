import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/platform/apple_distribution.dart';

bool get usesAppleDistribution => AppleDistribution.usesStoreDistribution;

final testFlightProvider = FutureProvider<bool>(
  (ref) => AppleDistribution.isTestFlight(),
);

Future<void> resetModelConsent() => AppleDistribution.resetModelConsent();
Future<bool> openPrivacyPolicy() => AppleDistribution.openPrivacyPolicy();
