import '../data/services/input_preferences_service.dart';
import 'workspace_state.dart';

class InputPreferenceBootstrap {
  const InputPreferenceBootstrap(this.mode, {this.error});
  final ChatInputMode mode;
  final Object? error;
}

/// A failed local read must not prevent the entire application from starting.
Future<InputPreferenceBootstrap> loadInputPreference(
  InputPreferencesService preferences,
) async {
  try {
    final stored = await preferences.read();
    return InputPreferenceBootstrap(
      stored == ChatInputMode.keyboard.name
          ? ChatInputMode.keyboard
          : ChatInputMode.voice,
    );
  } catch (error) {
    return InputPreferenceBootstrap(ChatInputMode.voice, error: error);
  }
}
