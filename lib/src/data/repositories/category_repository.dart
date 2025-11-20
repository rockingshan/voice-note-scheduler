import 'package:flutter/material.dart';
import '../../domain/entities/category.dart';
import '../datasources/hive_category_datasource.dart';

abstract class CategoryRepository {
  Future<void> createCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(String id);
  Future<Category?> getCategoryById(String id);
  Future<List<Category>> getAllCategories();
  Future<Category?> getDefaultCategory();
  Future<void> setDefaultCategory(String categoryId);
  Stream<List<Category>> watchAllCategories();
  Future<Category> ensureDefaultCategory();
}

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryDatasource _datasource;

  CategoryRepositoryImpl(this._datasource);

  @override
  Future<void> createCategory(Category category) async {
    await _datasource.createCategory(category);
  }

  @override
  Future<void> updateCategory(Category category) async {
    if (category.isDefault) {
      final currentDefault = await _datasource.getDefaultCategory();
      if (currentDefault != null && currentDefault.id != category.id) {
        final updatedCurrentDefault = currentDefault.copyWith(isDefault: false);
        await _datasource.updateCategory(updatedCurrentDefault);
      }
    }
    await _datasource.updateCategory(category);
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _datasource.deleteCategory(id);
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    return _datasource.getCategoryById(id);
  }

  @override
  Future<List<Category>> getAllCategories() async {
    return _datasource.getAllCategories();
  }

  @override
  Future<Category?> getDefaultCategory() async {
    return _datasource.getDefaultCategory();
  }

  @override
  Future<void> setDefaultCategory(String categoryId) async {
    final category = await _datasource.getCategoryById(categoryId);
    if (category != null) {
      final currentDefault = await _datasource.getDefaultCategory();
      if (currentDefault != null && currentDefault.id != categoryId) {
        final updatedCurrentDefault = currentDefault.copyWith(isDefault: false);
        await _datasource.updateCategory(updatedCurrentDefault);
      }
      
      final updatedCategory = category.copyWith(isDefault: true);
      await _datasource.updateCategory(updatedCategory);
    }
  }

  @override
  Stream<List<Category>> watchAllCategories() {
    return _datasource.watchAllCategories();
  }

  @override
  Future<Category> ensureDefaultCategory() async {
    final existingDefault = await _datasource.getDefaultCategory();
    if (existingDefault != null) {
      return existingDefault;
    }

    final defaultCategory = Category(
      name: 'General',
      color: Colors.blue.value,
      isDefault: true,
      createdAt: DateTime.now(),
    );

    await _datasource.createCategory(defaultCategory);
    return defaultCategory;
  }
}
