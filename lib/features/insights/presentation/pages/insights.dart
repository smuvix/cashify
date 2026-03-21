import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/widgets/app_scaffold.dart';
import '../../../../core/presentation/widgets/empty_state.dart';
import '../../../../core/utils/cashify_formatter_provider.dart';
import '../../../transactions/presentation/widgets/transaction_summary_strip.dart';
import '../../domain/entities/insight_period.dart';
import '../providers/insight_providers.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/income_expense_bar_chart.dart';

class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});

  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage> {
  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final selection = ref.read(insightSelectionProvider);

    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: selection.isCustom
          ? DateTimeRange(start: selection.dateFrom, end: selection.dateTo)
          : DateTimeRange(
              start: now.subtract(const Duration(days: 30)),
              end: now,
            ),
      helpText: 'SELECT DATE RANGE',
      saveText: 'APPLY',
    );

    if (range != null && mounted) {
      final dateFrom = DateTime(
        range.start.year,
        range.start.month,
        range.start.day,
      );
      final dateTo = DateTime(
        range.end.year,
        range.end.month,
        range.end.day + 1,
      ).subtract(const Duration(milliseconds: 1));

      ref
          .read(insightSelectionProvider.notifier)
          .selectCustomRange(dateFrom: dateFrom, dateTo: dateTo);
    }
  }

  static const _periods = [
    InsightPeriod.monthly,
    InsightPeriod.threeMonths,
    InsightPeriod.sixMonths,
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selection = ref.watch(insightSelectionProvider);

    return AppScaffold(
      title: Text('Insights'),
      body: Column(
        children: [
          Container(
            color: colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._periods.map((p) {
                    final selected =
                        !selection.isCustom && selection.period == p;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: p.label,
                        icon: Icons.schedule_rounded,
                        selected: selected,
                        onTap: () => ref
                            .read(insightSelectionProvider.notifier)
                            .selectPeriod(p),
                      ),
                    );
                  }),
                  _FilterChip(
                    label: 'Custom',
                    icon: selection.isCustom
                        ? Icons.check_rounded
                        : Icons.date_range_outlined,
                    selected: selection.isCustom,
                    onTap: _pickCustomRange,
                  ),
                ],
              ),
            ),
          ),
          const Expanded(child: _InsightBody()),
        ],
      ),
    );
  }
}

class _InsightBody extends ConsumerWidget {
  const _InsightBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fmt = ref.watch(cashifyFormatterProvider);
    final reportAsync = ref.watch(insightProvider);
    final selection = ref.watch(insightSelectionProvider);

    return reportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text('Failed to load insights', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            SelectableText('$e', style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.read(insightProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (report) {
        if (!report.hasData) {
          return EmptyState(
            icon: Icons.bar_chart_outlined,
            title: 'No transactions found',
            subtitle:
                '${fmt.date(selection.dateFrom)} – ${fmt.date(selection.dateTo)}\n'
                'Add income or expense transactions\nto see your insights.',
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withAlpha(80),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.date_range_outlined,
                          size: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${fmt.date(report.dateFrom)} – ${fmt.date(report.dateTo)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              TransactionSummaryStrip(transactions: report.transactions),
              const SizedBox(height: 28),
              _SectionLabel(label: 'Income vs Expenses'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withAlpha(80),
                  ),
                ),
                child: IncomeExpenseBarChart(bars: report.monthlyBars),
              ),
              if (report.categoryBreakdown.isNotEmpty) ...[
                const SizedBox(height: 28),
                _SectionLabel(label: 'Spending by Category'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withAlpha(80),
                    ),
                  ),
                  child: Center(
                    child: CategoryPieChart(
                      slices: report.categoryBreakdown,
                      totalExpenses: report.totalExpenses,
                      size: 220,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withAlpha(80),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}
