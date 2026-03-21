import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/widgets/app_scaffold.dart';
import '../../../../core/presentation/widgets/reusable_dialog.dart';
import '../../../../core/utils/cashify_formatter_provider.dart';
import '../../../accounts/domain/entities/account_entity.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../categories/domain/entities/category_type.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_query.dart';
import '../../domain/entities/transaction_type.dart';
import '../providers/transaction_providers.dart';

void goToTransactionForm(
  BuildContext context, {
  TransactionEntity? transaction,
}) {
  context.push('/transactions/form', extra: transaction);
}

class TransactionFormPage extends ConsumerStatefulWidget {
  const TransactionFormPage({
    super.key,
    this.transaction,
    this.initialType = TransactionType.expense,
  });

  final TransactionEntity? transaction;
  final TransactionType initialType;

  @override
  ConsumerState<TransactionFormPage> createState() =>
      _TransactionFormPageState();
}

class _TransactionFormPageState extends ConsumerState<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _amountController;
  late final TextEditingController _taxController;
  late final TextEditingController _notesController;

  late TransactionType _type;
  late DateTime _date;
  String? _accountId;
  String? _toAccountId;
  String? _categoryId;
  bool _submitting = false;

  bool get _isEditing => widget.transaction != null;
  bool get _isTransfer => _type == TransactionType.transfer;

  CategoryType get _categoryTypeFilter => switch (_type) {
    TransactionType.income => CategoryType.income,
    TransactionType.expense || TransactionType.transfer => CategoryType.expense,
  };

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _type = tx?.type ?? widget.initialType;
    _date = tx?.transactionDate ?? DateTime.now();
    _accountId = tx?.accountId;
    _toAccountId = tx?.toAccountId;
    _categoryId = tx?.categoryId;
    _amountController = TextEditingController(
      text: tx != null ? tx.amount.toString() : '',
    );
    _taxController = TextEditingController(
      text: tx?.tax != null ? tx!.tax.toString() : '',
    );
    _notesController = TextEditingController(text: tx?.notes ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _taxController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _pickAccount({required bool isToAccount}) async {
    final accounts = (ref.read(accountProvider).value ?? [])
        .cast<AccountEntity>();
    final active =
        isToAccount
              ? accounts.where((a) => a.id != _accountId).toList()
              : accounts
          ..toList();

    final picked = await showDialog<String>(
      context: context,
      builder: (_) => ReusableDialog<String?>(
        title: isToAccount ? 'To account' : 'Account',
        initialValue: isToAccount ? _toAccountId : _accountId,
        confirmText: 'Select',
        cancelText: 'Cancel',
        builder: (ctx, value, onChanged) => _AccountPickerContent(
          accounts: active,
          selectedId: value,
          onChanged: onChanged,
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isToAccount) {
          _toAccountId = picked;
        } else {
          _accountId = picked;
          if (_toAccountId == picked) _toAccountId = null;
        }
      });
    }
  }

  Future<void> _pickCategory() async {
    final categories = (ref.read(categoryProvider).value ?? [])
        .cast<CategoryEntity>();
    final filtered = categories
        .where((c) => c.type == _categoryTypeFilter)
        .toList();

    final picked = await showDialog<String>(
      context: context,
      builder: (_) => ReusableDialog<String?>(
        title: 'Category',
        initialValue: _categoryId,
        confirmText: 'Select',
        cancelText: 'Cancel',
        builder: (ctx, value, onChanged) => _CategoryPickerContent(
          categories: filtered,
          selectedId: value,
          onChanged: onChanged,
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _categoryId = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account.')),
      );
      return;
    }
    if (_isTransfer && _toAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination account.')),
      );
      return;
    }
    if (!_isTransfer && _categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final notifier = ref.read(
        transactionProvider(const TransactionQuery()).notifier,
      );

      if (_isEditing) {
        await notifier.updateTransaction(
          widget.transaction!,
          categoryId: _categoryId,
          transactionDate: _date,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
      } else {
        final tax = _type.hasTax && _taxController.text.trim().isNotEmpty
            ? double.tryParse(_taxController.text)
            : null;

        await notifier.createTransaction(
          type: _type,
          amount: double.parse(_amountController.text),
          tax: tax,
          accountId: _accountId!,
          toAccountId: _isTransfer ? _toAccountId : null,
          categoryId: _isTransfer ? null : _categoryId,
          transactionDate: _date,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
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

    final fmt = ref.watch(cashifyFormatterProvider);

    final accountsAsync = ref.watch(accountProvider);
    final categoriesAsync = ref.watch(categoryProvider);

    final accounts = accountsAsync.value?.cast<AccountEntity>() ?? [];
    final allCategories = categoriesAsync.value?.cast<CategoryEntity>() ?? [];
    final filteredCategories = allCategories
        .where((c) => c.type == _categoryTypeFilter)
        .toList();

    final selectedAccount = accounts.cast<AccountEntity?>().firstWhere(
      (a) => a?.id == _accountId,
      orElse: () => null,
    );
    final selectedToAccount = accounts.cast<AccountEntity?>().firstWhere(
      (a) => a?.id == _toAccountId,
      orElse: () => null,
    );
    final selectedCategory = filteredCategories
        .cast<CategoryEntity?>()
        .firstWhere((c) => c?.id == _categoryId, orElse: () => null);

    return AppScaffold(
      title: Text(_isEditing ? 'Edit transaction' : 'New transaction'),
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
                : Text(_isEditing ? 'Save' : 'Add'),
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
                margin: const EdgeInsets.only(bottom: 16),
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
                        'Amount, tax, account and type cannot be changed after creation.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (!_isEditing) ...[
              _SectionLabel(label: 'Type'),
              const SizedBox(height: 12),
              _FormCard(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: TransactionType.values.map((t) {
                        final selected = _type == t;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _type = t;
                                _categoryId = null;
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? t.color.withAlpha(30)
                                      : colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selected
                                        ? t.color
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(t.icon, size: 18, color: t.color),
                                    const SizedBox(height: 4),
                                    Text(
                                      t.label,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: selected
                                                ? t.color
                                                : colorScheme.onSurfaceVariant,
                                            fontWeight: selected
                                                ? FontWeight.w700
                                                : FontWeight.normal,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            _SectionLabel(label: 'Details'),
            const SizedBox(height: 12),
            _FormCard(
              children: [
                _LabeledField(
                  label: 'Amount',
                  required: !_isEditing,
                  locked: _isEditing,
                  child: TextFormField(
                    controller: _amountController,
                    enabled: !_isEditing,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    decoration: _fieldDecoration(
                      hint: '0.00',
                      suffixIcon: _isEditing
                          ? Icon(
                              Icons.lock_outline_rounded,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            )
                          : null,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Amount is required';
                      }
                      if (double.tryParse(v) == null) return 'Invalid amount';
                      if (double.parse(v) <= 0) {
                        return 'Amount must be greater than 0';
                      }
                      return null;
                    },
                  ),
                ),

                if (_type.hasTax) ...[
                  const _FieldDivider(),
                  _LabeledField(
                    label: 'Tax',
                    hint: _isEditing
                        ? null
                        : 'Optional — added on top of the amount',
                    locked: _isEditing,
                    child: TextFormField(
                      controller: _taxController,
                      enabled: !_isEditing,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      decoration: _fieldDecoration(
                        hint: '0.00',
                        suffixIcon: _isEditing
                            ? Icon(
                                Icons.lock_outline_rounded,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              )
                            : null,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        if (double.tryParse(v) == null) return 'Invalid amount';
                        return null;
                      },
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            _SectionLabel(label: 'Date'),
            const SizedBox(height: 12),
            _FormCard(
              children: [
                _LabeledField(
                  label: 'Transaction date',
                  required: true,
                  child: InkWell(
                    onTap: _pickDate,
                    child: _PickerField(
                      isEmpty: false,
                      hint: 'Select date',
                      child: Text(
                        fmt.date(_date),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Account ───────────────────────────────────────────────
            _SectionLabel(label: _isTransfer ? 'Transfer' : 'Account'),
            const SizedBox(height: 12),
            _FormCard(
              children: [
                _LabeledField(
                  label: _isTransfer ? 'From account' : 'Account',
                  required: !_isEditing,
                  locked: _isEditing,
                  child: InkWell(
                    onTap: _isEditing
                        ? null
                        : () => _pickAccount(isToAccount: false),
                    child: _PickerField(
                      isEmpty: selectedAccount == null,
                      hint: 'Select account',
                      isLocked: _isEditing,
                      child: selectedAccount != null
                          ? _AccountPickerTile(account: selectedAccount)
                          : null,
                    ),
                  ),
                ),
                if (_isTransfer) ...[
                  const _FieldDivider(),
                  _LabeledField(
                    label: 'To account',
                    required: !_isEditing,
                    locked: _isEditing,
                    child: InkWell(
                      onTap: _isEditing
                          ? null
                          : () => _pickAccount(isToAccount: true),
                      child: _PickerField(
                        isEmpty: selectedToAccount == null,
                        hint: 'Select destination account',
                        isLocked: _isEditing,
                        child: selectedToAccount != null
                            ? _AccountPickerTile(account: selectedToAccount)
                            : null,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            if (!_isTransfer) ...[
              _SectionLabel(label: 'Category'),
              const SizedBox(height: 12),
              _FormCard(
                children: [
                  _LabeledField(
                    label: 'Category',
                    required: true,
                    child: InkWell(
                      onTap: _pickCategory,
                      child: _PickerField(
                        isEmpty: selectedCategory == null,
                        hint: 'Select category',
                        child: selectedCategory != null
                            ? _CategoryPickerTile(category: selectedCategory)
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            _SectionLabel(label: 'Notes'),
            const SizedBox(height: 12),
            _FormCard(
              children: [
                _LabeledField(
                  label: 'Notes',
                  hint: 'Optional',
                  child: TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: _fieldDecoration(hint: 'Add a note…'),
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

InputDecoration _fieldDecoration({String? hint, Widget? suffixIcon}) =>
    InputDecoration(
      hintText: hint,
      suffixIcon: suffixIcon,
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
    this.locked = false,
  });

  final String label;
  final Widget child;
  final String? hint;
  final bool required;
  final bool locked;

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

class _AccountPickerContent extends StatelessWidget {
  const _AccountPickerContent({
    required this.accounts,
    required this.selectedId,
    required this.onChanged,
  });

  final List<AccountEntity> accounts;
  final String? selectedId;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: accounts.map((a) {
        final isSelected = a.id == selectedId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => onChanged(a.id),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
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
                      color: a.type.color.withAlpha(isSelected ? 60 : 30),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(a.type.icon, size: 18, color: a.type.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          a.currentBalance.toStringAsFixed(2),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isSelected
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

class _CategoryPickerContent extends StatelessWidget {
  const _CategoryPickerContent({
    required this.categories,
    required this.selectedId,
    required this.onChanged,
  });

  final List<CategoryEntity> categories;
  final String? selectedId;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: categories.map((c) {
        final isSelected = c.id == selectedId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => onChanged(c.id),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
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
                      color: c.color.withAlpha(isSelected ? 60 : 30),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(c.icon, size: 18, color: c.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      c.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: colorScheme.primary,
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

class _AccountPickerTile extends StatelessWidget {
  const _AccountPickerTile({required this.account});
  final AccountEntity account;

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
            color: account.type.color.withAlpha(30),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(account.type.icon, size: 14, color: account.type.color),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            account.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          account.currentBalance.toStringAsFixed(2),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CategoryPickerTile extends StatelessWidget {
  const _CategoryPickerTile({required this.category});
  final CategoryEntity category;

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
            color: category.color.withAlpha(30),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(category.icon, size: 14, color: category.color),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            category.name,
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
