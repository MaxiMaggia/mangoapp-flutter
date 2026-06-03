import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../domain/expenses_repository.dart';
import '../../utils/base_screen_state.dart';
import '../states/expenses_list_state.dart';

// El cerebro de la pantalla de Home: maneja la lista de gastos, la paginacion, los filtros y la busqueda.
class ExpensesListNotifier extends Notifier<ExpensesListState> {
  late final ExpensesRepository _repo = ref.read(expensesRepositoryProvider);

  // Cuantos gastos traemos por pagina.
  static const _pageSize = 10;

  @override
  ExpensesListState build() => const ExpensesListState();

  // Trae la primera tanda de gastos (con loading visible) cuando entras a Home.
  Future<void> fetchInitial(String userId) async {
    state = state.copyWith(screenState: const BaseScreenState.loading());
    try {
      final expenses = await _repo.getExpenses(
        userId: userId,
        limit: _pageSize,
      );
      state = state.copyWith(
        screenState: const BaseScreenState.idle(),
        expenses: expenses,
        hasMore: expenses.length == _pageSize,
      );
    } catch (error) {
      state = state.copyWith(
        screenState: BaseScreenState.error(error.toString()),
      );
    }
  }

  /// Pull-to-refresh. No muestra loading global.
  Future<void> refresh(String userId) async {
    try {
      final expenses = await _repo.getExpenses(
        userId: userId,
        limit: _pageSize,
      );
      state = state.copyWith(
        screenState: const BaseScreenState.idle(),
        expenses: expenses,
        hasMore: expenses.length == _pageSize,
      );
    } catch (error) {
      state = state.copyWith(
        screenState: BaseScreenState.error(error.toString()),
      );
    }
  }

  /// Carga la siguiente pagina (cursor = createdAt del ultimo gasto).
  /// El profe pidio paginar las listas, asi que esto es importante.
  Future<void> loadMore(String userId) async {
    if (state.isLoadingMore || !state.hasMore || state.expenses.isEmpty) {
      return;
    }
    state = state.copyWith(isLoadingMore: true);
    try {
      final cursor = state.expenses.last.createdAt;
      final next = await _repo.getExpenses(
        userId: userId,
        limit: _pageSize,
        lastCreatedAt: cursor,
      );
      state = state.copyWith(
        expenses: [...state.expenses, ...next],
        hasMore: next.length == _pageSize,
        isLoadingMore: false,
      );
    } catch (error) {
      state = state.copyWith(
        screenState: BaseScreenState.error(error.toString()),
        isLoadingMore: false,
      );
    }
  }

  // Borra un gasto y lo saca de la lista al toque, sin tener que recargar todo.
  Future<void> delete(String expenseId, String userId) async {
    try {
      await _repo.deleteExpenseById(expenseId);
      state = state.copyWith(
        expenses: state.expenses.where((e) => e.id != expenseId).toList(),
      );
    } catch (error) {
      state = state.copyWith(
        screenState: BaseScreenState.error(error.toString()),
      );
    }
  }

  // Guarda lo que el usuario escribe en el buscador.
  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  // Aplica (o saca, si viene null) el filtro por categoria.
  void setCategoryFilter(String? categoryId) {
    state = state.copyWith(
      categoryFilterId: categoryId,
      clearCategoryFilter: categoryId == null,
    );
  }
}
