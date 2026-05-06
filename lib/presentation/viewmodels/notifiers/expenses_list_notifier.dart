import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../domain/expenses_repository.dart';
import '../../utils/base_screen_state.dart';
import '../states/expenses_list_state.dart';

class ExpensesListNotifier extends Notifier<ExpensesListState> {
  late final ExpensesRepository _repo = ref.read(expensesRepositoryProvider);

  static const _pageSize = 10;

  @override
  ExpensesListState build() => const ExpensesListState();

  /// Carga inicial. Reemplaza la lista.
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

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCategoryFilter(String? categoryId) {
    state = state.copyWith(
      categoryFilterId: categoryId,
      clearCategoryFilter: categoryId == null,
    );
  }
}
