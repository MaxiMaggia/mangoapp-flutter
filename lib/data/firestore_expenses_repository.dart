import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/entity_status.dart';
import '../domain/expense.dart';
import '../domain/expenses_repository.dart';

class FirestoreExpensesRepositoryImpl implements ExpensesRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late final CollectionReference<Expense> _col = _db
      .collection('expenses')
      .withConverter<Expense>(
        fromFirestore: Expense.fromFirestore,
        toFirestore: (expense, _) => expense.toFirestore(),
      );

  @override
  Future<List<Expense>> getExpenses({
    required String userId,
    int limit = 20,
    DateTime? lastCreatedAt,
  }) async {
    Query<Expense> query = _col
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
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    final expense = doc.data();
    if (expense == null || expense.status == EntityStatus.deleted) return null;
    return expense;
  }

  @override
  Future<Expense> insertExpense(Expense expense) async {
    final ref = await _col.add(expense);
    final doc = await ref.get();
    return doc.data()!;
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    final updated = expense.copyWith(updatedAt: DateTime.now());
    await _col.doc(updated.id).set(updated);
  }

  @override
  Future<void> deleteExpenseById(String id) async {
    await _col.doc(id).update({
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
    final snapshot = await _col
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: EntityStatus.available.name)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
