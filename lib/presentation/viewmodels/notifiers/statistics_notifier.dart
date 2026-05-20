import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: re-habilitar cuando se reconecte estadísticas a Firestore
// import '../../../data/providers.dart';
// import '../../../domain/categories_repository.dart';
// import '../../../domain/expenses_repository.dart';

import '../../../domain/category.dart';
import '../../utils/base_screen_state.dart';
import '../../utils/category_icons.dart';
import '../providers.dart';
import '../states/statistics_state.dart';

// ============================================================================
// ESTADO ACTUAL: MOCK
// ----------------------------------------------------------------------------
// Esta pantalla está en modo demo: los datos son hardcodeados, no se
// consulta Firestore. La lógica real de agregaciones (groupBy por categoría
// y por trimestre) vive en el historial de git — al reconectar la feature,
// rescatarla de ahí, restaurar los imports comentados de arriba y volver a
// leer del expensesRepositoryProvider + categoriesRepositoryProvider.
// ============================================================================

class StatisticsNotifier extends Notifier<StatisticsState> {
  @override
  StatisticsState build() => StatisticsState();

  Future<void> load() async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;

    state = state.copyWith(screenState: const BaseScreenState.loading());
    await Future.delayed(const Duration(milliseconds: 400));

    final pieSlices = _mockSlices(state.selectedMonth);
    final monthTotal = pieSlices.fold<double>(0, (sum, s) => sum + s.total);
    final bars = _mockBars(state.selectedMonth);

    state = state.copyWith(
      screenState: const BaseScreenState.idle(),
      pieSlices: pieSlices,
      bars: bars,
      monthTotal: monthTotal,
    );
  }

  void selectMonth(DateTime month) {
    state = state.copyWith(selectedMonth: DateTime(month.year, month.month));
    load();
  }

  void setBarRange(StatsRange range) {
    state = state.copyWith(barRange: range);
  }

  List<CategorySlice> _mockSlices(DateTime month) {
    // Factor determinístico según el mes para que los gráficos cambien al
    // seleccionar otro mes, manteniendo los totales dentro del rango pedido.
    final factor = 0.6 + (month.month / 12) * 0.8; // ~0.67 .. 1.4
    final createdAt = DateTime(2025, 1, 1);

    CategorySlice make(
      String id,
      String title,
      String iconKey,
      int colorValue,
      double base,
    ) {
      return CategorySlice(
        category: Category(
          id: id,
          userId: 'mock',
          title: title,
          iconKey: iconKey,
          colorValue: colorValue,
          createdAt: createdAt,
        ),
        total: (base * factor).clamp(8000.0, 320000.0).toDouble(),
      );
    }

    final slices = [
      make('mock_food', 'Comida', CategoryIcons.food.key,
          CategoryColors.palette[0], 180000),
      make('mock_transport', 'Transporte', CategoryIcons.transport.key,
          CategoryColors.palette[3], 95000),
      make('mock_entertainment', 'Entretenimiento',
          CategoryIcons.entertainment.key, CategoryColors.palette[4], 62000),
      make('mock_home', 'Hogar', CategoryIcons.home.key,
          CategoryColors.palette[2], 145000),
      make('mock_health', 'Salud', CategoryIcons.health.key,
          CategoryColors.palette[6], 28000),
    ];
    slices.sort((a, b) => b.total.compareTo(a.total));
    return slices;
  }

  List<QuarterBar> _mockBars(DateTime month) {
    final factor = 0.6 + (month.month / 12) * 0.8;
    final currentQuarter = ((month.month - 1) ~/ 3) + 1;
    // Bases en orden cronológico: el trimestre más viejo primero, el actual al final.
    final bases = [820000.0, 940000.0, 760000.0, 1050000.0];
    final bars = <QuarterBar>[];
    for (var offset = 3; offset >= 0; offset--) {
      var q = currentQuarter - offset;
      var y = month.year;
      while (q <= 0) {
        q += 4;
        y -= 1;
      }
      bars.add(QuarterBar(
        year: y,
        quarter: q,
        total: (bases[3 - offset] * factor).clamp(200000.0, 1200000.0).toDouble(),
      ));
    }
    return bars;
  }
}
