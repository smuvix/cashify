import '../../domain/entities/user_settings_entity.dart';
import '../../domain/repositories/user_settings_repository.dart';

class LoadUserSettingsUseCase {
  const LoadUserSettingsUseCase(this._repository);
  final UserSettingsRepository _repository;
  Future<UserSettingsEntity> call() => _repository.loadSettings();
}

class SaveUserSettingsUseCase {
  const SaveUserSettingsUseCase(this._repository);
  final UserSettingsRepository _repository;
  Future<void> call(UserSettingsEntity entity) =>
      _repository.saveSettings(entity);
}

class UpdateUsernameUseCase {
  const UpdateUsernameUseCase(this._save);
  final SaveUserSettingsUseCase _save;

  Future<UserSettingsEntity> call(
    UserSettingsEntity current,
    String username,
  ) async {
    final updated = current.copyWith(username: username.trim());
    await _save(updated);
    return updated;
  }
}

class UpdateDateFormatUseCase {
  const UpdateDateFormatUseCase(this._save);
  final SaveUserSettingsUseCase _save;

  Future<UserSettingsEntity> call(
    UserSettingsEntity current,
    String dateFormat,
  ) async {
    final updated = current.copyWith(dateFormat: dateFormat);
    await _save(updated);
    return updated;
  }
}

class UpdateCurrencyUseCase {
  const UpdateCurrencyUseCase(this._save);
  final SaveUserSettingsUseCase _save;

  Future<UserSettingsEntity> call(
    UserSettingsEntity current,
    String currency,
  ) async {
    final updated = current.copyWith(currency: currency);
    await _save(updated);
    return updated;
  }
}
