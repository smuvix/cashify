import '../../../../core/constants/app_month.dart';
import '../../../../core/services/pdf_export.dart';
import '../../../../core/utils/cashify_formatter.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionPdfService {
  const TransactionPdfService();

  Future<void> exportMonth({
    required List<TransactionEntity> transactions,
    required List<CategoryEntity> categories,
    required AppMonth month,
    required int year,
    required CashifyFormatter formatter,
  }) async {
    final title = '${month.fullName} $year Expenses'.toUpperCase();

    final sorted = [...transactions]
      ..sort((a, b) => a.transactionDate.compareTo(b.transactionDate));

    final categoryMap = {for (final c in categories) c.id: c.name};

    final data = sorted.map((t) => _toRow(t, categoryMap, formatter)).toList();

    await PdfExportService.export(title: title, data: data);
  }

  Map<String, dynamic> _toRow(
    TransactionEntity t,
    Map<String, String> categoryMap,
    CashifyFormatter formatter,
  ) {
    final categoryName = categoryMap[t.categoryId] ?? 'Category deleted';
    final notes = (t.notes != null && t.notes!.isNotEmpty)
        ? t.notes!
        : '— no notes —';

    return {
      'Date': formatter.date(t.transactionDate),
      'Category': categoryName,
      'Notes': notes,
      'Amount': t.amount + (t.tax ?? 0),
    };
  }
}
