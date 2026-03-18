import 'package:flutter/material.dart';

import '../../features/categories/domain/entities/category_type.dart';

class DefaultCategoryTemplate {
  const DefaultCategoryTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.icon,
    required this.color,
  });

  final String id;
  final String name;
  final String description;
  final CategoryType type;
  final IconData icon;
  final Color color;
}

const List<DefaultCategoryTemplate> kDefaultCategories = [
  DefaultCategoryTemplate(
    id: 'default_salary',
    name: 'Salary',
    description: 'Monthly wages or employment income.',
    type: CategoryType.income,
    icon: Icons.work_outline,
    color: Colors.green,
  ),
  DefaultCategoryTemplate(
    id: 'default_freelance',
    name: 'Freelance',
    description: 'Income from contract or freelance work.',
    type: CategoryType.income,
    icon: Icons.laptop_outlined,
    color: Colors.teal,
  ),
  DefaultCategoryTemplate(
    id: 'default_business',
    name: 'Business',
    description: 'Revenue from a business or side hustle.',
    type: CategoryType.income,
    icon: Icons.storefront_outlined,
    color: Colors.cyan,
  ),
  DefaultCategoryTemplate(
    id: 'default_investment',
    name: 'Investment',
    description: 'Returns from stocks, bonds, or savings.',
    type: CategoryType.income,
    icon: Icons.trending_up_rounded,
    color: Colors.lightGreen,
  ),
  DefaultCategoryTemplate(
    id: 'default_gift_income',
    name: 'Gift',
    description: 'Money received as a gift or donation.',
    type: CategoryType.income,
    icon: Icons.card_giftcard_outlined,
    color: Colors.lime,
  ),
  DefaultCategoryTemplate(
    id: 'default_rental',
    name: 'Rental Income',
    description: 'Income from renting out property.',
    type: CategoryType.income,
    icon: Icons.house_outlined,
    color: Colors.green,
  ),
  DefaultCategoryTemplate(
    id: 'default_other_income',
    name: 'Other Income',
    description: 'Any other source of income.',
    type: CategoryType.income,
    icon: Icons.add_circle_outline,
    color: Colors.greenAccent,
  ),

  DefaultCategoryTemplate(
    id: 'default_food',
    name: 'Food & Dining',
    description: 'Groceries, restaurants, and takeout.',
    type: CategoryType.expense,
    icon: Icons.restaurant_outlined,
    color: Colors.orange,
  ),
  DefaultCategoryTemplate(
    id: 'default_transport',
    name: 'Transport',
    description: 'Fuel, public transit, ride-hailing, and parking.',
    type: CategoryType.expense,
    icon: Icons.directions_car_outlined,
    color: Colors.blue,
  ),
  DefaultCategoryTemplate(
    id: 'default_housing',
    name: 'Housing',
    description: 'Rent, mortgage, and home maintenance.',
    type: CategoryType.expense,
    icon: Icons.home_outlined,
    color: Colors.brown,
  ),
  DefaultCategoryTemplate(
    id: 'default_utilities',
    name: 'Utilities',
    description: 'Electricity, water, internet, and phone bills.',
    type: CategoryType.expense,
    icon: Icons.bolt_outlined,
    color: Colors.amber,
  ),
  DefaultCategoryTemplate(
    id: 'default_health',
    name: 'Health & Medical',
    description: 'Doctor visits, pharmacy, and insurance.',
    type: CategoryType.expense,
    icon: Icons.local_hospital_outlined,
    color: Colors.red,
  ),
  DefaultCategoryTemplate(
    id: 'default_education',
    name: 'Education',
    description: 'School fees, books, and courses.',
    type: CategoryType.expense,
    icon: Icons.school_outlined,
    color: Colors.indigo,
  ),
  DefaultCategoryTemplate(
    id: 'default_shopping',
    name: 'Shopping',
    description: 'Clothing, electronics, and general purchases.',
    type: CategoryType.expense,
    icon: Icons.shopping_bag_outlined,
    color: Colors.pink,
  ),
  DefaultCategoryTemplate(
    id: 'default_entertainment',
    name: 'Entertainment',
    description: 'Movies, streaming, hobbies, and events.',
    type: CategoryType.expense,
    icon: Icons.movie_outlined,
    color: Colors.purple,
  ),
  DefaultCategoryTemplate(
    id: 'default_savings',
    name: 'Savings',
    description: 'Transfers to savings or investment accounts.',
    type: CategoryType.expense,
    icon: Icons.savings_outlined,
    color: Colors.teal,
  ),
  DefaultCategoryTemplate(
    id: 'default_other_expense',
    name: 'Other Expense',
    description: 'Any other expense not listed above.',
    type: CategoryType.expense,
    icon: Icons.more_horiz_rounded,
    color: Colors.grey,
  ),
];
