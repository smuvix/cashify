import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/transaction_model.dart';
import '../../domain/entities/transaction_query.dart';

abstract interface class TransactionRemoteService {
  Stream<List<TransactionModel>> watchTransactions(TransactionQuery query);

  Future<TransactionModel?> fetchTransaction(String id);

  Future<List<TransactionModel>> fetchTransactions(TransactionQuery query);

  Future<void> createTransaction(TransactionModel model);

  Future<void> updateTransaction(TransactionModel model);

  Future<void> softDeleteTransaction(String id);

  Future<void> commitTransactionWithBalanceUpdate({
    required TransactionModel transaction,
    String? accountIdToSubtract,
    String? accountIdToAdd,
    required double subtractAmount,
    required double addAmount,
  });

  Future<void> correctTransactionWithBalanceUpdate({
    required TransactionModel newTransaction,
    String? reverseAccountIdToSubtract,
    String? reverseAccountIdToAdd,
    required double reverseSubtractAmount,
    required double reverseAddAmount,
    String? forwardAccountIdToSubtract,
    String? forwardAccountIdToAdd,
    required double forwardSubtractAmount,
    required double forwardAddAmount,
  });

  Future<void> reverseTransactionWithBalanceUpdate({
    required TransactionModel transaction,
    String? accountIdToSubtract,
    required String accountIdToAdd,
    required double amount,
  });
}

class TransactionRemoteServiceImpl implements TransactionRemoteService {
  TransactionRemoteServiceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('No authenticated user found.');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _txCol => _firestore
      .collection('users')
      .doc(_uid)
      .collection('cashify')
      .doc('data')
      .collection('transactions');

  CollectionReference<Map<String, dynamic>> get _accCol => _firestore
      .collection('users')
      .doc(_uid)
      .collection('cashify')
      .doc('data')
      .collection('accounts');

  DocumentReference<Map<String, dynamic>> _txDoc(String id) => _txCol.doc(id);

  DocumentReference<Map<String, dynamic>> _accDoc(String id) => _accCol.doc(id);

  DateTime _endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  Query<Map<String, dynamic>> _buildQuery(TransactionQuery q) {
    Query<Map<String, dynamic>> query = _txCol.where(
      TransactionModel.kIsDeleted,
      isEqualTo: false,
    );

    if (q.type != null) {
      query = query.where(
        TransactionModel.kType,
        isEqualTo: q.type!.toStorageString(),
      );
    }

    if (q.accountId != null) {
      query = query.where(TransactionModel.kAccountId, isEqualTo: q.accountId);
    }

    if (q.categoryId != null) {
      query = query.where(
        TransactionModel.kCategoryId,
        isEqualTo: q.categoryId,
      );
    }

    if (q.dateFrom != null) {
      query = query.where(
        TransactionModel.kTransactionDate,
        isGreaterThanOrEqualTo: Timestamp.fromDate(q.dateFrom!),
      );
    }

    if (q.dateTo != null) {
      query = query.where(
        TransactionModel.kTransactionDate,
        isLessThanOrEqualTo: Timestamp.fromDate(_endOfDay(q.dateTo!)),
      );
    }

    query = query.orderBy(TransactionModel.kTransactionDate, descending: true);

    if (q.limit != null) {
      query = query.limit(q.limit!);
    }

    return query;
  }

  Future<List<TransactionModel>> _fetchBothSides(TransactionQuery q) async {
    final mainSnap = await _buildQuery(q).get();
    final main = mainSnap.docs.map(TransactionModel.fromFirestore).toList();

    if (q.accountId == null) return main;

    Query<Map<String, dynamic>> toQuery = _txCol
        .where(TransactionModel.kIsDeleted, isEqualTo: false)
        .where(TransactionModel.kToAccountId, isEqualTo: q.accountId);

    if (q.dateFrom != null) {
      toQuery = toQuery.where(
        TransactionModel.kTransactionDate,
        isGreaterThanOrEqualTo: Timestamp.fromDate(q.dateFrom!),
      );
    }
    if (q.dateTo != null) {
      toQuery = toQuery.where(
        TransactionModel.kTransactionDate,
        isLessThanOrEqualTo: Timestamp.fromDate(_endOfDay(q.dateTo!)),
      );
    }
    toQuery = toQuery.orderBy(
      TransactionModel.kTransactionDate,
      descending: true,
    );

    final toSnap = await toQuery.get();
    final toList = toSnap.docs.map(TransactionModel.fromFirestore).toList();

    final seen = <String>{};
    final merged = <TransactionModel>[];
    for (final tx in [...main, ...toList]) {
      if (seen.add(tx.id)) merged.add(tx);
    }

    merged.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    return _applyClientFilters(merged, q);
  }

  List<TransactionModel> _applyClientFilters(
    List<TransactionModel> list,
    TransactionQuery q,
  ) {
    var result = list;
    if (q.minAmount != null) {
      result = result.where((t) => t.amount >= q.minAmount!).toList();
    }
    if (q.maxAmount != null) {
      result = result.where((t) => t.amount <= q.maxAmount!).toList();
    }
    if (q.notes != null && q.notes!.isNotEmpty) {
      final needle = q.notes!.toLowerCase();
      result = result
          .where((t) => t.notes?.toLowerCase().contains(needle) ?? false)
          .toList();
    }
    if (q.limit != null && result.length > q.limit!) {
      result = result.take(q.limit!).toList();
    }
    return result;
  }

  @override
  Stream<List<TransactionModel>> watchTransactions(TransactionQuery query) =>
      _buildQuery(query).snapshots().map(
        (snap) => _applyClientFilters(
          snap.docs.map(TransactionModel.fromFirestore).toList(),
          query,
        ),
      );

  @override
  Future<TransactionModel?> fetchTransaction(String id) async {
    final doc = await _txDoc(id).get();
    if (!doc.exists) return null;
    return TransactionModel.fromFirestore(doc);
  }

  @override
  Future<List<TransactionModel>> fetchTransactions(TransactionQuery query) =>
      _fetchBothSides(query);

  @override
  Future<void> createTransaction(TransactionModel model) =>
      _txDoc(model.id).set(model.toFirestore());

  @override
  Future<void> updateTransaction(TransactionModel model) =>
      _txDoc(model.id).update(model.toFirestore());

  @override
  Future<void> softDeleteTransaction(String id) => _txDoc(id).update({
    TransactionModel.kIsDeleted: true,
    TransactionModel.kDeletedAt: Timestamp.now(),
    TransactionModel.kUpdatedAt: Timestamp.now(),
  });

  @override
  Future<void> commitTransactionWithBalanceUpdate({
    required TransactionModel transaction,
    String? accountIdToSubtract,
    String? accountIdToAdd,
    required double subtractAmount,
    required double addAmount,
  }) async {
    final batch = _firestore.batch();
    final now = Timestamp.now();

    batch.set(_txDoc(transaction.id), transaction.toFirestore());

    if (accountIdToAdd != null && addAmount != 0) {
      batch.update(_accDoc(accountIdToAdd), {
        'currentBalance': FieldValue.increment(addAmount),
        'updatedAt': now,
      });
    }

    if (accountIdToSubtract != null && subtractAmount != 0) {
      batch.update(_accDoc(accountIdToSubtract), {
        'currentBalance': FieldValue.increment(-subtractAmount),
        'updatedAt': now,
      });
    }

    await batch.commit();
  }

  @override
  Future<void> correctTransactionWithBalanceUpdate({
    required TransactionModel newTransaction,
    String? reverseAccountIdToSubtract,
    String? reverseAccountIdToAdd,
    required double reverseSubtractAmount,
    required double reverseAddAmount,
    String? forwardAccountIdToSubtract,
    String? forwardAccountIdToAdd,
    required double forwardSubtractAmount,
    required double forwardAddAmount,
  }) async {
    final batch = _firestore.batch();
    final now = Timestamp.now();

    if (reverseAccountIdToAdd != null && reverseAddAmount != 0) {
      batch.update(_accDoc(reverseAccountIdToAdd), {
        'currentBalance': FieldValue.increment(reverseAddAmount),
        'updatedAt': now,
      });
    }
    if (reverseAccountIdToSubtract != null && reverseSubtractAmount != 0) {
      batch.update(_accDoc(reverseAccountIdToSubtract), {
        'currentBalance': FieldValue.increment(-reverseSubtractAmount),
        'updatedAt': now,
      });
    }

    if (forwardAccountIdToAdd != null && forwardAddAmount != 0) {
      batch.update(_accDoc(forwardAccountIdToAdd), {
        'currentBalance': FieldValue.increment(forwardAddAmount),
        'updatedAt': now,
      });
    }
    if (forwardAccountIdToSubtract != null && forwardSubtractAmount != 0) {
      batch.update(_accDoc(forwardAccountIdToSubtract), {
        'currentBalance': FieldValue.increment(-forwardSubtractAmount),
        'updatedAt': now,
      });
    }

    batch.update(_txDoc(newTransaction.id), newTransaction.toFirestore());

    await batch.commit();
  }

  @override
  Future<void> reverseTransactionWithBalanceUpdate({
    required TransactionModel transaction,
    String? accountIdToSubtract,
    required String accountIdToAdd,
    required double amount,
  }) async {
    final batch = _firestore.batch();
    final now = Timestamp.now();

    batch.update(_txDoc(transaction.id), {
      TransactionModel.kIsDeleted: true,
      TransactionModel.kDeletedAt: now,
      TransactionModel.kUpdatedAt: now,
    });

    batch.update(_accDoc(accountIdToAdd), {
      'currentBalance': FieldValue.increment(-amount),
      'updatedAt': now,
    });

    if (accountIdToSubtract != null) {
      batch.update(_accDoc(accountIdToSubtract), {
        'currentBalance': FieldValue.increment(amount),
        'updatedAt': now,
      });
    }

    await batch.commit();
  }
}
