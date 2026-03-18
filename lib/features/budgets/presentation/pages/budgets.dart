import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/widgets/app_scaffold.dart';
import '../../../../core/presentation/widgets/empty_state.dart';
import '../providers/budget_providers.dart';
import '../widgets/budget_card.dart';
import 'budget_form.dart';

class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetProvider);

    return AppScaffold(
      title: 'Budgets',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => goToBudgetForm(context),
        icon: const Icon(Icons.add),
        label: const Text('New budget'),
      ),
      body: budgetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(
                'Failed to load budgets',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              SelectableText(
                '$e',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(budgetProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (budgets) {
          if (budgets.isEmpty) {
            return EmptyState(
              icon: Icons.pie_chart_outline_rounded,
              title: 'No budgets yet',
              subtitle: 'Create a monthly budget to track your spending.',
              action: () => goToBudgetForm(context),
              actionLabel: 'New budget',
            );
          }

          final now = DateTime.now();
          final current = budgets
              .where(
                (b) => b.month.year == now.year && b.month.month == now.month,
              )
              .toList();
          final past = budgets
              .where(
                (b) =>
                    !(b.month.year == now.year && b.month.month == now.month),
              )
              .toList();

          return CustomScrollView(
            slivers: [
              if (current.isNotEmpty) ...[
                const _SectionHeader(label: 'Current month'),
                SliverList.builder(
                  itemCount: current.length,
                  itemBuilder: (_, i) => BudgetCard(budget: current[i]),
                ),
              ],
              if (past.isNotEmpty) ...[
                const _SectionHeader(label: 'Past budgets'),
                SliverList.builder(
                  itemCount: past.length,
                  itemBuilder: (_, i) => BudgetCard(budget: past[i]),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}
