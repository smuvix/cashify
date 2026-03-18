import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/account_entity.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/usecases/account_use_cases.dart';
import '../providers/account_providers.dart';

class AccountController extends AsyncNotifier<List<AccountEntity>> {
  late WatchAccountsUseCase _watch;
  late CreateAccountUseCase _create;
  late UpdateAccountUseCase _update;
  late DeleteAccountUseCase _delete;

  final Set<String> _pendingDeleteIds = {};
  Timer? _commitTimer;

  @override
  Future<List<AccountEntity>> build() async {
    _watch = ref.read(watchAccountsUseCaseProvider);
    _create = ref.read(createAccountUseCaseProvider);
    _update = ref.read(updateAccountUseCaseProvider);
    _delete = ref.read(deleteAccountUseCaseProvider);

    ref.onDispose(() => _commitTimer?.cancel());

    final sub = _watch().listen((accounts) {
      final filtered = _pendingDeleteIds.isEmpty
          ? accounts
          : accounts.where((a) => !_pendingDeleteIds.contains(a.id)).toList();
      state = AsyncData(filtered);
    }, onError: (e, st) => state = AsyncError(e, st));
    ref.onDispose(sub.cancel);

    return _watch().first;
  }

  Future<void> createAccount({
    required String name,
    required AccountType type,
    required double initialBalance,
  }) async {
    await _create(name: name, type: type, initialBalance: initialBalance);
  }

  Future<void> updateAccount(
    AccountEntity current, {
    String? name,
    AccountType? type,
  }) async {
    await _update(current, name: name, type: type);
  }

  Future<void> Function() deleteAccountWithUndo(
    AccountEntity account, {
    Duration undoWindow = const Duration(seconds: 4),
    VoidCallback? onCommitted,
  }) {
    _pendingDeleteIds.add(account.id);
    final current = state.value ?? [];
    state = AsyncData(current.where((a) => a.id != account.id).toList());

    _commitTimer?.cancel();
    var cancelled = false;

    _commitTimer = Timer(undoWindow, () async {
      if (cancelled) return;
      onCommitted?.call();
      _pendingDeleteIds.remove(account.id);
      try {
        await _delete(account.id);
      } catch (e, st) {
        _pendingDeleteIds.remove(account.id);
        state = AsyncError(e, st);
      }
    });

    return () async {
      cancelled = true;
      _commitTimer?.cancel();
      _pendingDeleteIds.remove(account.id);
      final restored = List<AccountEntity>.from(state.value ?? []);
      final insertIdx = restored.indexWhere(
        (a) => a.name.toLowerCase().compareTo(account.name.toLowerCase()) > 0,
      );
      if (insertIdx == -1) {
        restored.add(account);
      } else {
        restored.insert(insertIdx, account);
      }
      state = AsyncData(restored);
    };
  }
}
