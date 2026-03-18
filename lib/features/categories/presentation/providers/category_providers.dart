import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/category_repository_impl.dart';
import '../../data/services/category_remote_service.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/category_type.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/usecases/category_use_cases.dart';
import '../controllers/category_controller.dart';

final categoryRemoteServiceProvider = Provider<CategoryRemoteService>(
  (_) => CategoryRemoteServiceImpl(),
);

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepositoryImpl(ref.read(categoryRemoteServiceProvider)),
);

final seedDefaultCategoriesUseCaseProvider =
    Provider<SeedDefaultCategoriesUseCase>(
      (ref) =>
          SeedDefaultCategoriesUseCase(ref.read(categoryRepositoryProvider)),
    );

final watchCategoriesUseCaseProvider = Provider<WatchCategoriesUseCase>(
  (ref) => WatchCategoriesUseCase(ref.read(categoryRepositoryProvider)),
);

final createCategoryUseCaseProvider = Provider<CreateCategoryUseCase>(
  (ref) => CreateCategoryUseCase(ref.read(categoryRepositoryProvider)),
);

final updateCategoryUseCaseProvider = Provider<UpdateCategoryUseCase>(
  (ref) => UpdateCategoryUseCase(ref.read(categoryRepositoryProvider)),
);

final deleteCategoryUseCaseProvider = Provider<DeleteCategoryUseCase>(
  (ref) => DeleteCategoryUseCase(ref.read(categoryRepositoryProvider)),
);

final categoryProvider =
    AsyncNotifierProvider<CategoryController, List<CategoryEntity>>(
      CategoryController.new,
    );

final incomeCategoriesProvider = Provider<AsyncValue<List<CategoryEntity>>>(
  (ref) => ref
      .watch(categoryProvider)
      .whenData(
        (list) => list.where((c) => c.type == CategoryType.income).toList(),
      ),
);

final expenseCategoriesProvider = Provider<AsyncValue<List<CategoryEntity>>>(
  (ref) => ref
      .watch(categoryProvider)
      .whenData(
        (list) => list.where((c) => c.type == CategoryType.expense).toList(),
      ),
);

final customCategoriesProvider = Provider<AsyncValue<List<CategoryEntity>>>(
  (ref) => ref
      .watch(categoryProvider)
      .whenData((list) => list.where((c) => !c.isDefault).toList()),
);
