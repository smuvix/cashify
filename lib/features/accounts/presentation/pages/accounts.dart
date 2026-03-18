import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/widgets/app_scaffold.dart';
import '../../../../core/presentation/widgets/empty_state.dart';
import '../../../../core/utils/cashify_formatter_provider.dart';
import '../providers/account_providers.dart';
import '../widgets/account_card.dart';
import 'account_form.dart';

class AccountsPage extends ConsumerWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountProvider);
    final totalAsync = ref.watch(totalBalanceProvider);

    return AppScaffold(
      title: 'Accounts',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => goToAccountForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add account'),
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(
                'Failed to load accounts',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              SelectableText(
                '$e',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(accountProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (accounts) {
          if (accounts.isEmpty) {
            return EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No accounts yet',
              subtitle: 'Add your first account to get started.',
              action: () => goToAccountForm(context),
              actionLabel: 'Add account',
            );
          }
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _TotalBalanceBanner(totalAsync: totalAsync),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
                  child: _SectionLabel(label: 'All accounts'),
                ),
              ),
              SliverList.builder(
                itemCount: accounts.length,
                itemBuilder: (_, i) => AccountCard(account: accounts[i]),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}

class _TotalBalanceBanner extends ConsumerWidget {
  const _TotalBalanceBanner({required this.totalAsync});

  final AsyncValue<double> totalAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fmt = ref.watch(cashifyFormatterProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha(60),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withAlpha(40)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: colorScheme.onPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total balance',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                totalAsync.when(
                  loading: () => Container(
                    width: 100,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  error: (_, _) => const Text('—'),
                  data: (total) => Text(
                    fmt.amountCompact(total),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onPrimaryContainer,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
