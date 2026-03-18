import 'package:flutter/material.dart';

enum CategoryType {
  income(
    label: 'Income',
    icon: Icons.arrow_downward_rounded,
    color: Colors.green,
  ),
  expense(
    label: 'Expense',
    icon: Icons.arrow_upward_rounded,
    color: Colors.red,
  );

  const CategoryType({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  String toStorageString() => name;

  static CategoryType fromStorageString(String? value) => switch (value) {
    'income' => CategoryType.income,
    'expense' => CategoryType.expense,
    _ => CategoryType.expense,
  };
}
