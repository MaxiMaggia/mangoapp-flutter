import 'package:equatable/equatable.dart';

import '../../../domain/category.dart';
import '../../utils/base_screen_state.dart';

/// Estado de la pantalla que lista las categorias del usuario.
class CategoriesListState extends Equatable {
  final BaseScreenState screenState; // estado visual: loading / idle / error
  final List<Category> categories; // categorias ya cargadas (las paginas que trajimos)
  final bool hasMore; // todavia quedan paginas por traer del repo
  final bool isLoadingMore; // estamos trayendo la siguiente pagina

  const CategoriesListState({
    this.screenState = const BaseScreenState.idle(),
    this.categories = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  // Copia el estado cambiando solo los campos que le pasemos.
  CategoriesListState copyWith({
    BaseScreenState? screenState,
    List<Category>? categories,
    bool? hasMore,
    bool? isLoadingMore,
  }) =>
      CategoriesListState(
        screenState: screenState ?? this.screenState,
        categories: categories ?? this.categories,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );

  @override
  List<Object?> get props => [screenState, categories, hasMore, isLoadingMore];
}
