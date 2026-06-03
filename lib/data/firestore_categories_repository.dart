import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/categories_repository.dart';
import '../domain/category.dart';
import '../domain/entity_status.dart';

// Maneja las categorias en Firestore (coleccion 'categories'): listar, crear, editar y borrar.
class FirestoreCategoriesRepositoryImpl implements CategoriesRepository {
  // Si no te pasan Firestore, usa la instancia default de la app.
  FirestoreCategoriesRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // Atajo a la coleccion 'categories' ya tipada como Category.
  CollectionReference<Category> get _collection =>
      _firestore.collection('categories').withConverter<Category>(
            fromFirestore: Category.fromFirestore,
            toFirestore: (category, _) => {
              ...category.toFirestore(),
              // Guardamos el titulo en minuscula aparte para poder ordenar sin importar mayusculas.
              'titleLower': category.title.trim().toLowerCase(),
            },
          );

  // Trae todas las categorias disponibles del usuario, ordenadas alfabeticamente.
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
      // Si todavia falta el indice compuesto, filtramos y ordenamos a mano.
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

  // Busca una categoria por id; devuelve null si no existe o esta borrada.
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

  // Crea una categoria nueva y la devuelve ya con su id.
  @override
  Future<Category> insertCategory(Category category) async {
    // Generamos la referencia primero para poder guardar el id adentro del doc.
    final ref = _collection.doc();
    final withId = category.copyWith(id: ref.id);
    await ref.set(withId);
    return withId;
  }

  // Guarda los cambios de una categoria existente (y marca cuando se edito).
  @override
  Future<void> updateCategory(Category category) async {
    final id = category.id;
    if (id == null || id.isEmpty) {
      throw Exception('No se puede actualizar una categoria sin id.');
    }
    final updated = category.copyWith(updatedAt: DateTime.now());
    await _collection.doc(id).set(updated, SetOptions(merge: true));
  }

  // Borra una categoria de forma logica: solo le cambia el status a deleted.
  @override
  Future<void> deleteCategoryById(String id) async {
    await _collection.doc(id).update({
      'status': EntityStatus.deleted.name,
      'deletedAt': Timestamp.now(),
    });
  }

  // Marca todas las categorias del usuario como borradas (usado al eliminar la cuenta).
  @override
  Future<void> markAllUserCategoriesAsDeleted(String userId) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: EntityStatus.available.name)
        .get();
    if (snapshot.docs.isEmpty) return;

    // Todo en un batch para que sea una sola operacion atomica.
    final batch = _firestore.batch();
    final now = Timestamp.now();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'status': EntityStatus.deleted.name,
        'deletedAt': now,
      });
    }
    await batch.commit();
  }

  // Le crea al usuario nuevo un set de categorias por defecto (comida, transporte, etc.).
  @override
  Future<void> seedDefaultCategories(String userId) async {
    // Si ya tiene categorias no hacemos nada, para no duplicar.
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
      batch.set(ref, category.copyWith(id: ref.id));
    }
    await batch.commit();
  }
}
