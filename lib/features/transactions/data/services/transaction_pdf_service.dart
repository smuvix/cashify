import 'package:cashify/features/transactions/domain/entities/transaction_type.dart';

import '../../../../core/constants/app_month.dart';
import '../../../../core/services/pdf_export.dart';
import '../../../../core/utils/cashify_formatter.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionPdfService {
  const TransactionPdfService();

  Future<void> exportMonth({
    required List<TransactionEntity> transactions,
    required AppMonth month,
    required int year,
    required CashifyFormatter formatter,
  }) async {
    final title = '${month.fullName} Transactions';
    final data = transactions.map((t) => _toRow(t, formatter)).toList();
    await PdfExportService.export(title: title, data: data);
  }

  Map<String, dynamic> _toRow(TransactionEntity t, CashifyFormatter formatter) {
    return {
      'Date': formatter.date(t.transactionDate),
      'Type': t.type.label,
      'Amount': t.type == TransactionType.transfer
          ? t.amount
          : t.amount + (t.tax ?? 0),
      'Notes': t.notes ?? '',
    };
  }
}
