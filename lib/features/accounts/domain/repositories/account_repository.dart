import '../../domain/entities/account_entity.dart';

abstract interface class AccountRepository {
  Stream<List<AccountEntity>> watchAccounts();

  Future<AccountEntity?> fetchAccount(String id);

  Future<void> createAccount(AccountEntity entity);

  Future<void> updateAccount(AccountEntity entity);

  Future<void> deleteAccount(String id);
}