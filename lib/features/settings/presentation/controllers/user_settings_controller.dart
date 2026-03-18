import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_settings_entity.dart';
import '../../domain/usecases/user_settings_use_cases.dart';
import '../providers/user_settings_providers.dart';

class UserSettingsController extends AsyncNotifier<UserSettingsEntity> {
  late UpdateUsernameUseCase _updateUsername;
  late UpdateDateFormatUseCase _updateDateFormat;
  late UpdateCurrencyUseCase _updateCurrency;

  @override
  Future<UserSettingsEntity> build() async {
    _updateUsername = ref.read(updateUsernameUseCaseProvider);
    _updateDateFormat = ref.read(updateDateFormatUseCaseProvider);
    _updateCurrency = ref.read(updateCurrencyUseCaseProvider);
    return ref.read(loadUserSettingsUseCaseProvider)();
  }

  Future<void> setUsername(String username) async {
    final current = state.requireValue;
    state = AsyncData(await _updateUsername(current, username));
  }

  Future<void> setDateFormat(String dateFormat) async {
    final current = state.requireValue;
    state = AsyncData(await _updateDateFormat(current, dateFormat));
  }

  Future<void> setCurrency(String currency) async {
    final current = state.requireValue;
    state = AsyncData(await _updateCurrency(current, currency));
  }
}
