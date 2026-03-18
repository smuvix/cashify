import '../../domain/entities/category_entity.dart';

abstract interface class CategoryRepository {
  Stream<List<CategoryEntity>> watchCategories();

  Future<void> seedDefaults();

  Future<void> createCategory(CategoryEntity entity);

  Future<void> updateCategory(CategoryEntity entity);

  Future<void> deleteCategory(String id);
}
