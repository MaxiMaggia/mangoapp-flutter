import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_theme.dart';
import '../utils/base_screen_state.dart';
import '../viewmodels/providers.dart';
import '../widgets/category_item.dart';
import 'category_form_screen.dart';

class CategoryListScreen extends ConsumerStatefulWidget {
  static const name = 'CategoryListScreen';
  const CategoryListScreen({super.key});

  @override
  ConsumerState<CategoryListScreen> createState() =>
      _CategoryListScreenState();
}

class _CategoryListScreenState extends ConsumerState<CategoryListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoriesListViewModelProvider.notifier).fetch();
    });
  }

  Future<void> _refresh() async {
    await ref.read(categoriesListViewModelProvider.notifier).fetch();
  }

  Future<void> _confirmDelete(String id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar categoria'),
        content: Text(
            '¿Querés eliminar "$title"? Los gastos asociados quedaran sin categoria.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(categoriesListViewModelProvider.notifier)
          .delete(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoriesListViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorias'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.pushNamed(CategoryFormScreen.nameNew);
          if (mounted) _refresh();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
      body: state.screenState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (msg) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error: $msg', textAlign: TextAlign.center),
          ),
        ),
        idle: () {
          if (state.categories.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.category_outlined,
                        size: 64,
                        color: AppColors.textSecondary.withOpacity(0.5)),
                    const SizedBox(height: 12),
                    const Text(
                      'No hay categorias todavia',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Creá la primera con el botón de abajo.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 100),
              itemCount: state.categories.length,
              itemBuilder: (context, index) {
                final category = state.categories[index];
                return CategoryItem(
                  category: category,
                  onEdit: () async {
                    await context.pushNamed(
                      CategoryFormScreen.nameEdit,
                      pathParameters: {'id': category.id!},
                    );
                    if (mounted) _refresh();
                  },
                  onDelete: () =>
                      _confirmDelete(category.id!, category.title),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
