import 'package:flutter/material.dart';

import 'reusable_dialog.dart';

Future<bool> showDeleteDialog(
  BuildContext context, {
  required String title,
  required String itemName,
  String? customMessage,
  Future<bool> Function()? onConfirm,
}) async {
  final message =
      customMessage ??
      '"$itemName" will be permanently deleted. This cannot be undone.';

  final result = await showDialog<bool>(
    context: context,
    builder: (_) => ReusableDialog<bool>(
      title: title,
      initialValue: false,
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmColor: Theme.of(context).colorScheme.error,
      cancelColor: Theme.of(context).colorScheme.onSurfaceVariant,
      onConfirm: (_) async {
        if (onConfirm != null) return onConfirm();
        return true;
      },
      builder: (ctx, _, _) => _DeleteBody(message: message),
    ),
  );
  return result ?? false;
}

class _DeleteBody extends StatelessWidget {
  const _DeleteBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
