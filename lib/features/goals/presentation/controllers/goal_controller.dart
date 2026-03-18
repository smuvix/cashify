import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/goal_entity.dart';
import '../../domain/usecases/goal_use_cases.dart';
import '../providers/goal_providers.dart';

class GoalController extends AsyncNotifier<List<GoalEntity>> {
  late WatchGoalsUseCase _watch;
  late CreateGoalUseCase _create;
  late UpdateGoalUseCase _update;
  late DeleteGoalUseCase _delete;

  @override
  Future<List<GoalEntity>> build() async {
    _watch = ref.read(watchGoalsUseCaseProvider);
    _create = ref.read(createGoalUseCaseProvider);
    _update = ref.read(updateGoalUseCaseProvider);
    _delete = ref.read(deleteGoalUseCaseProvider);

    final completer = Completer<List<GoalEntity>>();
    final sub = _watch().listen(
      (goals) {
        if (!completer.isCompleted) completer.complete(goals);
        state = AsyncData(goals);
      },
      onError: (Object e, StackTrace st) {
        if (!completer.isCompleted) completer.completeError(e, st);
        state = AsyncError(e, st);
      },
    );
    ref.onDispose(sub.cancel);

    return completer.future;
  }

  Future<GoalEntity> createGoal({
    required String name,
    required String accountId,
    required double targetAmount,
    required DateTime startDate,
    required DateTime deadline,
    String? notes,
  }) => _create(
    name: name,
    accountId: accountId,
    targetAmount: targetAmount,
    startDate: startDate,
    deadline: deadline,
    notes: notes,
  );

  Future<GoalEntity> updateGoal(
    GoalEntity current, {
    String? name,
    double? targetAmount,
    DateTime? startDate,
    DateTime? deadline,
    String? notes,
    bool? isCompleted,
  }) => _update(
    current,
    name: name,
    targetAmount: targetAmount,
    startDate: startDate,
    deadline: deadline,
    notes: notes,
    isCompleted: isCompleted,
  );

  Future<void> deleteGoal(String id) async {
    await _delete(id);
    ref.invalidate(goalProgressProvider);
  }

  Future<void> markCompleted(GoalEntity goal) =>
      updateGoal(goal, isCompleted: true);

  Future<void> markIncomplete(GoalEntity goal) =>
      updateGoal(goal, isCompleted: false);
}
