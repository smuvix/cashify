import 'package:flutter/material.dart';

import 'reusable_dialog.dart';

Future<bool> showDeleteDialog(
  BuildContext context, {
  required String title,
  required String itemName,
  String? customMessage,
  Future<bool> Function()? onConfirm,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => ReusableDialog<bool>(
      title: title,
      initialValue: false,
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmColor: Theme.of(context).colorScheme.error,
      cancelColor: Theme.of(context).colorScheme.onSurfaceVariant,
      onConfirm: onConfirm != null ? (_) => onConfirm() : null,
      builder: (ctx, _, _) {
        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              customMessage ??
                  '"$itemName" will be permanently deleted. This cannot be undone.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    ),
  );
  return result ?? false;
}
