import 'package:flutter/material.dart';

enum AccountType {
  bank(
    name: 'Bank Account',
    icon: Icons.account_balance,
    description: 'Regular bank account for savings or checking.',
    color: Colors.blue,
    isSavings: false,
  ),
  cash(
    name: 'Cash',
    icon: Icons.money,
    description: 'Physical cash you carry or keep at home.',
    color: Colors.green,
    isSavings: false,
  ),
  mobileMoney(
    name: 'Mobile Money',
    icon: Icons.phone_android,
    description: 'Mobile wallet like M-Pesa or Airtel Money.',
    color: Colors.orange,
    isSavings: false,
  ),
  creditCard(
    name: 'Credit Card',
    icon: Icons.credit_card,
    description: 'Credit account with borrowing limit.',
    color: Colors.red,
    isSavings: false,
  ),
  savings(
    name: 'Savings Account',
    icon: Icons.savings,
    description: 'Dedicated savings account for goals.',
    color: Colors.teal,
    isSavings: true,
  );

  const AccountType({
    required this.name,
    required this.icon,
    required this.description,
    required this.color,
    required this.isSavings,
  });

  final String name;
  final IconData icon;
  final String description;
  final Color color;

  final bool isSavings;

  String toStorageString() => switch (this) {
    AccountType.bank => 'bank',
    AccountType.cash => 'cash',
    AccountType.mobileMoney => 'mobileMoney',
    AccountType.creditCard => 'creditCard',
    AccountType.savings => 'savings',
  };

  static AccountType fromStorageString(String? value) => switch (value) {
    'bank' => AccountType.bank,
    'cash' => AccountType.cash,
    'mobileMoney' => AccountType.mobileMoney,
    'creditCard' => AccountType.creditCard,
    'savings' => AccountType.savings,
    _ => AccountType.cash,
  };
}
