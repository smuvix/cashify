import '../../../../core/constants/app_month.dart';
import '../../../../core/utils/cashify_formatter.dart';
import '../../data/services/transaction_pdf_service.dart';
import '../../domain/entities/transaction_query.dart';
import '../../domain/repositories/transaction_repository.dart';

class ExportTransactionsUseCase {
  const ExportTransactionsUseCase(this._repository, this._pdfService);

  final TransactionRepository _repository;
  final TransactionPdfService _pdfService;

  Future<void> call({
    required AppMonth month,
    required int year,
    required CashifyFormatter formatter,
  }) async {
    final dateFrom = DateTime(year, month.number, 1);
    final dateTo = DateTime(
      year,
      month.number + 1,
      1,
    ).subtract(const Duration(milliseconds: 1));

    final transactions = await _repository.fetchTransactions(
      TransactionQuery(dateFrom: dateFrom, dateTo: dateTo),
    );

    if (transactions.isEmpty) {
      throw Exception('No transactions found for ${month.fullName} $year.');
    }

    await _pdfService.exportMonth(
      transactions: transactions,
      month: month,
      year: year,
      formatter: formatter,
    );
  }
}
