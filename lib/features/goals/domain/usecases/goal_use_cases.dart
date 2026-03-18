import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../../transactions/domain/entities/transaction_query.dart';
import '../../../transactions/domain/entities/transaction_type.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';
import '../entities/goal_entity.dart';
import '../entities/goal_progress_entity.dart';
import '../repositories/goal_repository.dart';

class WatchGoalsUseCase {
  const WatchGoalsUseCase(this._repository);
  final GoalRepository _repository;

  Stream<List<GoalEntity>> call() => _repository.watchGoals();
}

class FetchGoalByIdUseCase {
  const FetchGoalByIdUseCase(this._repository);
  final GoalRepository _repository;

  Future<GoalEntity?> call(String id) => _repository.fetchGoal(id);
}

class CreateGoalUseCase {
  const CreateGoalUseCase(this._repository);
  final GoalRepository _repository;

  Future<GoalEntity> call({
    required String name,
    required String accountId,
    required double targetAmount,
    required DateTime startDate,
    required DateTime deadline,
    String? notes,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('No authenticated user found.');

    if (targetAmount <= 0) {
      throw ArgumentError('Target amount must be greater than zero.');
    }

    final normalisedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final normalisedDeadline = DateTime(
      deadline.year,
      deadline.month,
      deadline.day,
    );

    if (!normalisedDeadline.isAfter(normalisedStart)) {
      throw ArgumentError('Deadline must be after start date.');
    }

    final existing = await _repository.watchGoals().first;
    final conflict = existing.any(
      (g) => g.accountId == accountId && !g.isCompleted && !g.isDeleted,
    );
    if (conflict) {
      throw ArgumentError(
        'This savings account already has an active goal. '
        'Complete or delete the existing goal before creating a new one.',
      );
    }

    final now = DateTime.now();
    final entity = GoalEntity(
      id: const Uuid().v4(),
      userId: uid,
      name: name.trim(),
      accountId: accountId,
      targetAmount: targetAmount,
      startDate: normalisedStart,
      deadline: normalisedDeadline,
      notes: notes?.trim().isEmpty ?? true ? null : notes!.trim(),
      isCompleted: false,
      isDeleted: false,
      createdAt: now,
      updatedAt: now,
    );

    await _repository.createGoal(entity);
    return entity;
  }
}

class UpdateGoalUseCase {
  const UpdateGoalUseCase(this._repository);
  final GoalRepository _repository;

  Future<GoalEntity> call(
    GoalEntity current, {
    String? name,
    double? targetAmount,
    DateTime? startDate,
    DateTime? deadline,
    String? notes,
    bool? isCompleted,
  }) async {
    if (targetAmount != null && targetAmount <= 0) {
      throw ArgumentError('Target amount must be greater than zero.');
    }

    final normalisedStart = startDate != null
        ? DateTime(startDate.year, startDate.month, startDate.day)
        : null;
    final normalisedDeadline = deadline != null
        ? DateTime(deadline.year, deadline.month, deadline.day)
        : null;

    final effectiveStart = normalisedStart ?? current.startDate;
    final effectiveDeadline = normalisedDeadline ?? current.deadline;

    if (!effectiveDeadline.isAfter(effectiveStart)) {
      throw ArgumentError('Deadline must be after start date.');
    }

    final updated = current.copyWith(
      name: name,
      targetAmount: targetAmount,
      startDate: normalisedStart,
      deadline: normalisedDeadline,
      notes: notes,
      isCompleted: isCompleted,
      updatedAt: DateTime.now(),
    );

    await _repository.updateGoal(updated);
    return updated;
  }
}

class DeleteGoalUseCase {
  const DeleteGoalUseCase(this._repository);
  final GoalRepository _repository;

  Future<void> call(String id) => _repository.deleteGoal(id);
}

class CalculateGoalProgressUseCase {
  const CalculateGoalProgressUseCase(this._transactionRepository);
  final TransactionRepository _transactionRepository;

  Future<GoalProgressEntity> call(GoalEntity goal) async {
    final transactions = await _transactionRepository.fetchTransactions(
      TransactionQuery(
        accountId: goal.accountId,
        dateFrom: goal.periodStart,
        dateTo: goal.periodEnd,
      ),
    );

    double savedAmount = 0.0;

    for (final tx in transactions) {
      if (tx.type == TransactionType.income && tx.accountId == goal.accountId) {
        savedAmount += tx.amount;
      } else if (tx.type == TransactionType.transfer &&
          tx.toAccountId == goal.accountId) {
        savedAmount += tx.amount;
      }
    }

    return GoalProgressEntity(goal: goal, savedAmount: savedAmount);
  }

  Future<List<GoalProgressEntity>> forAll(List<GoalEntity> goals) =>
      Future.wait(goals.map(call));
}
