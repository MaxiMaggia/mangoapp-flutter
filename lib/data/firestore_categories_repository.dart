import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/categories_repository.dart';
import '../domain/category.dart';

class FirestoreCategoriesRepositoryImpl implements CategoriesRepository {
  FirestoreCategoriesRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Category> get _collection =>
      _firestore.collection('categories').withConverter<Category>(
            fromFirestore: (snapshot, _) =>
                _categoryFromFirestore(snapshot.id, snapshot.data() ?? {}),
            toFirestore: (category, _) => _categoryToFirestore(category),
          );

  @override
  Future<List<Category>> getAllCategories(String userId) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .orderBy('titleLower')
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    final doc = await _collection.doc(id).get();
    return doc.data();
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
    await _collection.doc(id).set(category, SetOptions(merge: true));
  }

  @override
  Future<void> deleteCategoryById(String id) => _collection.doc(id).delete();

  static Category _categoryFromFirestore(
    String id,
    Map<String, dynamic> data,
  ) =>
      Category(
        id: id,
        userId: data['userId'] as String? ?? '',
        title: data['title'] as String? ?? '',
        iconKey: data['iconKey'] as String? ?? 'other',
        colorValue: data['colorValue'] as int? ?? 0xFF6B7280,
        createdAt: _dateFromFirestore(data['createdAt']),
      );

  static Map<String, Object?> _categoryToFirestore(Category category) => {
        'userId': category.userId,
        'title': category.title,
        'titleLower': category.title.trim().toLowerCase(),
        'iconKey': category.iconKey,
        'colorValue': category.colorValue,
        'createdAt': Timestamp.fromDate(category.createdAt),
      };

  static DateTime _dateFromFirestore(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
