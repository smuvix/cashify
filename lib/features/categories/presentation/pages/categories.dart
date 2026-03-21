import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/widgets/app_scaffold.dart';
import '../../../../core/presentation/widgets/empty_state.dart';
import '../../domain/entities/category_type.dart';
import '../providers/category_providers.dart';
import '../widgets/category_card.dart';
import 'category_form.dart';

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  CategoryType? _selectedType;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      title: Text('Categories'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => goToCategoryForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add category'),
      ),
      body: Column(
        children: [
          Container(
            color: colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    icon: Icons.list_rounded,
                    selected: _selectedType == null,
                    onTap: () => setState(() => _selectedType = null),
                  ),
                  ...CategoryType.values.map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _FilterChip(
                        label: t.label,
                        icon: t.icon,
                        selected: _selectedType == t,
                        onTap: () => setState(() => _selectedType = t),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: _CategoryListView(selectedType: _selectedType)),
        ],
      ),
    );
  }
}

class _CategoryListView extends ConsumerWidget {
  const _CategoryListView({required this.selectedType});

  final CategoryType? selectedType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allAsync = ref.watch(categoryProvider);

    return allAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(
              'Failed to load categories',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            SelectableText('$e', style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(categoryProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (all) {
        final filtered = selectedType == null
            ? all
            : all.where((c) => c.type == selectedType).toList();

        if (filtered.isEmpty) {
          return EmptyState(
            icon: selectedType?.icon ?? Icons.label_outline_rounded,
            title: selectedType != null
                ? 'No ${selectedType!.label.toLowerCase()} categories'
                : 'No categories yet',
            subtitle: 'Add a custom category or wait for defaults to load.',
            action: () => goToCategoryForm(context),
            actionLabel: 'Add category',
          );
        }

        final defaults = filtered.where((c) => c.isDefault).toList();
        final custom = filtered.where((c) => !c.isDefault).toList();

        return CustomScrollView(
          slivers: [
            if (custom.isNotEmpty) ...[
              const _SectionHeader(label: 'Custom'),
              SliverList.builder(
                itemCount: custom.length,
                itemBuilder: (_, i) => CategoryCard(category: custom[i]),
              ),
            ],
            if (defaults.isNotEmpty) ...[
              const _SectionHeader(label: 'Default'),
              SliverList.builder(
                itemCount: defaults.length,
                itemBuilder: (_, i) => CategoryCard(category: defaults[i]),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withAlpha(80),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    ),
  );
}
