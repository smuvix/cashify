import '../../../../core/constants/app_month.dart';
import '../../../../core/utils/cashify_formatter.dart';
import '../../../categories/domain/repositories/category_repository.dart';
import '../../data/services/transaction_pdf_service.dart';
import '../../domain/entities/transaction_query.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/repositories/transaction_repository.dart';

class ExportTransactionsUseCase {
  const ExportTransactionsUseCase(
    this._repository,
    this._categoryRepository,
    this._pdfService,
  );

  final TransactionRepository _repository;
  final CategoryRepository _categoryRepository;
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

    final allTransactions = await _repository.fetchTransactions(
      TransactionQuery(dateFrom: dateFrom, dateTo: dateTo),
    );

    final transactions = allTransactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    if (transactions.isEmpty) {
      throw Exception(
        'No expense transactions found for ${month.fullName} $year.',
      );
    }

    final categories = await _categoryRepository.watchCategories().first;

    await _pdfService.exportMonth(
      transactions: transactions,
      categories: categories,
      month: month,
      year: year,
      formatter: formatter,
    );
  }
}
