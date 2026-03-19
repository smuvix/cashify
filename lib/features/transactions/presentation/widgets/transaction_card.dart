import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/widgets/swipeable_card.dart';
import '../../../../core/utils/cashify_formatter_provider.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_query.dart';
import '../../domain/entities/transaction_type.dart';
import '../providers/transaction_providers.dart';

class TransactionCard extends ConsumerWidget {
  const TransactionCard({super.key, required this.transaction});

  final TransactionEntity transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwipeableCard(
      deleteTitle: 'Delete transaction?',
      customDeleteMessage: 'This will also reverse the account balance change.',
      skipConfirmDialog: true,
      onEdit: () => context.push('/transactions/form', extra: transaction),
      onDelete: () async {
        final notifier = ref.read(
          transactionProvider(const TransactionQuery()).notifier,
        );

        ScaffoldMessenger.of(context).clearSnackBars();
        final snackbarController = ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaction deleted'),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(label: 'Undo', onPressed: () {}),
          ),
        );

        final undo = notifier.deleteTransactionWithUndo(
          transaction,
          onCommitted: () {
            snackbarController.close();
          },
        );

        snackbarController.closed.then((reason) {
          if (reason == SnackBarClosedReason.action) undo();
        });

        return true;
      },
      child: _TransactionCardContent(transaction: transaction),
    );
  }
}

class _TransactionCardContent extends ConsumerWidget {
  const _TransactionCardContent({required this.transaction});

  final TransactionEntity transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fmt = ref.watch(cashifyFormatterProvider);
    final type = transaction.type;
    final isTransfer = type == TransactionType.transfer;

    final categoriesAsync = isTransfer ? null : ref.watch(categoryProvider);
    final category = isTransfer
        ? null
        : categoriesAsync!.whenData(
            (cats) =>
                cats.where((c) => c.id == transaction.categoryId).firstOrNull,
          );

    final accountsAsync = isTransfer ? ref.watch(accountProvider) : null;

    final iconColor =
        (!isTransfer ? category?.whenOrNull(data: (c) => c?.color) : null) ??
        type.color;

    final amountSign = switch (type) {
      TransactionType.income => '+',
      TransactionType.expense => '−',
      TransactionType.transfer => '⇄',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/transactions/form', extra: transaction),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: iconColor.withAlpha(60)),
                  ),
                  child: isTransfer
                      ? Icon(type.icon, color: type.color, size: 20)
                      : category!.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) =>
                              Icon(type.icon, color: type.color, size: 20),
                          data: (cat) => Icon(
                            cat?.icon ?? type.icon,
                            color: cat?.color ?? type.color,
                            size: 20,
                          ),
                        ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      isTransfer
                          ? Text(
                              type.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            )
                          : category!.when(
                              loading: () => const Text('…'),
                              error: (_, _) => Text(type.label),
                              data: (cat) => Text(
                                cat?.name ?? 'Category deleted',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                      if (isTransfer) ...[
                        const SizedBox(height: 2),
                        _TransferAccountsSubtitle(
                          transaction: transaction,
                          accountsAsync: accountsAsync!,
                        ),
                      ] else if (transaction.notes != null &&
                          transaction.notes!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          transaction.notes!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$amountSign ${fmt.amountWithSymbol(transaction.totalAmount)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: type.color,
                      ),
                    ),
                    if (transaction.tax != null && transaction.tax! > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${fmt.amountWithSymbol(transaction.amount)} + ${fmt.amountWithSymbol(transaction.tax!)} tax',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TransferAccountsSubtitle extends StatelessWidget {
  const _TransferAccountsSubtitle({
    required this.transaction,
    required this.accountsAsync,
  });

  final TransactionEntity transaction;
  final AsyncValue accountsAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return accountsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (accounts) {
        final list = (accounts as List<dynamic>);
        final fromName = list
            .where((a) => (a as dynamic).id == transaction.accountId)
            .map((a) => (a as dynamic).name as String)
            .firstOrNull;
        final toName = list
            .where((a) => (a as dynamic).id == transaction.toAccountId)
            .map((a) => (a as dynamic).name as String)
            .firstOrNull;

        if (fromName == null && toName == null) return const SizedBox.shrink();

        return Text(
          '${fromName ?? '?'} → ${toName ?? '?'}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
