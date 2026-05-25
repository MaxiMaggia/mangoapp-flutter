import 'package:equatable/equatable.dart';

import '../../../domain/category.dart';
import '../../utils/base_screen_state.dart';

/// Una porcion del grafico de torta para el periodo estadistico.
class CategorySlice extends Equatable {
  final Category category;
  final double total;

  const CategorySlice({required this.category, required this.total});

  @override
  List<Object?> get props => [category, total];
}

class StatisticsState extends Equatable {
  final BaseScreenState screenState;
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<CategorySlice> pieSlices;
  final double periodTotal;

  StatisticsState({
    this.screenState = const BaseScreenState.idle(),
    DateTime? periodStart,
    DateTime? periodEnd,
    this.pieSlices = const [],
    this.periodTotal = 0,
  })  : periodEnd = periodEnd ?? DateTime.now(),
        periodStart =
            periodStart ?? DateTime.now().subtract(const Duration(days: 30));

  StatisticsState copyWith({
    BaseScreenState? screenState,
    DateTime? periodStart,
    DateTime? periodEnd,
    List<CategorySlice>? pieSlices,
    double? periodTotal,
  }) =>
      StatisticsState(
        screenState: screenState ?? this.screenState,
        periodStart: periodStart ?? this.periodStart,
        periodEnd: periodEnd ?? this.periodEnd,
        pieSlices: pieSlices ?? this.pieSlices,
        periodTotal: periodTotal ?? this.periodTotal,
      );

  @override
  List<Object?> get props =>
      [screenState, periodStart, periodEnd, pieSlices, periodTotal];
}
