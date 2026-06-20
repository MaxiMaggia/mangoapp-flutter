import 'category.dart';

// Contrato para acceder a las categorias de gastos (la data real la pone Firestore).
abstract interface class CategoriesRepository {
  // Trae todas las categorias del usuario (sin paginar; lo usa el dropdown del form).
  Future<List<Category>> getAllCategories(String userId);

  /// Trae una pagina de categorias con cursor, ordenadas por titleLower.
  /// El cursor [lastTitleLower] es el titleLower del ultimo item ya cargado
  /// (null para la primera pagina). Lo usa la pantalla de lista de categorias.
  Future<List<Category>> getCategoriesPaginated({
    required String userId,
    required int limit,
    String? lastTitleLower,
  });
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
}
