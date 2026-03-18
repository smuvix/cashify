import '../../data/models/theme_mode_model.dart';
import '../../data/services/theme_local_service.dart';
import '../../domain/entities/theme_mode_entity.dart';
import '../../domain/repositories/theme_repository.dart';

class ThemeRepositoryImpl implements ThemeRepository {
  const ThemeRepositoryImpl(this._service);

  final ThemeLocalService _service;

  @override
  ThemeModeEntity loadThemeMode() {
    final raw = _service.loadThemeString();
    return ThemeModeModel.fromString(raw);
  }

  @override
  Future<void> saveThemeMode(ThemeModeEntity entity) {
    final model = ThemeModeModel.fromEntity(entity);
    return _service.saveThemeString(model.toStorageString());
  }
}
