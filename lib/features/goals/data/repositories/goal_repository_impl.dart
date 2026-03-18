import '../../data/models/goal_model.dart';
import '../../data/services/goal_remote_service.dart';
import '../../domain/entities/goal_entity.dart';
import '../../domain/repositories/goal_repository.dart';

class GoalRepositoryImpl implements GoalRepository {
  const GoalRepositoryImpl(this._service);

  final GoalRemoteService _service;

  @override
  Stream<List<GoalEntity>> watchGoals() => _service.watchGoals();

  @override
  Future<GoalEntity?> fetchGoal(String id) => _service.fetchGoal(id);

  @override
  Future<void> createGoal(GoalEntity entity) =>
      _service.createGoal(GoalModel.fromEntity(entity));

  @override
  Future<void> updateGoal(GoalEntity entity) =>
      _service.updateGoal(GoalModel.fromEntity(entity));

  @override
  Future<void> deleteGoal(String id) => _service.softDeleteGoal(id);
}
