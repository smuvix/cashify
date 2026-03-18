import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../../core/presentation/widgets/swipeable_card.dart';
import '../../../../core/utils/cashify_formatter_provider.dart';
import '../../domain/entities/goal_entity.dart';
import '../../domain/entities/goal_progress_entity.dart';
import '../providers/goal_providers.dart';
import '../pages/goal_form.dart';

class GoalCard extends ConsumerWidget {
  const GoalCard({super.key, required this.goal});

  final GoalEntity goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCompleted = goal.isCompleted;

    return SwipeableCard(
      deleteTitle: 'Delete goal?',
      deleteItemName: goal.name,
      onEdit: () => goToGoalForm(context, goal: goal),
      onDelete: () async {
        await ref.read(goalProvider.notifier).deleteGoal(goal.id);
        return true;
      },
      onAction: () async {
        final notifier = ref.read(goalProvider.notifier);
        if (isCompleted) {
          await notifier.markIncomplete(goal);
        } else {
          await notifier.markCompleted(goal);
        }
      },
      actionIcon: isCompleted
          ? Icons.radio_button_unchecked_rounded
          : Icons.check_circle_outline_rounded,
      actionLabel: isCompleted ? 'Reopen' : 'Complete',
      actionColor: isCompleted
          ? colorScheme.surfaceContainerHighest
          : Colors.green.shade700.withAlpha(40),
      actionIconColor: isCompleted
          ? colorScheme.onSurfaceVariant
          : Colors.green.shade700,
      child: _GoalCardContent(goal: goal),
    );
  }
}

class _GoalCardContent extends ConsumerWidget {
  const _GoalCardContent({required this.goal});

  final GoalEntity goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(goalProgressForProvider(goal.id));
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/goals/form', extra: goal),
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
              data: (progress) => _CardBody(goal: goal, progress: progress),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardBody extends ConsumerWidget {
  const _CardBody({required this.goal, required this.progress});

  final GoalEntity goal;
  final GoalProgressEntity progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fmt = ref.watch(cashifyFormatterProvider);

    final isCompleted = goal.isCompleted || progress.isReached;
    final isOverdue = goal.isOverdue && !isCompleted;

    final statusColor = isCompleted
        ? Colors.green
        : isOverdue
        ? colorScheme.error
        : colorScheme.primary;

    final statusLabel = isCompleted
        ? 'Completed'
        : isOverdue
        ? 'Overdue'
        : '${goal.daysRemaining}d left';

    final accountName = ref
        .watch(accountProvider)
        .when(
          data: (accounts) {
            try {
              return accounts.firstWhere((a) => a.id == goal.accountId).name;
            } catch (_) {
              return goal.accountId;
            }
          },
          loading: () => '…',
          error: (_, _) => '—',
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: statusColor.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusColor.withAlpha(50)),
              ),
              child: Icon(Icons.savings_outlined, size: 18, color: statusColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.savings_outlined,
                        size: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        accountName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withAlpha(60)),
              ),
              child: Text(
                statusLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress.progress,
            minHeight: 8,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
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
                    text: fmt.amountWithSymbol(progress.savedAmount),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isCompleted ? Colors.green : colorScheme.onSurface,
                    ),
                  ),
                  TextSpan(
                    text: '  /  ${fmt.amountWithSymbol(progress.targetAmount)}',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                if (isCompleted) ...[
                  const Icon(Icons.check_circle, size: 13, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Target reached!',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else ...[
                  if (isOverdue) ...[
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 13,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Row(
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 12,
                        color: isOverdue
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        fmt.date(goal.deadline),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isOverdue
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant,
                          fontWeight: isOverdue
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(width: 8),
                Text(
                  '${(progress.progress * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
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

class _ProgressSkeleton extends StatelessWidget {
  const _ProgressSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 120,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Container(
              width: 80,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
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
