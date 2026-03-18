import '../../../transactions/domain/entities/transaction_query.dart';
import '../../../transactions/domain/entities/transaction_type.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';
import '../entities/insight_report.dart';

class ComputeInsightReportUseCase {
  const ComputeInsightReportUseCase(this._repository);

  final TransactionRepository _repository;

  Future<InsightReport> call({
    required DateTime dateFrom,
    required DateTime dateTo,
  }) async {
    final results = await Future.wait([
      _repository.fetchTransactions(
        TransactionQuery(
          type: TransactionType.income,
          dateFrom: dateFrom,
          dateTo: dateTo,
        ),
      ),
      _repository.fetchTransactions(
        TransactionQuery(
          type: TransactionType.expense,
          dateFrom: dateFrom,
          dateTo: dateTo,
        ),
      ),
    ]);

    final incomeList = results[0];
    final expenseList = results[1];

    final totalIncome = incomeList.fold(0.0, (sum, tx) => sum + tx.amount);
    final totalExpenses = expenseList.fold(
      0.0,
      (sum, tx) => sum + tx.totalAmount,
    );

    final monthKeys = <(int, int)>[];
    var cursor = DateTime(dateFrom.year, dateFrom.month, 1);
    final loopEnd = DateTime(dateTo.year, dateTo.month, 1);
    while (!cursor.isAfter(loopEnd)) {
      monthKeys.add((cursor.year, cursor.month));
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }

    final incomeByMonth = <(int, int), double>{};
    final expensesByMonth = <(int, int), double>{};

    for (final tx in incomeList) {
      final key = (tx.transactionDate.year, tx.transactionDate.month);
      incomeByMonth[key] = (incomeByMonth[key] ?? 0.0) + tx.amount;
    }
    for (final tx in expenseList) {
      final key = (tx.transactionDate.year, tx.transactionDate.month);
      expensesByMonth[key] = (expensesByMonth[key] ?? 0.0) + tx.totalAmount;
    }

    final monthlyBars = monthKeys
        .map(
          (k) => MonthlyBar(
            year: k.$1,
            month: k.$2,
            income: incomeByMonth[k] ?? 0.0,
            expenses: expensesByMonth[k] ?? 0.0,
          ),
        )
        .toList();

    final categoryTotals = <String, double>{};
    for (final tx in expenseList) {
      final categoryId = tx.categoryId ?? 'unknown';
      categoryTotals[categoryId] =
          (categoryTotals[categoryId] ?? 0.0) + tx.totalAmount;
    }

    final categoryBreakdown =
        categoryTotals.entries
            .map(
              (e) => CategorySlice(
                categoryId: e.key,
                amount: e.value,
                percentage: totalExpenses > 0 ? e.value / totalExpenses : 0.0,
              ),
            )
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    return InsightReport(
      dateFrom: dateFrom,
      dateTo: dateTo,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netSavings: totalIncome - totalExpenses,
      monthlyBars: monthlyBars,
      categoryBreakdown: categoryBreakdown,
      transactions: [...incomeList, ...expenseList],
    );
  }
}
