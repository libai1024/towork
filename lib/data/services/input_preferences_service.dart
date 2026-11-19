import 'package:shared_preferences/shared_preferences.dart';

/// The sole platform-storage boundary for the default input preference.
abstract interface class InputPreferencesService {
  Future<String?> read();
  Future<void> write(String value);
}

class SharedInputPreferencesService implements InputPreferencesService {
  SharedInputPreferencesService({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const storageKey = 'default_input_mode';
  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read() => _preferences.getString(storageKey);

  @override
  Future<void> write(String value) => _preferences.setString(storageKey, value);
}
