import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/goal_model.dart';

abstract interface class GoalRemoteService {
  Stream<List<GoalModel>> watchGoals();

  Future<GoalModel?> fetchGoal(String id);

  Future<void> createGoal(GoalModel model);

  Future<void> updateGoal(GoalModel model);

  Future<void> softDeleteGoal(String id);
}

class GoalRemoteServiceImpl implements GoalRemoteService {
  GoalRemoteServiceImpl({FirebaseFirestore? firestore, FirebaseAuth? auth})
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
      .collection('goals');

  DocumentReference<Map<String, dynamic>> _doc(String id) => _col.doc(id);

  @override
  Stream<List<GoalModel>> watchGoals() => _col
      .where(GoalModel.kIsDeleted, isEqualTo: false)
      .orderBy(GoalModel.kDeadline)
      .snapshots()
      .map((snap) => snap.docs.map(GoalModel.fromFirestore).toList());

  @override
  Future<GoalModel?> fetchGoal(String id) async {
    final doc = await _doc(id).get();
    if (!doc.exists) return null;
    return GoalModel.fromFirestore(doc);
  }

  @override
  Future<void> createGoal(GoalModel model) =>
      _doc(model.id).set(model.toFirestore());

  @override
  Future<void> updateGoal(GoalModel model) =>
      _doc(model.id).update(model.toFirestore());

  @override
  Future<void> softDeleteGoal(String id) => _doc(id).update({
    GoalModel.kIsDeleted: true,
    GoalModel.kDeletedAt: Timestamp.now(),
    GoalModel.kUpdatedAt: Timestamp.now(),
  });
}
