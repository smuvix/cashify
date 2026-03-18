import '../../data/models/transaction_model.dart';
import '../../data/services/transaction_remote_service.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_query.dart';
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
    required double amount,
  }) => _service.commitTransactionWithBalanceUpdate(
    transaction: TransactionModel.fromEntity(transaction),
    accountIdToSubtract: accountIdToSubtract,
    accountIdToAdd: accountIdToAdd,
    amount: amount,
  );

  @override
  Future<void> updateTransaction(TransactionEntity entity) =>
      _service.updateTransaction(TransactionModel.fromEntity(entity));

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
}
