import 'package:collection/collection.dart';

import '../domain/expense.dart';
import '../domain/expenses_repository.dart';

class FakeExpensesRepository implements ExpensesRepository {
  final List<Expense> _expenses;
  int _nextId;

  FakeExpensesRepository()
      : _expenses = _seed(),
        _nextId = _seed().length + 1;

  /// Crea un set inicial de gastos distribuidos en los ultimos meses
  /// para que las estadisticas tengan datos que mostrar.
  static List<Expense> _seed() {
    final now = DateTime.now();
    return [
      // Mes actual
      Expense(
        id: 'e_1',
        userId: 'u_demo',
        name: 'Supermercado Coto',
        categoryId: 'c_1',
        amountArs: 28500,
        date: DateTime(now.year, now.month, 2),
        createdAt: DateTime(now.year, now.month, 2),
      ),
      Expense(
        id: 'e_2',
        userId: 'u_demo',
        name: 'SUBE',
        categoryId: 'c_2',
        amountArs: 5000,
        date: DateTime(now.year, now.month, 1),
        createdAt: DateTime(now.year, now.month, 1),
      ),
      Expense(
        id: 'e_3',
        userId: 'u_demo',
        name: 'Steam - juego nuevo',
        categoryId: 'c_3',
        amountArs: 18000,
        originalAmount: 14.99,
        currency: Currency.usd,
        dolarType: 'tarjeta',
        date: DateTime(now.year, now.month, 3),
        createdAt: DateTime(now.year, now.month, 3),
      ),
      Expense(
        id: 'e_4',
        userId: 'u_demo',
        name: 'Netflix',
        categoryId: 'c_3',
        amountArs: 7500,
        date: DateTime(now.year, now.month, 1),
        createdAt: DateTime(now.year, now.month, 1),
      ),
      Expense(
        id: 'e_5',
        userId: 'u_demo',
        name: 'Farmacia',
        categoryId: 'c_6',
        amountArs: 12300,
        date: DateTime(now.year, now.month, 2),
        createdAt: DateTime(now.year, now.month, 2),
      ),

      // Mes anterior
      Expense(
        id: 'e_6',
        userId: 'u_demo',
        name: 'Alquiler',
        categoryId: 'c_4',
        amountArs: 320000,
        date: DateTime(now.year, now.month - 1, 5),
        createdAt: DateTime(now.year, now.month - 1, 5),
      ),
      Expense(
        id: 'e_7',
        userId: 'u_demo',
        name: 'Supermercado',
        categoryId: 'c_1',
        amountArs: 95000,
        date: DateTime(now.year, now.month - 1, 10),
        createdAt: DateTime(now.year, now.month - 1, 10),
      ),
      Expense(
        id: 'e_8',
        userId: 'u_demo',
        name: 'Curso online',
        categoryId: 'c_5',
        amountArs: 45000,
        date: DateTime(now.year, now.month - 1, 15),
        createdAt: DateTime(now.year, now.month - 1, 15),
      ),

      // Hace 2 meses
      Expense(
        id: 'e_9',
        userId: 'u_demo',
        name: 'Uber',
        categoryId: 'c_2',
        amountArs: 18500,
        date: DateTime(now.year, now.month - 2, 8),
        createdAt: DateTime(now.year, now.month - 2, 8),
      ),
      Expense(
        id: 'e_10',
        userId: 'u_demo',
        name: 'Restaurante',
        categoryId: 'c_1',
        amountArs: 42000,
        date: DateTime(now.year, now.month - 2, 20),
        createdAt: DateTime(now.year, now.month - 2, 20),
      ),

      // Hace 4 meses
      Expense(
        id: 'e_11',
        userId: 'u_demo',
        name: 'Libros',
        categoryId: 'c_5',
        amountArs: 28000,
        date: DateTime(now.year, now.month - 4, 12),
        createdAt: DateTime(now.year, now.month - 4, 12),
      ),
      // Hace 6 meses
      Expense(
        id: 'e_12',
        userId: 'u_demo',
        name: 'Cine',
        categoryId: 'c_3',
        amountArs: 15000,
        date: DateTime(now.year, now.month - 6, 5),
        createdAt: DateTime(now.year, now.month - 6, 5),
      ),
    ];
  }

  @override
  Future<List<Expense>> getExpenses({
    required String userId,
    int limit = 20,
    DateTime? lastCreatedAt,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final all = _expenses
        .where((e) => e.userId == userId)
        .sortedBy<DateTime>((e) => e.createdAt)
        .reversed
        .toList();

    Iterable<Expense> filtered = all;
    if (lastCreatedAt != null) {
      filtered = all.where((e) => e.createdAt.isBefore(lastCreatedAt));
    }
    return filtered.take(limit).toList();
  }

  @override
  Future<Expense?> getExpenseById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _expenses.firstWhereOrNull((e) => e.id == id);
  }

  @override
  Future<Expense> insertExpense(Expense expense) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newExpense = expense.copyWith(id: 'e_${_nextId++}');
    _expenses.add(newExpense);
    return newExpense;
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index >= 0) _expenses[index] = expense;
  }

  @override
  Future<void> deleteExpenseById(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _expenses.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<Expense>> getExpensesInRange({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _expenses
        .where((e) =>
            e.userId == userId &&
            !e.date.isBefore(from) &&
            !e.date.isAfter(to))
        .toList();
  }
}
