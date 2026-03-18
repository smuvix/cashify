import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract interface class UserSettingsRemoteService {
  Future<Map<String, dynamic>?> fetchSettings();

  Future<void> saveSettings(Map<String, dynamic> data);
}

class UserSettingsRemoteServiceImpl implements UserSettingsRemoteService {
  UserSettingsRemoteServiceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> get _doc {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('No authenticated user found.');
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('cashify')
        .doc('settings');
  }

  @override
  Future<Map<String, dynamic>?> fetchSettings() async {
    final snapshot = await _doc.get();
    return snapshot.data();
  }

  @override
  Future<void> saveSettings(Map<String, dynamic> data) =>
      _doc.set(data, SetOptions(merge: true));
}
