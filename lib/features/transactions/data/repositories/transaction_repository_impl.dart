import '../../data/models/transaction_model.dart';
import '../../data/services/transaction_remote_service.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_query.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  const TransactionRepositoryImpl(this._service);

  final TransactionRemoteService _service;

  @override
  Stream<List<TransactionEntity>> watchTransactions(TransactionQuery query) =>
      _service.watchTransactions(query);

  @override
  Future<TransactionEntity?> fetchTransactionById(String id) =>
      _service.fetchTransaction(id);

  @override
  Future<List<TransactionEntity>> fetchTransactions(TransactionQuery query) =>
      _service.fetchTransactions(query);

  @override
  Future<void> commitTransaction({
    required TransactionEntity transaction,
    String? accountIdToSubtract,
    String? accountIdToAdd,
    required double subtractAmount,
    required double addAmount,
  }) => _service.commitTransactionWithBalanceUpdate(
    transaction: TransactionModel.fromEntity(transaction),
    accountIdToSubtract: accountIdToSubtract,
    accountIdToAdd: accountIdToAdd,
    subtractAmount: subtractAmount,
    addAmount: addAmount,
  );

  @override
  Future<void> updateTransaction(TransactionEntity entity) =>
      _service.updateTransaction(TransactionModel.fromEntity(entity));

  @override
  Future<void> updateTransactionWithBalanceCorrection({
    required TransactionEntity oldTransaction,
    required TransactionEntity newTransaction,
  }) {
    final (oldSubtract, oldAdd, oldSubId, oldAddId) = _balanceSides(
      oldTransaction,
    );

    final (newSubtract, newAdd, newSubId, newAddId) = _balanceSides(
      newTransaction,
    );

    return _service.correctTransactionWithBalanceUpdate(
      newTransaction: TransactionModel.fromEntity(newTransaction),
      reverseAccountIdToSubtract: oldAddId,
      reverseAccountIdToAdd: oldSubId,
      reverseSubtractAmount: oldAdd,
      reverseAddAmount: oldSubtract,
      forwardAccountIdToSubtract: newSubId,
      forwardAccountIdToAdd: newAddId,
      forwardSubtractAmount: newSubtract,
      forwardAddAmount: newAdd,
    );
  }

  @override
  Future<void> softDeleteTransaction(String id) =>
      _service.softDeleteTransaction(id);

  @override
  Future<void> deleteTransaction({
    required TransactionEntity transaction,
    String? accountIdToSubtract,
    required String accountIdToAdd,
    required double amount,
  }) => _service.reverseTransactionWithBalanceUpdate(
    transaction: TransactionModel.fromEntity(transaction),
    accountIdToSubtract: accountIdToSubtract,
    accountIdToAdd: accountIdToAdd,
    amount: amount,
  );

  (double, double, String?, String?) _balanceSides(TransactionEntity t) {
    final tax = t.tax ?? 0.0;
    return switch (t.type) {
      TransactionType.income => (0.0, t.amount, null, t.accountId),
      TransactionType.expense => (t.amount + tax, 0.0, t.accountId, null),
      TransactionType.transfer => (
        t.amount + tax,
        t.amount,
        t.accountId,
        t.toAccountId,
      ),
    };
  }
}
