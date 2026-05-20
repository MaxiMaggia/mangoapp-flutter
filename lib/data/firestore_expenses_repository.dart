import 'package:cloud_firestore/cloud_firestore.dart';
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
    return doc.data();
  }

  @override
  Future<Expense> insertExpense(Expense expense) async {
    final ref = await _col.add(expense);
    final doc = await ref.get();
    return doc.data()!;
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    await _col.doc(expense.id).update(expense.toFirestore());
  }

  @override
  Future<void> deleteExpenseById(String id) async {
    await _col.doc(id).delete();
  }

  @override
  Future<List<Expense>> getExpensesInRange({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    final snapshot = await _col
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
