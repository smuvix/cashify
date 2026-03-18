import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/user_settings_entity.dart';

class UserSettingsModel extends UserSettingsEntity {
  const UserSettingsModel({
    required super.username,
    required super.dateFormat,
    required super.currency,
  });

  factory UserSettingsModel.fromFirestore(Map<String, dynamic>? data) =>
      UserSettingsModel(
        username:
            (data?[AppConstants.kUsername] as String?) ??
            AppConstants.defaultUsername,
        dateFormat:
            (data?[AppConstants.kDateFormat] as String?) ??
            AppConstants.defaultDateFormat,
        currency:
            (data?[AppConstants.kCurrency] as String?) ??
            AppConstants.defaultCurrency,
      );

  Map<String, dynamic> toFirestore() => {
    AppConstants.kUsername: username,
    AppConstants.kDateFormat: dateFormat,
    AppConstants.kCurrency: currency,
  };

  factory UserSettingsModel.fromEntity(UserSettingsEntity entity) =>
      UserSettingsModel(
        username: entity.username,
        dateFormat: entity.dateFormat,
        currency: entity.currency,
      );
}
