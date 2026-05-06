import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_theme.dart';
import '../../domain/category.dart';
import '../../domain/expense.dart';
import '../utils/base_screen_state.dart';
import '../utils/category_icons.dart';
import '../utils/formatter.dart';
import '../viewmodels/providers.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  static const nameNew = 'ExpenseFormScreenNew';
  static const nameEdit = 'ExpenseFormScreenEdit';

  final String? expenseId;
  const ExpenseFormScreen({super.key, this.expenseId});

  @override
  ConsumerState<ExpenseFormScreen> createState() =>
      _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _categoryId;
  DateTime _date = DateTime.now();
  Currency _currency = Currency.ars;
  String _dolarType = DolarType.tarjeta.code;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(expenseFormViewModelProvider.notifier).loadCategories();
      if (widget.expenseId != null) {
        await ref
            .read(expenseFormViewModelProvider.notifier)
            .loadExpense(widget.expenseId!);
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _hydrateFromState(Expense expense) {
    if (_initialized) return;
    _initialized = true;
    _nameCtrl.text = expense.name;
    final amountToShow = expense.currency == Currency.usd
        ? (expense.originalAmount ?? expense.amountArs)
        : expense.amountArs;
    _amountCtrl.text = amountToShow.toString();
    setState(() {
      _categoryId = expense.categoryId;
      _date = expense.date;
      _currency = expense.currency;
      _dolarType = expense.dolarType ?? DolarType.tarjeta.code;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elegi una categoria')),
      );
      return;
    }

    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
    final notifier = ref.read(expenseFormViewModelProvider.notifier);

    final amountArs = _currency == Currency.usd
        ? notifier.convertUsdToArs(amount, _dolarType)
        : amount;
    final originalAmount = _currency == Currency.usd ? amount : null;

    notifier.save(
      name: _nameCtrl.text.trim(),
      categoryId: _categoryId!,
      amountArs: amountArs,
      date: _date,
      currency: _currency,
      originalAmount: originalAmount,
      dolarType: _currency == Currency.usd ? _dolarType : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseFormViewModelProvider);

    // Hidratar form si llego un expense para editar
    if (state.expense != null) {
      _hydrateFromState(state.expense!);
    }

    ref.listen(expenseFormViewModelProvider, (_, next) {
      if (next.wasSaved) {
        Navigator.of(context).pop(true);
      }
      if (next.screenState.isError) {
        final msg = next.screenState.errorMessage;
        if (msg != null && msg.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
          );
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(state.isEditing ? 'Editar gasto' : 'Nuevo gasto'),
        actions: [
          TextButton(
            onPressed: state.screenState.isLoading ? null : _submit,
            child: const Text('Guardar',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Stack(
        children: [
          AbsorbPointer(
            absorbing: state.screenState.isLoading,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _SectionLabel('Detalle'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Descripcion',
                      hintText: 'Ej: Supermercado, Netflix...',
                      errorText: state.nameError ? 'Requerido' : null,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 14),
                  _CategoryPicker(
                    categories: state.categories,
                    selectedId: _categoryId,
                    hasError: state.categoryError,
                    onPicked: (id) => setState(() => _categoryId = id),
                    onCreateNew: () async {
                      await context.push('/categories/new');
                      if (mounted) {
                        ref
                            .read(expenseFormViewModelProvider.notifier)
                            .loadCategories();
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Fecha',
                        prefixIcon: const Icon(Icons.calendar_today),
                        errorText: state.dateError ? 'Fecha invalida' : null,
                      ),
                      child: Text(Fmt.shortDate(_date)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel('Monto'),
                  const SizedBox(height: 8),
                  _CurrencyToggle(
                    currency: _currency,
                    onChanged: (c) => setState(() => _currency = c),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: InputDecoration(
                      labelText:
                          _currency == Currency.ars ? 'Monto (ARS)' : 'Monto (USD)',
                      prefixText:
                          _currency == Currency.ars ? '\$  ' : 'US\$  ',
                      errorText: state.amountError ? 'Requerido' : null,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      final n = double.tryParse(v.replaceAll(',', '.'));
                      if (n == null || n <= 0) return 'Numero invalido';
                      return null;
                    },
                  ),
                  if (_currency == Currency.usd) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _dolarType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de cotizacion',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      items: DolarType.all
                          .map((t) => DropdownMenuItem(
                                value: t.code,
                                child: Text(t.label),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _dolarType = v ?? 'tarjeta'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Convertimos a pesos al guardar usando la cotizacion seleccionada.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withOpacity(0.9),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (state.screenState.isLoading)
            Container(
              color: Colors.black.withOpacity(0.05),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  final List<Category> categories;
  final String? selectedId;
  final bool hasError;
  final ValueChanged<String> onPicked;
  final VoidCallback onCreateNew;

  const _CategoryPicker({
    required this.categories,
    required this.selectedId,
    required this.hasError,
    required this.onPicked,
    required this.onCreateNew,
  });

  @override
  Widget build(BuildContext context) {
    Category? selected;
    for (final c in categories) {
      if (c.id == selectedId) {
        selected = c;
        break;
      }
    }

    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Categoria',
        errorText: hasError ? 'Elegi una categoria' : null,
        prefixIcon: selected == null
            ? const Icon(Icons.category_outlined)
            : Icon(CategoryIcons.iconFor(selected.iconKey),
                color: selected.color),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            for (final c in categories) ...[
              GestureDetector(
                onTap: () => onPicked(c.id!),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: c.id == selectedId
                        ? c.color.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: c.id == selectedId
                          ? c.color
                          : Colors.black.withOpacity(0.08),
                      width: c.id == selectedId ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CategoryIcons.iconFor(c.iconKey),
                          size: 14, color: c.color),
                      const SizedBox(width: 6),
                      Text(
                        c.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: c.id == selectedId
                              ? c.color
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            TextButton.icon(
              onPressed: onCreateNew,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Nueva'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyToggle extends StatelessWidget {
  final Currency currency;
  final ValueChanged<Currency> onChanged;
  const _CurrencyToggle({required this.currency, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleButton(
              label: 'Pesos',
              selected: currency == Currency.ars,
              onTap: () => onChanged(Currency.ars),
            ),
          ),
          Expanded(
            child: _ToggleButton(
              label: 'Dolares',
              selected: currency == Currency.usd,
              onTap: () => onChanged(Currency.usd),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleButton(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.mangoDeep : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
