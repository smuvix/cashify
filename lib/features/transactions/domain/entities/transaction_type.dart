import 'package:flutter/material.dart';

enum TransactionType {
  income(
    label: 'Income',
    icon: Icons.arrow_downward_rounded,
    color: Colors.green,
    hasTax: false,
  ),
  expense(
    label: 'Expense',
    icon: Icons.arrow_upward_rounded,
    color: Colors.red,
    hasTax: true,
  ),
  transfer(
    label: 'Transfer',
    icon: Icons.swap_horiz_rounded,
    color: Colors.blue,
    hasTax: true,
  );

  const TransactionType({
    required this.label,
    required this.icon,
    required this.color,
    required this.hasTax,
  });

  final String label;
  final IconData icon;
  final Color color;

  final bool hasTax;

  String toStorageString() => name;

  static TransactionType fromStorageString(String? value) => switch (value) {
    'income' => TransactionType.income,
    'expense' => TransactionType.expense,
    'transfer' => TransactionType.transfer,
    _ => TransactionType.expense,
  };
}
