import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../domain/entities/goal_progress_entity.dart';
import '../../domain/usecases/goal_use_cases.dart';
import '../providers/goal_providers.dart';

class GoalProgressController
    extends AsyncNotifier<Map<String, GoalProgressEntity>> {
  late CalculateGoalProgressUseCase _calculate;
  late UpdateGoalUseCase _update;

  @override
  Future<Map<String, GoalProgressEntity>> build() async {
    _calculate = ref.read(calculateGoalProgressUseCaseProvider);
    _update = ref.read(updateGoalUseCaseProvider);

    final goals = await ref.watch(goalProvider.future);

    ref.watch(incomeTransactionsProvider);
    ref.watch(transferTransactionsProvider);

    final results = await Future.wait(goals.map(_calculate.call));

    for (final p in results) {
      if (p.isReached && !p.goal.isCompleted) {
        _update(p.goal, isCompleted: true).ignore();
      }
    }

    return {for (final p in results) p.goal.id: p};
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> refreshOne(String goalId) async {
    final Map<String, GoalProgressEntity>? current = state.when(
      data: (map) => map,
      loading: () => null,
      error: (_, _) => null,
    );

    if (current == null) return refresh();

    final goals = await ref.read(goalProvider.future);
    final goal = goals.where((g) => g.id == goalId).firstOrNull;
    if (goal == null) return;

    final updated = await _calculate(goal);

    if (updated.isReached && !updated.goal.isCompleted) {
      _update(updated.goal, isCompleted: true).ignore();
    }

    state = AsyncData(Map.of(current)..[goalId] = updated);
  }
}
