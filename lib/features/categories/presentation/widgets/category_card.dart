import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/widgets/swipeable_card.dart';
import '../../domain/entities/category_entity.dart';
import '../providers/category_providers.dart';
import '../pages/category_form.dart';

class CategoryCard extends ConsumerWidget {
  const CategoryCard({super.key, required this.category});

  final CategoryEntity category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (category.isDefault) {
      return _CategoryCardContent(category: category);
    }

    return SwipeableCard(
      deleteTitle: 'Delete category?',
      deleteItemName: category.name,
      skipConfirmDialog: true,
      onEdit: () => goToCategoryForm(context, category: category),
      onDelete: () async {
        final notifier = ref.read(categoryProvider.notifier);

        ScaffoldMessenger.of(context).clearSnackBars();
        final snackbarController = ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${category.name} deleted'),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(label: 'Undo', onPressed: () {}),
          ),
        );

        final undo = notifier.deleteCategoryWithUndo(
          category,
          onCommitted: snackbarController.close,
        );

        snackbarController.closed.then((reason) {
          if (reason == SnackBarClosedReason.action) undo();
        });

        return true;
      },
      child: _CategoryCardContent(category: category),
    );
  }
}

class _CategoryCardContent extends ConsumerWidget {
  const _CategoryCardContent({required this.category});

  final CategoryEntity category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: category.isDefault
              ? null
              : () => goToCategoryForm(context, category: category),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: category.color.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: category.color.withAlpha(60)),
                  ),
                  child: Icon(category.icon, color: category.color, size: 20),
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (category.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          category.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                if (category.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withAlpha(80),
                      ),
                    ),
                    child: Text(
                      'Default',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
