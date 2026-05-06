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

  void _pickMonth() async {
    final state = ref.read(statisticsViewModelProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: state.selectedMonth,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime.now(),
      helpText: 'Mes',
    );
    if (picked != null) {
      ref.read(statisticsViewModelProvider.notifier).selectMonth(picked);
    }
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
                month: state.selectedMonth,
                total: state.monthTotal,
                onPickMonth: _pickMonth,
              ),
              const SizedBox(height: 16),
              _SectionTitle(
                  text: 'Distribucion por categoria (${Fmt.monthLabel(state.selectedMonth)})'),
              const SizedBox(height: 12),
              if (state.pieSlices.isEmpty)
                const _EmptyChart(message: 'No hay gastos en este mes')
              else
                _PieChartCard(
                  slices: state.pieSlices,
                  monthTotal: state.monthTotal,
                  touchedIndex: _touchedPieIndex,
                  onTouch: (i) => setState(() => _touchedPieIndex = i),
                ),
              const SizedBox(height: 24),
              _SectionTitle(text: 'Ultimos 4 trimestres'),
              const SizedBox(height: 12),
              if (state.bars.isEmpty)
                const _EmptyChart(message: 'No hay datos suficientes')
              else
                _BarsChartCard(bars: state.bars),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Header con el total y selector de mes
class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final double total;
  final VoidCallback onPickMonth;
  const _MonthHeader(
      {required this.month, required this.total, required this.onPickMonth});

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
                'Total del mes',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
              InkWell(
                onTap: onPickMonth,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
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
                        Fmt.monthLabel(month),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
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
  final double monthTotal;
  final int touchedIndex;
  final ValueChanged<int> onTouch;

  const _PieChartCard({
    required this.slices,
    required this.monthTotal,
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
                  final percent =
                      monthTotal == 0 ? 0.0 : (slice.total / monthTotal) * 100;
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
                percent: monthTotal == 0 ? 0 : (s.total / monthTotal) * 100,
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

// -----------------------------------------------------------------------------
// Bar chart trimestral
class _BarsChartCard extends StatelessWidget {
  final List<QuarterBar> bars;
  const _BarsChartCard({required this.bars});

  @override
  Widget build(BuildContext context) {
    final maxValue = bars.fold<double>(0, (m, b) => b.total > m ? b.total : m);
    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue * 1.2,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.black.withOpacity(0.05),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 56,
                getTitlesWidget: (value, _) {
                  if (value == 0) return const SizedBox();
                  final k = (value / 1000).toStringAsFixed(0);
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      '\$${k}k',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= bars.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      bars[i].label,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600),
                    ),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: List.generate(bars.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: bars[i].total,
                  width: 22,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8), bottom: Radius.zero),
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [AppColors.mangoOrange, AppColors.mangoYellow],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
