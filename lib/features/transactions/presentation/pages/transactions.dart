import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/widgets/app_scaffold.dart';
import '../../../../core/presentation/widgets/empty_state.dart';
import '../../../../core/utils/cashify_formatter_provider.dart';
import '../../domain/entities/transaction_query.dart';
import '../../domain/entities/transaction_type.dart';
import '../providers/transaction_providers.dart';
import '../widgets/transaction_card.dart';
import 'transaction_form.dart';
import '../widgets/transaction_summary_strip.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  TransactionType? _selectedType;

  late DateTime _dateFrom;
  late DateTime _dateTo;
  bool _isCustomRange = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateFrom = DateTime(now.year, now.month, 1);
    _dateTo = DateTime(now.year, now.month + 1, 0);
  }

  TransactionQuery get _query => TransactionQuery(
    type: _selectedType,
    dateFrom: _dateFrom,
    dateTo: _dateTo,
  );

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _dateFrom, end: _dateTo),
    );
    if (range != null && mounted) {
      setState(() {
        _dateFrom = range.start;
        _dateTo = range.end;
        _isCustomRange = true;
      });
    }
  }

  void _clearDateFilter() {
    final now = DateTime.now();
    setState(() {
      _dateFrom = DateTime(now.year, now.month, 1);
      _dateTo = DateTime(now.year, now.month + 1, 0);
      _isCustomRange = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      title: 'Transactions',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            tooltip: _isCustomRange ? 'Clear date filter' : 'Filter by date',
            icon: Icon(
              _isCustomRange
                  ? Icons.calendar_month
                  : Icons.calendar_month_outlined,
              color: _isCustomRange ? colorScheme.primary : null,
            ),
            style: _isCustomRange
                ? IconButton.styleFrom(
                    backgroundColor: colorScheme.primaryContainer,
                  )
                : null,
            onPressed: _isCustomRange ? _clearDateFilter : _pickDateRange,
          ),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => goToTransactionForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add transaction'),
      ),
      body: _TransactionTabView(
        query: _query,
        selectedType: _selectedType,
        onTypeChanged: (t) => setState(() => _selectedType = t),
      ),
    );
  }
}

class _TransactionTabView extends ConsumerWidget {
  const _TransactionTabView({
    required this.query,
    required this.selectedType,
    required this.onTypeChanged,
  });

  final TransactionQuery query;
  final TransactionType? selectedType;
  final void Function(TransactionType?) onTypeChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final txAsync = ref.watch(transactionProvider(query));
    final fmt = ref.watch(cashifyFormatterProvider);

    return Column(
      children: [
        Container(
          color: colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  icon: Icons.list_rounded,
                  selected: selectedType == null,
                  onTap: () => onTypeChanged(null),
                ),
                const SizedBox(width: 8),
                ...TransactionType.values.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: t.label,
                      icon: t.icon,
                      selected: selectedType == t,
                      onTap: () => onTypeChanged(t),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: txAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load transactions',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  SelectableText('$e', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(transactionProvider(query)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (transactions) {
              if (transactions.isEmpty) {
                return EmptyState(
                  icon: selectedType?.icon ?? Icons.receipt_long_outlined,
                  title: selectedType != null
                      ? 'No ${selectedType!.label.toLowerCase()} transactions yet'
                      : 'No transactions yet',
                  subtitle: 'Tap + to record your first transaction.',
                );
              }

              final grouped = _groupByDate(transactions);

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: TransactionSummaryStrip(
                      transactions: transactions,
                      dateFrom: query.dateFrom,
                      dateTo: query.dateTo,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  for (final entry in grouped.entries) ...[
                    SliverToBoxAdapter(
                      child: _DateHeader(label: fmt.date(entry.key)),
                    ),
                    SliverList.builder(
                      itemCount: entry.value.length,
                      itemBuilder: (_, i) =>
                          TransactionCard(transaction: entry.value[i]),
                    ),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Map<DateTime, List> _groupByDate(List transactions) {
    final map = <DateTime, List>{};
    for (final tx in transactions) {
      final d = (tx as dynamic).transactionDate as DateTime;
      final key = DateTime(d.year, d.month, d.day);
      map.putIfAbsent(key, () => []).add(tx);
    }
    return map;
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

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    ),
  );
}
