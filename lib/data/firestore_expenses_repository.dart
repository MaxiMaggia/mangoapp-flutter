import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/expense.dart';
import '../domain/expenses_repository.dart';

class FirestoreExpensesRepositoryImpl implements ExpensesRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<List<Expense>> getExpenses({
    required String userId,
    int limit = 20,
    DateTime? lastCreatedAt,
  }) async {
    Query query = _db
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (lastCreatedAt != null) {
      query = query.startAfter([lastCreatedAt]);
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => Expense.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }))
        .toList();
  }

  @override
  Future<Expense?> getExpenseById(String id) async {
    final doc = await _db.collection('expenses').doc(id).get();
    if (!doc.exists) return null;
    return Expense.fromJson({
      ...doc.data() as Map<String, dynamic>,
      'id': doc.id,
    });
  }

  @override
  Future<Expense> insertExpense(Expense expense) async {
    final ref = await _db.collection('expenses').add(expense.toJson());
    final doc = await ref.get();
    return Expense.fromJson({
      ...doc.data() as Map<String, dynamic>,
      'id': doc.id,
    });
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    await _db.collection('expenses').doc(expense.id).update(expense.toJson());
  }

  @override
  Future<void> deleteExpenseById(String id) async {
    await _db.collection('expenses').doc(id).delete();
  }

  @override
  Future<List<Expense>> getExpensesInRange({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    final snapshot = await _db
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: from)
        .where('date', isLessThanOrEqualTo: to)
        .get();
    return snapshot.docs
        .map((doc) => Expense.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }))
        .toList();
  }
}
