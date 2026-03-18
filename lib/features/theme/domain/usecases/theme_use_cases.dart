import 'package:flutter/material.dart';

import '../entities/theme_mode_entity.dart';
import '../repositories/theme_repository.dart';

class LoadThemeModeUseCase {
  const LoadThemeModeUseCase(this._repository);

  final ThemeRepository _repository;

  ThemeModeEntity call() => _repository.loadThemeMode();
}

class SaveThemeModeUseCase {
  const SaveThemeModeUseCase(this._repository);

  final ThemeRepository _repository;

  Future<void> call(ThemeModeEntity entity) =>
      _repository.saveThemeMode(entity);
}

class ToggleThemeModeUseCase {
  const ToggleThemeModeUseCase(this._saveThemeMode);

  final SaveThemeModeUseCase _saveThemeMode;

  Future<ThemeModeEntity> call(ThemeModeEntity current) async {
    final next = switch (current.mode) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.system => ThemeMode.light,
    };
    final entity = ThemeModeEntity(next);
    await _saveThemeMode(entity);
    return entity;
  }
}

class ResetThemeModeUseCase {
  const ResetThemeModeUseCase(this._saveThemeMode);

  final SaveThemeModeUseCase _saveThemeMode;

  Future<ThemeModeEntity> call() async {
    const entity = ThemeModeEntity(ThemeMode.system);
    await _saveThemeMode(entity);
    return entity;
  }
}
