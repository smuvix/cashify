import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_month.dart';
import '../../../../core/utils/cashify_formatter_provider.dart';
import '../../../budgets/presentation/widgets/month_picker_dialog.dart';
import '../../presentation/providers/transaction_export_providers.dart';

class TransactionExportButton extends ConsumerStatefulWidget {
  const TransactionExportButton({super.key});

  @override
  ConsumerState<TransactionExportButton> createState() =>
      _TransactionExportButtonState();
}

class _TransactionExportButtonState
    extends ConsumerState<TransactionExportButton> {
  bool _isLoading = false;

  Future<void> _handleExport() async {
    final now = DateTime.now();

    final picked = await showMonthPickerDialog(context, initialMonth: now);
    if (picked == null || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final formatter = ref.read(cashifyFormatterProvider);
      final useCase = ref.read(exportTransactionsUseCaseProvider);

      await useCase(
        month: AppMonth.of(picked),
        year: picked.year,
        formatter: formatter,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppMonth.of(picked).fullName} ${picked.year} exported successfully.',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Export as PDF',
      onPressed: _isLoading ? null : _handleExport,
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.picture_as_pdf_outlined),
    );
  }
}
