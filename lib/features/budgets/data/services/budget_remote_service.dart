import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/budget_model.dart';

abstract interface class BudgetRemoteService {
  Stream<List<BudgetModel>> watchBudgets();

  Future<BudgetModel?> fetchBudget(String id);

  Future<BudgetModel?> fetchBudgetForMonth(DateTime month);

  Future<void> createBudget(BudgetModel model);

  Future<void> updateBudget(BudgetModel model);

  Future<void> softDeleteBudget(String id);
}

class BudgetRemoteServiceImpl implements BudgetRemoteService {
  BudgetRemoteServiceImpl({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('No authenticated user found.');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _col => _firestore
      .collection('users')
      .doc(_uid)
      .collection('cashify')
      .doc('data')
      .collection('budgets');

  DocumentReference<Map<String, dynamic>> _doc(String id) => _col.doc(id);

  @override
  Stream<List<BudgetModel>> watchBudgets() => _col
      .where(BudgetModel.kIsDeleted, isEqualTo: false)
      .orderBy(BudgetModel.kMonth, descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(BudgetModel.fromFirestore).toList());

  @override
  Future<BudgetModel?> fetchBudget(String id) async {
    final doc = await _doc(id).get();
    if (!doc.exists) return null;
    return BudgetModel.fromFirestore(doc);
  }

  @override
  Future<BudgetModel?> fetchBudgetForMonth(DateTime month) async {
    final normalised = DateTime(month.year, month.month);
    final snap = await _col
        .where(BudgetModel.kIsDeleted, isEqualTo: false)
        .where(BudgetModel.kMonth, isEqualTo: Timestamp.fromDate(normalised))
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return BudgetModel.fromFirestore(snap.docs.first);
  }

  @override
  Future<void> createBudget(BudgetModel model) =>
      _doc(model.id).set(model.toFirestore());

  @override
  Future<void> updateBudget(BudgetModel model) =>
      _doc(model.id).update(model.toFirestore());

  @override
  Future<void> softDeleteBudget(String id) => _doc(id).update({
    BudgetModel.kIsDeleted: true,
    BudgetModel.kDeletedAt: Timestamp.now(),
    BudgetModel.kUpdatedAt: Timestamp.now(),
  });
}
