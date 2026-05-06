import 'package:equatable/equatable.dart';

import '../../../domain/category.dart';
import '../../../domain/expense.dart';
import '../../utils/base_screen_state.dart';

class ExpenseFormState extends Equatable {
  final BaseScreenState screenState;
  final Expense? expense; // si no es null, esta editando
  final List<Category> categories;
  final bool isEditing;
  final bool wasSaved;

  // Errores por campo
  final bool nameError;
  final bool categoryError;
  final bool amountError;
  final bool dateError;

  const ExpenseFormState({
    this.screenState = const BaseScreenState.idle(),
    this.expense,
    this.categories = const [],
    this.isEditing = false,
    this.wasSaved = false,
    this.nameError = false,
    this.categoryError = false,
    this.amountError = false,
    this.dateError = false,
  });

  ExpenseFormState copyWith({
    BaseScreenState? screenState,
    Expense? expense,
    List<Category>? categories,
    bool? isEditing,
    bool? wasSaved,
    bool? nameError,
    bool? categoryError,
    bool? amountError,
    bool? dateError,
  }) =>
      ExpenseFormState(
        screenState: screenState ?? this.screenState,
        expense: expense ?? this.expense,
        categories: categories ?? this.categories,
        isEditing: isEditing ?? this.isEditing,
        wasSaved: wasSaved ?? this.wasSaved,
        nameError: nameError ?? this.nameError,
        categoryError: categoryError ?? this.categoryError,
        amountError: amountError ?? this.amountError,
        dateError: dateError ?? this.dateError,
      );

  @override
  List<Object?> get props => [
        screenState,
        expense,
        categories,
        isEditing,
        wasSaved,
        nameError,
        categoryError,
        amountError,
        dateError,
      ];
}
