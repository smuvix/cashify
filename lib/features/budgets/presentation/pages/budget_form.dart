import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../categories/domain/entities/category_entity.dart';
import '../../../categories/domain/entities/category_type.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../../core/presentation/widgets/app_scaffold.dart';
import '../../../../core/constants/app_month.dart';
import '../../domain/entities/budget_entity.dart';
import '../providers/budget_providers.dart';
import '../widgets/month_picker_dialog.dart';

void goToBudgetForm(BuildContext context, {BudgetEntity? budget}) {
  context.push('/budgets/form', extra: budget);
}

class BudgetFormPage extends ConsumerStatefulWidget {
  const BudgetFormPage({super.key, this.budget});

  final BudgetEntity? budget;

  @override
  ConsumerState<BudgetFormPage> createState() => _BudgetFormPageState();
}

class _BudgetFormPageState extends ConsumerState<BudgetFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  late DateTime _selectedMonth;
  final Map<String, TextEditingController> _allocationControllers = {};
  bool _submitting = false;

  bool get _isEditing => widget.budget != null;

  @override
  void initState() {
    super.initState();
    final b = widget.budget;
    final now = DateTime.now();
    _selectedMonth = b != null
        ? DateTime(b.month.year, b.month.month)
        : DateTime(now.year, now.month);

    _nameController = TextEditingController(
      text: b?.name ?? _defaultName(_selectedMonth),
    );

    if (b != null) {
      for (final entry in b.categoryAllocations.entries) {
        _allocationControllers[entry.key] = TextEditingController(
          text: entry.value.toStringAsFixed(2),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _allocationControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _defaultName(DateTime month) =>
      '${AppMonth.of(month).fullName} ${month.year}';

  Future<void> _pickMonth() async {
    final picked = await showMonthPickerDialog(
      context,
      initialMonth: _selectedMonth,
    );
    if (picked != null && mounted) {
      setState(() {
        final oldDefault = _defaultName(_selectedMonth);
        _selectedMonth = picked;
        if (_nameController.text == oldDefault ||
            _nameController.text.isEmpty) {
          _nameController.text = _defaultName(picked);
        }
      });
    }
  }

  void _toggleCategory(String categoryId) {
    setState(() {
      if (_allocationControllers.containsKey(categoryId)) {
        _allocationControllers.remove(categoryId)?.dispose();
      } else {
        _allocationControllers[categoryId] = TextEditingController();
      }
    });
  }

  Future<void> _submit(List<CategoryEntity> expenseCategories) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_allocationControllers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one category.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final allocations = <String, double>{};
      for (final entry in _allocationControllers.entries) {
        final val = double.tryParse(entry.value.text.trim()) ?? 0.0;
        if (val > 0) allocations[entry.key] = val;
      }

      if (allocations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All amounts must be greater than 0.')),
        );
        return;
      }

      final notifier = ref.read(budgetProvider.notifier);

      if (_isEditing) {
        await notifier.updateBudget(
          widget.budget!,
          name: _nameController.text.trim(),
          categoryAllocations: allocations,
        );
      } else {
        await notifier.createBudget(
          name: _nameController.text.trim(),
          month: _selectedMonth,
          categoryAllocations: allocations,
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
    final categoriesAsync = ref.watch(categoryProvider);

    return AppScaffold(
      title: _isEditing ? 'Edit budget' : 'New budget',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FilledButton(
            onPressed: _submitting
                ? null
                : () {
                    final cats =
                        categoriesAsync.whenData((categories) {
                          return categories
                              .where((c) => c.type == CategoryType.expense)
                              .toList();
                        }).value ??
                        [];
                    _submit(cats);
                  },
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
                        'The budget month cannot be changed after creation.',
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

            const _SectionLabel(label: 'Budget details'),
            const SizedBox(height: 12),
            _FormCard(
              children: [
                _LabeledField(
                  label: 'Budget name',
                  required: true,
                  child: TextFormField(
                    controller: _nameController,
                    decoration: _fieldDecoration(
                      hint: 'e.g. January 2025',
                      icon: Icons.label_outline_rounded,
                    ),
                    textCapitalization: TextCapitalization.words,
                    style: theme.textTheme.bodyMedium,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Name is required'
                        : null,
                  ),
                ),
                const _FieldDivider(),
                _LabeledField(
                  label: 'Month',
                  required: true,
                  hint: _isEditing
                      ? 'Month cannot be changed after creation'
                      : null,
                  child: InkWell(
                    onTap: _isEditing ? null : _pickMonth,
                    borderRadius: BorderRadius.circular(10),
                    child: _PickerField(
                      isEmpty: false,
                      hint: '',
                      isLocked: _isEditing,
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _defaultName(_selectedMonth),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: _isEditing
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const _SectionLabel(label: 'Category budgets'),
            const SizedBox(height: 6),
            Text(
              'Select expense categories and set a spending limit for each.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            categoriesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text(
                'Failed to load categories: $e',
                style: TextStyle(color: colorScheme.error),
              ),
              data: (categories) {
                final expenseCats = categories
                    .where((c) => c.type == CategoryType.expense)
                    .toList();

                if (expenseCats.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'No expense categories found. Add categories first.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  );
                }

                return _FormCard(
                  children: expenseCats.asMap().entries.map((entry) {
                    final i = entry.key;
                    final cat = entry.value;
                    final isLast = i == expenseCats.length - 1;
                    return Column(
                      children: [
                        _CategoryAllocationRow(
                          category: cat,
                          controller: _allocationControllers[cat.id],
                          isSelected: _allocationControllers.containsKey(
                            cat.id,
                          ),
                          onToggle: () => _toggleCategory(cat.id),
                        ),
                        if (!isLast) const _FieldDivider(),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryAllocationRow extends StatelessWidget {
  const _CategoryAllocationRow({
    required this.category,
    required this.controller,
    required this.isSelected,
    required this.onToggle,
  });

  final CategoryEntity category;
  final TextEditingController? controller;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? category.color : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? category.color
                      : colorScheme.outlineVariant,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: category.color.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(category.icon, size: 16, color: category.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              category.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isSelected && controller != null) ...[
            const SizedBox(width: 10),
            SizedBox(
              width: 110,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: '0.00',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  style: theme.textTheme.bodyMedium,
                  validator: (v) {
                    if (!isSelected) return null;
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final n = double.tryParse(v);
                    if (n == null || n <= 0) return '> 0';
                    return null;
                  },
                ),
              ),
            ),
          ] else if (!isSelected) ...[
            const SizedBox(width: 118),
          ],
        ],
      ),
    );
  }
}

InputDecoration _fieldDecoration({
  required String hint,
  required IconData icon,
}) => InputDecoration(
  hintText: hint,
  prefixIcon: Icon(icon, size: 20),
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
  errorBorder: InputBorder.none,
  focusedErrorBorder: InputBorder.none,
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
