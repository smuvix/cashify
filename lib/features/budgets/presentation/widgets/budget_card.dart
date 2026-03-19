import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/widgets/swipeable_card.dart';
import '../../../../core/constants/app_month.dart';
import '../../../../core/utils/cashify_formatter_provider.dart';
import '../../domain/entities/budget_entity.dart';
import '../../domain/entities/budget_progress_entity.dart';
import '../pages/budget_form.dart';
import '../providers/budget_providers.dart';

class BudgetCard extends ConsumerWidget {
  const BudgetCard({super.key, required this.budget});

  final BudgetEntity budget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwipeableCard(
      deleteTitle: 'Delete budget?',
      deleteItemName: budget.name,
      skipConfirmDialog: true,
      onEdit: () => goToBudgetForm(context, budget: budget),
      onDelete: () async {
        final notifier = ref.read(budgetProvider.notifier);
        final messenger = ScaffoldMessenger.of(context);

        late final ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
        snackbarController;

        final undo = notifier.deleteBudgetWithUndo(
          budget,
          onCommitted: () => snackbarController.close(),
        );

        messenger.clearSnackBars();
        snackbarController = messenger.showSnackBar(
          SnackBar(
            content: Text('${budget.name} deleted'),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(label: 'Undo', onPressed: undo),
          ),
        );

        return true;
      },
      child: _BudgetCardContent(budget: budget),
    );
  }
}

class _BudgetCardContent extends ConsumerWidget {
  const _BudgetCardContent({required this.budget});

  final BudgetEntity budget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(budgetProgressForProvider(budget.id));
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/budgets/${budget.id}'),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: colorScheme.outlineVariant.withAlpha(80),
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(16),
            child: progressAsync.when(
              loading: () => const _ProgressSkeleton(),
              error: (e, _) => _ErrorChip(message: '$e'),
              data: (progress) => _CardBody(budget: budget, progress: progress),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardBody extends ConsumerWidget {
  const _CardBody({required this.budget, required this.progress});

  final BudgetEntity budget;
  final BudgetProgressEntity progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fmt = ref.watch(cashifyFormatterProvider);

    final isOver = progress.isOverallOverBudget;
    final barColor = isOver ? colorScheme.error : colorScheme.primary;

    final now = DateTime.now();
    final isCurrentMonth =
        budget.month.year == now.year && budget.month.month == now.month;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.primary.withAlpha(50)),
              ),
              child: Icon(
                Icons.pie_chart_outline_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    budget.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${AppMonth.of(budget.month).fullName} ${budget.month.year}'
                    '  ·  ${budget.categoryAllocations.length} '
                    '${budget.categoryAllocations.length == 1 ? 'category' : 'categories'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isCurrentMonth) ...[
              const SizedBox(width: 8),
              _StatusChip(
                label: 'This month',
                color: colorScheme.primaryContainer,
                textColor: colorScheme.onPrimaryContainer,
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),

        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress.overallProgress,
            minHeight: 8,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                style: theme.textTheme.bodySmall,
                children: [
                  TextSpan(
                    text: fmt.amountWithSymbol(progress.totalSpent),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isOver ? colorScheme.error : colorScheme.onSurface,
                    ),
                  ),
                  TextSpan(
                    text:
                        '  /  ${fmt.amountWithSymbol(progress.totalBudgeted)}',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                if (isOver) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Over budget',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  '${(progress.overallProgress * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: barColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ProgressSkeleton extends StatelessWidget {
  const _ProgressSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 120,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

class _ErrorChip extends StatelessWidget {
  const _ErrorChip({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.error_outline, size: 16, color: colorScheme.error),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Failed to load progress: $message',
            style: TextStyle(color: colorScheme.error, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
