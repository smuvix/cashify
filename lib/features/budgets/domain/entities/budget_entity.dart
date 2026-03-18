class BudgetEntity {
  const BudgetEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.month,
    required this.categoryAllocations,
    required this.isDeleted,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;

  final String name;

  final DateTime month;

  final Map<String, double> categoryAllocations;

  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  DateTime get periodStart =>
      DateTime(month.year, month.month, 1, 0, 0, 0, 0, 0);

  DateTime get periodEnd => DateTime(
    month.year,
    month.month + 1,
    1,
    0,
    0,
    0,
    0,
    0,
  ).subtract(const Duration(microseconds: 1));

  double get totalBudgeted =>
      categoryAllocations.values.fold(0.0, (sum, v) => sum + v);

  BudgetEntity copyWith({
    String? name,
    DateTime? month,
    Map<String, double>? categoryAllocations,
    bool? isDeleted,
    DateTime? deletedAt,
    DateTime? updatedAt,
  }) => BudgetEntity(
    id: id,
    userId: userId,
    name: name ?? this.name,
    month: month ?? this.month,
    categoryAllocations: categoryAllocations ?? this.categoryAllocations,
    isDeleted: isDeleted ?? this.isDeleted,
    deletedAt: deletedAt ?? this.deletedAt,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  bool operator ==(Object other) => other is BudgetEntity && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'BudgetEntity(id: $id, name: $name, month: $month, '
      'categories: ${categoryAllocations.length})';
}
