import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../domain/categories_repository.dart';
import '../../../domain/category.dart';
import '../../utils/base_screen_state.dart';
import '../states/category_form_state.dart';
import '../providers.dart';

class CategoryFormNotifier extends AutoDisposeNotifier<CategoryFormState> {
  late final CategoriesRepository _repo =
      ref.read(categoriesRepositoryProvider);

  @override
  CategoryFormState build() => const CategoryFormState();

  Future<void> loadCategory(String categoryId) async {
    state = state.copyWith(
      screenState: const BaseScreenState.loading(),
      isEditing: true,
    );
    try {
      final category = await _repo.getCategoryById(categoryId);
      if (category == null) {
        state = state.copyWith(
          screenState: const BaseScreenState.error('Categoria no encontrada'),
        );
        return;
      }
      state = state.copyWith(
        screenState: const BaseScreenState.idle(),
        category: category,
      );
    } catch (error) {
      state = state.copyWith(
        screenState: BaseScreenState.error(error.toString()),
      );
    }
  }

  Future<void> save({
    required String title,
    required String iconKey,
    required int colorValue,
  }) async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) {
      state = state.copyWith(
        screenState: const BaseScreenState.error('Usuario no autenticado'),
      );
      return;
    }

    final category = state.isEditing
        ? state.category!.copyWith(
            title: title,
            iconKey: iconKey,
            colorValue: colorValue,
          )
        : Category(
            userId: user.id,
            title: title,
            iconKey: iconKey,
            colorValue: colorValue,
          );

    if (!category.isValid) {
      state = state.copyWith(
        screenState:
            const BaseScreenState.error('El nombre es obligatorio'),
        titleError: !category.isTitleValid,
      );
      return;
    }

    state = state.copyWith(
      screenState: const BaseScreenState.loading(),
      titleError: false,
    );

    try {
      if (state.isEditing) {
        await _repo.updateCategory(category);
      } else {
        await _repo.insertCategory(category);
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
}
