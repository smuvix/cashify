import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_type.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.amount,
    super.tax,
    required super.accountId,
    super.toAccountId,
    super.categoryId,
    required super.transactionDate,
    super.notes,
    required super.isDeleted,
    super.deletedAt,
    required super.createdAt,
    required super.updatedAt,
  });

  static const kId = 'id';
  static const kUserId = 'userId';
  static const kType = 'type';
  static const kAmount = 'amount';
  static const kTax = 'tax';
  static const kAccountId = 'accountId';
  static const kToAccountId = 'toAccountId';
  static const kCategoryId = 'categoryId';
  static const kTransactionDate = 'transactionDate';
  static const kNotes = 'notes';
  static const kIsDeleted = 'isDeleted';
  static const kDeletedAt = 'deletedAt';
  static const kCreatedAt = 'createdAt';
  static const kUpdatedAt = 'updatedAt';

  factory TransactionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return TransactionModel(
      id: doc.id,
      userId: data[kUserId] as String,
      type: TransactionType.fromStorageString(data[kType] as String?),
      amount: (data[kAmount] as num).toDouble(),
      tax: data[kTax] != null ? (data[kTax] as num).toDouble() : null,
      accountId: data[kAccountId] as String,
      toAccountId: data[kToAccountId] as String?,
      categoryId: data[kCategoryId] as String?,
      transactionDate: (data[kTransactionDate] as Timestamp).toDate(),
      notes: data[kNotes] as String?,
      isDeleted: data[kIsDeleted] as bool? ?? false,
      deletedAt: (data[kDeletedAt] as Timestamp?)?.toDate(),
      createdAt: (data[kCreatedAt] as Timestamp).toDate(),
      updatedAt: (data[kUpdatedAt] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    kId: id,
    kUserId: userId,
    kType: type.toStorageString(),
    kAmount: amount,
    kTax: tax,
    kAccountId: accountId,
    kToAccountId: toAccountId,
    kCategoryId: categoryId,
    kTransactionDate: Timestamp.fromDate(transactionDate),
    kNotes: notes,
    kIsDeleted: isDeleted,
    kDeletedAt: deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
    kCreatedAt: Timestamp.fromDate(createdAt),
    kUpdatedAt: Timestamp.fromDate(updatedAt),
  };

  factory TransactionModel.fromEntity(TransactionEntity entity) =>
      TransactionModel(
        id: entity.id,
        userId: entity.userId,
        type: entity.type,
        amount: entity.amount,
        tax: entity.tax,
        accountId: entity.accountId,
        toAccountId: entity.toAccountId,
        categoryId: entity.categoryId,
        transactionDate: entity.transactionDate,
        notes: entity.notes,
        isDeleted: entity.isDeleted,
        deletedAt: entity.deletedAt,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      );
}
