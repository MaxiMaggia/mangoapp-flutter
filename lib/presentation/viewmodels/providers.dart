import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/dolar_quote.dart';
import 'notifiers/auth_notifier.dart';
import 'notifiers/categories_list_notifier.dart';
import 'notifiers/category_form_notifier.dart';
import 'notifiers/expense_details_notifier.dart';
import 'notifiers/expense_form_notifier.dart';
import 'notifiers/expenses_list_notifier.dart';
import 'notifiers/statistics_notifier.dart';
import 'states/auth_state.dart';
import 'states/categories_list_state.dart';
import 'states/category_form_state.dart';
import 'states/expense_details_state.dart';
import 'states/expense_form_state.dart';
import 'states/expenses_list_state.dart';
import 'states/statistics_state.dart';

// Acceso global al estado de autenticacion (quien esta logueado).
final authViewModelProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

// Estado de la lista de gastos del Home.
final expensesListViewModelProvider =
    NotifierProvider<ExpensesListNotifier, ExpensesListState>(
        ExpensesListNotifier.new);

// Estado del formulario de gasto (auto-dispose: se limpia al cerrar la pantalla).
final expenseFormViewModelProvider =
    AutoDisposeNotifierProvider<ExpenseFormNotifier, ExpenseFormState>(
        ExpenseFormNotifier.new);

// Estado del detalle de un gasto, uno por cada id (family).
final expenseDetailsViewModelProvider =
    AutoDisposeNotifierProviderFamily<ExpenseDetailsNotifier,
        ExpenseDetailsState, String>(ExpenseDetailsNotifier.new);

// Estado de la lista de categorias.
final categoriesListViewModelProvider =
    NotifierProvider<CategoriesListNotifier, CategoriesListState>(
        CategoriesListNotifier.new);

// Estado del formulario de categoria (auto-dispose).
final categoryFormViewModelProvider =
    AutoDisposeNotifierProvider<CategoryFormNotifier, CategoryFormState>(
        CategoryFormNotifier.new);

// Estado de la pantalla de estadisticas.
final statisticsViewModelProvider =
    NotifierProvider<StatisticsNotifier, StatisticsState>(
        StatisticsNotifier.new);

/// Cotizaciones del dólar cacheadas por sesión.
final dolarQuotesProvider = FutureProvider<List<DolarQuote>>((ref) async {
  final repo = ref.read(dolarRepositoryProvider);
  return repo.getQuotes();
});
