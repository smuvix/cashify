import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/user_settings_providers.dart';
import '../../../../core/presentation/widgets/reusable_dialog.dart';

void showUsernameDialog(BuildContext context, WidgetRef ref, String current) {
  showDialog<void>(
    context: context,
    builder: (_) => _UsernameDialog(current: current, ref: ref),
  );
}

class _UsernameDialog extends StatefulWidget {
  const _UsernameDialog({required this.current, required this.ref});

  final String current;
  final WidgetRef ref;

  @override
  State<_UsernameDialog> createState() => _UsernameDialogState();
}

class _UsernameDialogState extends State<_UsernameDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.current);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ReusableDialog<String>(
      title: 'Set username',
      initialValue: widget.current,
      confirmText: 'Save',
      onConfirm: (value) async {
        if (_formKey.currentState?.validate() ?? false) {
          await widget.ref
              .read(userSettingsProvider.notifier)
              .setUsername(_controller.text);
          return true;
        }
        return false;
      },
      builder: (context, value, onChanged) {
        final colorScheme = Theme.of(context).colorScheme;
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Username',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: TextFormField(
                  controller: _controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Enter your username',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    isDense: true,
                    prefixIcon: Icon(
                      Icons.person_outline_rounded,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: onChanged,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Username cannot be empty';
                    }
                    if (v.trim().length < 2) {
                      return 'At least 2 characters required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
