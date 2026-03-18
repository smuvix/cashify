import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/widgets/app_scaffold.dart';
import '../../../../core/presentation/widgets/empty_state.dart';
import '../providers/goal_providers.dart';
import '../widgets/goal_card.dart';
import 'goal_form.dart';

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalProvider);

    return AppScaffold(
      title: 'Goals',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => goToGoalForm(context),
        icon: const Icon(Icons.add),
        label: const Text('New goal'),
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(
                'Failed to load goals',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              SelectableText(
                '$e',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(goalProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (goals) {
          if (goals.isEmpty) {
            return EmptyState(
              icon: Icons.savings_outlined,
              title: 'No goals yet',
              subtitle:
                  'Create a savings goal and link it to a\nsavings account to track your progress.',
              action: () => goToGoalForm(context),
              actionLabel: 'New goal',
            );
          }

          final active = goals.where((g) => !g.isCompleted).toList();
          final completed = goals.where((g) => g.isCompleted).toList();

          return CustomScrollView(
            slivers: [
              if (active.isNotEmpty) ...[
                const _SectionHeader(label: 'Active'),
                SliverList.builder(
                  itemCount: active.length,
                  itemBuilder: (_, i) => GoalCard(goal: active[i]),
                ),
              ],
              if (completed.isNotEmpty) ...[
                const _SectionHeader(label: 'Completed'),
                SliverList.builder(
                  itemCount: completed.length,
                  itemBuilder: (_, i) => GoalCard(goal: completed[i]),
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
