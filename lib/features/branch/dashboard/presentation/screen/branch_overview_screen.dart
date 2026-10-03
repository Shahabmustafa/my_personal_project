import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/branch_overview_model.dart';
import '../provider/branch_overview_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
class BranchOverviewScreen extends ConsumerWidget {
  const BranchOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(branchOverviewProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(branchOverviewProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dashboard',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        SizedBox(height: 2),
                        Text('Overview of your branch',
                            style: TextStyle(fontSize: 13, color: Color(0xFF8A8FA3))),
                      ],
                    ),
                  ),
                  Tooltip(
                    message: 'Refresh',
                    child: InkWell(
                      onTap: () => ref.invalidate(branchOverviewProvider),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE7E9F0)),
                        ),
                        child: const AppIcon(AppIcons.refresh, color: Color(0xFF3E63DD), size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              overviewAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(children: [
                      const AppIcon(AppIcons.errorOutline, size: 40, color: Colors.redAccent),
                      const SizedBox(height: 10),
                      Text('Error: $e', style: const TextStyle(color: Color(0xFF8A8FA3))),
                    ]),
                  ),
                ),
                data: (data) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CardGrid(data: data),
                    const SizedBox(height: 20),
                    _WeeklySaleChart(rows: data.weeklySale),
                    const SizedBox(height: 20),
                    _TopArticlesCard(rows: data.topArticles),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Card grid — 3 per row on desktop, stacked on mobile ────────────────────

class _CardGrid extends StatelessWidget {
  final BranchOverviewData data;
  const _CardGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _CardSpec(
        label: 'Total Article',
        value: '${data.totalArticles}',
        icon: AppIcons.inventory2Outlined,
        color: const Color(0xFF3E63DD),
      ),
      _CardSpec(
        label: 'Total Invoice',
        value: '${data.totalInvoices}',
        icon: AppIcons.receiptLongOutlined,
        color: const Color(0xFF6C4DE0),
      ),
      _CardSpec(
        label: 'Today Sale',
        value: 'Rs. ${_fmtAmt(data.todaySale)}',
        icon: AppIcons.pointOfSaleOutlined,
        color: const Color(0xFF22A06B),
      ),
      _CardSpec(
        label: 'Today Target',
        value: data.todayTarget > 0 ? 'Rs. ${_fmtAmt(data.todayTarget)}' : 'Not set',
        icon: AppIcons.flagOutlined,
        color: data.todayTarget <= 0
            ? const Color(0xFF8A8FA3)
            : data.todaySale >= data.todayTarget
                ? const Color(0xFF22A06B)
                : const Color(0xFFE56A00),
        muted: data.todayTarget <= 0,
      ),
      _CardSpec(
        label: 'Total Salesman',
        value: '${data.totalSalesman}',
        icon: AppIcons.badgeOutlined,
        color: const Color(0xFF1565C0),
      ),
      _CardSpec(
        label: 'Total Expense',
        value: 'Rs. ${_fmtAmt(data.todayExpense)}',
        icon: AppIcons.receiptOutlined,
        color: const Color(0xFFE56A00),
      ),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 700;
      if (isMobile) {
        return Column(
          children: cards
              .map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OverviewCard(spec: c),
                  ))
              .toList(),
        );
      }
      final rows = <Widget>[];
      for (var i = 0; i < cards.length; i += 3) {
        final rowCards = cards.sublist(i, (i + 3).clamp(0, cards.length));
        rows.add(Row(
          children: [
            for (int j = 0; j < rowCards.length; j++) ...[
              Expanded(child: _OverviewCard(spec: rowCards[j])),
              if (j != rowCards.length - 1) const SizedBox(width: 14),
            ],
          ],
        ));
        rows.add(const SizedBox(height: 14));
      }
      return Column(children: rows);
    });
  }
}

class _CardSpec {
  final String label;
  final String value;
  final String icon;
  final Color color;
  final bool muted;
  const _CardSpec({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.muted = false,
  });
}

class _OverviewCard extends StatelessWidget {
  final _CardSpec spec;
  const _OverviewCard({required this.spec});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E9F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: spec.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppIcon(spec.icon, color: spec.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(spec.label,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF8A8FA3), fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  spec.value,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    fontStyle: spec.muted ? FontStyle.italic : FontStyle.normal,
                    color: spec.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _fmtAmt(double v) {
  if (v == v.truncate()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(2);
}

// ── Shared card shell ─────────────────────────────────────────────────────

class _PanelCard extends StatelessWidget {
  final Widget child;
  const _PanelCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E9F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

String _pkrShort(double v) {
  if (v < 0) return '-${_pkrShort(-v)}';
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
  return v.toStringAsFixed(0);
}

// ── Weekly sale line graph — last 7 days ───────────────────────────────────

class _WeeklySaleChart extends StatelessWidget {
  final List<DaySale> rows;
  const _WeeklySaleChart({required this.rows});

  static const _accent = Color(0xFF3E63DD);
  static const _muted = Color(0xFF8A8FA3);
  static const _negative = Color(0xFFC62828);
  static const _weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _month = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _dayMonth(DateTime d) => '${d.day} ${_month[d.month - 1]}';

  @override
  Widget build(BuildContext context) {
    final total = rows.fold<double>(0, (s, r) => s + r.amount);
    final avg = rows.isEmpty ? 0.0 : total / rows.length;
    DaySale? best;
    for (final r in rows) {
      if (best == null || r.amount > best.amount) best = r;
    }

    final maxVal = rows.fold<double>(0, (a, r) => r.amount > a ? r.amount : a);
    // Return zyada ho to kisi din ki net sale minus mein ja sakti hai.
    final minVal = rows.fold<double>(0, (a, r) => r.amount < a ? r.amount : a);
    final maxY = maxVal <= 0 ? 1.0 : maxVal * 1.2;
    final minY = minVal < 0 ? minVal * 1.2 : 0.0;
    final interval = (maxY - minY) / 4;
    final lastIndex = rows.length - 1;

    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  size: 18,
                  color: _accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weekly Sale',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rows.isEmpty
                          ? 'Last 7 days'
                          : '${_dayMonth(rows.first.day)} – ${_dayMonth(rows.last.day)} · net of returns',
                      style: const TextStyle(fontSize: 11, color: _muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatChip(
                label: 'Total',
                value: 'Rs. ${_pkrShort(total)}',
                color: total < 0 ? _negative : const Color(0xFF2E7D32),
              ),
              _StatChip(
                label: 'Avg / day',
                value: 'Rs. ${_pkrShort(avg)}',
                color: _accent,
              ),
              if (best != null && best.amount > 0)
                _StatChip(
                  label: 'Best',
                  value:
                      '${_weekday[best.day.weekday - 1]} · Rs. ${_pkrShort(best.amount)}',
                  color: const Color(0xFFE08A00),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (rows.isEmpty)
            const SizedBox(
              height: 160,
              child: Center(
                child: Text('Data nahi', style: TextStyle(color: _muted)),
              ),
            )
          else
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  minX: -0.2,
                  maxX: lastIndex + 0.2,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: Color(0xFFEDEFF5),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  // Net sale minus ho to zero ki line wazeh dikhe.
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      if (minY < 0)
                        HorizontalLine(
                          y: 0,
                          color: const Color(0xFFB0B5C5),
                          strokeWidth: 1,
                        ),
                    ],
                  ),
                  borderData: FlBorderData(show: false),
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
                        reservedSize: 40,
                        interval: interval,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.max) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            _pkrShort(value),
                            style: const TextStyle(fontSize: 10, color: _muted),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final i = value.round();
                          if (i < 0 || i > lastIndex || value != i) {
                            return const SizedBox.shrink();
                          }
                          final isToday = i == lastIndex;
                          final color = isToday ? _accent : _muted;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isToday
                                      ? 'Today'
                                      : _weekday[rows[i].day.weekday - 1],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: color,
                                    fontWeight: isToday
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${rows[i].day.day}',
                                  style: TextStyle(fontSize: 9, color: color),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => const Color(0xFF1F2333),
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (spots) => spots.map((spot) {
                        final i = spot.x.round();
                        final d = rows[i].day;
                        return LineTooltipItem(
                          '${_weekday[d.weekday - 1]}, ${_dayMonth(d)}\n',
                          const TextStyle(
                            color: Color(0xFFB8BDD0),
                            fontSize: 10,
                          ),
                          children: [
                            TextSpan(
                              text: 'Rs. ${_fmtAmt(spot.y)}',
                              style: TextStyle(
                                color: spot.y < 0
                                    ? const Color(0xFFFF8A80)
                                    : Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    getTouchedSpotIndicator: (barData, indexes) => indexes
                        .map(
                          (_) => TouchedSpotIndicatorData(
                            FlLine(
                              color: _accent.withValues(alpha: 0.35),
                              strokeWidth: 1.5,
                              dashArray: [4, 3],
                            ),
                            FlDotData(
                              getDotPainter: (spot, percent, bar, index) =>
                                  FlDotCirclePainter(
                                    radius: 6,
                                    color: _accent,
                                    strokeWidth: 3,
                                    strokeColor: Colors.white,
                                  ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < rows.length; i++)
                          FlSpot(i.toDouble(), rows[i].amount),
                      ],
                      isCurved: true,
                      curveSmoothness: 0.35,
                      preventCurveOverShooting: true,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C9BFF), _accent],
                      ),
                      barWidth: 3.5,
                      isStrokeCapRound: true,
                      shadow: Shadow(
                        color: _accent.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) {
                          final isToday = index == lastIndex;
                          final dotColor = spot.y < 0 ? _negative : _accent;
                          return FlDotCirclePainter(
                            radius: isToday ? 5.5 : 3.5,
                            color: isToday ? dotColor : Colors.white,
                            strokeWidth: isToday ? 3 : 2,
                            strokeColor: isToday ? Colors.white : dotColor,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        cutOffY: 0,
                        applyCutOffY: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _accent.withValues(alpha: 0.25),
                            _accent.withValues(alpha: 0.02),
                          ],
                        ),
                      ),
                      aboveBarData: BarAreaData(
                        show: minY < 0,
                        cutOffY: 0,
                        applyCutOffY: true,
                        color: _negative.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11, color: Color(0xFF8A8FA3)),
          children: [
            TextSpan(text: '$label  '),
            TextSpan(
              text: value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top 10 articles sold (branch) — vertical bar chart ──────────────────────

class _TopArticlesCard extends StatelessWidget {
  final List<TopArticle> rows;
  const _TopArticlesCard({required this.rows});

  static const _accent = Color(0xFF3E63DD);

  @override
  Widget build(BuildContext context) {
    final maxQty = rows.fold<int>(0, (a, r) => r.quantity > a ? r.quantity : a);
    final maxY = maxQty <= 0 ? 1.0 : maxQty * 1.2;

    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top 10 Articles Sold',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sab se zyada bikne wale articles',
            style: TextStyle(fontSize: 12, color: Color(0xFF8A8FA3)),
          ),
          const SizedBox(height: 16),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Data nahi',
                    style: TextStyle(color: Color(0xFF8A8FA3))),
              ),
            )
          else
            SizedBox(
              height: 280,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: Color(0xFFEDEFF5), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
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
                        reservedSize: 32,
                        interval: maxY / 4,
                        getTitlesWidget: (value, meta) => Text(
                          value.round().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF8A8FA3),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 64,
                        getTitlesWidget: (value, meta) {
                          final i = value.round();
                          if (i < 0 || i >= rows.length) {
                            return const SizedBox.shrink();
                          }
                          final name = rows[i].articleName;
                          final label = name.length > 10
                              ? '${name.substring(0, 10)}…'
                              : name;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Transform.rotate(
                              angle: -0.6,
                              alignment: Alignment.topRight,
                              child: Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFF8A8FA3),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final article = rows[group.x.toInt()];
                        return BarTooltipItem(
                          '${article.articleName}\n${article.quantity} pcs\nRs. ${_pkrShort(article.amount)}',
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
                    for (var i = 0; i < rows.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: rows[i].quantity.toDouble(),
                            color: _accent,
                            width: 16,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
