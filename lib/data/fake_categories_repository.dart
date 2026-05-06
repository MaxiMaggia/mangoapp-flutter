import 'package:collection/collection.dart';

import '../domain/categories_repository.dart';
import '../domain/category.dart';
import '../presentation/utils/category_icons.dart';

class FakeCategoriesRepository implements CategoriesRepository {
  final List<Category> _categories;
  int _nextId;

  FakeCategoriesRepository()
      : _categories = _seed(),
        _nextId = _seed().length + 1;

  static List<Category> _seed() {
    return [
      Category(
        id: 'c_1',
        userId: 'u_demo',
        title: 'Comida',
        iconKey: CategoryIcons.food.key,
        colorValue: 0xFFEF4444,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Category(
        id: 'c_2',
        userId: 'u_demo',
        title: 'Transporte',
        iconKey: CategoryIcons.transport.key,
        colorValue: 0xFF3B82F6,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Category(
        id: 'c_3',
        userId: 'u_demo',
        title: 'Entretenimiento',
        iconKey: CategoryIcons.entertainment.key,
        colorValue: 0xFFA855F7,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Category(
        id: 'c_4',
        userId: 'u_demo',
        title: 'Hogar',
        iconKey: CategoryIcons.home.key,
        colorValue: 0xFF10B981,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Category(
        id: 'c_5',
        userId: 'u_demo',
        title: 'Educacion',
        iconKey: CategoryIcons.education.key,
        colorValue: 0xFFF59E0B,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Category(
        id: 'c_6',
        userId: 'u_demo',
        title: 'Salud',
        iconKey: CategoryIcons.health.key,
        colorValue: 0xFF14B8A6,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ];
  }

  @override
  Future<List<Category>> getAllCategories(String userId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _categories
        .where((c) => c.userId == userId)
        .sortedBy<String>((c) => c.title.toLowerCase())
        .toList();
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _categories.firstWhereOrNull((c) => c.id == id);
  }

  @override
  Future<Category> insertCategory(Category category) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final newCategory = category.copyWith(id: 'c_${_nextId++}');
    _categories.add(newCategory);
    return newCategory;
  }

  @override
  Future<void> updateCategory(Category category) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index >= 0) _categories[index] = category;
  }

  @override
  Future<void> deleteCategoryById(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _categories.removeWhere((c) => c.id == id);
  }
}
