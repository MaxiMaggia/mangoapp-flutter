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

final authViewModelProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

final expensesListViewModelProvider =
    NotifierProvider<ExpensesListNotifier, ExpensesListState>(
        ExpensesListNotifier.new);

final expenseFormViewModelProvider =
    AutoDisposeNotifierProvider<ExpenseFormNotifier, ExpenseFormState>(
        ExpenseFormNotifier.new);

final expenseDetailsViewModelProvider =
    AutoDisposeNotifierProviderFamily<ExpenseDetailsNotifier,
        ExpenseDetailsState, String>(ExpenseDetailsNotifier.new);

final categoriesListViewModelProvider =
    NotifierProvider<CategoriesListNotifier, CategoriesListState>(
        CategoriesListNotifier.new);

final categoryFormViewModelProvider =
    AutoDisposeNotifierProvider<CategoryFormNotifier, CategoryFormState>(
        CategoryFormNotifier.new);

final statisticsViewModelProvider =
    NotifierProvider<StatisticsNotifier, StatisticsState>(
        StatisticsNotifier.new);

/// Cotizaciones del dólar cacheadas por sesión.
final dolarQuotesProvider = FutureProvider<List<DolarQuote>>((ref) async {
  final repo = ref.read(dolarRepositoryProvider);
  return repo.getQuotes();
});
