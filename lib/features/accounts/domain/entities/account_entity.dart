import 'account_type.dart';

class AccountEntity {
  const AccountEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.initialBalance,
    required this.currentBalance,
    required this.isDeleted,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final AccountType type;
  final double initialBalance;
  final double currentBalance;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  AccountEntity copyWith({
    String? id,
    String? userId,
    String? name,
    AccountType? type,
    double? initialBalance,
    double? currentBalance,
    bool? isDeleted,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AccountEntity(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    type: type ?? this.type,
    initialBalance: initialBalance ?? this.initialBalance,
    currentBalance: currentBalance ?? this.currentBalance,
    isDeleted: isDeleted ?? this.isDeleted,
    deletedAt: deletedAt ?? this.deletedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  bool operator ==(Object other) => other is AccountEntity && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'AccountEntity(id: $id, name: $name, type: ${type.name})';
}
