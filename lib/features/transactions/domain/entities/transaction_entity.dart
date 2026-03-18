import 'transaction_type.dart';

class TransactionEntity {
  const TransactionEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    this.tax,
    required this.accountId,
    this.toAccountId,
    this.categoryId,
    required this.transactionDate,
    this.notes,
    required this.isDeleted,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final TransactionType type;

  final double amount;

  final double? tax;

  final String accountId;

  final String? toAccountId;

  final String? categoryId;
  final DateTime transactionDate;
  final String? notes;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get totalAmount => amount + (tax ?? 0.0);

  TransactionEntity copyWith({
    TransactionType? type,
    double? amount,
    double? tax,
    String? accountId,
    String? toAccountId,
    String? categoryId,
    DateTime? transactionDate,
    String? notes,
    bool? isDeleted,
    DateTime? deletedAt,
    DateTime? updatedAt,
  }) => TransactionEntity(
    id: id,
    userId: userId,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    tax: tax ?? this.tax,
    accountId: accountId ?? this.accountId,
    toAccountId: toAccountId ?? this.toAccountId,
    categoryId: categoryId ?? this.categoryId,
    transactionDate: transactionDate ?? this.transactionDate,
    notes: notes ?? this.notes,
    isDeleted: isDeleted ?? this.isDeleted,
    deletedAt: deletedAt ?? this.deletedAt,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is TransactionEntity && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'TransactionEntity(id: $id, type: ${type.name}, amount: $amount)';
}
