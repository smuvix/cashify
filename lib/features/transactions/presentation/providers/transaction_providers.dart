import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/transaction_repository_impl.dart';
import '../../data/services/transaction_remote_service.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_query.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/usecases/transaction_use_cases.dart';
import '../controllers/transaction_controller.dart';

final transactionRemoteServiceProvider = Provider<TransactionRemoteService>(
  (_) => TransactionRemoteServiceImpl(),
);

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) =>
      TransactionRepositoryImpl(ref.read(transactionRemoteServiceProvider)),
);

final watchTransactionsUseCaseProvider = Provider<WatchTransactionsUseCase>(
  (ref) => WatchTransactionsUseCase(ref.read(transactionRepositoryProvider)),
);

final fetchTransactionByIdUseCaseProvider =
    Provider<FetchTransactionByIdUseCase>(
      (ref) =>
          FetchTransactionByIdUseCase(ref.read(transactionRepositoryProvider)),
    );

final fetchTransactionsUseCaseProvider = Provider<FetchTransactionsUseCase>(
  (ref) => FetchTransactionsUseCase(ref.read(transactionRepositoryProvider)),
);

final adjustAccountBalancesUseCaseProvider =
    Provider<AdjustAccountBalancesUseCase>(
      (ref) =>
          AdjustAccountBalancesUseCase(ref.read(transactionRepositoryProvider)),
    );

final createTransactionUseCaseProvider = Provider<CreateTransactionUseCase>(
  (ref) =>
      CreateTransactionUseCase(ref.read(adjustAccountBalancesUseCaseProvider)),
);

final updateTransactionUseCaseProvider = Provider<UpdateTransactionUseCase>(
  (ref) => UpdateTransactionUseCase(ref.read(transactionRepositoryProvider)),
);

final deleteTransactionUseCaseProvider = Provider<DeleteTransactionUseCase>(
  (ref) => DeleteTransactionUseCase(ref.read(transactionRepositoryProvider)),
);

final transactionProvider =
    AsyncNotifierProvider.family<
      TransactionController,
      List<TransactionEntity>,
      TransactionQuery
    >((query) => TransactionController(query));

final recentTransactionsProvider =
    Provider<AsyncValue<List<TransactionEntity>>>(
      (ref) =>
          ref.watch(transactionProvider(const TransactionQuery(limit: 30))),
    );

final incomeTransactionsProvider =
    Provider<AsyncValue<List<TransactionEntity>>>(
      (ref) => ref.watch(
        transactionProvider(
          const TransactionQuery(type: TransactionType.income),
        ),
      ),
    );

final expenseTransactionsProvider =
    Provider<AsyncValue<List<TransactionEntity>>>(
      (ref) => ref.watch(
        transactionProvider(
          const TransactionQuery(type: TransactionType.expense),
        ),
      ),
    );

final transferTransactionsProvider =
    Provider<AsyncValue<List<TransactionEntity>>>(
      (ref) => ref.watch(
        transactionProvider(
          const TransactionQuery(type: TransactionType.transfer),
        ),
      ),
    );

final transactionsByAccountProvider =
    Provider.family<AsyncValue<List<TransactionEntity>>, String>(
      (ref, accountId) => ref.watch(
        transactionProvider(TransactionQuery(accountId: accountId)),
      ),
    );
