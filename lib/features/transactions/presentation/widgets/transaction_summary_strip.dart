import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/cashify_formatter_provider.dart';
import '../../../../core/constants/app_month.dart';
import '../../domain/entities/transaction_type.dart';

class TransactionSummaryStrip extends ConsumerWidget {
  const TransactionSummaryStrip({
    super.key,
    required this.transactions,
    this.dateFrom,
    this.dateTo,
  });

  final List transactions;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = ref.watch(cashifyFormatterProvider);

    double income = 0, expense = 0;
    for (final tx in transactions) {
      final t = tx as dynamic;
      if (t.type == TransactionType.income) {
        income += (t.totalAmount as double);
      } else if (t.type == TransactionType.expense) {
        expense += (t.totalAmount as double);
      }
    }
    final net = income - expense;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dateFrom != null && dateTo != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DateRangeLabel(dateFrom: dateFrom!, dateTo: dateTo!),
            ),
          ],
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Income',
                  value: income,
                  formatted: fmt.amountCompact(income),
                  icon: Icons.arrow_downward_rounded,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  label: 'Expenses',
                  value: expense,
                  formatted: fmt.amountCompact(expense),
                  icon: Icons.arrow_upward_rounded,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  label: 'Net',
                  value: net,
                  formatted: fmt.amountCompact(net),
                  icon: net >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: net >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateRangeLabel extends StatelessWidget {
  const _DateRangeLabel({required this.dateFrom, required this.dateTo});

  final DateTime dateFrom;
  final DateTime dateTo;

  String get _label {
    if (dateFrom.year == dateTo.year && dateFrom.month == dateTo.month) {
      final month = AppMonth.of(dateFrom);
      return '${month.fullName} ${dateFrom.year}';
    }
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    return '${fmt(dateFrom)} – ${fmt(dateTo)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          Icons.calendar_today_outlined,
          size: 12,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 5),
        Text(
          _label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.formatted,
    required this.icon,
    required this.color,
  });

  final String label;
  final double value;
  final String formatted;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: color.withAlpha(60)),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatted,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
