import 'package:equatable/equatable.dart';

import '../../../domain/category.dart';
import '../../utils/base_screen_state.dart';

/// Estado de la pantalla que lista las categorias del usuario.
class CategoriesListState extends Equatable {
  final BaseScreenState screenState; // estado visual: loading / idle / error
  final List<Category> categories;

  const CategoriesListState({
    this.screenState = const BaseScreenState.idle(),
    this.categories = const [],
  });

  // Copia el estado cambiando solo los campos que le pasemos.
  CategoriesListState copyWith({
    BaseScreenState? screenState,
    List<Category>? categories,
  }) =>
      CategoriesListState(
        screenState: screenState ?? this.screenState,
        categories: categories ?? this.categories,
      );

  @override
  List<Object?> get props => [screenState, categories];
}
