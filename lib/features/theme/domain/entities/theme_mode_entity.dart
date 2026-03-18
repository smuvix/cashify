import 'package:flutter/material.dart';

class ThemeModeEntity {
  const ThemeModeEntity(this.mode);

  final ThemeMode mode;

  bool get isLight => mode == ThemeMode.light;
  bool get isDark => mode == ThemeMode.dark;
  bool get isSystem => mode == ThemeMode.system;

  @override
  bool operator ==(Object other) =>
      other is ThemeModeEntity && other.mode == mode;

  @override
  int get hashCode => mode.hashCode;

  @override
  String toString() => 'ThemeModeEntity(mode: $mode)';
}
