import 'category.dart';

// Contrato para acceder a las categorias de gastos (la data real la pone Firestore).
abstract interface class CategoriesRepository {
  // Trae todas las categorias del usuario.
  Future<List<Category>> getAllCategories(String userId);
  // Busca una categoria puntual por su id.
  Future<Category?> getCategoryById(String id);
  // Crea una categoria nueva y la devuelve ya con su id.
  Future<Category> insertCategory(Category category);
  // Guarda los cambios de una categoria existente.
  Future<void> updateCategory(Category category);
  // Borra (logicamente) una categoria por su id.
  Future<void> deleteCategoryById(String id);
  // Carga las categorias por defecto para un usuario recien creado.
  Future<void> seedDefaultCategories(String userId);

  /// Marca todas las categorias del usuario como deleted. Usado en el flujo
  /// de borrado de cuenta.
  Future<void> markAllUserCategoriesAsDeleted(String userId);
}
