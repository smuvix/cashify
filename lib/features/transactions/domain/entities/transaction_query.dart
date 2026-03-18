import 'transaction_type.dart';

class TransactionQuery {
  const TransactionQuery({
    this.accountId,
    this.categoryId,
    this.type,
    this.dateFrom,
    this.dateTo,
    this.minAmount,
    this.maxAmount,
    this.limit,
    this.notes,
  });

  final String? accountId;

  final String? categoryId;

  final TransactionType? type;

  final DateTime? dateFrom;

  final DateTime? dateTo;

  final double? minAmount;

  final double? maxAmount;

  final int? limit;

  final String? notes;

  TransactionQuery copyWith({
    String? accountId,
    String? categoryId,
    TransactionType? type,
    DateTime? dateFrom,
    DateTime? dateTo,
    double? minAmount,
    double? maxAmount,
    int? limit,
    String? notes,
  }) => TransactionQuery(
    accountId: accountId ?? this.accountId,
    categoryId: categoryId ?? this.categoryId,
    type: type ?? this.type,
    dateFrom: dateFrom ?? this.dateFrom,
    dateTo: dateTo ?? this.dateTo,
    minAmount: minAmount ?? this.minAmount,
    maxAmount: maxAmount ?? this.maxAmount,
    limit: limit ?? this.limit,
    notes: notes ?? this.notes,
  );

  @override
  String toString() =>
      'TransactionQuery('
      'accountId: $accountId, '
      'type: ${type?.name}, '
      'dateFrom: $dateFrom, '
      'dateTo: $dateTo)';
}
