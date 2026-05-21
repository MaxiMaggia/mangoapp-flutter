import 'category.dart';

abstract interface class CategoriesRepository {
  Future<List<Category>> getAllCategories(String userId);
  Future<Category?> getCategoryById(String id);
  Future<Category> insertCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategoryById(String id);
  Future<void> seedDefaultCategories(String userId);
}
