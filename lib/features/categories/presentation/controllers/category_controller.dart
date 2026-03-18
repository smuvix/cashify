import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/category_entity.dart';
import '../../domain/entities/category_type.dart';
import '../../domain/usecases/category_use_cases.dart';
import '../providers/category_providers.dart';

class CategoryController extends AsyncNotifier<List<CategoryEntity>> {
  late SeedDefaultCategoriesUseCase _seed;
  late WatchCategoriesUseCase _watch;
  late CreateCategoryUseCase _create;
  late UpdateCategoryUseCase _update;
  late DeleteCategoryUseCase _delete;

  @override
  Future<List<CategoryEntity>> build() async {
    _seed = ref.read(seedDefaultCategoriesUseCaseProvider);
    _watch = ref.read(watchCategoriesUseCaseProvider);
    _create = ref.read(createCategoryUseCaseProvider);
    _update = ref.read(updateCategoryUseCaseProvider);
    _delete = ref.read(deleteCategoryUseCaseProvider);

    await _seed();

    final sub = _watch().listen(
      (categories) => state = AsyncData(categories),
      onError: (e, st) => state = AsyncError(e, st),
    );
    ref.onDispose(sub.cancel);

    return _watch().first;
  }

  Future<void> createCategory({
    required String name,
    required String description,
    required CategoryType type,
    required IconData icon,
    required Color color,
  }) async {
    await _create(
      name: name,
      description: description,
      type: type,
      icon: icon,
      color: color,
    );
  }

  Future<void> updateCategory(
    CategoryEntity current, {
    String? name,
    String? description,
    CategoryType? type,
    IconData? icon,
    Color? color,
  }) async {
    await _update(
      current,
      name: name,
      description: description,
      type: type,
      icon: icon,
      color: color,
    );
  }

  Future<void> deleteCategory(String id) => _delete(id);
}
