import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../domain/category.dart';
import '../../domain/dolar_quote.dart';
import '../../domain/expense.dart';
import '../utils/base_screen_state.dart';
import '../utils/category_icons.dart';
import '../utils/formatter.dart';
import '../viewmodels/providers.dart';

// Pantalla de alta/edicion de un gasto: nombre, categoria, fecha, moneda (ARS/USD) y monto.
class ExpenseFormScreen extends ConsumerStatefulWidget {
  static const nameNew = 'ExpenseFormScreenNew';
  static const nameEdit = 'ExpenseFormScreenEdit';

  // Si viene un id estamos editando; si es null, es alta.
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
  // Flag para hidratar el form una sola vez cuando llega el gasto a editar.
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Primero cargamos las categorias y, si estamos editando, traemos el gasto.
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

  // Vuelca los datos del gasto a editar en los controles del form (una sola vez).
  void _hydrateFromState(Expense expense) {
    if (_initialized) return;
    _initialized = true;
    _nameCtrl.text = expense.name;
    // Si fue en USD mostramos el monto original ingresado, no el convertido a ARS.
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

  // Abre el date picker (no permite fechas futuras) y guarda la elegida.
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  // Valida, arma el monto (convirtiendo USD->ARS si hace falta) y manda a guardar.
  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;
    // La categoria no la cubre el validator del form, asi que la chequeamos aparte.
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elegi una categoria')),
      );
      return;
    }

    // Aceptamos coma o punto como separador decimal.
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
    final notifier = ref.read(expenseFormViewModelProvider.notifier);
    final quotes = ref.read(dolarQuotesProvider).valueOrNull ?? const [];

    // En USD guardamos el equivalente en ARS y dejamos el monto original aparte.
    final amountArs = _currency == Currency.usd
        ? notifier.convertUsdToArs(amount, _dolarType, quotes)
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

  // Arma la UI del formulario de gasto (detalle, monto y, si es USD, cotizacion).
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseFormViewModelProvider);
    final quotesAsync = ref.watch(dolarQuotesProvider);

    // Hidratar form si llego un expense para editar
    if (state.expense != null) {
      _hydrateFromState(state.expense!);
    }

    // Reacciona al guardado: si salio bien cierra, si fallo muestra el error.
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
                  // Solo si el gasto es en USD pedimos el tipo de cotizacion y la mostramos.
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
                    _DolarQuoteBox(
                      quotesAsync: quotesAsync,
                      dolarTypeCode: _dolarType,
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

// Cajita que muestra la cotizacion del dolar segun el tipo elegido (o avisa si no hay).
class _DolarQuoteBox extends StatelessWidget {
  final AsyncValue<List<DolarQuote>> quotesAsync;
  final String dolarTypeCode;

  const _DolarQuoteBox({
    required this.quotesAsync,
    required this.dolarTypeCode,
  });

  static final _dateTimeFmt = DateFormat('dd/MM/yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    return quotesAsync.when(
      loading: () => Text(
        'Cargando cotización...',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary.withOpacity(0.9),
        ),
      ),
      error: (_, __) => Text(
        'No se pudo obtener cotización, se usará tabla por defecto',
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.mangoDeep,
          fontWeight: FontWeight.w600,
        ),
      ),
      data: (quotes) {
        // Buscamos la cotizacion que corresponde a la "casa" del tipo elegido.
        final apiCasa = DolarType.all
                .firstWhere(
                  (t) => t.code == dolarTypeCode,
                  orElse: () => DolarType.blue,
                )
                .apiCasa;
        DolarQuote? quote;
        for (final q in quotes) {
          if (q.casa == apiCasa) {
            quote = q;
            break;
          }
        }

        if (quote == null) {
          return Text(
            'No se pudo obtener cotización, se usará tabla por defecto',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mangoDeep,
              fontWeight: FontWeight.w600,
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.mangoYellow.withOpacity(0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1 USD = ${Fmt.money(quote.venta)} ARS (${quote.nombre})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mangoDeep,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Actualizado: '
                '${_dateTimeFmt.format(quote.fechaActualizacion.toLocal())}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Etiqueta de seccion en mayusculas (tipo "DETALLE", "MONTO").
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

// Selector horizontal de categorias en chips, con un boton "Nueva" al final para crear una.
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

// Toggle Pesos/Dolares para elegir la moneda del gasto.
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

// Cada uno de los dos botones del toggle de moneda.
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
