import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../../core/constants/app_month.dart';

class InsightReport {
  const InsightReport({
    required this.dateFrom,
    required this.dateTo,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netSavings,
    required this.monthlyBars,
    required this.categoryBreakdown,
    required this.transactions,
  });

  final DateTime dateFrom;
  final DateTime dateTo;
  final double totalIncome;
  final double totalExpenses;
  final double netSavings;
  final List<MonthlyBar> monthlyBars;
  final List<CategorySlice> categoryBreakdown;
  final List<TransactionEntity> transactions;

  bool get hasData => totalIncome > 0 || totalExpenses > 0;
}

class MonthlyBar {
  const MonthlyBar({
    required this.year,
    required this.month,
    required this.income,
    required this.expenses,
  });

  final int year;
  final int month;
  final double income;
  final double expenses;

  String get shortLabel => AppMonth.fromNumber(month).shortName;

  String get fullLabel => '$shortLabel $year';
}

class CategorySlice {
  const CategorySlice({
    required this.categoryId,
    required this.amount,
    required this.percentage,
  });

  final String categoryId;

  final double amount;

  final double percentage;
}
