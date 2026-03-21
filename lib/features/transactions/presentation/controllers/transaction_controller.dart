import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_query.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/usecases/transaction_use_cases.dart';
import '../providers/transaction_providers.dart';

class TransactionController extends AsyncNotifier<List<TransactionEntity>> {
  TransactionController(this._query);

  final TransactionQuery _query;

  late WatchTransactionsUseCase _watch;
  late CreateTransactionUseCase _create;
  late UpdateTransactionUseCase _update;
  late DeleteTransactionUseCase _delete;
  late FetchTransactionsUseCase _fetch;

  final Set<String> _pendingDeleteIds = {};
  Timer? _commitTimer;

  @override
  Future<List<TransactionEntity>> build() async {
    _watch = ref.read(watchTransactionsUseCaseProvider);
    _create = ref.read(createTransactionUseCaseProvider);
    _update = ref.read(updateTransactionUseCaseProvider);
    _delete = ref.read(deleteTransactionUseCaseProvider);
    _fetch = ref.read(fetchTransactionsUseCaseProvider);

    ref.onDispose(() {
      _commitTimer?.cancel();
    });

    final sub = _watch(_query).listen((txs) {
      final filtered = _pendingDeleteIds.isEmpty
          ? txs
          : txs.where((t) => !_pendingDeleteIds.contains(t.id)).toList();
      state = AsyncData(filtered);
    }, onError: (e, st) => state = AsyncError(e, st));
    ref.onDispose(sub.cancel);

    return _watch(_query).first;
  }

  Future<TransactionEntity> createTransaction({
    required TransactionType type,
    required double amount,
    double? tax,
    required String accountId,
    String? toAccountId,
    String? categoryId,
    required DateTime transactionDate,
    String? notes,
  }) => _create(
    type: type,
    amount: amount,
    tax: tax,
    accountId: accountId,
    toAccountId: toAccountId,
    categoryId: categoryId,
    transactionDate: transactionDate,
    notes: notes,
  );

  Future<TransactionEntity> updateTransaction(
    TransactionEntity current, {
    String? categoryId,
    DateTime? transactionDate,
    String? notes,
  }) => _update(
    current,
    categoryId: categoryId,
    transactionDate: transactionDate,
    notes: notes,
  );

  Future<TransactionEntity> updateTransactionAmount(
    TransactionEntity current, {
    required double newAmount,
    double? newTax,
    String? categoryId,
    DateTime? transactionDate,
    String? notes,
  }) => _update.withAmountUpdate(
    current,
    newAmount: newAmount,
    newTax: newTax,
    categoryId: categoryId,
    transactionDate: transactionDate,
    notes: notes,
  );

  Future<void> Function() deleteTransactionWithUndo(
    TransactionEntity transaction, {
    Duration undoWindow = const Duration(seconds: 4),
    void Function()? onCommitted,
  }) {
    _pendingDeleteIds.add(transaction.id);
    final current = state.value ?? [];
    state = AsyncData(current.where((t) => t.id != transaction.id).toList());

    _commitTimer?.cancel();
    var cancelled = false;

    _commitTimer = Timer(undoWindow, () async {
      if (cancelled) return;
      onCommitted?.call();
      _pendingDeleteIds.remove(transaction.id);
      try {
        await _delete(transaction);
      } catch (e, st) {
        _pendingDeleteIds.remove(transaction.id);
        state = AsyncError(e, st);
      }
    });

    return () async {
      cancelled = true;
      _commitTimer?.cancel();
      _pendingDeleteIds.remove(transaction.id);
      final restored = List<TransactionEntity>.from(state.value ?? []);
      final insertIdx = restored.indexWhere(
        (t) => t.transactionDate.isBefore(transaction.transactionDate),
      );
      if (insertIdx == -1) {
        restored.add(transaction);
      } else {
        restored.insert(insertIdx, transaction);
      }
      state = AsyncData(restored);
    };
  }

  Future<List<TransactionEntity>> fetchByAccount(String accountId) =>
      _fetch.byAccount(accountId);

  Future<List<TransactionEntity>> fetchByDateRange(
    DateTime from,
    DateTime to,
  ) => _fetch.byDateRange(from, to);

  Future<List<TransactionEntity>> fetchByType(TransactionType type) =>
      _fetch.byType(type);

  Future<List<TransactionEntity>> fetchByCategory(String categoryId) =>
      _fetch.byCategory(categoryId);

  Future<List<TransactionEntity>> fetchRecent({int limit = 20}) =>
      _fetch.recent(limit: limit);
}
