import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/category.dart';

abstract class CategoryDatasource {
  Future<void> createCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(String id);
  Future<Category?> getCategoryById(String id);
  Future<List<Category>> getAllCategories();
  Future<Category?> getDefaultCategory();
  Stream<List<Category>> watchAllCategories();
}

class HiveCategoryDatasource implements CategoryDatasource {
  static const String categoryBoxName = 'categories_box';
  late Box<Category> _categoriesBox;

  HiveCategoryDatasource() {
    _categoriesBox = Hive.box<Category>(categoryBoxName);
  }

  @override
  Future<void> createCategory(Category category) async {
    await _categoriesBox.put(category.id, category);
  }

  @override
  Future<void> updateCategory(Category category) async {
    await _categoriesBox.put(category.id, category);
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _categoriesBox.delete(id);
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    return _categoriesBox.get(id);
  }

  @override
  Future<List<Category>> getAllCategories() async {
    return _categoriesBox.values.toList();
  }

  @override
  Future<Category?> getDefaultCategory() async {
    for (final category in _categoriesBox.values) {
      if (category.isDefault) {
        return category;
      }
    }
    return null;
  }

  @override
  Stream<List<Category>> watchAllCategories() {
    return _categoriesBox.watch().map((_) => _categoriesBox.values.toList());
  }
}
