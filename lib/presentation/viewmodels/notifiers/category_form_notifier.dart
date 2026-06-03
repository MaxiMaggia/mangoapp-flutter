import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../domain/categories_repository.dart';
import '../../../domain/category.dart';
import '../../utils/base_screen_state.dart';
import '../states/category_form_state.dart';
import '../providers.dart';

// El cerebro de la pantalla de crear/editar categoria: carga la categoria a editar y la guarda.
class CategoryFormNotifier extends AutoDisposeNotifier<CategoryFormState> {
  // Acceso al repo de categorias (de donde leemos/escribimos).
  late final CategoriesRepository _repo =
      ref.read(categoriesRepositoryProvider);

  // Arranca con el form vacio.
  @override
  CategoryFormState build() => const CategoryFormState();

  // Trae una categoria existente para editarla y marca el form como "modo edicion".
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

  // Crea o actualiza la categoria segun si estamos editando o no.
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

    // Si editamos, copiamos la categoria existente con los nuevos datos; si no, creamos una nueva.
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

    // Validamos antes de pegarle a la base; si el nombre esta mal, marcamos el error en el campo.
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
