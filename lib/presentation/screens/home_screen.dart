import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_theme.dart';
import '../../domain/category.dart';
import '../utils/base_screen_state.dart';
import '../utils/formatter.dart';
import '../viewmodels/providers.dart';
import '../widgets/category_item.dart';
import '../widgets/expense_item.dart';
import 'expense_details_screen.dart';
import 'expense_form_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  static const name = 'HomeScreen';
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;
  bool _showFilter = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authViewModelProvider).user;
      if (user == null) return;
      ref.read(expensesListViewModelProvider.notifier).fetchInitial(user.id);
      ref.read(categoriesListViewModelProvider.notifier).fetch();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Detecta proximidad al final de la lista para cargar mas paginas.
  /// (Cumple el "el que no pagina reprueba" del profe.)
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final user = ref.read(authViewModelProvider).user;
      if (user != null) {
        ref.read(expensesListViewModelProvider.notifier).loadMore(user.id);
      }
    }
  }

  Future<void> _onRefresh() async {
    final user = ref.read(authViewModelProvider).user;
    if (user != null) {
      await ref.read(expensesListViewModelProvider.notifier).refresh(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expensesListViewModelProvider);
    final categoriesState = ref.watch(categoriesListViewModelProvider);
    final categoryById = {
      for (final c in categoriesState.categories) c.id!: c
    };
    final filteredExpenses = state.filteredExpenses;
    final totalShown = filteredExpenses.fold<double>(
      0,
      (sum, e) => sum + e.amountArs,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mango'),
        actions: [
          IconButton(
            tooltip: 'Buscar',
            icon: Icon(_showSearch ? Icons.search_off : Icons.search),
            onPressed: () => setState(() => _showSearch = !_showSearch),
          ),
          IconButton(
            tooltip: 'Filtrar',
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => setState(() => _showFilter = !_showFilter),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.pushNamed(ExpenseFormScreen.nameNew);
          // Al volver, refresca la lista
          if (mounted) _onRefresh();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo gasto'),
      ),
      body: Column(
        children: [
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => ref
                    .read(expensesListViewModelProvider.notifier)
                    .setSearch(v),
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
          if (_showFilter && categoriesState.categories.isNotEmpty)
            _CategoryFilterBar(
              categories: categoriesState.categories,
              selectedId: state.categoryFilterId,
              onSelected: (id) => ref
                  .read(expensesListViewModelProvider.notifier)
                  .setCategoryFilter(id),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total mostrado',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  Fmt.money(totalShown),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mangoDeep,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: state.screenState.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              idle: () {
                if (filteredExpenses.isEmpty) {
                  return const _EmptyState();
                }
                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 6, bottom: 100),
                    itemCount:
                        filteredExpenses.length + (state.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= filteredExpenses.length) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final expense = filteredExpenses[index];
                      return ExpenseItem(
                        expense: expense,
                        category: categoryById[expense.categoryId],
                        onTap: () async {
                          await context.pushNamed(
                            ExpenseDetailsScreen.name,
                            pathParameters: {'id': expense.id!},
                          );
                          if (mounted) _onRefresh();
                        },
                        onEdit: () async {
                          await context.pushNamed(
                            ExpenseFormScreen.nameEdit,
                            pathParameters: {'id': expense.id!},
                          );
                          if (mounted) _onRefresh();
                        },
                        onDelete: () => _confirmDelete(expense.id!),
                      );
                    },
                  ),
                );
              },
              error: (msg) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error: $msg', textAlign: TextAlign.center),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: const Text('Esta accion no se puede deshacer.'),
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
      final user = ref.read(authViewModelProvider).user;
      if (user != null) {
        await ref
            .read(expensesListViewModelProvider.notifier)
            .delete(id, user.id);
      }
    }
  }
}

class _CategoryFilterBar extends StatelessWidget {
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const _CategoryFilterBar({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          _AllChip(
            selected: selectedId == null,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: 8),
          for (final c in categories) ...[
            CategoryChipBadge(
              category: c,
              selected: selectedId == c.id,
              onTap: () => onSelected(c.id),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _AllChip extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  const _AllChip({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.mangoOrange.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.mangoOrange
                : Colors.black.withOpacity(0.08),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          'Todas',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.mangoDeep : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 72, color: AppColors.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'Aun no cargaste gastos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tocá el boton de abajo para empezar.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
