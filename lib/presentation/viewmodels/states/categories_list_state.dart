import 'package:equatable/equatable.dart';

import '../../../domain/category.dart';
import '../../utils/base_screen_state.dart';

class CategoriesListState extends Equatable {
  final BaseScreenState screenState;
  final List<Category> categories;

  const CategoriesListState({
    this.screenState = const BaseScreenState.idle(),
    this.categories = const [],
  });

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
