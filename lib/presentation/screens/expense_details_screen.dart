import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_theme.dart';
import '../../domain/expense.dart';
import '../utils/base_screen_state.dart';
import '../utils/category_icons.dart';
import '../utils/formatter.dart';
import '../viewmodels/providers.dart';
import 'expense_form_screen.dart';

class ExpenseDetailsScreen extends ConsumerWidget {
  static const name = 'ExpenseDetailsScreen';
  final String expenseId;
  const ExpenseDetailsScreen({super.key, required this.expenseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(expenseDetailsViewModelProvider(expenseId));

    ref.listen(expenseDetailsViewModelProvider(expenseId), (_, next) {
      if (next.wasDeleted) {
        Navigator.of(context).pop(true);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del gasto'),
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: state.expense == null
                ? null
                : () async {
                    await context.pushNamed(
                      ExpenseFormScreen.nameEdit,
                      pathParameters: {'id': state.expense!.id!},
                    );
                    // Refrescar al volver del editar
                    ref
                        .read(expenseDetailsViewModelProvider(expenseId)
                            .notifier)
                        .fetch(expenseId);
                  },
          ),
        ],
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
          final expense = state.expense;
          if (expense == null) return const SizedBox();
          final categoryColor = state.category?.color ?? AppColors.mangoOrange;
          final iconKey =
              state.category?.iconKey ?? CategoryIcons.other.key;
          final categoryTitle = state.category?.title ?? 'Sin categoria';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Tarjeta principal con monto
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      categoryColor,
                      Color.lerp(categoryColor, Colors.black, 0.15)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        CategoryIcons.iconFor(iconKey),
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      expense.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      categoryTitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      Fmt.money(expense.amountArs),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (expense.currency == Currency.usd &&
                        expense.originalAmount != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Pagado: ${Fmt.usd(expense.originalAmount!)}'
                        ' (${expense.dolarType ?? 'tarjeta'})',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _DetailRow(
                  icon: Icons.calendar_today,
                  label: 'Fecha',
                  value: Fmt.longDate(expense.date)),
              _DetailRow(
                icon: Icons.add_circle_outline,
                label: 'Cargado el',
                value: Fmt.longDate(expense.createdAt),
              ),
              if (expense.updatedAt != null)
                _DetailRow(
                  icon: Icons.edit_calendar_outlined,
                  label: 'Actualizado',
                  value: Fmt.longDate(expense.updatedAt!),
                ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _confirmDelete(context, ref),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Eliminar gasto'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
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
      await ref
          .read(expenseDetailsViewModelProvider(expenseId).notifier)
          .delete();
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.mangoOrange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.mangoDeep, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
