import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../utils/base_screen_state.dart';
import '../utils/category_icons.dart';
import '../utils/formatter.dart';
import '../viewmodels/providers.dart';
import '../viewmodels/states/statistics_state.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  static const name = 'StatisticsScreen';
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  int _touchedPieIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(statisticsViewModelProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statisticsViewModelProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadisticas'),
      ),
      body: state.screenState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (msg) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error: $msg'),
          ),
        ),
        idle: () => RefreshIndicator(
          onRefresh: () =>
              ref.read(statisticsViewModelProvider.notifier).load(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _MonthHeader(
                periodStart: state.periodStart,
                periodEnd: state.periodEnd,
                total: state.periodTotal,
              ),
              const SizedBox(height: 16),
              _SectionTitle(
                text:
                    'Distribucion por categoria (${Fmt.shortDate(state.periodStart)} - ${Fmt.shortDate(state.periodEnd)})',
              ),
              const SizedBox(height: 12),
              if (state.pieSlices.isEmpty)
                const _EmptyChart(
                  message: 'No hay gastos en los ultimos 30 dias',
                )
              else
                _PieChartCard(
                  slices: state.pieSlices,
                  periodTotal: state.periodTotal,
                  touchedIndex: _touchedPieIndex,
                  onTouch: (i) => setState(() => _touchedPieIndex = i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Header con el total y el rango activo
class _MonthHeader extends StatelessWidget {
  final DateTime periodStart;
  final DateTime periodEnd;
  final double total;
  const _MonthHeader({
    required this.periodStart,
    required this.periodEnd,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.mangoYellow, AppColors.mangoOrange],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total ultimos 30 dias',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      '${Fmt.shortDate(periodStart)} - ${Fmt.shortDate(periodEnd)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Fmt.money(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String message;
  const _EmptyChart({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Center(
        child: Text(message,
            style: const TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Pie chart
class _PieChartCard extends StatelessWidget {
  final List<CategorySlice> slices;
  final double periodTotal;
  final int touchedIndex;
  final ValueChanged<int> onTouch;

  const _PieChartCard({
    required this.slices,
    required this.periodTotal,
    required this.touchedIndex,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 56,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    if (response?.touchedSection == null) {
                      onTouch(-1);
                      return;
                    }
                    onTouch(response!.touchedSection!.touchedSectionIndex);
                  },
                ),
                sections: List.generate(slices.length, (i) {
                  final slice = slices[i];
                  final isTouched = i == touchedIndex;
                  final radius = isTouched ? 78.0 : 70.0;
                  final percent = periodTotal == 0
                      ? 0.0
                      : (slice.total / periodTotal) * 100;
                  return PieChartSectionData(
                    color: slice.category.color,
                    value: slice.total,
                    title: percent >= 7 ? '${percent.toStringAsFixed(0)}%' : '',
                    radius: radius,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...slices.map((s) => _LegendRow(
                slice: s,
                percent: periodTotal == 0 ? 0 : (s.total / periodTotal) * 100,
              )),
        ],
      ),
    );
  }
}
class _LegendRow extends StatelessWidget {
  final CategorySlice slice;
  final double percent;
  const _LegendRow({required this.slice, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: slice.category.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              CategoryIcons.iconFor(slice.category.iconKey),
              color: slice.category.color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slice.category.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '${percent.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(Fmt.money(slice.total),
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
