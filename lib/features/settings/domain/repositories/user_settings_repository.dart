import '../../domain/entities/user_settings_entity.dart';

abstract interface class UserSettingsRepository {
  Future<UserSettingsEntity> loadSettings();
  Future<void> saveSettings(UserSettingsEntity entity);
}
