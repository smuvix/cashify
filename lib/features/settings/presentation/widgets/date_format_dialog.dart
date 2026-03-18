import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/date_formats.dart';
import '../providers/user_settings_providers.dart';
import '../../../../core/presentation/widgets/reusable_dialog.dart';

void showDateFormatDialog(BuildContext context, WidgetRef ref, String current) {
  showDialog<void>(
    context: context,
    builder: (_) => ReusableDialog<String>(
      title: 'Date format',
      initialValue: current,
      confirmText: 'Apply',
      onConfirm: (selected) async {
        await ref.read(userSettingsProvider.notifier).setDateFormat(selected);
        return true;
      },
      builder: (context, selected, onChanged) =>
          _DateFormatPickerContent(selected: selected, onChanged: onChanged),
    ),
  );
}

class _DateFormatPickerContent extends StatelessWidget {
  const _DateFormatPickerContent({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: kDateFormatOptions.map((option) {
        final isSelected = option.value == selected;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => onChanged(option.value),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  // Calendar icon badge
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha(
                        isSelected ? 60 : 30,
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          option.example,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? colorScheme.onPrimaryContainer.withAlpha(180)
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
