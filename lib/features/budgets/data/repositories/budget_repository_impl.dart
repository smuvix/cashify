import '../../data/models/budget_model.dart';
import '../../data/services/budget_remote_service.dart';
import '../../domain/entities/budget_entity.dart';
import '../../domain/repositories/budget_repository.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  const BudgetRepositoryImpl(this._service);

  final BudgetRemoteService _service;

  @override
  Stream<List<BudgetEntity>> watchBudgets() => _service.watchBudgets();

  @override
  Future<BudgetEntity?> fetchBudget(String id) => _service.fetchBudget(id);

  @override
  Future<BudgetEntity?> fetchBudgetForMonth(DateTime month) =>
      _service.fetchBudgetForMonth(month);

  @override
  Future<void> createBudget(BudgetEntity entity) =>
      _service.createBudget(BudgetModel.fromEntity(entity));

  @override
  Future<void> updateBudget(BudgetEntity entity) =>
      _service.updateBudget(BudgetModel.fromEntity(entity));

  @override
  Future<void> deleteBudget(String id) => _service.softDeleteBudget(id);
}
