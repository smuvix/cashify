import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/domain/entities/user_settings_entity.dart';
import '../../features/settings/presentation/providers/user_settings_providers.dart';
import 'cashify_formatter.dart';

final cashifyFormatterProvider = Provider<CashifyFormatter>((ref) {
  final settingsAsync = ref.watch(userSettingsProvider);

  return settingsAsync.when(
    data: (settings) => CashifyFormatter(settings),
    loading: () => CashifyFormatter(_defaultSettings),
    error: (_, _) => CashifyFormatter(_defaultSettings),
  );
});

final _defaultSettings = UserSettingsEntity(
  currency: 'USD',
  dateFormat: 'd MMM yyyy',
  username: '',
);
