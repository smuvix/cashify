import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/presentation/widgets/app_scaffold.dart';
import '../../../../core/constants/app_month.dart';

import '../../../../core/utils/cashify_formatter_provider.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../domain/entities/budget_entity.dart';
import '../providers/budget_providers.dart';
import '../widgets/budget_progress_bar.dart';

class BudgetDetailsPage extends ConsumerWidget {
  const BudgetDetailsPage({super.key, required this.budgetId});

  final String budgetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetProvider);

    return budgetsAsync.when(
      loading: () => const AppScaffold(
        title: 'Budget',
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => AppScaffold(
        title: 'Budget',
        body: Center(child: Text('$e')),
      ),
      data: (budgets) {
        final budget = budgets.cast<BudgetEntity?>().firstWhere(
          (b) => b?.id == budgetId,
          orElse: () => null,
        );

        if (budget == null) {
          return const AppScaffold(
            title: 'Budget',
            body: Center(child: Text('Budget not found.')),
          );
        }

        return _BudgetDetailsView(budget: budget);
      },
    );
  }
}

class _BudgetDetailsView extends ConsumerWidget {
  const _BudgetDetailsView({required this.budget});

  final BudgetEntity budget;

  void _deleteBudget(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(budgetProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);

    late final ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
    snackbarController;

    final undo = notifier.deleteBudgetWithUndo(
      budget,
      onCommitted: () => snackbarController.close(),
    );

    context.pop();

    messenger.clearSnackBars();
    snackbarController = messenger.showSnackBar(
      SnackBar(
        content: Text('${budget.name} deleted'),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(label: 'Undo', onPressed: undo),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fmt = ref.watch(cashifyFormatterProvider);
    final progressAsync = ref.watch(budgetProgressForProvider(budget.id));
    final categoriesAsync = ref.watch(categoryProvider);

    final now = DateTime.now();
    final isCurrentMonth =
        budget.month.year == now.year && budget.month.month == now.month;

    return AppScaffold(
      title: budget.name,
      actions: [
        IconButton(
          tooltip: 'Edit budget',
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => context.push('/budgets/form', extra: budget),
        ),
        IconButton(
          tooltip: 'Delete budget',
          icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
          onPressed: () => _deleteBudget(context, ref),
        ),
        const SizedBox(width: 4),
      ],
      body: progressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Failed to load progress: $e',
            style: TextStyle(color: colorScheme.error),
          ),
        ),
        data: (progress) {
          final isOver = progress.isOverallOverBudget;
          final barColor = isOver ? colorScheme.error : colorScheme.primary;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withAlpha(60),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.primary.withAlpha(40)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.primary.withAlpha(50),
                            ),
                          ),
                          child: Icon(
                            Icons.pie_chart_outline_rounded,
                            color: colorScheme.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                budget.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
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
                        if (isCurrentMonth)
                          _Chip(
                            label: 'This month',
                            color: colorScheme.primaryContainer,
                            textColor: colorScheme.onPrimaryContainer,
                            hasBorder: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total spent',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodyMedium,
                            children: [
                              TextSpan(
                                text: fmt.amountWithSymbol(progress.totalSpent),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isOver
                                      ? colorScheme.error
                                      : colorScheme.onSurface,
                                ),
                              ),
                              TextSpan(
                                text:
                                    '  /  ${fmt.amountWithSymbol(progress.totalBudgeted)}',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    BudgetProgressBar(
                      progress: progress.overallProgress,
                      isOverBudget: isOver,
                      height: 10,
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${(progress.overallProgress * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: barColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    if (isOver) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Over budget by ${fmt.amountWithSymbol(progress.totalSpent - progress.totalBudgeted)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),

              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'BY CATEGORY',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),

              categoriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const SizedBox.shrink(),
                data: (categories) {
                  final catMap = {for (final c in categories) c.id: c};
                  return Column(
                    children: progress.budget.categoryAllocations.entries.map((
                      e,
                    ) {
                      final cat = catMap[e.key];
                      final spent = progress.spentFor(e.key);
                      final budgeted = e.value;
                      final frac = progress.progressFor(e.key);
                      final over = progress.isOverBudget(e.key);
                      final catColor = cat?.color ?? colorScheme.primary;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withAlpha(80),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: catColor.withAlpha(25),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: catColor.withAlpha(60),
                                    ),
                                  ),
                                  child: Icon(
                                    cat?.icon ?? Icons.category_outlined,
                                    size: 18,
                                    color: catColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    cat?.name ?? e.key,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (over)
                                  _Chip(
                                    label: 'Over budget',
                                    color: colorScheme.errorContainer,
                                    textColor: colorScheme.onErrorContainer,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            BudgetProgressBar(
                              progress: frac,
                              isOverBudget: over,
                              height: 7,
                              color: catColor,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Spent',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  '${fmt.amountWithSymbol(spent)} / ${fmt.amountWithSymbol(budgeted)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: over
                                        ? colorScheme.error
                                        : colorScheme.onSurface,
                                    fontWeight: over
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    required this.textColor,
    this.hasBorder = false,
  });

  final String label;
  final Color color;
  final Color textColor;
  final bool hasBorder;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: hasBorder
            ? Border.all(color: colorScheme.primary.withAlpha(60))
            : null,
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
