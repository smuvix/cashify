import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/category_entity.dart';
import '../../domain/entities/category_type.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.description,
    required super.type,
    required super.icon,
    required super.color,
    required super.isDefault,
    required super.isDeleted,
    super.deletedAt,
    required super.createdAt,
    required super.updatedAt,
  });

  static const kId = 'id';
  static const kUserId = 'userId';
  static const kName = 'name';
  static const kDescription = 'description';
  static const kType = 'type';
  static const kIcon = 'icon';
  static const kColor = 'color';
  static const kIsDefault = 'isDefault';
  static const kIsDeleted = 'isDeleted';
  static const kDeletedAt = 'deletedAt';
  static const kCreatedAt = 'createdAt';
  static const kUpdatedAt = 'updatedAt';

  static Map<String, dynamic> _iconToMap(IconData icon) => {
    'codePoint': icon.codePoint,
    'fontFamily': icon.fontFamily ?? 'MaterialIcons',
    'fontPackage': icon.fontPackage,
    'matchTextDirection': icon.matchTextDirection,
  };

  static IconData _iconFromMap(Map<String, dynamic>? map) {
    if (map == null) return Icons.label_outline;
    return IconData(
      map['codePoint'] as int,
      fontFamily: map['fontFamily'] as String?,
      fontPackage: map['fontPackage'] as String?,
      matchTextDirection: map['matchTextDirection'] as bool? ?? false,
    );
  }

  factory CategoryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return CategoryModel(
      id: doc.id,
      userId: data[kUserId] as String? ?? '',
      name: data[kName] as String,
      description: data[kDescription] as String? ?? '',
      type: CategoryType.fromStorageString(data[kType] as String?),
      icon: _iconFromMap(data[kIcon] as Map<String, dynamic>?),
      color: Color(data[kColor] as int),
      isDefault: data[kIsDefault] as bool? ?? false,
      isDeleted: data[kIsDeleted] as bool? ?? false,
      deletedAt: (data[kDeletedAt] as Timestamp?)?.toDate(),
      createdAt: (data[kCreatedAt] as Timestamp).toDate(),
      updatedAt: (data[kUpdatedAt] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    kId: id,
    kUserId: userId,
    kName: name,
    kDescription: description,
    kType: type.toStorageString(),
    kIcon: _iconToMap(icon),
    kColor: color.toARGB32(),
    kIsDefault: isDefault,
    kIsDeleted: isDeleted,
    kDeletedAt: deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
    kCreatedAt: Timestamp.fromDate(createdAt),
    kUpdatedAt: Timestamp.fromDate(updatedAt),
  };

  factory CategoryModel.fromEntity(CategoryEntity entity) => CategoryModel(
    id: entity.id,
    userId: entity.userId,
    name: entity.name,
    description: entity.description,
    type: entity.type,
    icon: entity.icon,
    color: entity.color,
    isDefault: entity.isDefault,
    isDeleted: entity.isDeleted,
    deletedAt: entity.deletedAt,
    createdAt: entity.createdAt,
    updatedAt: entity.updatedAt,
  );
}
