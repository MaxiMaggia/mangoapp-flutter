import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../domain/categories_repository.dart';
import '../../../domain/dolar_quote.dart';
import '../../../domain/expense.dart';
import '../../../domain/expenses_repository.dart';
import '../../utils/base_screen_state.dart';
import '../states/expense_form_state.dart';
import '../providers.dart';

class ExpenseFormNotifier extends AutoDisposeNotifier<ExpenseFormState> {
  late final ExpensesRepository _expensesRepo =
      ref.read(expensesRepositoryProvider);
  late final CategoriesRepository _categoriesRepo =
      ref.read(categoriesRepositoryProvider);

  @override
  ExpenseFormState build() => const ExpenseFormState();

  Future<void> loadCategories() async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;
    try {
      final categories = await _categoriesRepo.getAllCategories(user.id);
      state = state.copyWith(categories: categories);
    } catch (_) {
      // No bloqueamos el form si fallan las categorias; queda vacio
    }
  }

  Future<void> loadExpense(String expenseId) async {
    state = state.copyWith(
      screenState: const BaseScreenState.loading(),
      isEditing: true,
    );
    try {
      final expense = await _expensesRepo.getExpenseById(expenseId);
      if (expense == null) {
        state = state.copyWith(
          screenState: const BaseScreenState.error('Gasto no encontrado'),
        );
        return;
      }
      state = state.copyWith(
        screenState: const BaseScreenState.idle(),
        expense: expense,
      );
    } catch (error) {
      state = state.copyWith(
        screenState: BaseScreenState.error(error.toString()),
      );
    }
  }

  /// Crea o edita el gasto. `amount` y `originalAmount` ya vienen como double
  /// validados por la vista (parsed). Si la moneda es ARS, originalAmount es
  /// null y amountArs es directamente el monto cargado.
  Future<void> save({
    required String name,
    required String categoryId,
    required double amountArs,
    required DateTime date,
    Currency currency = Currency.ars,
    double? originalAmount,
    String? dolarType,
  }) async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) {
      state = state.copyWith(
        screenState: const BaseScreenState.error('Usuario no autenticado'),
      );
      return;
    }

    final expense = state.isEditing
        ? state.expense!.copyWith(
            name: name,
            categoryId: categoryId,
            amountArs: amountArs,
            originalAmount: originalAmount,
            currency: currency,
            dolarType: dolarType,
            date: date,
            updatedAt: DateTime.now(),
          )
        : Expense(
            userId: user.id,
            name: name,
            categoryId: categoryId,
            amountArs: amountArs,
            originalAmount: originalAmount,
            currency: currency,
            dolarType: dolarType,
            date: date,
          );

    if (!expense.isValid) {
      state = state.copyWith(
        screenState:
            const BaseScreenState.error('Revisa los campos del formulario'),
        nameError: !expense.isNameValid,
        categoryError: !expense.isCategoryValid,
        amountError: !expense.isAmountValid,
        dateError: !expense.isDateValid,
      );
      return;
    }

    state = state.copyWith(
      screenState: const BaseScreenState.loading(),
      nameError: false,
      categoryError: false,
      amountError: false,
      dateError: false,
    );

    try {
      if (state.isEditing) {
        await _expensesRepo.updateExpense(expense);
      } else {
        await _expensesRepo.insertExpense(expense);
      }
      state = state.copyWith(
        screenState: const BaseScreenState.idle(),
        wasSaved: true,
      );
    } catch (error) {
      state = state.copyWith(
        screenState: BaseScreenState.error(error.toString()),
      );
    }
  }

  /// Conversion USD -> ARS usando la cotización 'venta' de la casa
  /// correspondiente. Si la API no tiene la casa pedida, cae a una tabla
  /// local de respaldo.
  double convertUsdToArs(
    double usd,
    String dolarTypeCode,
    List<DolarQuote> quotes,
  ) {
    final dolarType = DolarType.all.firstWhereOrNull(
      (t) => t.code == dolarTypeCode,
    );
    final apiCasa = dolarType?.apiCasa ?? dolarTypeCode;
    final quote = quotes.firstWhereOrNull((q) => q.casa == apiCasa);
    if (quote == null) {
      const fallback = {
        'oficial': 1100.0,
        'tarjeta': 1800.0,
        'mep': 1450.0,
        'blue': 1500.0,
      };
      final rate = fallback[dolarTypeCode] ?? 1500.0;
      return usd * rate;
    }
    return usd * quote.venta;
  }
}
