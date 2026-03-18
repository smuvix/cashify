import 'goal_entity.dart';

class GoalProgressEntity {
  const GoalProgressEntity({required this.goal, required this.savedAmount});

  final GoalEntity goal;

  final double savedAmount;

  double get targetAmount => goal.targetAmount;

  double get progress =>
      targetAmount <= 0 ? 0.0 : (savedAmount / targetAmount).clamp(0.0, 1.0);

  double get remainingAmount =>
      (targetAmount - savedAmount).clamp(0.0, double.infinity);

  bool get isReached => savedAmount >= targetAmount;

  @override
  String toString() =>
      'GoalProgressEntity(goal: ${goal.name}, saved: $savedAmount, '
      'target: $targetAmount, progress: ${(progress * 100).toStringAsFixed(1)}%)';
}
