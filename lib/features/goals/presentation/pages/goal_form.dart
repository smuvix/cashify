import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../accounts/domain/entities/account_type.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../../core/presentation/widgets/app_scaffold.dart';
import '../../../../core/presentation/widgets/reusable_dialog.dart';
import '../../../../core/utils/cashify_formatter_provider.dart';
import '../../domain/entities/goal_entity.dart';
import '../providers/goal_providers.dart';

void goToGoalForm(BuildContext context, {GoalEntity? goal}) {
  context.push('/goals/form', extra: goal);
}

class GoalFormPage extends ConsumerStatefulWidget {
  const GoalFormPage({super.key, this.goal});

  final GoalEntity? goal;

  @override
  ConsumerState<GoalFormPage> createState() => _GoalFormPageState();
}

class _GoalFormPageState extends ConsumerState<GoalFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _targetController;
  late final TextEditingController _notesController;

  late DateTime _startDate;
  late DateTime _deadline;
  String? _accountId;
  bool _submitting = false;

  bool get _isEditing => widget.goal != null;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    final now = DateTime.now();

    _nameController = TextEditingController(text: g?.name ?? '');
    _targetController = TextEditingController(
      text: g != null ? g.targetAmount.toStringAsFixed(2) : '',
    );
    _notesController = TextEditingController(text: g?.notes ?? '');
    _startDate = g?.startDate ?? DateTime(now.year, now.month, now.day);
    _deadline = g?.deadline ?? DateTime(now.year, now.month + 3, now.day);
    _accountId = g?.accountId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: _deadline.subtract(const Duration(days: 1)),
    );
    if (picked != null && mounted) setState(() => _startDate = picked);
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: _startDate.add(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _deadline = picked);
  }

  Future<void> _pickAccount(
    List<dynamic> savingsAccounts,
    Set<String> linkedAccountIds,
  ) async {
    final picked = await showDialog<String>(
      context: context,
      builder: (_) => ReusableDialog<String?>(
        title: 'Select account',
        initialValue: _accountId,
        confirmText: 'Select',
        cancelText: 'Cancel',
        builder: (ctx, value, onChanged) => _AccountPickerContent(
          accounts: savingsAccounts,
          selectedId: value,
          linkedAccountIds: linkedAccountIds,
          onChanged: onChanged,
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _accountId = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _accountId == null) {
      if (_accountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a savings account.')),
        );
      }
      return;
    }

    setState(() => _submitting = true);

    try {
      final notifier = ref.read(goalProvider.notifier);
      final notesText = _notesController.text.trim();

      if (_isEditing) {
        await notifier.updateGoal(
          widget.goal!,
          name: _nameController.text.trim(),
          targetAmount: double.parse(_targetController.text),
          startDate: _startDate,
          deadline: _deadline,
          notes: notesText.isEmpty ? null : notesText,
        );
      } else {
        await notifier.createGoal(
          name: _nameController.text.trim(),
          accountId: _accountId!,
          targetAmount: double.parse(_targetController.text),
          startDate: _startDate,
          deadline: _deadline,
          notes: notesText.isEmpty ? null : notesText,
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accountsAsync = ref.watch(accountProvider);
    final linkedAccountIds =
        ref
            .watch(goalProvider)
            .whenData(
              (goals) => goals
                  .where((g) => !g.isCompleted)
                  .where((g) => g.id != widget.goal?.id)
                  .map((g) => g.accountId)
                  .toSet(),
            )
            .value ??
        {};
    final fmt = ref.watch(cashifyFormatterProvider);

    return AppScaffold(
      title: Text(_isEditing ? 'Edit goal' : 'New goal'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size(80, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _submitting
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : Text(_isEditing ? 'Save' : 'Create'),
          ),
        ),
      ],
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 60),
          children: [
            if (_isEditing) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withAlpha(120),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.secondary.withAlpha(80),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'The linked savings account cannot be changed '
                        'after creation.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            const _SectionLabel(label: 'Goal details'),
            const SizedBox(height: 12),
            _FormCard(
              children: [
                _LabeledField(
                  label: 'Goal name',
                  required: true,
                  child: TextFormField(
                    controller: _nameController,
                    decoration: _fieldDecoration(
                      hint: 'e.g. Emergency Fund, New Car',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name is required'
                        : null,
                  ),
                ),
                const _FieldDivider(),
                _LabeledField(
                  label: 'Target amount',
                  required: true,
                  child: TextFormField(
                    controller: _targetController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    decoration: _fieldDecoration(hint: '0.00'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Target amount is required';
                      }
                      if (double.tryParse(v) == null) return 'Invalid amount';
                      if (double.parse(v) <= 0) {
                        return 'Amount must be greater than 0';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const _SectionLabel(label: 'Timeline'),
            const SizedBox(height: 12),
            _FormCard(
              children: [
                _LabeledField(
                  label: 'Start date',
                  required: true,
                  child: InkWell(
                    onTap: _pickStartDate,
                    child: _PickerField(
                      isEmpty: false,
                      hint: 'Select start date',
                      child: Text(
                        fmt.date(_startDate),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
                const _FieldDivider(),
                _LabeledField(
                  label: 'Deadline',
                  required: true,
                  child: InkWell(
                    onTap: _pickDeadline,
                    child: _PickerField(
                      isEmpty: false,
                      hint: 'Select deadline',
                      child: Text(
                        fmt.date(_deadline),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const _SectionLabel(label: 'Savings account'),
            const SizedBox(height: 12),
            accountsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(
                'Failed to load accounts: $e',
                style: TextStyle(color: colorScheme.error),
              ),
              data: (accounts) {
                final savingsAccounts = accounts
                    .where((a) => (a as dynamic).type == AccountType.savings)
                    .toList();

                final selectedAccount = savingsAccounts
                    .cast<dynamic>()
                    .where((a) => a.id == _accountId)
                    .firstOrNull;

                return _FormCard(
                  children: [
                    _LabeledField(
                      label: 'Account',
                      required: true,
                      child: InkWell(
                        onTap: _isEditing
                            ? null
                            : () => _pickAccount(
                                savingsAccounts,
                                linkedAccountIds,
                              ),
                        child: _PickerField(
                          isEmpty: selectedAccount == null,
                          hint: savingsAccounts.isEmpty
                              ? 'No savings accounts found'
                              : 'Select savings account',
                          isLocked: _isEditing,
                          child: selectedAccount != null
                              ? _AccountTile(account: selectedAccount)
                              : null,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            const _SectionLabel(label: 'Notes'),
            const SizedBox(height: 12),
            _FormCard(
              children: [
                _LabeledField(
                  label: 'Notes',
                  hint: 'Optional',
                  child: TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: _fieldDecoration(
                      hint: 'Why are you saving for this?',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration({String? hint}) => InputDecoration(
  hintText: hint,
  border: InputBorder.none,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  isDense: true,
);

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

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.hint,
    this.required = false,
  });

  final String label;
  final Widget child;
  final String? hint;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              if (required) ...[
                const SizedBox(width: 3),
                Text(
                  '*',
                  style: TextStyle(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(
              hint!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FieldDivider extends StatelessWidget {
  const _FieldDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.outlineVariant.withAlpha(60),
      indent: 16,
      endIndent: 16,
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.isEmpty,
    required this.hint,
    this.child,
    this.isLocked = false,
  });

  final bool isEmpty;
  final String hint;
  final Widget? child;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: isEmpty
                ? Text(
                    hint,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  )
                : child ?? const SizedBox.shrink(),
          ),
          if (!isLocked)
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          if (isLocked)
            Icon(
              Icons.lock_outline_rounded,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.account});
  final dynamic account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AccountType.savings.color.withAlpha(30),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            AccountType.savings.icon,
            size: 14,
            color: AccountType.savings.color,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            account.name as String,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _AccountPickerContent extends StatelessWidget {
  const _AccountPickerContent({
    required this.accounts,
    required this.selectedId,
    required this.linkedAccountIds,
    required this.onChanged,
  });

  final List<dynamic> accounts;
  final String? selectedId;
  final Set<String> linkedAccountIds;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: accounts.map<Widget>((a) {
        final isSelected = a.id == selectedId;
        final isLinked = linkedAccountIds.contains(a.id as String);
        final isDisabled = isLinked && !isSelected;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: isDisabled ? null : () => onChanged(a.id as String),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isDisabled
                    ? colorScheme.surfaceContainerHighest.withAlpha(120)
                    : isSelected
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AccountType.savings.color.withAlpha(
                        isDisabled
                            ? 15
                            : isSelected
                            ? 60
                            : 30,
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      AccountType.savings.icon,
                      size: 18,
                      color: AccountType.savings.color.withAlpha(
                        isDisabled ? 80 : 255,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.name as String,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDisabled
                                ? colorScheme.onSurface.withAlpha(80)
                                : isSelected
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          isDisabled
                              ? 'Already linked to a goal'
                              : (a.currentBalance as double).toStringAsFixed(2),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDisabled
                                ? colorScheme.onSurface.withAlpha(60)
                                : isSelected
                                ? colorScheme.onPrimaryContainer.withAlpha(180)
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    )
                  else if (isDisabled)
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: colorScheme.onSurface.withAlpha(60),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
