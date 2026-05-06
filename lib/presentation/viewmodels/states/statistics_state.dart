import 'package:equatable/equatable.dart';

import '../../../domain/category.dart';
import '../../utils/base_screen_state.dart';

/// Una porcion del grafico de torta (un mes) o una barra del grafico
/// trimestral / anual.
class CategorySlice extends Equatable {
  final Category category;
  final double total;

  const CategorySlice({required this.category, required this.total});

  @override
  List<Object?> get props => [category, total];
}

class QuarterBar extends Equatable {
  final int year;
  final int quarter; // 1..4
  final double total;
  const QuarterBar(
      {required this.year, required this.quarter, required this.total});

  String get label => 'Q$quarter $year';

  @override
  List<Object?> get props => [year, quarter, total];
}

enum StatsRange { month, quarter, year }

class StatisticsState extends Equatable {
  final BaseScreenState screenState;
  final DateTime selectedMonth; // mes a graficar en torta
  final List<CategorySlice> pieSlices;
  final List<QuarterBar> bars;
  final StatsRange barRange;
  final double monthTotal;

  StatisticsState({
    this.screenState = const BaseScreenState.idle(),
    DateTime? selectedMonth,
    this.pieSlices = const [],
    this.bars = const [],
    this.barRange = StatsRange.year,
    this.monthTotal = 0,
  }) : selectedMonth =
            selectedMonth ?? DateTime(DateTime.now().year, DateTime.now().month);

  StatisticsState copyWith({
    BaseScreenState? screenState,
    DateTime? selectedMonth,
    List<CategorySlice>? pieSlices,
    List<QuarterBar>? bars,
    StatsRange? barRange,
    double? monthTotal,
  }) =>
      StatisticsState(
        screenState: screenState ?? this.screenState,
        selectedMonth: selectedMonth ?? this.selectedMonth,
        pieSlices: pieSlices ?? this.pieSlices,
        bars: bars ?? this.bars,
        barRange: barRange ?? this.barRange,
        monthTotal: monthTotal ?? this.monthTotal,
      );

  @override
  List<Object?> get props =>
      [screenState, selectedMonth, pieSlices, bars, barRange, monthTotal];
}
