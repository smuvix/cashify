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

  final Set<String> _pendingDeleteIds = {};
  Timer? _commitTimer;

  @override
  Future<List<BudgetEntity>> build() async {
    _watch = ref.read(watchBudgetsUseCaseProvider);
    _create = ref.read(createBudgetUseCaseProvider);
    _update = ref.read(updateBudgetUseCaseProvider);
    _delete = ref.read(deleteBudgetUseCaseProvider);

    ref.onDispose(() => _commitTimer?.cancel());

    final completer = Completer<List<BudgetEntity>>();
    final sub = _watch().listen(
      (budgets) {
        final filtered = _pendingDeleteIds.isEmpty
            ? budgets
            : budgets.where((b) => !_pendingDeleteIds.contains(b.id)).toList();
        if (!completer.isCompleted) completer.complete(filtered);
        state = AsyncData(filtered);
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

  Future<void> Function() deleteBudgetWithUndo(
    BudgetEntity budget, {
    Duration undoWindow = const Duration(seconds: 4),
    void Function()? onCommitted,
  }) {
    _pendingDeleteIds.add(budget.id);
    final current = state.value ?? [];
    state = AsyncData(current.where((b) => b.id != budget.id).toList());

    _commitTimer?.cancel();
    var cancelled = false;

    _commitTimer = Timer(undoWindow, () async {
      if (cancelled) return;
      onCommitted?.call();
      _pendingDeleteIds.remove(budget.id);
      try {
        await _delete(budget.id);
      } catch (e, st) {
        _pendingDeleteIds.remove(budget.id);
        state = AsyncError(e, st);
      }
    });

    return () async {
      cancelled = true;
      _commitTimer?.cancel();
      _pendingDeleteIds.remove(budget.id);
      final restored = List<BudgetEntity>.from(state.value ?? []);
      final insertIdx = restored.indexWhere(
        (b) => b.month.isBefore(budget.month),
      );
      if (insertIdx == -1) {
        restored.add(budget);
      } else {
        restored.insert(insertIdx, budget);
      }
      state = AsyncData(restored);
    };
  }
}
