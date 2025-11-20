import '../entities/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> getCategories();
  Future<Category?> getCategoryById(String id);
  Future<void> addCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(String id);
  Future<Category?> getDefaultCategory();
  Future<void> setDefaultCategory(String categoryId);
  Future<void> ensureDefaultCategory();
  Stream<List<Category>> watchCategories();
  Stream<Category?> watchDefaultCategory();
}