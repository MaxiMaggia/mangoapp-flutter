import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../domain/categories_repository.dart';
import '../../../domain/expenses_repository.dart';
import '../../utils/base_screen_state.dart';
import '../states/expense_details_state.dart';

class ExpenseDetailsNotifier
    extends AutoDisposeFamilyNotifier<ExpenseDetailsState, String> {
  late final ExpensesRepository _expensesRepo =
      ref.read(expensesRepositoryProvider);
  late final CategoriesRepository _categoriesRepo =
      ref.read(categoriesRepositoryProvider);

  @override
  ExpenseDetailsState build(String expenseId) {
    fetch(expenseId);
    return const ExpenseDetailsState(
      screenState: BaseScreenState.loading(),
    );
  }

  Future<void> fetch(String expenseId) async {
    try {
      final expense = await _expensesRepo.getExpenseById(expenseId);
      if (expense == null) {
        state = state.copyWith(
          screenState: const BaseScreenState.error('Gasto no encontrado'),
        );
        return;
      }
      final category = await _categoriesRepo.getCategoryById(expense.categoryId);
      state = state.copyWith(
        screenState: const BaseScreenState.idle(),
        expense: expense,
        category: category,
      );
    } catch (error) {
      state = state.copyWith(
        screenState: BaseScreenState.error(error.toString()),
      );
    }
  }

  Future<void> delete() async {
    final id = state.expense?.id;
    if (id == null) return;
    state = state.copyWith(screenState: const BaseScreenState.loading());
    try {
      await _expensesRepo.deleteExpenseById(id);
      state = state.copyWith(
        screenState: const BaseScreenState.idle(),
        wasDeleted: true,
      );
    } catch (error) {
      state = state.copyWith(
        screenState: BaseScreenState.error(error.toString()),
      );
    }
  }
}
