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
    required double amount,
  });

  Future<void> updateTransaction(TransactionEntity entity);

  Future<void> softDeleteTransaction(String id);

  Future<void> deleteTransaction({
    required TransactionEntity transaction,
    String? accountIdToSubtract,
    required String accountIdToAdd,
    required double amount,
  });
}
