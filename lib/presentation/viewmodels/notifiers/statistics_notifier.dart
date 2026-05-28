import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../domain/category.dart';
import '../../../domain/categories_repository.dart';
import '../../../domain/expense.dart';
import '../../../domain/expenses_repository.dart';
import '../../utils/base_screen_state.dart';
import '../providers.dart';
import '../states/statistics_state.dart';

class StatisticsNotifier extends Notifier<StatisticsState> {
  late final ExpensesRepository _expensesRepo =
      ref.read(expensesRepositoryProvider);
  late final CategoriesRepository _categoriesRepo =
      ref.read(categoriesRepositoryProvider);

  @override
  StatisticsState build() => StatisticsState();

  Future<void> load() async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;

    state = state.copyWith(screenState: const BaseScreenState.loading());

    try {
      final categories = await _categoriesRepo.getAllCategories(user.id);

      final start = DateTime(
          state.selectedMonth.year, state.selectedMonth.month, 1);
      final end = DateTime(
          state.selectedMonth.year, state.selectedMonth.month + 1, 0,
          23, 59, 59);
      final expenses = await _expensesRepo.getExpensesInRange(
        userId: user.id,
        from: start,
        to: end,
      );

      final pieSlices = _buildPieSlices(expenses, categories);
      final monthTotal =
          expenses.fold<double>(0, (sum, expense) => sum + expense.amountArs);

      state = state.copyWith(
        screenState: const BaseScreenState.idle(),
        pieSlices: pieSlices,
        monthTotal: monthTotal,
      );
    } catch (error) {
      state = state.copyWith(
        screenState: BaseScreenState.error(error.toString()),
      );
    }
  }

  void goToPreviousMonth() {
    final prev = DateTime(
        state.selectedMonth.year, state.selectedMonth.month - 1, 1);
    state = state.copyWith(selectedMonth: prev);
    load();
  }

  void goToNextMonth() {
    final next = DateTime(
        state.selectedMonth.year, state.selectedMonth.month + 1, 1);
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    if (next.isAfter(currentMonth)) return;
    state = state.copyWith(selectedMonth: next);
    load();
  }

  bool get canGoNext {
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final next = DateTime(
        state.selectedMonth.year, state.selectedMonth.month + 1, 1);
    return !next.isAfter(currentMonth);
  }

  void selectMonth(DateTime month) {
    final normalized = DateTime(month.year, month.month, 1);
    state = state.copyWith(selectedMonth: normalized);
    load();
  }

  List<CategorySlice> _buildPieSlices(
    List<Expense> expenses,
    List<Category> categories,
  ) {
    final byCategory = groupBy<Expense, String>(
      expenses,
      (expense) => expense.categoryId,
    );
    final slices = <CategorySlice>[];

    for (final entry in byCategory.entries) {
      final category = categories.firstWhereOrNull((c) => c.id == entry.key);
      if (category == null) continue;

      final total =
          entry.value.fold<double>(0, (sum, expense) => sum + expense.amountArs);
      slices.add(CategorySlice(category: category, total: total));
    }

    slices.sort((a, b) => b.total.compareTo(a.total));
    return slices;
  }
}
