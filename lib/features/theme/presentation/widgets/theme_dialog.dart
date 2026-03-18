import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/theme_provider.dart';
import '../../../../core/presentation/widgets/reusable_dialog.dart';

void showThemeDialog(BuildContext context, WidgetRef ref, ThemeMode current) {
  showDialog<void>(
    context: context,
    builder: (_) => ReusableDialog<ThemeMode>(
      title: 'Choose theme',
      initialValue: current,
      confirmText: 'Apply',
      onConfirm: (selected) async {
        await ref.read(themeModeProvider.notifier).setThemeMode(selected);
        return true;
      },
      builder: (context, selected, onChanged) => Column(
        mainAxisSize: MainAxisSize.min,
        children: ThemeMode.values
            .map(
              (mode) => RadioGroup(
                groupValue: selected,
                onChanged: (value) {
                  if (value != null) onChanged(value);
                },
                child: RadioListTile<ThemeMode>(
                  value: mode,
                  controlAffinity: ListTileControlAffinity.trailing,
                  secondary: Icon(_themeIcon(mode)),
                  title: Text(_themeLabel(mode)),
                ),
              ),
            )
            .toList(),
      ),
    ),
  );
}

String _themeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.light => 'Light Mode',
  ThemeMode.dark => 'Dark Mode',
  ThemeMode.system => 'Follow system',
};

IconData _themeIcon(ThemeMode mode) => switch (mode) {
  ThemeMode.light => Icons.light_mode,
  ThemeMode.dark => Icons.dark_mode,
  ThemeMode.system => Icons.brightness_auto,
};
