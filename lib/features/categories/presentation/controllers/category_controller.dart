import 'dart:async';

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

  final Set<String> _pendingDeleteIds = {};
  Timer? _commitTimer;

  @override
  Future<List<CategoryEntity>> build() async {
    _seed = ref.read(seedDefaultCategoriesUseCaseProvider);
    _watch = ref.read(watchCategoriesUseCaseProvider);
    _create = ref.read(createCategoryUseCaseProvider);
    _update = ref.read(updateCategoryUseCaseProvider);
    _delete = ref.read(deleteCategoryUseCaseProvider);

    ref.onDispose(() => _commitTimer?.cancel());

    await _seed();

    final sub = _watch().listen((categories) {
      final filtered = _pendingDeleteIds.isEmpty
          ? categories
          : categories.where((c) => !_pendingDeleteIds.contains(c.id)).toList();
      state = AsyncData(filtered);
    }, onError: (e, st) => state = AsyncError(e, st));
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

  Future<void> Function() deleteCategoryWithUndo(
    CategoryEntity category, {
    Duration undoWindow = const Duration(seconds: 4),
    void Function()? onCommitted,
  }) {
    _pendingDeleteIds.add(category.id);
    final current = state.value ?? [];
    state = AsyncData(current.where((c) => c.id != category.id).toList());

    _commitTimer?.cancel();
    var cancelled = false;

    _commitTimer = Timer(undoWindow, () async {
      if (cancelled) return;
      onCommitted?.call();
      _pendingDeleteIds.remove(category.id);
      try {
        await _delete(category.id);
      } catch (e, st) {
        _pendingDeleteIds.remove(category.id);
        state = AsyncError(e, st);
      }
    });

    return () async {
      cancelled = true;
      _commitTimer?.cancel();
      _pendingDeleteIds.remove(category.id);
      final restored = List<CategoryEntity>.from(state.value ?? []);
      final insertIdx = restored.indexWhere(
        (c) => !category.isDefault && c.isDefault,
      );
      if (insertIdx == -1) {
        restored.add(category);
      } else {
        restored.insert(insertIdx, category);
      }
      state = AsyncData(restored);
    };
  }
}
