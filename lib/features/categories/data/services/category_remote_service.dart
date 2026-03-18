import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/category_model.dart';
import '../../domain/entities/category_entity.dart';
import '../../../../core/constants/default_categories.dart';

abstract interface class CategoryRemoteService {
  Stream<List<CategoryModel>> watchCategories();

  Future<void> seedDefaultsIfNeeded();

  Future<void> createCategory(CategoryModel model);

  Future<void> updateCategory(CategoryModel model);

  Future<void> softDeleteCategory(String id);
}

class CategoryRemoteServiceImpl implements CategoryRemoteService {
  CategoryRemoteServiceImpl({FirebaseFirestore? firestore, FirebaseAuth? auth})
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
      .collection('categories');

  DocumentReference<Map<String, dynamic>> _doc(String id) => _col.doc(id);

  @override
  Stream<List<CategoryModel>> watchCategories() => _col
      .where(CategoryModel.kIsDeleted, isEqualTo: false)
      .orderBy(CategoryModel.kName)
      .snapshots()
      .map((snap) => snap.docs.map(CategoryModel.fromFirestore).toList());

  @override
  Future<void> seedDefaultsIfNeeded() async {
    final first = await _col
        .where(CategoryModel.kIsDefault, isEqualTo: true)
        .limit(1)
        .get();

    if (first.docs.isNotEmpty) return;

    final batch = _firestore.batch();
    final now = Timestamp.now();

    for (final template in kDefaultCategories) {
      final entity = CategoryEntity.fromDefault(template);
      final model = CategoryModel.fromEntity(entity);
      final data = model.toFirestore()
        ..[CategoryModel.kCreatedAt] = now
        ..[CategoryModel.kUpdatedAt] = now
        ..[CategoryModel.kUserId] = _uid;

      batch.set(_doc(template.id), data);
    }

    await batch.commit();
  }

  @override
  Future<void> createCategory(CategoryModel model) =>
      _doc(model.id).set(model.toFirestore());

  @override
  Future<void> updateCategory(CategoryModel model) =>
      _doc(model.id).update(model.toFirestore());

  @override
  Future<void> softDeleteCategory(String id) => _doc(id).update({
    CategoryModel.kIsDeleted: true,
    CategoryModel.kDeletedAt: Timestamp.now(),
    CategoryModel.kUpdatedAt: Timestamp.now(),
  });
}
