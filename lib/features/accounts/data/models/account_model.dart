import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/account_entity.dart';
import '../../domain/entities/account_type.dart';

class AccountModel extends AccountEntity {
  const AccountModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.type,
    required super.initialBalance,
    required super.currentBalance,
    required super.isDeleted,
    super.deletedAt,
    required super.createdAt,
    required super.updatedAt,
  });

  static const kId = 'id';
  static const kUserId = 'userId';
  static const kName = 'name';
  static const kType = 'type';
  static const kInitialBalance = 'initialBalance';
  static const kCurrentBalance = 'currentBalance';
  static const kIsDeleted = 'isDeleted';
  static const kDeletedAt = 'deletedAt';
  static const kCreatedAt = 'createdAt';
  static const kUpdatedAt = 'updatedAt';

  factory AccountModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return AccountModel(
      id: doc.id,
      userId: data[kUserId] as String,
      name: data[kName] as String,
      type: AccountType.fromStorageString(data[kType] as String?),
      initialBalance: (data[kInitialBalance] as num).toDouble(),
      currentBalance: (data[kCurrentBalance] as num).toDouble(),
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
    kType: type.toStorageString(),
    kInitialBalance: initialBalance,
    kCurrentBalance: currentBalance,
    kIsDeleted: isDeleted,
    kDeletedAt: deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
    kCreatedAt: Timestamp.fromDate(createdAt),
    kUpdatedAt: Timestamp.fromDate(updatedAt),
  };

  factory AccountModel.fromEntity(AccountEntity entity) => AccountModel(
    id: entity.id,
    userId: entity.userId,
    name: entity.name,
    type: entity.type,
    initialBalance: entity.initialBalance,
    currentBalance: entity.currentBalance,
    isDeleted: entity.isDeleted,
    deletedAt: entity.deletedAt,
    createdAt: entity.createdAt,
    updatedAt: entity.updatedAt,
  );
}