import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entity_status.dart';
import '../domain/expense.dart';
import '../domain/expenses_repository.dart';

// Maneja los gastos en Firestore (colección 'expenses'): listar, crear, editar y borrar.
class FirestoreExpensesRepositoryImpl implements ExpensesRepository {
  // Si no te pasan Firestore, usa la instancia default de la app.
  FirestoreExpensesRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // Atajo a la colección 'expenses' ya tipada como Expense.
  CollectionReference<Expense> get _collection =>
      _firestore.collection('expenses').withConverter<Expense>(
            fromFirestore: Expense.fromFirestore,
            toFirestore: (expense, _) => expense.toFirestore(),
          );

  // Trae una tanda de gastos del usuario (paginado): de a `limit`, los mas nuevos primero.
  @override
  Future<List<Expense>> getExpenses({
    required String userId,
    int limit = 20,
    DateTime? lastCreatedAt,
  }) async {
    try {
      Query<Expense> query = _collection
          .where('userId', isEqualTo: userId)
          // Solo los disponibles: dejamos afuera los borrados logicamente.
          .where('status', isEqualTo: EntityStatus.available.name)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      // Si nos pasan el cursor, arrancamos despues del ultimo gasto que ya trajimos.
      if (lastCreatedAt != null) {
        query = query.startAfter([Timestamp.fromDate(lastCreatedAt)]);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } on FirebaseException catch (error) {
      // Si Firestore todavia no tiene el indice compuesto, filtramos y ordenamos a mano.
      if (error.code != 'failed-precondition') rethrow;

      final snapshot =
          await _collection.where('userId', isEqualTo: userId).get();
      final expenses = snapshot.docs
          .map((doc) => doc.data())
          .where((expense) => expense.status == EntityStatus.available)
          .where((expense) =>
              lastCreatedAt == null || expense.createdAt.isBefore(lastCreatedAt))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return expenses.take(limit).toList();
    }
  }

  // Busca un gasto por id; devuelve null si no existe o si esta borrado.
  @override
  Future<Expense?> getExpenseById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    final expense = doc.data();
    if (expense == null || expense.status == EntityStatus.deleted) {
      return null;
    }
    return expense;
  }

  // Crea un gasto nuevo y lo devuelve ya con el id que le asigno Firestore.
  @override
  Future<Expense> insertExpense(Expense expense) async {
    // Generamos la referencia primero para poder guardar el id adentro del doc.
    final ref = _collection.doc();
    final withId = expense.copyWith(id: ref.id);
    await ref.set(withId);
    return withId;
  }

  // Guarda los cambios de un gasto existente (y le marca cuando se edito).
  @override
  Future<void> updateExpense(Expense expense) async {
    final id = expense.id;
    if (id == null || id.isEmpty) {
      throw Exception('No se puede actualizar un gasto sin id.');
    }
    final updated = expense.copyWith(updatedAt: DateTime.now());
    await _collection.doc(id).set(updated, SetOptions(merge: true));
  }

  // Borra un gasto, pero "logicamente": solo le cambia el status a deleted.
  @override
  Future<void> deleteExpenseById(String id) async {
    await _collection.doc(id).update({
      'status': EntityStatus.deleted.name,
      'deletedAt': Timestamp.now(),
    });
  }

  // Trae los gastos del usuario entre dos fechas (lo usa la pantalla de estadisticas).
  @override
  Future<List<Expense>> getExpensesInRange({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final snapshot = await _collection
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: EntityStatus.available.name)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(to))
          .orderBy('date')
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } on FirebaseException catch (error) {
      // Mismo fallback que arriba: si falta el indice, filtramos en memoria.
      if (error.code != 'failed-precondition') rethrow;

      final snapshot =
          await _collection.where('userId', isEqualTo: userId).get();
      final expenses = snapshot.docs
          .map((doc) => doc.data())
          .where((expense) => expense.status == EntityStatus.available)
          .where((expense) =>
              !expense.date.isBefore(from) && !expense.date.isAfter(to))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      return expenses;
    }
  }
}
