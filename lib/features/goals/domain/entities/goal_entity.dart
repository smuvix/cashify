class GoalEntity {
  const GoalEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.accountId,
    required this.targetAmount,
    required this.startDate,
    required this.deadline,
    this.notes,
    required this.isCompleted,
    required this.isDeleted,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;

  final String name;

  final String accountId;

  final double targetAmount;

  final DateTime startDate;

  final DateTime deadline;

  final String? notes;

  final bool isCompleted;

  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  DateTime get periodStart =>
      DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0, 0, 0);

  DateTime get periodEnd => DateTime(
    deadline.year,
    deadline.month,
    deadline.day + 1,
    0,
    0,
    0,
    0,
    0,
  ).subtract(const Duration(microseconds: 1));

  bool get isOverdue => !isCompleted && DateTime.now().isAfter(periodEnd);

  int get daysRemaining => periodEnd.difference(DateTime.now()).inDays;

  GoalEntity copyWith({
    String? name,
    String? accountId,
    double? targetAmount,
    DateTime? startDate,
    DateTime? deadline,
    String? notes,
    bool? isCompleted,
    bool? isDeleted,
    DateTime? deletedAt,
    DateTime? updatedAt,
  }) => GoalEntity(
    id: id,
    userId: userId,
    name: name ?? this.name,
    accountId: accountId ?? this.accountId,
    targetAmount: targetAmount ?? this.targetAmount,
    startDate: startDate ?? this.startDate,
    deadline: deadline ?? this.deadline,
    notes: notes ?? this.notes,
    isCompleted: isCompleted ?? this.isCompleted,
    isDeleted: isDeleted ?? this.isDeleted,
    deletedAt: deletedAt ?? this.deletedAt,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  bool operator ==(Object other) => other is GoalEntity && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'GoalEntity(id: $id, name: $name, target: $targetAmount, '
      'deadline: $deadline)';
}
