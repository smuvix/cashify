import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/widgets/swipeable_card.dart';
import '../../../../core/utils/cashify_formatter_provider.dart';
import '../../domain/entities/account_entity.dart';
import '../providers/account_providers.dart';
import '../pages/account_form.dart';

class AccountCard extends ConsumerWidget {
  const AccountCard({super.key, required this.account});

  final AccountEntity account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwipeableCard(
      deleteTitle: 'Delete account?',
      deleteItemName: account.name,
      skipConfirmDialog: true,
      onEdit: () => goToAccountForm(context, account: account),
      onDelete: () async {
        final notifier = ref.read(accountProvider.notifier);

        ScaffoldMessenger.of(context).clearSnackBars();
        final snackbarController = ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${account.name}" deleted'),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(label: 'Undo', onPressed: () {}),
          ),
        );

        final undo = notifier.deleteAccountWithUndo(
          account,
          onCommitted: snackbarController.close,
        );

        snackbarController.closed.then((reason) {
          if (reason == SnackBarClosedReason.action) undo();
        });

        return true;
      },
      child: _AccountCardContent(account: account),
    );
  }
}

class _AccountCardContent extends ConsumerWidget {
  const _AccountCardContent({required this.account});

  final AccountEntity account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final typeColor = account.type.color;
    final isNegative = account.currentBalance < 0;

    final fmt = ref.watch(cashifyFormatterProvider);
    final balanceText = fmt.amountWithSymbol(account.currentBalance);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => goToAccountForm(context, account: account),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: typeColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: typeColor.withAlpha(60)),
                  ),
                  child: Icon(account.type.icon, color: typeColor, size: 20),
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        account.type.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isNegative) ...[
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      balanceText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isNegative
                            ? colorScheme.error
                            : colorScheme.onSurface,
                      ),
                    ),
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
