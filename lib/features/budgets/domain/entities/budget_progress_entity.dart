import 'budget_entity.dart';

class BudgetProgressEntity {
  const BudgetProgressEntity({
    required this.budget,
    required this.spentByCategory,
  });

  final BudgetEntity budget;

  final Map<String, double> spentByCategory;

  double get totalSpent => budget.categoryAllocations.keys.fold(
    0.0,
    (sum, id) => sum + (spentByCategory[id] ?? 0.0),
  );

  double get totalBudgeted => budget.totalBudgeted;

  double get overallProgress =>
      totalBudgeted <= 0 ? 0.0 : (totalSpent / totalBudgeted).clamp(0.0, 1.0);

  double spentFor(String categoryId) => spentByCategory[categoryId] ?? 0.0;

  double budgetedFor(String categoryId) =>
      budget.categoryAllocations[categoryId] ?? 0.0;

  double progressFor(String categoryId) {
    final budgeted = budgetedFor(categoryId);
    if (budgeted <= 0) return 0.0;
    return (spentFor(categoryId) / budgeted).clamp(0.0, 1.0);
  }

  bool isOverBudget(String categoryId) =>
      spentFor(categoryId) > budgetedFor(categoryId);

  bool get isOverallOverBudget => totalSpent > totalBudgeted;
}
