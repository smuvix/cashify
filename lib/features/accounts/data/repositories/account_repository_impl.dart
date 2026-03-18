import '../../data/models/account_model.dart';
import '../../data/services/account_remote_service.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  const AccountRepositoryImpl(this._service);

  final AccountRemoteService _service;

  @override
  Stream<List<AccountEntity>> watchAccounts() => _service.watchAccounts();

  @override
  Future<AccountEntity?> fetchAccount(String id) => _service.fetchAccount(id);

  @override
  Future<void> createAccount(AccountEntity entity) =>
      _service.createAccount(AccountModel.fromEntity(entity));

  @override
  Future<void> updateAccount(AccountEntity entity) =>
      _service.updateAccount(AccountModel.fromEntity(entity));

  @override
  Future<void> deleteAccount(String id) => _service.softDeleteAccount(id);
}
