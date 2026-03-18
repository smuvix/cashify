import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/user_settings_repository_impl.dart';
import '../../data/services/user_settings_remote_service.dart';
import '../../domain/entities/user_settings_entity.dart';
import '../../domain/repositories/user_settings_repository.dart';
import '../../domain/usecases/user_settings_use_cases.dart';
import '../controllers/user_settings_controller.dart';

final userSettingsRemoteServiceProvider = Provider<UserSettingsRemoteService>(
  (_) => UserSettingsRemoteServiceImpl(),
);

final userSettingsRepositoryProvider = Provider<UserSettingsRepository>(
  (ref) =>
      UserSettingsRepositoryImpl(ref.read(userSettingsRemoteServiceProvider)),
);

final loadUserSettingsUseCaseProvider = Provider<LoadUserSettingsUseCase>(
  (ref) => LoadUserSettingsUseCase(ref.read(userSettingsRepositoryProvider)),
);

final saveUserSettingsUseCaseProvider = Provider<SaveUserSettingsUseCase>(
  (ref) => SaveUserSettingsUseCase(ref.read(userSettingsRepositoryProvider)),
);

final updateUsernameUseCaseProvider = Provider<UpdateUsernameUseCase>(
  (ref) => UpdateUsernameUseCase(ref.read(saveUserSettingsUseCaseProvider)),
);

final updateDateFormatUseCaseProvider = Provider<UpdateDateFormatUseCase>(
  (ref) => UpdateDateFormatUseCase(ref.read(saveUserSettingsUseCaseProvider)),
);

final updateCurrencyUseCaseProvider = Provider<UpdateCurrencyUseCase>(
  (ref) => UpdateCurrencyUseCase(ref.read(saveUserSettingsUseCaseProvider)),
);

final userSettingsProvider =
    AsyncNotifierProvider<UserSettingsController, UserSettingsEntity>(
      UserSettingsController.new,
    );
