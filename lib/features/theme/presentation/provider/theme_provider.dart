import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/theme_repository_impl.dart';
import '../../data/services/theme_local_service.dart';
import '../../domain/entities/theme_mode_entity.dart';
import '../../domain/repositories/theme_repository.dart';
import '../../domain/usecases/theme_use_cases.dart';
import '../controllers/theme_mode_controller.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

final themeLocalServiceProvider = Provider<ThemeLocalService>(
  (ref) => ThemeLocalServiceImpl(ref.read(sharedPreferencesProvider)),
);

final themeRepositoryProvider = Provider<ThemeRepository>(
  (ref) => ThemeRepositoryImpl(ref.read(themeLocalServiceProvider)),
);

final loadThemeModeUseCaseProvider = Provider<LoadThemeModeUseCase>(
  (ref) => LoadThemeModeUseCase(ref.read(themeRepositoryProvider)),
);

final saveThemeModeUseCaseProvider = Provider<SaveThemeModeUseCase>(
  (ref) => SaveThemeModeUseCase(ref.read(themeRepositoryProvider)),
);

final toggleThemeModeUseCaseProvider = Provider<ToggleThemeModeUseCase>(
  (ref) => ToggleThemeModeUseCase(ref.read(saveThemeModeUseCaseProvider)),
);

final resetThemeModeUseCaseProvider = Provider<ResetThemeModeUseCase>(
  (ref) => ResetThemeModeUseCase(ref.read(saveThemeModeUseCaseProvider)),
);

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeModeEntity>(
      ThemeModeController.new,
    );

final lightThemeProvider = Provider<ThemeData>(
  (_) => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
    ),
  ),
);

final darkThemeProvider = Provider<ThemeData>(
  (_) => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
    ),
  ),
);

final resolvedThemeModeProvider = Provider<ThemeMode>(
  (ref) => ref.watch(themeModeProvider).mode,
);
