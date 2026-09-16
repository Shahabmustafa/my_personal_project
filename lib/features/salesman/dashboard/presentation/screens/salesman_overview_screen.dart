import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../branch/sale_invoice/data/model/sale_invoice_model.dart';
import '../../../my_activity/presentation/providers/my_activity_provider.dart';
import '../../../profile/presentation/providers/salesman_profile_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';

/// Salesman dashboard ka home tab — apni salary/commission ka quick glance
/// aur aaj/is mahine ki apni sale ka khulasa.
class SalesmanOverviewScreen extends ConsumerWidget {
  const SalesmanOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final profileAsync = ref.watch(salesmanProfileProvider);
    final salesAsync = ref.watch(mySalesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(salesmanProfileProvider);
          ref.invalidate(mySalesProvider);
          await Future.wait([
            ref.read(salesmanProfileProvider.future),
            ref.read(mySalesProvider.future),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assalam-o-Alaikum, ${user?.username ?? ''}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              const Text('Aapki aaj ki sale aur profile ka khulasa',
                  style: TextStyle(fontSize: 13, color: Color(0xFF8A8FA3))),
              const SizedBox(height: 20),
              salesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Error: $e',
                    style: const TextStyle(color: Colors.red)),
                data: (sales) {
                  final now = DateTime.now();
                  final today = sales.where((s) =>
                      s.createdAt.year == now.year &&
                      s.createdAt.month == now.month &&
                      s.createdAt.day == now.day);
                  final thisMonth = sales.where((s) =>
                      s.createdAt.year == now.year &&
                      s.createdAt.month == now.month);
                  final todayTotal =
                      today.fold<double>(0, (s, i) => s + i.totalAmount);
                  final monthTotal =
                      thisMonth.fold<double>(0, (s, i) => s + i.totalAmount);
                  final monthCommission = thisMonth.fold<double>(
                      0, (s, i) => s + i.salesmanCommissionAmount);

                  final profile = profileAsync.asData?.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CardGrid(specs: [
                        _CardSpec('Today Sale', 'Rs. ${todayTotal.toStringAsFixed(0)}',
                            AppIcons.pointOfSaleOutlined, const Color(0xFF22A06B)),
                        _CardSpec('This Month Sale',
                            'Rs. ${monthTotal.toStringAsFixed(0)}',
                            AppIcons.trendingUpOutlined, const Color(0xFF3E63DD)),
                        _CardSpec('This Month Commission',
                            'Rs. ${monthCommission.toStringAsFixed(0)}',
                            AppIcons.percentOutlined, const Color(0xFF6C4DE0)),
                        _CardSpec(
                            'My Salary',
                            profile == null
                                ? '—'
                                : 'Rs. ${profile.salary.toStringAsFixed(0)}',
                            AppIcons.savingsOutlined, const Color(0xFF1565C0)),
                      ]),
                      const SizedBox(height: 20),
                      _RecentSalesCard(sales: sales.take(5).toList()),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardSpec {
  final String label;
  final String value;
  final String icon;
  final Color color;
  const _CardSpec(this.label, this.value, this.icon, this.color);
}

class _CardGrid extends StatelessWidget {
  final List<_CardSpec> specs;
  const _CardGrid({required this.specs});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 700;
      if (isMobile) {
        return Column(
          children: specs
              .map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OverviewCard(spec: c),
                  ))
              .toList(),
        );
      }
      return Row(
        children: [
          for (int j = 0; j < specs.length; j++) ...[
            Expanded(child: _OverviewCard(spec: specs[j])),
            if (j != specs.length - 1) const SizedBox(width: 14),
          ],
        ],
      );
    });
  }
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
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
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
                        fontSize: 12,
                        color: Color(0xFF8A8FA3),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(spec.value,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w800, color: spec.color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentSalesCard extends StatelessWidget {
  final List<SaleInvoiceModel> sales;
  const _RecentSalesCard({required this.sales});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Sales',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (sales.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Abhi tak koi sale nahi hui',
                  style: TextStyle(color: Color(0xFF8A8FA3))),
            )
          else
            ...sales.map((s) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(s.invoiceNumber,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(s.customerName ?? '—',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF8A8FA3))),
                      ),
                      Text('Rs. ${s.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2E7D32))),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
