import '../entities/budget_entity.dart';

abstract interface class BudgetRepository {
  Stream<List<BudgetEntity>> watchBudgets();

  Future<BudgetEntity?> fetchBudget(String id);

  Future<BudgetEntity?> fetchBudgetForMonth(DateTime month);

  Future<void> createBudget(BudgetEntity entity);

  Future<void> updateBudget(BudgetEntity entity);

  Future<void> deleteBudget(String id);
}
