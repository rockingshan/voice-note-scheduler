import '../../domain/entities/category.dart';

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
