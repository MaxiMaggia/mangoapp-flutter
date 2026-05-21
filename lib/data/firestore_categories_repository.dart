import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/categories_repository.dart';
import '../domain/category.dart';
import '../domain/entity_status.dart';

class FirestoreCategoriesRepositoryImpl implements CategoriesRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late final CollectionReference<Category> _col = _db
      .collection('categories')
      .withConverter<Category>(
        fromFirestore: Category.fromFirestore,
        toFirestore: (category, _) => category.toFirestore(),
      );

  @override
  Future<List<Category>> getAllCategories(String userId) async {
    final snapshot = await _col
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: EntityStatus.available.name)
        .orderBy('title')
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    final category = doc.data();
    if (category == null || category.status == EntityStatus.deleted) {
      return null;
    }
    return category;
  }

  @override
  Future<Category> insertCategory(Category category) async {
    final ref = await _col.add(category);
    final doc = await ref.get();
    return doc.data()!;
  }

  @override
  Future<void> updateCategory(Category category) async {
    final updated = category.copyWith(updatedAt: DateTime.now());
    await _col.doc(updated.id).set(updated);
  }

  @override
  Future<void> deleteCategoryById(String id) async {
    await _col.doc(id).update({
      'status': EntityStatus.deleted.name,
      'updatedAt': Timestamp.now(),
    });
  }
}
