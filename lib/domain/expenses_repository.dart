import 'expense.dart';

/// Contrato para acceder a gastos.
///
/// Cuando se conecte Firebase, se va a crear FirestoreExpensesRepository
/// que implemente esta interface, sin tocar viewmodels ni vistas.
abstract interface class ExpensesRepository {
  /// Trae los gastos del usuario, paginados.
  ///
  /// IMPORTANTE: el profe pidio paginar las listas. `lastCreatedAt` es el
  /// cursor para traer la siguiente pagina (el created_at del ultimo gasto
  /// recibido). Si es null trae la primera pagina.
  Future<List<Expense>> getExpenses({
    required String userId,
    int limit = 20,
    DateTime? lastCreatedAt,
  });

  Future<Expense?> getExpenseById(String id);

  Future<Expense> insertExpense(Expense expense);

  Future<void> updateExpense(Expense expense);

  Future<void> deleteExpenseById(String id);

  /// Para la pantalla de estadisticas: gastos del rango indicado.
  Future<List<Expense>> getExpensesInRange({
    required String userId,
    required DateTime from,
    required DateTime to,
  });
}
