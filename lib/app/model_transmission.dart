import '../l10n/strings.dart';
import '../data/ai/openai_compatible_gateway.dart';
import '../data/platform/apple_distribution.dart';
import '../domain/ai/model_transmission.dart';

Future<void> _allow(String origin, String provider) async {}

AuthorizeModelTransmission get platformModelAuthorization =>
    AppleDistribution.usesStoreDistribution
    ? (origin, provider) => AppleDistribution.authorize(
        origin,
        provider,
        language: strings.localeName,
      )
    : _allow;

OpenAiCompatibleGateway createPlatformModelGateway() =>
    OpenAiCompatibleGateway(authorize: platformModelAuthorization);
