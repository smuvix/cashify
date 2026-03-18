import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/category_entity.dart';
import '../../domain/entities/category_type.dart';
import '../../domain/repositories/category_repository.dart';


class SeedDefaultCategoriesUseCase {
  const SeedDefaultCategoriesUseCase(this._repository);
  final CategoryRepository _repository;

  Future<void> call() => _repository.seedDefaults();
}


class WatchCategoriesUseCase {
  const WatchCategoriesUseCase(this._repository);
  final CategoryRepository _repository;

  Stream<List<CategoryEntity>> call() => _repository.watchCategories();
}


class CreateCategoryUseCase {
  const CreateCategoryUseCase(this._repository);
  final CategoryRepository _repository;

  Future<CategoryEntity> call({
    required String name,
    required String description,
    required CategoryType type,
    required IconData icon,
    required Color color,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('No authenticated user found.');

    final now = DateTime.now();
    final entity = CategoryEntity(
      id: const Uuid().v4(),
      userId: uid,
      name: name.trim(),
      description: description.trim(),
      type: type,
      icon: icon,
      color: color,
      isDefault: false,
      isDeleted: false,
      createdAt: now,
      updatedAt: now,
    );

    await _repository.createCategory(entity);
    return entity;
  }
}


class UpdateCategoryUseCase {
  const UpdateCategoryUseCase(this._repository);
  final CategoryRepository _repository;

  Future<CategoryEntity> call(
    CategoryEntity current, {
    String? name,
    String? description,
    CategoryType? type,
    IconData? icon,
    Color? color,
  }) async {
    final updated = current.copyWith(
      name: name?.trim(),
      description: description?.trim(),
      type: type,
      icon: icon,
      color: color,
      updatedAt: DateTime.now(),
    );
    await _repository.updateCategory(updated);
    return updated;
  }
}


class DeleteCategoryUseCase {
  const DeleteCategoryUseCase(this._repository);
  final CategoryRepository _repository;

  Future<void> call(String id) => _repository.deleteCategory(id);
}
