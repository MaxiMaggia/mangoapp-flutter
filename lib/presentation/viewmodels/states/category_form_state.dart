import 'package:equatable/equatable.dart';

import '../../../domain/category.dart';
import '../../utils/base_screen_state.dart';

class CategoryFormState extends Equatable {
  final BaseScreenState screenState;
  final Category? category;
  final bool isEditing;
  final bool wasSaved;
  final bool titleError;

  const CategoryFormState({
    this.screenState = const BaseScreenState.idle(),
    this.category,
    this.isEditing = false,
    this.wasSaved = false,
    this.titleError = false,
  });

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
