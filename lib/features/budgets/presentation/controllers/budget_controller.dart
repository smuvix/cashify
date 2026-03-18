import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/budget_entity.dart';
import '../../domain/usecases/budget_use_cases.dart';
import '../providers/budget_providers.dart';

class BudgetController extends AsyncNotifier<List<BudgetEntity>> {
  late WatchBudgetsUseCase _watch;
  late CreateBudgetUseCase _create;
  late UpdateBudgetUseCase _update;
  late DeleteBudgetUseCase _delete;

  @override
  Future<List<BudgetEntity>> build() async {
    _watch = ref.read(watchBudgetsUseCaseProvider);
    _create = ref.read(createBudgetUseCaseProvider);
    _update = ref.read(updateBudgetUseCaseProvider);
    _delete = ref.read(deleteBudgetUseCaseProvider);

    final completer = Completer<List<BudgetEntity>>();
    final sub = _watch().listen(
      (budgets) {
        if (!completer.isCompleted) completer.complete(budgets);
        state = AsyncData(budgets);
      },
      onError: (Object e, StackTrace st) {
        if (!completer.isCompleted) completer.completeError(e, st);
        state = AsyncError(e, st);
      },
    );
    ref.onDispose(sub.cancel);

    return completer.future;
  }

  Future<BudgetEntity> createBudget({
    required String name,
    required DateTime month,
    required Map<String, double> categoryAllocations,
  }) => _create(
    name: name,
    month: month,
    categoryAllocations: categoryAllocations,
  );

  Future<BudgetEntity> updateBudget(
    BudgetEntity current, {
    String? name,
    Map<String, double>? categoryAllocations,
  }) => _update(current, name: name, categoryAllocations: categoryAllocations);

  Future<void> deleteBudget(String id) async {
    await _delete(id);
    ref.invalidate(budgetProgressProvider);
  }
}
