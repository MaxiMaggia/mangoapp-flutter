import 'package:equatable/equatable.dart';

import '../../../domain/category.dart';
import '../../../domain/expense.dart';
import '../../utils/base_screen_state.dart';

/// Estado de la pantalla de detalle de un gasto puntual.
class ExpenseDetailsState extends Equatable {
  final BaseScreenState screenState; // estado visual: loading / idle / error
  final Expense? expense; // el gasto que estamos mirando
  final Category? category; // su categoria, ya resuelta para mostrar nombre/color
  final bool wasDeleted; // se borro -> la pantalla vuelve a la lista

  const ExpenseDetailsState({
    this.screenState = const BaseScreenState.idle(),
    this.expense,
    this.category,
    this.wasDeleted = false,
  });

  // Copia el estado cambiando solo los campos que le pasemos.
  ExpenseDetailsState copyWith({
    BaseScreenState? screenState,
    Expense? expense,
    Category? category,
    bool? wasDeleted,
  }) =>
      ExpenseDetailsState(
        screenState: screenState ?? this.screenState,
        expense: expense ?? this.expense,
        category: category ?? this.category,
        wasDeleted: wasDeleted ?? this.wasDeleted,
      );

  @override
  List<Object?> get props => [screenState, expense, category, wasDeleted];
}
