import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../../transactions/domain/entities/transaction_query.dart';
import '../../../transactions/domain/entities/transaction_type.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';
import '../entities/budget_entity.dart';
import '../entities/budget_progress_entity.dart';
import '../repositories/budget_repository.dart';

class WatchBudgetsUseCase {
  const WatchBudgetsUseCase(this._repository);
  final BudgetRepository _repository;

  Stream<List<BudgetEntity>> call() => _repository.watchBudgets();
}

class FetchBudgetByIdUseCase {
  const FetchBudgetByIdUseCase(this._repository);
  final BudgetRepository _repository;

  Future<BudgetEntity?> call(String id) => _repository.fetchBudget(id);
}

class FetchBudgetForMonthUseCase {
  const FetchBudgetForMonthUseCase(this._repository);
  final BudgetRepository _repository;

  Future<BudgetEntity?> call(DateTime month) =>
      _repository.fetchBudgetForMonth(month);
}

class CreateBudgetUseCase {
  const CreateBudgetUseCase(this._repository);
  final BudgetRepository _repository;

  Future<BudgetEntity> call({
    required String name,
    required DateTime month,
    required Map<String, double> categoryAllocations,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('No authenticated user found.');

    if (categoryAllocations.isEmpty) {
      throw ArgumentError('A budget must have at least one category.');
    }
    if (categoryAllocations.values.any((v) => v <= 0)) {
      throw ArgumentError('All category amounts must be greater than zero.');
    }

    final now = DateTime.now();
    final normalisedMonth = DateTime(month.year, month.month, 1);

    final entity = BudgetEntity(
      id: const Uuid().v4(),
      userId: uid,
      name: name.trim(),
      month: normalisedMonth,
      categoryAllocations: Map.unmodifiable(categoryAllocations),
      isDeleted: false,
      createdAt: now,
      updatedAt: now,
    );

    await _repository.createBudget(entity);
    return entity;
  }
}

class UpdateBudgetUseCase {
  const UpdateBudgetUseCase(this._repository);
  final BudgetRepository _repository;

  Future<BudgetEntity> call(
    BudgetEntity current, {
    String? name,
    Map<String, double>? categoryAllocations,
  }) async {
    if (categoryAllocations != null) {
      if (categoryAllocations.isEmpty) {
        throw ArgumentError('A budget must have at least one category.');
      }
      if (categoryAllocations.values.any((v) => v <= 0)) {
        throw ArgumentError('All category amounts must be greater than zero.');
      }
    }

    final updated = current.copyWith(
      name: name,
      categoryAllocations: categoryAllocations,
      updatedAt: DateTime.now(),
    );
    await _repository.updateBudget(updated);
    return updated;
  }
}

class DeleteBudgetUseCase {
  const DeleteBudgetUseCase(this._repository);
  final BudgetRepository _repository;

  Future<void> call(String id) => _repository.deleteBudget(id);
}

class CalculateBudgetProgressUseCase {
  const CalculateBudgetProgressUseCase(this._transactionRepository);
  final TransactionRepository _transactionRepository;

  Future<BudgetProgressEntity> call(BudgetEntity budget) async {
    final transactions = await _transactionRepository.fetchTransactions(
      TransactionQuery(
        type: TransactionType.expense,
        dateFrom: budget.periodStart,
        dateTo: budget.periodEnd,
      ),
    );

    final spentByCategory = <String, double>{};
    for (final tx in transactions) {
      final categoryId = tx.categoryId;
      if (categoryId == null) continue;
      if (!budget.categoryAllocations.containsKey(categoryId)) continue;
      spentByCategory[categoryId] =
          (spentByCategory[categoryId] ?? 0.0) + tx.totalAmount;
    }

    return BudgetProgressEntity(
      budget: budget,
      spentByCategory: spentByCategory,
    );
  }

  Future<List<BudgetProgressEntity>> forAll(List<BudgetEntity> budgets) =>
      Future.wait(budgets.map(call));
}
