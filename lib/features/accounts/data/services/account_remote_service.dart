import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/account_model.dart';

abstract interface class AccountRemoteService {
  Stream<List<AccountModel>> watchAccounts();

  Future<AccountModel?> fetchAccount(String id);

  Future<void> createAccount(AccountModel model);

  Future<void> updateAccount(AccountModel model);

  Future<void> softDeleteAccount(String id);
}

class AccountRemoteServiceImpl implements AccountRemoteService {
  AccountRemoteServiceImpl({FirebaseFirestore? firestore, FirebaseAuth? auth})
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
      .collection('accounts');

  DocumentReference<Map<String, dynamic>> _doc(String id) => _col.doc(id);

  @override
  Stream<List<AccountModel>> watchAccounts() => _col
      .where(AccountModel.kIsDeleted, isEqualTo: false)
      .orderBy(AccountModel.kName)
      .snapshots()
      .map((snap) => snap.docs.map(AccountModel.fromFirestore).toList());

  @override
  Future<AccountModel?> fetchAccount(String id) async {
    final doc = await _doc(id).get();
    if (!doc.exists) return null;
    return AccountModel.fromFirestore(doc);
  }

  @override
  Future<void> createAccount(AccountModel model) =>
      _doc(model.id).set(model.toFirestore());

  @override
  Future<void> updateAccount(AccountModel model) =>
      _doc(model.id).update(model.toFirestore());

  @override
  Future<void> softDeleteAccount(String id) => _doc(id).update({
    AccountModel.kIsDeleted: true,
    AccountModel.kDeletedAt: Timestamp.now(),
    AccountModel.kUpdatedAt: Timestamp.now(),
  });
}