import 'package:flutter/material.dart';

class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({
    super.key,
    required this.progress,
    required this.isOverBudget,
    required this.height,
    this.color,
  });

  final double progress;
  final bool isOverBudget;
  final double height;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final barColor = isOverBudget
        ? colorScheme.error
        : (color ?? colorScheme.primary);

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: height,
        backgroundColor: colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation<Color>(barColor),
      ),
    );
  }
}
