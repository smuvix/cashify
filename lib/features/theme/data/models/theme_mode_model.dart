import 'package:flutter/material.dart';

import '../../domain/entities/theme_mode_entity.dart';

class ThemeModeModel extends ThemeModeEntity {
  const ThemeModeModel(super.mode);

  static const _light = 'light';
  static const _dark = 'dark';
  static const _system = 'system';

  factory ThemeModeModel.fromString(String? raw) {
    final mode = switch (raw) {
      _light => ThemeMode.light,
      _dark => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return ThemeModeModel(mode);
  }

  String toStorageString() => switch (mode) {
    ThemeMode.light => _light,
    ThemeMode.dark => _dark,
    ThemeMode.system => _system,
  };

  factory ThemeModeModel.fromEntity(ThemeModeEntity entity) =>
      ThemeModeModel(entity.mode);
}
