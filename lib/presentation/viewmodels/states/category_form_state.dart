import 'package:equatable/equatable.dart';

import '../../../domain/category.dart';
import '../../utils/base_screen_state.dart';

/// Estado del formulario de alta/edicion de una categoria.
class CategoryFormState extends Equatable {
  final BaseScreenState screenState; // estado visual: loading / idle / error
  final Category? category; // la categoria que estamos editando (null si es alta)
  final bool isEditing; // true = editando una existente, false = creando
  final bool wasSaved; // se guardo ok -> la pantalla cierra/navega
  final bool titleError; // marca el campo titulo en rojo si quedo invalido

  const CategoryFormState({
    this.screenState = const BaseScreenState.idle(),
    this.category,
    this.isEditing = false,
    this.wasSaved = false,
    this.titleError = false,
  });

  // Copia el estado cambiando solo los campos que le pasemos.
  CategoryFormState copyWith({
    BaseScreenState? screenState,
    Category? category,
    bool? isEditing,
    bool? wasSaved,
    bool? titleError,
  }) =>
      CategoryFormState(
        screenState: screenState ?? this.screenState,
        category: category ?? this.category,
        isEditing: isEditing ?? this.isEditing,
        wasSaved: wasSaved ?? this.wasSaved,
        titleError: titleError ?? this.titleError,
      );

  @override
  List<Object?> get props =>
      [screenState, category, isEditing, wasSaved, titleError];
}
