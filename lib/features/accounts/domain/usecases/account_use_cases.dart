import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/account_entity.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/repositories/account_repository.dart';

class WatchAccountsUseCase {
  const WatchAccountsUseCase(this._repository);
  final AccountRepository _repository;

  Stream<List<AccountEntity>> call() => _repository.watchAccounts();
}

class FetchAccountUseCase {
  const FetchAccountUseCase(this._repository);
  final AccountRepository _repository;

  Future<AccountEntity?> call(String id) => _repository.fetchAccount(id);
}

class CreateAccountUseCase {
  const CreateAccountUseCase(this._repository);
  final AccountRepository _repository;

  Future<AccountEntity> call({
    required String name,
    required AccountType type,
    required double initialBalance,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('No authenticated user found.');

    final now = DateTime.now();
    final entity = AccountEntity(
      id: const Uuid().v4(),
      userId: uid,
      name: name.trim(),
      type: type,
      initialBalance: initialBalance,
      currentBalance: initialBalance,
      isDeleted: false,
      createdAt: now,
      updatedAt: now,
    );

    await _repository.createAccount(entity);
    return entity;
  }
}

class UpdateAccountUseCase {
  const UpdateAccountUseCase(this._repository);
  final AccountRepository _repository;

  Future<AccountEntity> call(
    AccountEntity current, {
    String? name,
    AccountType? type,
  }) async {
    final updated = current.copyWith(
      name: name?.trim() ?? current.name,
      type: type ?? current.type,
      updatedAt: DateTime.now(),
    );
    await _repository.updateAccount(updated);
    return updated;
  }
}

class DeleteAccountUseCase {
  const DeleteAccountUseCase(this._repository);
  final AccountRepository _repository;

  Future<void> call(String id) => _repository.deleteAccount(id);
}
