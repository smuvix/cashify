import 'package:shared_preferences/shared_preferences.dart';

abstract interface class ThemeLocalService {
  String? loadThemeString();

  Future<void> saveThemeString(String value);
}

class ThemeLocalServiceImpl implements ThemeLocalService {
  const ThemeLocalServiceImpl(this._prefs);

  final SharedPreferences _prefs;

  static const _kThemeModeKey = 'theme_mode';

  @override
  String? loadThemeString() => _prefs.getString(_kThemeModeKey);

  @override
  Future<void> saveThemeString(String value) =>
      _prefs.setString(_kThemeModeKey, value);
}
