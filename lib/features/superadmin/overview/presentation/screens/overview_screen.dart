import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/overview_datasource.dart';
import '../providers/overview_provider.dart';

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
                      Text('Dashboard',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      Text('Sab branches ka overview',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF8A8FA3))),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => ref.invalidate(overviewStatsProvider),
                  icon: const Icon(Icons.refresh, color: _accent),
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
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 44),
                      const SizedBox(height: 10),
                      Text('Error: $e',
                          style: const TextStyle(color: Color(0xFF8A8FA3))),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: () =>
                            ref.invalidate(overviewStatsProvider),
                        icon: const Icon(Icons.refresh, size: 16),
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
      _StatCardData('Today Sale (All Branches)', _pkr(stats.todaySale),
          Icons.point_of_sale_outlined, const Color(0xFF2E7D32),
          subtitle: '${stats.todayInvoiceCount} invoices'),
      _StatCardData('Total Articles', '${stats.totalArticles}',
          Icons.inventory_2_outlined, const Color(0xFF3E63DD)),
      _StatCardData('Total Branches', '${stats.totalBranches}',
          Icons.apartment_outlined, const Color(0xFF00838F)),
      _StatCardData('Total Warehouses', '${stats.totalWarehouses}',
          Icons.warehouse_outlined, const Color(0xFF6A1B9A)),
      _StatCardData('This Month Sale', _pkr(stats.monthSale),
          Icons.calendar_month_outlined, const Color(0xFF1565C0)),
      _StatCardData('Today Sale Return', _pkr(stats.todaySaleReturn),
          Icons.assignment_return_outlined, const Color(0xFFC62828)),
      _StatCardData('Pending Stock Assignments', '${stats.pendingAssignments}',
          Icons.hourglass_empty_outlined, const Color(0xFFEF6C00)),
      _StatCardData('Total Users', '${stats.totalUsers}',
          Icons.people_outline, const Color(0xFF5D4037)),
      _StatCardData('Total Customers', '${stats.totalCustomers}',
          Icons.groups_outlined, const Color(0xFF00695C)),
      _StatCardData('Total Companies', '${stats.totalCompanies}',
          Icons.business_outlined, const Color(0xFF455A64)),
      _StatCardData('Head Office Stock', '${stats.headOfficeStockPairs} pairs',
          Icons.store_mall_directory_outlined, const Color(0xFF3949AB)),
      _StatCardData('Warehouse Stock', '${stats.warehouseStockPairs} pairs',
          Icons.inventory_outlined, const Color(0xFF00897B)),
      _StatCardData('Branch Stock', '${stats.branchStockPairs} pairs',
          Icons.storefront_outlined, const Color(0xFF7B1FA2)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(builder: (ctx, c) {
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
                SizedBox(width: cardW, child: _StatCard(data: d)),
            ],
          );
        }),
        const SizedBox(height: 28),
        _TodayByBranch(rows: stats.todaySaleByBranch),
      ],
    );
  }
}

class _StatCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  _StatCardData(this.label, this.value, this.icon, this.color, {this.subtitle});
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
                child: Icon(data.icon, color: data.color, size: 20),
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
                color: Color(0xFF1B1F3B)),
          ),
          const SizedBox(height: 4),
          Text(
            data.label,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF8A8FA3)),
          ),
          if (data.subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              data.subtitle!,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: data.color),
            ),
          ],
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
            child: Text("Aaj Ki Sale — Branch Wise",
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
          const Divider(height: 1, color: Color(0xFFE7E9F0)),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('Aaj abhi tak koi sale nahi',
                    style: TextStyle(color: Color(0xFF8A8FA3))),
              ),
            )
          else
            ...rows.map((r) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront_outlined,
                          size: 18, color: Color(0xFF3E63DD)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(r.branchName,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                      Text('${r.invoiceCount} inv',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF8A8FA3))),
                      const SizedBox(width: 16),
                      Text(
                        'PKR ${r.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E7D32)),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
