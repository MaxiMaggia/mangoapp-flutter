import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/categories_repository.dart';
import '../domain/category.dart';
import '../domain/entity_status.dart';

class FirestoreCategoriesRepositoryImpl implements CategoriesRepository {
  FirestoreCategoriesRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Category> get _collection =>
      _firestore.collection('categories').withConverter<Category>(
            fromFirestore: Category.fromFirestore,
            toFirestore: (category, _) => {
              ...category.toFirestore(),
              'titleLower': category.title.trim().toLowerCase(),
            },
          );

  @override
  Future<List<Category>> getAllCategories(String userId) async {
    try {
      final snapshot = await _collection
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: EntityStatus.available.name)
          .orderBy('titleLower')
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } on FirebaseException catch (error) {
      if (error.code != 'failed-precondition') rethrow;

      final snapshot =
          await _collection.where('userId', isEqualTo: userId).get();
      final categories = snapshot.docs
          .map((doc) => doc.data())
          .where((category) => category.status == EntityStatus.available)
          .toList()
        ..sort((a, b) =>
            a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      return categories;
    }
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    final category = doc.data();
    if (category == null || category.status == EntityStatus.deleted) {
      return null;
    }
    return category;
  }

  @override
  Future<Category> insertCategory(Category category) async {
    final doc = await _collection.add(category);
    return category.copyWith(id: doc.id);
  }

  @override
  Future<void> updateCategory(Category category) async {
    final id = category.id;
    if (id == null || id.isEmpty) {
      throw Exception('No se puede actualizar una categoria sin id.');
    }
    final updated = category.copyWith(updatedAt: DateTime.now());
    await _collection.doc(id).set(updated, SetOptions(merge: true));
  }

  @override
  Future<void> deleteCategoryById(String id) async {
    await _collection.doc(id).update({
      'status': EntityStatus.deleted.name,
      'updatedAt': Timestamp.now(),
    });
  }

  @override
  Future<void> seedDefaultCategories(String userId) async {
    final existing = await getAllCategories(userId);
    if (existing.isNotEmpty) return;

    final batch = _firestore.batch();
    final now = DateTime.now();
    final defaults = [
      Category(
        userId: userId,
        title: 'Comida',
        iconKey: 'food',
        colorValue: 0xFFEF4444,
        createdAt: now,
      ),
      Category(
        userId: userId,
        title: 'Transporte',
        iconKey: 'transport',
        colorValue: 0xFF3B82F6,
        createdAt: now,
      ),
      Category(
        userId: userId,
        title: 'Entretenimiento',
        iconKey: 'entertainment',
        colorValue: 0xFFA855F7,
        createdAt: now,
      ),
      Category(
        userId: userId,
        title: 'Hogar',
        iconKey: 'home',
        colorValue: 0xFF10B981,
        createdAt: now,
      ),
      Category(
        userId: userId,
        title: 'Salud',
        iconKey: 'health',
        colorValue: 0xFF14B8A6,
        createdAt: now,
      ),
    ];

    for (final category in defaults) {
      final ref = _collection.doc();
      batch.set(ref, category);
    }
    await batch.commit();
  }
}
