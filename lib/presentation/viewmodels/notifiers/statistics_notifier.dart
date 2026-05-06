import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../domain/categories_repository.dart';
import '../../../domain/category.dart';
import '../../../domain/expenses_repository.dart';
import '../../utils/base_screen_state.dart';
import '../states/statistics_state.dart';
import 'auth_notifier.dart';
import '../providers.dart';

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
      // Categorias
      final categories = await _categoriesRepo.getAllCategories(user.id);

      // Gastos del mes seleccionado (para el pie chart)
      final monthStart =
          DateTime(state.selectedMonth.year, state.selectedMonth.month, 1);
      final monthEnd = DateTime(
          state.selectedMonth.year, state.selectedMonth.month + 1, 0, 23, 59, 59);
      final monthExpenses = await _expensesRepo.getExpensesInRange(
        userId: user.id,
        from: monthStart,
        to: monthEnd,
      );

      final pieSlices = _buildPieSlices(monthExpenses, categories);
      final monthTotal =
          monthExpenses.fold<double>(0, (sum, e) => sum + e.amountArs);

      // Gastos del ultimo año para el bar chart trimestral
      final yearStart =
          DateTime(state.selectedMonth.year - 1, state.selectedMonth.month + 1);
      final yearEnd = monthEnd;
      final yearExpenses = await _expensesRepo.getExpensesInRange(
        userId: user.id,
        from: yearStart,
        to: yearEnd,
      );

      final bars = _buildQuarterBars(yearExpenses);

      state = state.copyWith(
        screenState: const BaseScreenState.idle(),
        pieSlices: pieSlices,
        bars: bars,
        monthTotal: monthTotal,
      );
    } catch (error) {
      state = state.copyWith(
        screenState: BaseScreenState.error(error.toString()),
      );
    }
  }

  void selectMonth(DateTime month) {
    state = state.copyWith(selectedMonth: DateTime(month.year, month.month));
    load();
  }

  void setBarRange(StatsRange range) {
    state = state.copyWith(barRange: range);
  }

  List<CategorySlice> _buildPieSlices(
    List expenses,
    List<Category> categories,
  ) {
    final byCategory = groupBy<dynamic, String>(expenses, (e) => e.categoryId);
    final slices = <CategorySlice>[];
    for (final entry in byCategory.entries) {
      final category =
          categories.firstWhereOrNull((c) => c.id == entry.key);
      if (category == null) continue;
      final total = entry.value
          .fold<double>(0, (sum, e) => sum + (e.amountArs as double));
      slices.add(CategorySlice(category: category, total: total));
    }
    slices.sort((a, b) => b.total.compareTo(a.total));
    return slices;
  }

  List<QuarterBar> _buildQuarterBars(List expenses) {
    final Map<String, QuarterBar> byKey = {};
    for (final e in expenses) {
      final date = e.date as DateTime;
      final quarter = ((date.month - 1) ~/ 3) + 1;
      final key = '${date.year}-Q$quarter';
      final current = byKey[key] ??
          QuarterBar(year: date.year, quarter: quarter, total: 0);
      byKey[key] = QuarterBar(
        year: current.year,
        quarter: current.quarter,
        total: current.total + (e.amountArs as double),
      );
    }
    final list = byKey.values.toList()
      ..sort((a, b) {
        final yearCompare = a.year.compareTo(b.year);
        return yearCompare != 0 ? yearCompare : a.quarter.compareTo(b.quarter);
      });
    return list;
  }
}
