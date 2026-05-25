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

      final now = DateTime.now();
      final periodStart = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 29));
      final periodEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      final expenses = await _expensesRepo.getExpensesInRange(
        userId: user.id,
        from: periodStart,
        to: periodEnd,
      );

      final pieSlices = _buildPieSlices(expenses, categories);
      final periodTotal =
          expenses.fold<double>(0, (sum, expense) => sum + expense.amountArs);

      state = state.copyWith(
        screenState: const BaseScreenState.idle(),
        periodStart: periodStart,
        periodEnd: periodEnd,
        pieSlices: pieSlices,
        periodTotal: periodTotal,
      );
    } catch (error) {
      state = state.copyWith(
        screenState: BaseScreenState.error(error.toString()),
      );
    }
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
