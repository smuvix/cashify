import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/widgets/reusable_dialog.dart';
import '../../../../core/constants/app_month.dart';

Future<DateTime?> showMonthPickerDialog(
  BuildContext context, {
  required DateTime initialMonth,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) => ReusableDialog<_MonthPickerValue>(
      title: 'Select month',
      initialValue: _MonthPickerValue(
        year: initialMonth.year,
        month: initialMonth.month,
      ),
      confirmText: 'Select',
      cancelText: 'Cancel',
      onConfirm: (value) async {
        context.pop(DateTime(value.year, value.month));
        return false;
      },
      builder: (ctx, value, onChanged) =>
          _MonthPickerContent(value: value, onChanged: onChanged),
    ),
  );
}

class _MonthPickerValue {
  final int year;
  final int month;

  const _MonthPickerValue({required this.year, required this.month});

  _MonthPickerValue copyWith({int? year, int? month}) =>
      _MonthPickerValue(year: year ?? this.year, month: month ?? this.month);
}

class _MonthPickerContent extends StatelessWidget {
  const _MonthPickerContent({required this.value, required this.onChanged});

  final _MonthPickerValue value;
  final void Function(_MonthPickerValue) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () => onChanged(value.copyWith(year: value.year - 1)),
            ),
            Text(
              '${value.year}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: () => onChanged(value.copyWith(year: value.year + 1)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: AppMonth.values.length,
          itemBuilder: (_, i) {
            final month = AppMonth.values[i];
            final isSelected = month.number == value.month;

            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onChanged(value.copyWith(month: month.number)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  month.shortName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
