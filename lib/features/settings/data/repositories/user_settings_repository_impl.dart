import '../../data/models/user_settings_model.dart';
import '../../data/services/user_settings_remote_service.dart';
import '../../domain/entities/user_settings_entity.dart';
import '../../domain/repositories/user_settings_repository.dart';

class UserSettingsRepositoryImpl implements UserSettingsRepository {
  const UserSettingsRepositoryImpl(this._service);

  final UserSettingsRemoteService _service;

  @override
  Future<UserSettingsEntity> loadSettings() async {
    final data = await _service.fetchSettings();
    return UserSettingsModel.fromFirestore(data);
  }

  @override
  Future<void> saveSettings(UserSettingsEntity entity) {
    final model = UserSettingsModel.fromEntity(entity);
    return _service.saveSettings(model.toFirestore());
  }
}
