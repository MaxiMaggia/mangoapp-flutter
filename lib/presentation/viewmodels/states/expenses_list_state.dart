import 'package:equatable/equatable.dart';

import '../../../domain/expense.dart';
import '../../utils/base_screen_state.dart';

/// Estado de la pantalla principal: lista de gastos con busqueda, filtro por
/// categoria y paginado (scroll infinito).
class ExpensesListState extends Equatable {
  final BaseScreenState screenState; // estado visual: loading / idle / error
  final List<Expense> expenses; // gastos ya cargados (las paginas que trajimos)
  final String searchQuery; // texto del buscador
  final String? categoryFilterId; // null = todas
  final bool hasMore; // todavia quedan paginas por traer del repo
  final bool isLoadingMore; // estamos trayendo la siguiente pagina

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

  // Copia el estado cambiando solo lo que le pasemos. clearCategoryFilter
  // fuerza el filtro a null (volver a "todas"), porque con el ?? no se puede
  // distinguir "no lo toques" de "ponelo en null".
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
