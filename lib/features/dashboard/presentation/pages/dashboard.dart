import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/widgets/app_scaffold.dart';
import '../widgets/dashboard_balance_card.dart';
import '../widgets/dashboard_budget_card.dart';
import '../widgets/dashboard_goals_row.dart';
import '../widgets/dashboard_greeting.dart';
import '../widgets/dashboard_recent_transactions.dart';
import '../widgets/dashboard_section_header.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: 'Cashify',
      actions: [
        IconButton(
          tooltip: 'Insights',
          icon: const Icon(Icons.bar_chart_rounded),
          onPressed: () => context.go('/insights'),
        ),
        IconButton(
          tooltip: 'Settings',
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.go('/settings'),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/transactions/form'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add transaction'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: DashboardGreeting(),
          ),
          const SizedBox(height: 20),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: DashboardBalanceCard(),
          ),
          const SizedBox(height: 28),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DashboardSectionHeader(
              title: "This Month's Budget",
              actionLabel: 'All budgets',
              onAction: () => context.go('/budgets'),
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: DashboardBudgetCard(),
          ),
          const SizedBox(height: 28),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DashboardSectionHeader(
              title: 'Savings Goals',
              actionLabel: 'All goals',
              onAction: () => context.go('/goals'),
            ),
          ),
          const SizedBox(height: 10),
          const DashboardGoalsRow(),
          const SizedBox(height: 28),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DashboardSectionHeader(
              title: 'Recent Transactions',
              actionLabel: 'See all',
              onAction: () => context.go('/transactions'),
            ),
          ),
          const SizedBox(height: 8),
          const DashboardRecentTransactions(),
        ],
      ),
    );
  }
}
