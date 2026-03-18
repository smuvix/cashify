import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../data/repositories/goal_repository_impl.dart';
import '../../data/services/goal_remote_service.dart';
import '../../domain/entities/goal_entity.dart';
import '../../domain/entities/goal_progress_entity.dart';
import '../../domain/repositories/goal_repository.dart';
import '../../domain/usecases/goal_use_cases.dart';
import '../controllers/goal_controller.dart';
import '../controllers/goal_progress_controller.dart';

final goalRemoteServiceProvider = Provider<GoalRemoteService>(
  (_) => GoalRemoteServiceImpl(),
);

final goalRepositoryProvider = Provider<GoalRepository>(
  (ref) => GoalRepositoryImpl(ref.read(goalRemoteServiceProvider)),
);

final watchGoalsUseCaseProvider = Provider<WatchGoalsUseCase>(
  (ref) => WatchGoalsUseCase(ref.read(goalRepositoryProvider)),
);

final fetchGoalByIdUseCaseProvider = Provider<FetchGoalByIdUseCase>(
  (ref) => FetchGoalByIdUseCase(ref.read(goalRepositoryProvider)),
);

final createGoalUseCaseProvider = Provider<CreateGoalUseCase>(
  (ref) => CreateGoalUseCase(ref.read(goalRepositoryProvider)),
);

final updateGoalUseCaseProvider = Provider<UpdateGoalUseCase>(
  (ref) => UpdateGoalUseCase(ref.read(goalRepositoryProvider)),
);

final deleteGoalUseCaseProvider = Provider<DeleteGoalUseCase>(
  (ref) => DeleteGoalUseCase(ref.read(goalRepositoryProvider)),
);

final calculateGoalProgressUseCaseProvider =
    Provider<CalculateGoalProgressUseCase>(
      (ref) =>
          CalculateGoalProgressUseCase(ref.read(transactionRepositoryProvider)),
    );

final goalProvider = AsyncNotifierProvider<GoalController, List<GoalEntity>>(
  GoalController.new,
);

final goalProgressProvider =
    AsyncNotifierProvider<
      GoalProgressController,
      Map<String, GoalProgressEntity>
    >(GoalProgressController.new);

final goalProgressForProvider =
    Provider.family<AsyncValue<GoalProgressEntity>, String>(
      (ref, goalId) => ref.watch(goalProgressProvider).whenData((map) {
        final entry = map[goalId];
        if (entry == null) {
          throw StateError('Goal $goalId not found in progress map.');
        }
        return entry;
      }),
    );

final activeGoalsProvider = Provider<AsyncValue<List<GoalEntity>>>(
  (ref) => ref
      .watch(goalProvider)
      .whenData((goals) => goals.where((g) => !g.isCompleted).toList()),
);

final completedGoalsProvider = Provider<AsyncValue<List<GoalEntity>>>(
  (ref) => ref
      .watch(goalProvider)
      .whenData((goals) => goals.where((g) => g.isCompleted).toList()),
);
