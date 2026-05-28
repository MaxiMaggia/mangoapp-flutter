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

  Future<void> _showMonthPicker(DateTime selected) async {
    final now = DateTime.now();
    final months = List.generate(
      12,
      (i) => DateTime(now.year, now.month - i, 1),
    );

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                'Elegí un mes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            for (final month in months)
              ListTile(
                title: Text(Fmt.monthYear(month)),
                trailing: month.year == selected.year &&
                        month.month == selected.month
                    ? const Icon(Icons.check, color: AppColors.mangoDeep)
                    : null,
                onTap: () {
                  ref
                      .read(statisticsViewModelProvider.notifier)
                      .selectMonth(month);
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
      ),
    );
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
        idle: () {
          final notifier = ref.read(statisticsViewModelProvider.notifier);
          return RefreshIndicator(
            onRefresh: () => notifier.load(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _MonthHeader(
                  selectedMonth: state.selectedMonth,
                  total: state.monthTotal,
                  canGoNext: notifier.canGoNext,
                  onPrev: notifier.goToPreviousMonth,
                  onNext: notifier.goToNextMonth,
                  onTapMonth: () => _showMonthPicker(state.selectedMonth),
                ),
                const SizedBox(height: 16),
                _SectionTitle(
                  text: 'Distribucion por categoria',
                ),
                const SizedBox(height: 12),
                if (state.pieSlices.isEmpty)
                  _EmptyChart(
                    message:
                        'No hay gastos en ${Fmt.monthYear(state.selectedMonth)}',
                  )
                else
                  _PieChartCard(
                    slices: state.pieSlices,
                    monthTotal: state.monthTotal,
                    touchedIndex: _touchedPieIndex,
                    onTouch: (i) => setState(() => _touchedPieIndex = i),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Header con el total y el selector de mes navegable
class _MonthHeader extends StatelessWidget {
  final DateTime selectedMonth;
  final double total;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onTapMonth;

  const _MonthHeader({
    required this.selectedMonth,
    required this.total,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
    required this.onTapMonth,
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
              Expanded(
                child: Text(
                  'Total de ${Fmt.monthYear(selectedMonth)}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
              _MonthNavigator(
                selectedMonth: selectedMonth,
                canGoNext: canGoNext,
                onPrev: onPrev,
                onNext: onNext,
                onTapMonth: onTapMonth,
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

class _MonthNavigator extends StatelessWidget {
  final DateTime selectedMonth;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onTapMonth;

  const _MonthNavigator({
    required this.selectedMonth,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
    required this.onTapMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ArrowButton(icon: Icons.chevron_left, onTap: onPrev),
        const SizedBox(width: 2),
        InkWell(
          onTap: onTapMonth,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                  Fmt.monthYear(selectedMonth),
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
        const SizedBox(width: 2),
        _ArrowButton(
          icon: Icons.chevron_right,
          onTap: canGoNext ? onNext : null,
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _ArrowButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(
          icon,
          color: enabled ? Colors.white : Colors.white.withOpacity(0.4),
          size: 24,
        ),
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
                  final percent = monthTotal == 0
                      ? 0.0
                      : (slice.total / monthTotal) * 100;
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
