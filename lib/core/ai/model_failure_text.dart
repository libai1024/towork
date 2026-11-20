import 'package:towork/l10n/strings.dart';

import '../../domain/ai/model_gateway.dart';
import '../../domain/settings/model_settings.dart';

/// 模型账户相关错误的用户文案，账户列表、编辑页和模型选择器共用。
/// 只映射类型化错误码，绝不显示服务商返回的原文。
String describeModelSettingsError(Object error) => switch (error) {
  SettingsFailure(:final code) => switch (code) {
    SettingsFailureCode.validation => strings.enterAValidKeyWithoutSpacesOr,
    SettingsFailureCode.credentials =>
      strings.secureStorageIsUnavailableUnlockTheDevice,
    SettingsFailureCode.conflict => strings.settingsChangedReloadAndTryAgain,
    SettingsFailureCode.missingKey => strings.enterAKeyForTheSelectedProvider,
    SettingsFailureCode.storage => strings.couldntReadOrSaveLocalSettingsTry,
  },
  ModelFailure(:final code) => switch (code) {
    ModelFailureCode.configuration => strings.enterAValidModelNameAndKey,
    ModelFailureCode.authentication =>
      strings.authenticationFailedCheckTheKeyApiProduct,
    ModelFailureCode.forbidden =>
      strings.accessDeniedCheckYourSubscriptionAndApi,
    ModelFailureCode.rateLimited => strings.rateLimitReachedTryAgainLater,
    ModelFailureCode.quota => strings.quotaOrBalanceExhaustedCheckTheProvider,
    ModelFailureCode.unavailableModel =>
      strings.modelOrEndpointNotFoundCheckYour,
    ModelFailureCode.cancelled => strings.testCanceled,
    ModelFailureCode.timeout => strings.connectionTimedOutCheckYourNetworkAnd,
    ModelFailureCode.network => strings.connectionFailedTryAgain,
    _ => strings.theServiceReturnedAnIncompleteResponseTry,
  },
  _ => strings.couldntCompleteTheActionTryAgain,
};
