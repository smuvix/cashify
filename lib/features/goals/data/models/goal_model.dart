import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/goal_entity.dart';

class GoalModel extends GoalEntity {
  const GoalModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.accountId,
    required super.targetAmount,
    required super.startDate,
    required super.deadline,
    super.notes,
    required super.isCompleted,
    required super.isDeleted,
    super.deletedAt,
    required super.createdAt,
    required super.updatedAt,
  });

  static const kId = 'id';
  static const kUserId = 'userId';
  static const kName = 'name';
  static const kAccountId = 'accountId';
  static const kTargetAmount = 'targetAmount';
  static const kStartDate = 'startDate';
  static const kDeadline = 'deadline';
  static const kNotes = 'notes';
  static const kIsCompleted = 'isCompleted';
  static const kIsDeleted = 'isDeleted';
  static const kDeletedAt = 'deletedAt';
  static const kCreatedAt = 'createdAt';
  static const kUpdatedAt = 'updatedAt';

  factory GoalModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    final rawStart = (data[kStartDate] as Timestamp).toDate();
    final rawDeadline = (data[kDeadline] as Timestamp).toDate();

    return GoalModel(
      id: doc.id,
      userId: data[kUserId] as String,
      name: data[kName] as String,
      accountId: data[kAccountId] as String,
      targetAmount: (data[kTargetAmount] as num).toDouble(),
      startDate: DateTime(rawStart.year, rawStart.month, rawStart.day),
      deadline: DateTime(rawDeadline.year, rawDeadline.month, rawDeadline.day),
      notes: data[kNotes] as String?,
      isCompleted: data[kIsCompleted] as bool? ?? false,
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
    kAccountId: accountId,
    kTargetAmount: targetAmount,
    kStartDate: Timestamp.fromDate(startDate),
    kDeadline: Timestamp.fromDate(deadline),
    kNotes: notes,
    kIsCompleted: isCompleted,
    kIsDeleted: isDeleted,
    kDeletedAt: deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
    kCreatedAt: Timestamp.fromDate(createdAt),
    kUpdatedAt: Timestamp.fromDate(updatedAt),
  };

  factory GoalModel.fromEntity(GoalEntity entity) => GoalModel(
    id: entity.id,
    userId: entity.userId,
    name: entity.name,
    accountId: entity.accountId,
    targetAmount: entity.targetAmount,
    startDate: entity.startDate,
    deadline: entity.deadline,
    notes: entity.notes,
    isCompleted: entity.isCompleted,
    isDeleted: entity.isDeleted,
    deletedAt: entity.deletedAt,
    createdAt: entity.createdAt,
    updatedAt: entity.updatedAt,
  );
}
