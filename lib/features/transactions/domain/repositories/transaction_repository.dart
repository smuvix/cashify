import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_query.dart';

abstract interface class TransactionRepository {
  Stream<List<TransactionEntity>> watchTransactions(TransactionQuery query);

  Future<TransactionEntity?> fetchTransactionById(String id);

  Future<List<TransactionEntity>> fetchTransactions(TransactionQuery query);

  Future<void> commitTransaction({
    required TransactionEntity transaction,
    String? accountIdToSubtract,
    String? accountIdToAdd,
    required double subtractAmount,
    required double addAmount,
  });

  Future<void> updateTransaction(TransactionEntity entity);

  Future<void> updateTransactionWithBalanceCorrection({
    required TransactionEntity oldTransaction,
    required TransactionEntity newTransaction,
  });

  Future<void> softDeleteTransaction(String id);

  Future<void> deleteTransaction({
    required TransactionEntity transaction,
    String? accountIdToSubtract,
    required String accountIdToAdd,
    required double amount,
  });
}
