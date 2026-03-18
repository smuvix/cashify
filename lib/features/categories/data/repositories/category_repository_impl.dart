import '../../data/models/category_model.dart';
import '../../data/services/category_remote_service.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  const CategoryRepositoryImpl(this._service);

  final CategoryRemoteService _service;

  @override
  Stream<List<CategoryEntity>> watchCategories() => _service.watchCategories();

  @override
  Future<void> seedDefaults() => _service.seedDefaultsIfNeeded();

  @override
  Future<void> createCategory(CategoryEntity entity) =>
      _service.createCategory(CategoryModel.fromEntity(entity));

  @override
  Future<void> updateCategory(CategoryEntity entity) =>
      _service.updateCategory(CategoryModel.fromEntity(entity));

  @override
  Future<void> deleteCategory(String id) => _service.softDeleteCategory(id);
}
