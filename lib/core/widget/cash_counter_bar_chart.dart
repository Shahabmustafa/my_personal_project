import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Ek bar ka data — [short] chart ke neeche axis label, [label] tooltip aur
/// neeche wali list mein poora naam.
class CashCounterBar {
  final String short;
  final String label;
  final double value;
  final Color color;
  const CashCounterBar(this.short, this.label, this.value, this.color);
}

/// Cash counter ke ek din (row) ka breakdown bar graph mein — branch aur
/// head office dono cash counter screens ke detail slider mein use hota hai.
/// Graph ke neeche har bar ki exact amount bhi list hoti hai.
class CashCounterBarChart extends StatelessWidget {
  final List<CashCounterBar> bars;
  const CashCounterBarChart({super.key, required this.bars});

  static String _short(double v) {
    final a = v.abs();
    final sign = v < 0 ? '-' : '';
    if (a >= 1000000) return '$sign${(a / 1000000).toStringAsFixed(1)}M';
    if (a >= 1000) return '$sign${(a / 1000).toStringAsFixed(1)}k';
    return '$sign${a.toStringAsFixed(0)}';
  }

  static String _amt(double v) =>
      v == v.truncate() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final maxVal = bars.fold<double>(0, (a, b) => b.value > a ? b.value : a);
    final minVal = bars.fold<double>(0, (a, b) => b.value < a ? b.value : a);
    // Headroom taake sab se oonchi bar top se na lage.
    final maxY = maxVal <= 0 ? 1.0 : maxVal * 1.15;
    final minY = minVal < 0 ? minVal * 1.15 : 0.0;
    final interval = ((maxY - minY) / 4).clamp(1, double.infinity).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 240,
          child: BarChart(
            BarChartData(
              minY: minY,
              maxY: maxY,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: Color(0xFFEEEEEE), strokeWidth: 0.8),
              ),
              borderData: FlBorderData(
                show: true,
                border: const Border(
                  left: BorderSide(color: Color(0xFFE0E0E0)),
                  bottom: BorderSide(color: Color(0xFFE0E0E0)),
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 38,
                    interval: interval,
                    getTitlesWidget: (value, meta) => Text(
                      _short(value),
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF8A8FA3),
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 26,
                    getTitlesWidget: (value, meta) {
                      final i = value.round();
                      if (i < 0 || i >= bars.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          bars[i].short,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF1F2333),
                  tooltipRoundedRadius: 8,
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final b = bars[group.x];
                    return BarTooltipItem(
                      '${b.label}\nRs. ${_amt(b.value)}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              barGroups: [
                for (var i = 0; i < bars.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: bars[i].value,
                        color: bars[i].color,
                        width: bars.length > 6 ? 14 : 22,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        for (final b in bars)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: b.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  b.label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8A8FA3),
                  ),
                ),
                const Spacer(),
                Text(
                  'Rs. ${_amt(b.value)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: b.color,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
