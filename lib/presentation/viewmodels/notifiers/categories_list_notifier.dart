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

  // Cuantas categorias traemos por pagina (mismo valor que la lista de gastos).
  static const _pageSize = 10;

  @override
  CategoriesListState build() => const CategoriesListState();

  // Trae la primera tanda de categorias (con loading visible) al entrar.
  Future<void> fetch() async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;
    state = state.copyWith(screenState: const BaseScreenState.loading());
    try {
      final categories = await _repo.getCategoriesPaginated(
        userId: user.id,
        limit: _pageSize,
      );
      state = state.copyWith(
        screenState: const BaseScreenState.idle(),
        categories: categories,
        hasMore: categories.length == _pageSize,
      );
    } catch (error) {
      state = state.copyWith(
        screenState: BaseScreenState.error(error.toString()),
      );
    }
  }

  /// Carga la siguiente pagina (cursor = titleLower de la ultima categoria).
  /// El profe pidio paginar todas las listas, igual que la lista de gastos.
  Future<void> loadMore(String userId) async {
    if (state.isLoadingMore || !state.hasMore || state.categories.isEmpty) {
      return;
    }
    state = state.copyWith(isLoadingMore: true);
    try {
      // El cursor es el titleLower del ultimo item (la lista va por titleLower).
      final cursor = state.categories.last.title.trim().toLowerCase();
      final next = await _repo.getCategoriesPaginated(
        userId: userId,
        limit: _pageSize,
        lastTitleLower: cursor,
      );
      state = state.copyWith(
        categories: [...state.categories, ...next],
        hasMore: next.length == _pageSize,
        isLoadingMore: false,
      );
    } catch (error) {
      state = state.copyWith(
        screenState: BaseScreenState.error(error.toString()),
        isLoadingMore: false,
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
