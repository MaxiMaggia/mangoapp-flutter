import 'package:equatable/equatable.dart';

import '../../../domain/category.dart';
import '../../utils/base_screen_state.dart';

/// Una porcion del grafico de torta para el mes seleccionado.
class CategorySlice extends Equatable {
  final Category category;
  final double total;

  const CategorySlice({required this.category, required this.total});

  @override
  List<Object?> get props => [category, total];
}

class StatisticsState extends Equatable {
  final BaseScreenState screenState;

  /// Primer dia del mes seleccionado (ej: DateTime(2026, 5, 1)).
  final DateTime selectedMonth;
  final List<CategorySlice> pieSlices;
  final double monthTotal;

  StatisticsState({
    this.screenState = const BaseScreenState.idle(),
    DateTime? selectedMonth,
    this.pieSlices = const [],
    this.monthTotal = 0,
  }) : selectedMonth = selectedMonth ??
            DateTime(DateTime.now().year, DateTime.now().month, 1);

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
