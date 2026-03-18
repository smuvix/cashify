import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/budget_entity.dart';

class BudgetModel extends BudgetEntity {
  const BudgetModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.month,
    required super.categoryAllocations,
    required super.isDeleted,
    super.deletedAt,
    required super.createdAt,
    required super.updatedAt,
  });

  static const kId = 'id';
  static const kUserId = 'userId';
  static const kName = 'name';
  static const kMonth = 'month';
  static const kCategoryAllocations = 'categoryAllocations';
  static const kIsDeleted = 'isDeleted';
  static const kDeletedAt = 'deletedAt';
  static const kCreatedAt = 'createdAt';
  static const kUpdatedAt = 'updatedAt';

  factory BudgetModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;

    final rawAllocations =
        (data[kCategoryAllocations] as Map<String, dynamic>?) ?? {};
    final allocations = rawAllocations.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );

    final rawMonth = (data[kMonth] as Timestamp).toDate();
    final normalisedMonth = DateTime(rawMonth.year, rawMonth.month, 1);

    return BudgetModel(
      id: doc.id,
      userId: data[kUserId] as String,
      name: data[kName] as String,
      month: normalisedMonth,
      categoryAllocations: allocations,
      isDeleted: data[kIsDeleted] as bool? ?? false,
      deletedAt: (data[kDeletedAt] as Timestamp?)?.toDate(),
      createdAt: (data[kCreatedAt] as Timestamp).toDate(),
      updatedAt: (data[kUpdatedAt] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    kId: id,
    kUserId: userId,
    kName: name,
    kMonth: Timestamp.fromDate(month),
    kCategoryAllocations: categoryAllocations,
    kIsDeleted: isDeleted,
    kDeletedAt: deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
    kCreatedAt: Timestamp.fromDate(createdAt),
    kUpdatedAt: Timestamp.fromDate(updatedAt),
  };

  factory BudgetModel.fromEntity(BudgetEntity entity) => BudgetModel(
    id: entity.id,
    userId: entity.userId,
    name: entity.name,
    month: entity.month,
    categoryAllocations: entity.categoryAllocations,
    isDeleted: entity.isDeleted,
    deletedAt: entity.deletedAt,
    createdAt: entity.createdAt,
    updatedAt: entity.updatedAt,
  );
}
