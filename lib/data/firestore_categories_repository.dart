import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/categories_repository.dart';
import '../domain/category.dart';

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
        .orderBy('title')
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  @override
  Future<Category> insertCategory(Category category) async {
    final ref = await _col.add(category);
    final doc = await ref.get();
    return doc.data()!;
  }

  @override
  Future<void> updateCategory(Category category) async {
    await _col.doc(category.id).update(category.toFirestore());
  }

  @override
  Future<void> deleteCategoryById(String id) async {
    await _col.doc(id).delete();
  }
}
