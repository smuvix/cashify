import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../data/services/budget_remote_service.dart';
import '../../domain/entities/budget_entity.dart';
import '../../domain/entities/budget_progress_entity.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/usecases/budget_use_cases.dart';
import '../controllers/budget_controller.dart';
import '../controllers/budget_progress_controller.dart';

final budgetRemoteServiceProvider = Provider<BudgetRemoteService>(
  (_) => BudgetRemoteServiceImpl(),
);

final budgetRepositoryProvider = Provider<BudgetRepository>(
  (ref) => BudgetRepositoryImpl(ref.read(budgetRemoteServiceProvider)),
);

final watchBudgetsUseCaseProvider = Provider<WatchBudgetsUseCase>(
  (ref) => WatchBudgetsUseCase(ref.read(budgetRepositoryProvider)),
);

final fetchBudgetByIdUseCaseProvider = Provider<FetchBudgetByIdUseCase>(
  (ref) => FetchBudgetByIdUseCase(ref.read(budgetRepositoryProvider)),
);

final fetchBudgetForMonthUseCaseProvider = Provider<FetchBudgetForMonthUseCase>(
  (ref) => FetchBudgetForMonthUseCase(ref.read(budgetRepositoryProvider)),
);

final createBudgetUseCaseProvider = Provider<CreateBudgetUseCase>(
  (ref) => CreateBudgetUseCase(ref.read(budgetRepositoryProvider)),
);

final updateBudgetUseCaseProvider = Provider<UpdateBudgetUseCase>(
  (ref) => UpdateBudgetUseCase(ref.read(budgetRepositoryProvider)),
);

final deleteBudgetUseCaseProvider = Provider<DeleteBudgetUseCase>(
  (ref) => DeleteBudgetUseCase(ref.read(budgetRepositoryProvider)),
);

final calculateBudgetProgressUseCaseProvider =
    Provider<CalculateBudgetProgressUseCase>(
      (ref) => CalculateBudgetProgressUseCase(
        ref.read(transactionRepositoryProvider),
      ),
    );

final budgetProvider =
    AsyncNotifierProvider<BudgetController, List<BudgetEntity>>(
      BudgetController.new,
    );

final budgetProgressProvider =
    AsyncNotifierProvider<
      BudgetProgressController,
      Map<String, BudgetProgressEntity>
    >(BudgetProgressController.new);

final budgetProgressForProvider =
    Provider.family<AsyncValue<BudgetProgressEntity>, String>(
      (ref, budgetId) => ref.watch(budgetProgressProvider).whenData((map) {
        final entry = map[budgetId];
        if (entry == null) throw StateError('Budget $budgetId not found.');
        return entry;
      }),
    );

final currentMonthBudgetProvider = Provider<AsyncValue<BudgetEntity?>>(
  (ref) => ref.watch(budgetProvider).whenData((budgets) {
    final now = DateTime.now();
    try {
      return budgets.firstWhere(
        (b) => b.month.year == now.year && b.month.month == now.month,
      );
    } catch (_) {
      return null;
    }
  }),
);
