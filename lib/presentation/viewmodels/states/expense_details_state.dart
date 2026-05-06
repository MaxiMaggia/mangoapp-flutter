import 'package:equatable/equatable.dart';

import '../../../domain/category.dart';
import '../../../domain/expense.dart';
import '../../utils/base_screen_state.dart';

class ExpenseDetailsState extends Equatable {
  final BaseScreenState screenState;
  final Expense? expense;
  final Category? category;
  final bool wasDeleted;

  const ExpenseDetailsState({
    this.screenState = const BaseScreenState.idle(),
    this.expense,
    this.category,
    this.wasDeleted = false,
  });

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
