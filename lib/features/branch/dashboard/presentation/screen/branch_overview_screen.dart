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
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
  return v.toStringAsFixed(0);
}

// ── Weekly sale bar graph — last 7 days ────────────────────────────────────

class _WeeklySaleChart extends StatelessWidget {
  final List<DaySale> rows;
  const _WeeklySaleChart({required this.rows});

  static const _accent = Color(0xFF3E63DD);
  static const _weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final total = rows.fold<double>(0, (s, r) => s + r.amount);
    final maxVal = rows.fold<double>(0, (a, r) => r.amount > a ? r.amount : a);
    final maxY = maxVal <= 0 ? 1.0 : maxVal * 1.2;

    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '1 Week Sale — Last 7 Days',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                'Rs. ${_pkrShort(total)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (rows.isEmpty)
            const SizedBox(
              height: 160,
              child: Center(
                child: Text('Data nahi',
                    style: TextStyle(color: Color(0xFF8A8FA3))),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY,
                  minX: 0,
                  maxX: (rows.length - 1).toDouble(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 3,
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
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final i = value.round();
                          if (i < 0 || i >= rows.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _weekday[rows[i].day.weekday - 1],
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF8A8FA3),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((spot) {
                        final i = spot.x.round();
                        final day = i >= 0 && i < rows.length
                            ? _weekday[rows[i].day.weekday - 1]
                            : '';
                        return LineTooltipItem(
                          '$day\nRs. ${_pkrShort(spot.y)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                    getTouchedSpotIndicator: (barData, indexes) => indexes
                        .map((_) => TouchedSpotIndicatorData(
                              FlLine(color: _accent.withOpacity(0.3), strokeWidth: 2),
                              FlDotData(
                                getDotPainter: (spot, percent, bar, index) =>
                                    FlDotCirclePainter(
                                  radius: 5,
                                  color: _accent,
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < rows.length; i++)
                          FlSpot(i.toDouble(), rows[i].amount),
                      ],
                      isCurved: true,
                      curveSmoothness: 0.3,
                      preventCurveOverShooting: true,
                      color: _accent,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2.5,
                          strokeColor: _accent,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _accent.withOpacity(0.28),
                            _accent.withOpacity(0.0),
                          ],
                        ),
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

// ── Top 10 articles sold (branch) ─────────────────────────────────────────

class _TopArticlesCard extends StatelessWidget {
  final List<TopArticle> rows;
  const _TopArticlesCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    final maxQty = rows.fold<int>(0, (a, r) => r.quantity > a ? r.quantity : a);

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
          const SizedBox(height: 14),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Data nahi',
                    style: TextStyle(color: Color(0xFF8A8FA3))),
              ),
            )
          else
            for (var i = 0; i < rows.length; i++) ...[
              if (i != 0) const Divider(height: 18, color: Color(0xFFEDEFF5)),
              _TopArticleRow(
                rank: i + 1,
                article: rows[i],
                maxQty: maxQty <= 0 ? 1 : maxQty,
              ),
            ],
        ],
      ),
    );
  }
}

class _TopArticleRow extends StatelessWidget {
  final int rank;
  final TopArticle article;
  final int maxQty;
  const _TopArticleRow({
    required this.rank,
    required this.article,
    required this.maxQty,
  });

  static const _accent = Color(0xFF3E63DD);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 22,
          child: Text(
            '$rank',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8A8FA3),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                article.articleName,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: article.quantity / maxQty,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFEDEFF5),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(_accent),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${article.quantity} pcs',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              'Rs. ${_pkrShort(article.amount)}',
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF8A8FA3)),
            ),
          ],
        ),
      ],
    );
  }
}
