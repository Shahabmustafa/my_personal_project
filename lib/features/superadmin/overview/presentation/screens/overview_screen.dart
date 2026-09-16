import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/overview_datasource.dart';
import '../providers/overview_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  static const _accent = Color(0xFF3E63DD);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(overviewStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(overviewStatsProvider.future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Sab branches ka overview',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8A8FA3),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => ref.invalidate(overviewStatsProvider),
                  icon: const AppIcon(AppIcons.refresh, size: 18, color: _accent),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 20),
            statsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Center(
                  child: Column(
                    children: [
                      const AppIcon(
                        AppIcons.errorOutline,
                        color: Colors.redAccent,
                        size: 44,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Error: $e',
                        style: const TextStyle(color: Color(0xFF8A8FA3)),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: () => ref.invalidate(overviewStatsProvider),
                        icon: const AppIcon(AppIcons.refresh, size: 16),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (s) => _Content(stats: s),
            ),
          ],
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final OverviewStats stats;
  const _Content({required this.stats});

  String _pkr(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return 'PKR $buf';
  }

  @override
  Widget build(BuildContext context) {
    final cards = <_StatCardData>[
      _StatCardData(
        'All Branch Article',
        '${stats.branchStockPairs} pairs',
        AppIcons.storefrontOutlined,
        const Color(0xFF7B1FA2),
      ),
      _StatCardData(
        "Today's Profit",
        _pkr(stats.todayProfit),
        AppIcons.savingsOutlined,
        const Color(0xFF00796B),
      ),
      _StatCardData(
        'Total Articles',
        '${stats.totalArticles}',
        AppIcons.inventory2Outlined,
        const Color(0xFF3E63DD),
      ),
      _StatCardData(
        'Total Warehouses',
        '${stats.totalWarehouses}',
        AppIcons.warehouseOutlined,
        const Color(0xFF6A1B9A),
      ),
      _StatCardData(
        'Total Branches',
        '${stats.totalBranches}',
        AppIcons.apartmentOutlined,
        const Color(0xFF00838F),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (ctx, c) {
            final w = c.maxWidth;
            final cols = w > 1100
                ? 4
                : w > 820
                ? 3
                : w > 520
                ? 2
                : 1;
            const gap = 16.0;
            final cardW = (w - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final d in cards)
                  SizedBox(
                    width: cardW,
                    child: _StatCard(data: d),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        _WeeklySaleChart(rows: stats.weeklySale),
        const SizedBox(height: 20),
        _TopArticleCard(article: stats.topArticle),
        const SizedBox(height: 20),
        _TodayByBranch(rows: stats.todaySaleByBranch),
      ],
    );
  }
}

/// Pichle 7 din ki daily sale — fl_chart package se line graph.
class _WeeklySaleChart extends StatelessWidget {
  final List<DaySale> rows;
  const _WeeklySaleChart({required this.rows});

  static const _accent = Color(0xFF3E63DD);
  static const _weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static String _pkrShort(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final total = rows.fold<double>(0, (s, r) => s + r.amount);
    final maxVal = rows.fold<double>(0, (a, r) => r.amount > a ? r.amount : a);
    final maxY = maxVal <= 0 ? 1.0 : maxVal * 1.2;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E9F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Weekly Sale — Last 7 Days',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                'PKR ${_pkrShort(total)}',
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
                child: Text(
                  'Data nahi',
                  style: TextStyle(color: Color(0xFF8A8FA3)),
                ),
              ),
            )
          else
            SizedBox(
              height: 190,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY,
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
                      getTooltipItems: (spots) => spots.map((s) {
                        final i = s.x.round();
                        final day = i >= 0 && i < rows.length
                            ? _weekday[rows[i].day.weekday - 1]
                            : '';
                        return LineTooltipItem(
                          '$day\nPKR ${_pkrShort(s.y)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < rows.length; i++)
                          FlSpot(i.toDouble(), rows[i].amount),
                      ],
                      isCurved: true,
                      color: _accent,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                              radius: 3,
                              color: _accent,
                              strokeWidth: 1.5,
                              strokeColor: Colors.white,
                            ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x333E63DD), Color(0x003E63DD)],
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

class _TopArticleCard extends StatelessWidget {
  final TopArticle? article;
  const _TopArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    final a = article;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E9F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sab Se Zyada Bikne Wala Article',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          if (a == null)
            const Text(
              'Abhi tak koi sale nahi',
              style: TextStyle(color: Color(0xFF8A8FA3)),
            )
          else
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF6C00).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: const AppIcon(
                      AppIcons.emojiEventsOutlined,
                      color: Color(0xFFEF6C00),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    a.articleName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${a.quantity} pairs',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFEF6C00),
                      ),
                    ),
                    Text(
                      'PKR ${a.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8A8FA3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatCardData {
  final String label;
  final String value;
  final String icon;
  final Color color;
  _StatCardData(this.label, this.value, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final _StatCardData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E9F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: data.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: AppIcon(data.icon, color: data.color, size: 20)),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            data.value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B1F3B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.label,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF8A8FA3)),
          ),
        ],
      ),
    );
  }
}

class _TodayByBranch extends StatelessWidget {
  final List<BranchSaleToday> rows;
  const _TodayByBranch({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E9F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 16, 18, 10),
            child: Text(
              "Aaj Ki Sale — Branch Wise",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE7E9F0)),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Aaj abhi tak koi sale nahi',
                  style: TextStyle(color: Color(0xFF8A8FA3)),
                ),
              ),
            )
          else
            ...rows.map(
              (r) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const AppIcon(
                      AppIcons.storefrontOutlined,
                      size: 18,
                      color: Color(0xFF3E63DD),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        r.branchName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${r.invoiceCount} inv',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8A8FA3),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'PKR ${r.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E7D32),
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
