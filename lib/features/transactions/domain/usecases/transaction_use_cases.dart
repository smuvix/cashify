import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_query.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/repositories/transaction_repository.dart';

class WatchTransactionsUseCase {
  const WatchTransactionsUseCase(this._repository);
  final TransactionRepository _repository;

  Stream<List<TransactionEntity>> call(TransactionQuery query) =>
      _repository.watchTransactions(query);
}

class FetchTransactionByIdUseCase {
  const FetchTransactionByIdUseCase(this._repository);
  final TransactionRepository _repository;

  Future<TransactionEntity?> call(String id) =>
      _repository.fetchTransactionById(id);
}

class FetchTransactionsUseCase {
  const FetchTransactionsUseCase(this._repository);
  final TransactionRepository _repository;

  Future<List<TransactionEntity>> call(TransactionQuery query) =>
      _repository.fetchTransactions(query);

  Future<List<TransactionEntity>> byAccount(String accountId) =>
      _repository.fetchTransactions(TransactionQuery(accountId: accountId));

  Future<List<TransactionEntity>> byDateRange(DateTime from, DateTime to) =>
      _repository.fetchTransactions(
        TransactionQuery(dateFrom: from, dateTo: to),
      );

  Future<List<TransactionEntity>> byType(TransactionType type) =>
      _repository.fetchTransactions(TransactionQuery(type: type));

  Future<List<TransactionEntity>> byCategory(String categoryId) =>
      _repository.fetchTransactions(TransactionQuery(categoryId: categoryId));

  Future<List<TransactionEntity>> recent({int limit = 20}) =>
      _repository.fetchTransactions(TransactionQuery(limit: limit));
}

class AdjustAccountBalancesUseCase {
  const AdjustAccountBalancesUseCase(this._repository);
  final TransactionRepository _repository;

  Future<void> call({
    required TransactionEntity transaction,
    double? balanceAmount,
  }) {
    final amount = balanceAmount ?? transaction.amount;
    return switch (transaction.type) {
      TransactionType.income => _repository.commitTransaction(
        transaction: transaction,
        accountIdToSubtract: null,
        accountIdToAdd: transaction.accountId,
        amount: amount,
      ),
      TransactionType.expense => _repository.commitTransaction(
        transaction: transaction,
        accountIdToSubtract: transaction.accountId,
        accountIdToAdd: null,
        amount: amount,
      ),
      TransactionType.transfer => () {
        if (transaction.toAccountId == null) {
          throw ArgumentError(
            'toAccountId must not be null for a transfer transaction.',
          );
        }
        return _repository.commitTransaction(
          transaction: transaction,
          accountIdToSubtract: transaction.accountId,
          accountIdToAdd: transaction.toAccountId!,
          amount: amount,
        );
      }(),
    };
  }
}

class CreateTransactionUseCase {
  const CreateTransactionUseCase(this._adjustBalances);

  final AdjustAccountBalancesUseCase _adjustBalances;

  Future<TransactionEntity> call({
    required TransactionType type,
    required double amount,
    double? tax,
    required String accountId,
    String? toAccountId,
    String? categoryId,
    required DateTime transactionDate,
    String? notes,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('No authenticated user found.');

    if (type == TransactionType.transfer && toAccountId == null) {
      throw ArgumentError('toAccountId is required for transfers.');
    }

    final now = DateTime.now();
    final entity = TransactionEntity(
      id: const Uuid().v4(),
      userId: uid,
      type: type,
      amount: amount,
      tax: type.hasTax ? tax : null,
      accountId: accountId,
      toAccountId: toAccountId,
      categoryId: type == TransactionType.transfer ? null : categoryId,
      transactionDate: transactionDate,
      notes: notes,
      isDeleted: false,
      createdAt: now,
      updatedAt: now,
    );

    final balanceAmount = entity.amount + (entity.tax ?? 0.0);
    await _adjustBalances(transaction: entity, balanceAmount: balanceAmount);
    return entity;
  }
}

class UpdateTransactionUseCase {
  const UpdateTransactionUseCase(this._repository);
  final TransactionRepository _repository;

  Future<TransactionEntity> call(
    TransactionEntity current, {
    String? categoryId,
    DateTime? transactionDate,
    String? notes,
  }) async {
    final updated = current.copyWith(
      categoryId: categoryId,
      transactionDate: transactionDate,
      notes: notes,
      updatedAt: DateTime.now(),
    );
    await _repository.updateTransaction(updated);
    return updated;
  }
}

class DeleteTransactionUseCase {
  const DeleteTransactionUseCase(this._repository);
  final TransactionRepository _repository;

  Future<void> call(TransactionEntity transaction) =>
      _repository.softDeleteTransaction(transaction.id);
}
