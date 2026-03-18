import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/account_repository_impl.dart';
import '../../data/services/account_remote_service.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/usecases/account_use_cases.dart';
import '../controllers/account_controller.dart';

final accountRemoteServiceProvider = Provider<AccountRemoteService>(
  (_) => AccountRemoteServiceImpl(),
);

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepositoryImpl(ref.read(accountRemoteServiceProvider)),
);

final watchAccountsUseCaseProvider = Provider<WatchAccountsUseCase>(
  (ref) => WatchAccountsUseCase(ref.read(accountRepositoryProvider)),
);

final fetchAccountUseCaseProvider = Provider<FetchAccountUseCase>(
  (ref) => FetchAccountUseCase(ref.read(accountRepositoryProvider)),
);

final createAccountUseCaseProvider = Provider<CreateAccountUseCase>(
  (ref) => CreateAccountUseCase(ref.read(accountRepositoryProvider)),
);

final updateAccountUseCaseProvider = Provider<UpdateAccountUseCase>(
  (ref) => UpdateAccountUseCase(ref.read(accountRepositoryProvider)),
);

final deleteAccountUseCaseProvider = Provider<DeleteAccountUseCase>(
  (ref) => DeleteAccountUseCase(ref.read(accountRepositoryProvider)),
);

final accountProvider =
    AsyncNotifierProvider<AccountController, List<AccountEntity>>(
      AccountController.new,
    );

final totalBalanceProvider = Provider<AsyncValue<double>>(
  (ref) => ref
      .watch(accountProvider)
      .whenData((list) => list.fold(0.0, (sum, a) => sum + a.currentBalance)),
);
