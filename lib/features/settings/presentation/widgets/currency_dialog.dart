import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/widgets/reusable_dialog.dart';
import '../../../../core/constants/currencies.dart';
import '../providers/user_settings_providers.dart';

void showCurrencyDialog(BuildContext context, WidgetRef ref, String current) {
  showDialog<void>(
    context: context,
    builder: (_) => ReusableDialog<String>(
      title: 'Currency',
      initialValue: current,
      confirmText: 'Apply',
      onConfirm: (selected) async {
        await ref.read(userSettingsProvider.notifier).setCurrency(selected);
        return true;
      },
      builder: (context, selected, onChanged) =>
          _CurrencyPickerContent(selected: selected, onChanged: onChanged),
    ),
  );
}

class _CurrencyPickerContent extends StatefulWidget {
  const _CurrencyPickerContent({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final void Function(String) onChanged;

  @override
  State<_CurrencyPickerContent> createState() => _CurrencyPickerContentState();
}

class _CurrencyPickerContentState extends State<_CurrencyPickerContent> {
  final _searchController = TextEditingController();
  String _query = '';

  static final _allEntries = kCurrencies.entries.toList()
    ..sort((a, b) => a.value.name.compareTo(b.value.name));

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MapEntry<String, ({String name, String symbol})>> get _filtered {
    if (_query.isEmpty) return _allEntries;
    final q = _query.toLowerCase();
    return _allEntries.where((e) {
      return e.key.toLowerCase().contains(q) ||
          e.value.name.toLowerCase().contains(q) ||
          e.value.symbol.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filtered = _filtered;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: false,
            decoration: InputDecoration(
              hintText: 'Search currency or code…',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
        ),

        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 340),
          child: filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No currencies match "$_query"',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final entry = filtered[i];
                    final code = entry.key;
                    final info = entry.value;
                    final isSelected = code == widget.selected;

                    return InkWell(
                      onTap: () => widget.onChanged(code),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withAlpha(
                                  isSelected ? 60 : 30,
                                ),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Center(
                                child: Text(
                                  info.symbol,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.primary,
                                  ),
                                  overflow: TextOverflow.clip,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    info.name,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.onSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    code,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isSelected
                                          ? colorScheme.onPrimaryContainer
                                                .withAlpha(180)
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
                    );
                  },
                ),
        ),
      ],
    );
  }
}
