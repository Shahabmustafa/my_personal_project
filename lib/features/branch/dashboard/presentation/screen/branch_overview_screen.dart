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
                    _ChartsRow(data: data),
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: spec.color.withValues(alpha: 0.1),
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

String _pkrShort(double v) {
  if (v < 0) return '-${_pkrShort(-v)}';
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
  return v.toStringAsFixed(0);
}

// ── Charts row — Jan Ghani branch dashboard jaisa style ────────────────────
// Desktop pe dono charts side-by-side, mobile pe ek ke neeche ek.

const _kTitle = Color(0xFF1A1D23);
const _kAxisLabel = Color(0xFF9CA3AF);
const _kXLabel = Color(0xFF6B7280);
const _kGrid = Color(0xFFEEEEEE);
const _kAxis = Color(0xFFD1D5DB);
const _kBarTop = Color(0xFF3B9A5E);
const _kBarBottom = Color(0xFF8ED4AA);
const _kLine = Color(0xFF38BDF8);
const _kNegative = Color(0xFFC62828);
const _kWeekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _kMonth = [
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

String _dayMonth(DateTime d) => '${d.day} ${_kMonth[d.month - 1]}';

class _ChartsRow extends StatelessWidget {
  final BranchOverviewData data;
  const _ChartsRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final weekly = _WeeklySaleChart(rows: data.weeklySale);
    final top = _TopArticlesChart(rows: data.topArticles);
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 700) {
        return Column(children: [weekly, const SizedBox(height: 16), top]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: weekly),
          const SizedBox(width: 12),
          Expanded(child: top),
        ],
      );
    });
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _kTitle,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 200, child: child),
        ],
      ),
    );
  }
}

const _kEmpty = Center(
  child: Text('No data', style: TextStyle(color: _kAxisLabel)),
);

FlBorderData _axisBorder() => FlBorderData(
      show: true,
      border: const Border(
        left: BorderSide(color: _kAxis),
        bottom: BorderSide(color: _kAxis),
      ),
    );

FlGridData _grid(double interval) => FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: interval,
      getDrawingHorizontalLine: (_) =>
          const FlLine(color: _kGrid, strokeWidth: 0.8),
    );

SideTitles _leftTitles(double interval, String Function(double) fmt) =>
    SideTitles(
      showTitles: true,
      reservedSize: 36,
      interval: interval,
      getTitlesWidget: (value, meta) => Text(
        fmt(value),
        style: const TextStyle(fontSize: 9, color: _kAxisLabel),
      ),
    );

const _noTitles = AxisTitles(sideTitles: SideTitles(showTitles: false));

// ── Last week sale — green gradient bars ───────────────────────────────────

class _WeeklySaleChart extends StatelessWidget {
  final List<DaySale> rows;
  const _WeeklySaleChart({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const _ChartCard(title: 'Last Week Sales', child: _kEmpty);
    }

    final maxVal = rows.fold<double>(0, (a, r) => r.amount > a ? r.amount : a);
    // Return zyada ho to kisi din ki net sale minus mein ja sakti hai.
    final minVal = rows.fold<double>(0, (a, r) => r.amount < a ? r.amount : a);
    final maxY = maxVal <= 0 ? 1.0 : maxVal;
    final minY = minVal < 0 ? minVal : 0.0;
    final interval = (maxY - minY) / 4;
    final lastIndex = rows.length - 1;

    return _ChartCard(
      title: 'Last Week Sales',
      child: BarChart(
        BarChartData(
          minY: minY,
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          gridData: _grid(interval),
          borderData: _axisBorder(),
          titlesData: FlTitlesData(
            topTitles: _noTitles,
            rightTitles: _noTitles,
            leftTitles: AxisTitles(
              sideTitles: _leftTitles(interval, _pkrShort),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if (i < 0 || i > lastIndex) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      i == lastIndex
                          ? 'Today'
                          : _kWeekday[rows[i].day.weekday - 1],
                      style: const TextStyle(fontSize: 10, color: _kXLabel),
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
                final d = rows[group.x].day;
                return BarTooltipItem(
                  '${_kWeekday[d.weekday - 1]}, ${_dayMonth(d)}\n',
                  const TextStyle(color: Color(0xFFB8BDD0), fontSize: 10),
                  children: [
                    TextSpan(
                      text: 'Rs. ${_fmtAmt(rod.toY)}',
                      style: TextStyle(
                        color: rod.toY < 0
                            ? const Color(0xFFFF8A80)
                            : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
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
                    toY: rows[i].amount,
                    width: 22,
                    borderRadius: BorderRadius.circular(4),
                    color: rows[i].amount < 0 ? _kNegative : null,
                    gradient: rows[i].amount < 0
                        ? null
                        : const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [_kBarTop, _kBarBottom],
                          ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ── Top articles — smooth line with soft fill ──────────────────────────────

class _TopArticlesChart extends StatelessWidget {
  final List<TopArticle> rows;
  const _TopArticlesChart({required this.rows});

  @override
  Widget build(BuildContext context) {
    const title = 'Top Articles — Sales Trend';
    if (rows.length < 2) {
      return const _ChartCard(title: title, child: _kEmpty);
    }

    final maxQty = rows.fold<int>(0, (a, r) => r.quantity > a ? r.quantity : a);
    final maxY = maxQty <= 0 ? 1.0 : maxQty.toDouble();
    final interval = maxY / 4;
    final lastIndex = rows.length - 1;

    return _ChartCard(
      title: title,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          minX: 0,
          maxX: lastIndex.toDouble(),
          gridData: _grid(interval),
          borderData: _axisBorder(),
          titlesData: FlTitlesData(
            topTitles: _noTitles,
            rightTitles: _noTitles,
            leftTitles: AxisTitles(
              sideTitles: _leftTitles(interval, (v) => v.round().toString()),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if (i < 0 || i > lastIndex || value != i) {
                    return const SizedBox.shrink();
                  }
                  final name = rows[i].articleName.split(' ').first;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      name.length > 8 ? '${name.substring(0, 8)}…' : name,
                      style: const TextStyle(fontSize: 9, color: _kXLabel),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF1F2333),
              tooltipRoundedRadius: 8,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (spots) => spots.map((spot) {
                final a = rows[spot.x.round()];
                return LineTooltipItem(
                  '${a.articleName}\n',
                  const TextStyle(color: Color(0xFFB8BDD0), fontSize: 10),
                  children: [
                    TextSpan(
                      text: '${a.quantity} pcs · Rs. ${_pkrShort(a.amount)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < rows.length; i++)
                  FlSpot(i.toDouble(), rows[i].quantity.toDouble()),
              ],
              isCurved: true,
              preventCurveOverShooting: true,
              color: _kLine,
              barWidth: 2.2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                  radius: 3.5,
                  color: _kLine,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: _kLine.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
