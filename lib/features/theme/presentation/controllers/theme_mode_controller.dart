import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/theme_mode_entity.dart';
import '../../domain/usecases/theme_use_cases.dart';
import '../provider/theme_provider.dart';

class ThemeModeController extends Notifier<ThemeModeEntity> {
  late LoadThemeModeUseCase _load;
  late SaveThemeModeUseCase _save;
  late ToggleThemeModeUseCase _toggle;
  late ResetThemeModeUseCase _reset;

  @override
  ThemeModeEntity build() {
    _load = ref.read(loadThemeModeUseCaseProvider);
    _save = ref.read(saveThemeModeUseCaseProvider);
    _toggle = ref.read(toggleThemeModeUseCaseProvider);
    _reset = ref.read(resetThemeModeUseCaseProvider);
    return _load();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final entity = ThemeModeEntity(mode);
    await _save(entity);
    state = entity;
  }

  Future<void> toggleTheme() async {
    state = await _toggle(state);
  }

  Future<void> resetToSystem() async {
    state = await _reset();
  }

  bool get isLight => state.isLight;
  bool get isDark => state.isDark;
  bool get isSystem => state.isSystem;
}
