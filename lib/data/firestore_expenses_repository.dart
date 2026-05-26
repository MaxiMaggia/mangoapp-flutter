import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entity_status.dart';
import '../domain/expense.dart';
import '../domain/expenses_repository.dart';

class FirestoreExpensesRepositoryImpl implements ExpensesRepository {
  FirestoreExpensesRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Expense> get _collection =>
      _firestore.collection('expenses').withConverter<Expense>(
            fromFirestore: Expense.fromFirestore,
            toFirestore: (expense, _) => expense.toFirestore(),
          );

  @override
  Future<List<Expense>> getExpenses({
    required String userId,
    int limit = 20,
    DateTime? lastCreatedAt,
  }) async {
    Query<Expense> query = _collection
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: EntityStatus.available.name)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastCreatedAt != null) {
      query = query.startAfter([Timestamp.fromDate(lastCreatedAt)]);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

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

  @override
  Future<Expense> insertExpense(Expense expense) async {
    final doc = await _collection.add(expense);
    return expense.copyWith(id: doc.id);
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    final id = expense.id;
    if (id == null || id.isEmpty) {
      throw Exception('No se puede actualizar un gasto sin id.');
    }
    final updated = expense.copyWith(updatedAt: DateTime.now());
    await _collection.doc(id).set(updated, SetOptions(merge: true));
  }

  @override
  Future<void> deleteExpenseById(String id) async {
    await _collection.doc(id).update({
      'status': EntityStatus.deleted.name,
      'updatedAt': Timestamp.now(),
    });
  }

  @override
  Future<List<Expense>> getExpensesInRange({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: EntityStatus.available.name)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('date')
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
