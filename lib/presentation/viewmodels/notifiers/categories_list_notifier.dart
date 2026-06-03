import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../domain/categories_repository.dart';
import '../../utils/base_screen_state.dart';
import '../states/categories_list_state.dart';
import '../providers.dart';

// El cerebro de la pantalla de categorias: carga la lista del usuario y permite borrarlas.
class CategoriesListNotifier extends Notifier<CategoriesListState> {
  late final CategoriesRepository _repo =
      ref.read(categoriesRepositoryProvider);

  @override
  CategoriesListState build() => const CategoriesListState();

  // Trae todas las categorias del usuario logueado.
  Future<void> fetch() async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;
    state = state.copyWith(screenState: const BaseScreenState.loading());
    try {
      final categories = await _repo.getAllCategories(user.id);
      state = state.copyWith(
        screenState: const BaseScreenState.idle(),
        categories: categories,
      );
    } catch (error) {
      state = state.copyWith(
        screenState: BaseScreenState.error(error.toString()),
      );
    }
  }

  // Borra una categoria y la saca de la lista al instante, sin recargar todo.
  Future<void> delete(String id) async {
    try {
      await _repo.deleteCategoryById(id);
      state = state.copyWith(
        categories: state.categories.where((c) => c.id != id).toList(),
      );
    } catch (error) {
      state = state.copyWith(
        screenState: BaseScreenState.error(error.toString()),
      );
    }
  }
}
