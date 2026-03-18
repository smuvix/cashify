import 'package:flutter/material.dart';

import 'category_type.dart';
import '../../../../core/constants/default_categories.dart';

class CategoryEntity {
  const CategoryEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.type,
    required this.icon,
    required this.color,
    required this.isDefault,
    required this.isDeleted,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  final String userId;

  final String name;
  final String description;
  final CategoryType type;
  final IconData icon;
  final Color color;

  final bool isDefault;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryEntity copyWith({
    String? name,
    String? description,
    CategoryType? type,
    IconData? icon,
    Color? color,
    bool? isDeleted,
    DateTime? deletedAt,
    DateTime? updatedAt,
  }) => CategoryEntity(
    id: id,
    userId: userId,
    name: name ?? this.name,
    description: description ?? this.description,
    type: type ?? this.type,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    isDefault: isDefault,
    isDeleted: isDeleted ?? this.isDeleted,
    deletedAt: deletedAt ?? this.deletedAt,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  factory CategoryEntity.fromDefault(DefaultCategoryTemplate template) {
    final now = DateTime.fromMillisecondsSinceEpoch(0);
    return CategoryEntity(
      id: template.id,
      userId: '',
      name: template.name,
      description: template.description,
      type: template.type,
      icon: template.icon,
      color: template.color,
      isDefault: true,
      isDeleted: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  bool operator ==(Object other) => other is CategoryEntity && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CategoryEntity(id: $id, name: $name, type: ${type.name})';
}
