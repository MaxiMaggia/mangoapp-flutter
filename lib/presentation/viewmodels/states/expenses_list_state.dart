import 'package:equatable/equatable.dart';

import '../../../domain/expense.dart';
import '../../utils/base_screen_state.dart';

class ExpensesListState extends Equatable {
  final BaseScreenState screenState;
  final List<Expense> expenses;
  final String searchQuery;
  final String? categoryFilterId; // null = todas
  final bool hasMore;
  final bool isLoadingMore;

  const ExpensesListState({
    this.screenState = const BaseScreenState.idle(),
    this.expenses = const [],
    this.searchQuery = '',
    this.categoryFilterId,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  /// Filtrado en memoria por busqueda y categoria.
  /// (El paginado real, en cambio, viene del repositorio.)
  List<Expense> get filteredExpenses {
    return expenses.where((e) {
      final matchesQuery = searchQuery.isEmpty ||
          e.name.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory =
          categoryFilterId == null || e.categoryId == categoryFilterId;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  ExpensesListState copyWith({
    BaseScreenState? screenState,
    List<Expense>? expenses,
    String? searchQuery,
    String? categoryFilterId,
    bool clearCategoryFilter = false,
    bool? hasMore,
    bool? isLoadingMore,
  }) =>
      ExpensesListState(
        screenState: screenState ?? this.screenState,
        expenses: expenses ?? this.expenses,
        searchQuery: searchQuery ?? this.searchQuery,
        categoryFilterId: clearCategoryFilter
            ? null
            : (categoryFilterId ?? this.categoryFilterId),
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );

  @override
  List<Object?> get props => [
        screenState,
        expenses,
        searchQuery,
        categoryFilterId,
        hasMore,
        isLoadingMore,
      ];
}
