import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/expense.dart';
import '../domain/expenses_repository.dart';

class FirestoreExpensesRepositoryImpl implements ExpensesRepository {
  FirestoreExpensesRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Expense> get _collection =>
      _firestore.collection('expenses').withConverter<Expense>(
            fromFirestore: (snapshot, _) =>
                _expenseFromFirestore(snapshot.id, snapshot.data() ?? {}),
            toFirestore: (expense, _) => _expenseToFirestore(expense),
          );

  @override
  Future<List<Expense>> getExpenses({
    required String userId,
    int limit = 20,
    DateTime? lastCreatedAt,
  }) async {
    Query<Expense> query = _collection
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
    final doc = await _collection.doc(id).get();
    return doc.data();
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
    await _collection.doc(id).set(expense, SetOptions(merge: true));
  }

  @override
  Future<void> deleteExpenseById(String id) => _collection.doc(id).delete();

  @override
  Future<List<Expense>> getExpensesInRange({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('date')
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  static Expense _expenseFromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final currencyName = data['currency'] as String? ?? Currency.ars.name;
    final currency = Currency.values.firstWhere(
      (value) => value.name == currencyName,
      orElse: () => Currency.ars,
    );

    return Expense(
      id: id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      amountArs: _numToDouble(data['amountArs']),
      originalAmount: data['originalAmount'] == null
          ? null
          : _numToDouble(data['originalAmount']),
      currency: currency,
      dolarType: data['dolarType'] as String?,
      date: _dateFromFirestore(data['date']),
      attachmentUrl: data['attachmentUrl'] as String?,
      createdAt: _dateFromFirestore(data['createdAt']),
      updatedAt: data['updatedAt'] == null
          ? null
          : _dateFromFirestore(data['updatedAt']),
    );
  }

  static Map<String, Object?> _expenseToFirestore(Expense expense) => {
        'userId': expense.userId,
        'name': expense.name,
        'categoryId': expense.categoryId,
        'amountArs': expense.amountArs,
        'originalAmount': expense.originalAmount,
        'currency': expense.currency.name,
        'dolarType': expense.dolarType,
        'date': Timestamp.fromDate(expense.date),
        'attachmentUrl': expense.attachmentUrl,
        'createdAt': Timestamp.fromDate(expense.createdAt),
        'updatedAt': expense.updatedAt == null
            ? null
            : Timestamp.fromDate(expense.updatedAt!),
      };

  static DateTime _dateFromFirestore(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  static double _numToDouble(Object? value) {
    if (value is num) return value.toDouble();
    return 0;
  }
}
