import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../domain/entities/budget_progress_entity.dart';
import '../../domain/usecases/budget_use_cases.dart';
import '../providers/budget_providers.dart';

class BudgetProgressController
    extends AsyncNotifier<Map<String, BudgetProgressEntity>> {
  late CalculateBudgetProgressUseCase _calculate;

  @override
  Future<Map<String, BudgetProgressEntity>> build() async {
    _calculate = ref.read(calculateBudgetProgressUseCaseProvider);

    final budgets = await ref.watch(budgetProvider.future);
    ref.watch(expenseTransactionsProvider);

    final results = await Future.wait(budgets.map(_calculate.call));

    return {for (final p in results) p.budget.id: p};
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> refreshOne(String budgetId) async {
    final Map<String, BudgetProgressEntity>? current = state.when(
      data: (map) => map,
      loading: () => null,
      error: (_, _) => null,
    );

    if (current == null) return refresh();

    final budgets = await ref.read(budgetProvider.future);
    final budget = budgets.where((b) => b.id == budgetId).firstOrNull;
    if (budget == null) return;

    final updated = await _calculate(budget);
    state = AsyncData(Map.of(current)..[budgetId] = updated);
  }
}
