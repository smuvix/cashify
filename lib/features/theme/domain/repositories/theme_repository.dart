import '../../domain/entities/theme_mode_entity.dart';

abstract interface class ThemeRepository {
  ThemeModeEntity loadThemeMode();

  Future<void> saveThemeMode(ThemeModeEntity entity);
}
