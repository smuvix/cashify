import '../entities/goal_entity.dart';

abstract interface class GoalRepository {
  Stream<List<GoalEntity>> watchGoals();

  Future<GoalEntity?> fetchGoal(String id);

  Future<void> createGoal(GoalEntity entity);

  Future<void> updateGoal(GoalEntity entity);

  Future<void> deleteGoal(String id);
}
