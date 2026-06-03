import 'package:equatable/equatable.dart';

import '../../../domain/category.dart';
import '../../utils/base_screen_state.dart';

/// Una porcion del grafico de torta para el mes seleccionado.
class CategorySlice extends Equatable {
  final Category category; // la categoria que representa esta porcion
  final double total; // cuanto se gasto en esa categoria ese mes

  const CategorySlice({required this.category, required this.total});

  @override
  List<Object?> get props => [category, total];
}

/// Estado de la pantalla de estadisticas: grafico de torta por categoria del
/// mes elegido, mas el total gastado en ese mes.
class StatisticsState extends Equatable {
  final BaseScreenState screenState; // estado visual: loading / idle / error

  /// Primer dia del mes seleccionado (ej: DateTime(2026, 5, 1)).
  final DateTime selectedMonth;
  final List<CategorySlice> pieSlices; // porciones del grafico (una por categoria)
  final double monthTotal; // total gastado en el mes seleccionado

  StatisticsState({
    this.screenState = const BaseScreenState.idle(),
    DateTime? selectedMonth,
    this.pieSlices = const [],
    this.monthTotal = 0,
  }) : // si no nos dan mes, arrancamos en el mes actual (dia 1).
        selectedMonth = selectedMonth ??
            DateTime(DateTime.now().year, DateTime.now().month, 1);

  // Copia el estado cambiando solo los campos que le pasemos.
  StatisticsState copyWith({
    BaseScreenState? screenState,
    DateTime? selectedMonth,
    List<CategorySlice>? pieSlices,
    double? monthTotal,
  }) =>
      StatisticsState(
        screenState: screenState ?? this.screenState,
        selectedMonth: selectedMonth ?? this.selectedMonth,
        pieSlices: pieSlices ?? this.pieSlices,
        monthTotal: monthTotal ?? this.monthTotal,
      );

  @override
  List<Object?> get props =>
      [screenState, selectedMonth, pieSlices, monthTotal];
}
