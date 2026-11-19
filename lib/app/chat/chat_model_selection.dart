import '../../domain/settings/app_preferences.dart';
import '../../domain/settings/model_account_service.dart';
import '../app_preferences_provider.dart';

/// Signals that selecting a model failed and automatic routing could not be
/// restored. The UI must expose the remaining manual-routing state.
class ModelSelectionRestoreFailure implements Exception {}

/// Switch to a fixed model, restoring routing on failure without overwriting a
/// newer preference edit. Account persistence retains its own atomic revision.
Future<void> selectChatModel({
  required ModelAccountService accounts,
  required AppPreferencesController preferences,
  required String accountId,
  required String model,
}) async {
  final before = preferences.current();
  final disabled = before.autoRoute
      ? await preferences.save({'auto_route': false})
      : before;
  try {
    await accounts.activate(accountId, model: model);
  } catch (_) {
    if (before.autoRoute) {
      try {
        await preferences.save({
          'auto_route': true,
        }, expectedVersion: disabled.version);
      } on PreferenceFailure catch (error) {
        // A newer preference edit belongs to its caller. Leave it untouched.
        if (error.code != PreferenceFailureCode.conflict) {
          throw ModelSelectionRestoreFailure();
        }
      } catch (_) {
        throw ModelSelectionRestoreFailure();
      }
    }
    rethrow;
  }
}
