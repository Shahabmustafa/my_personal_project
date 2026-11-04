import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safishoe_app/core/utils/error_text.dart';
import '../../data/model/customer_model.dart';
import '../providers/customer_sales_provider.dart';

const _primary = Color(0xFF3E63DD);
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _fmt(double v) => v == v.truncate() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

String _short(double v) {
  if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
  if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
  return v.toStringAsFixed(0);
}

class CustomerDetailPanel extends ConsumerWidget {
  final CustomerModel customer;
  final String branchId;
  const CustomerDetailPanel({super.key, required this.customer, required this.branchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = customer;
    final salesAsync = ref.watch(customerMonthlySalesProvider(
        (customerId: c.id, branchId: branchId)));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFFEAEFFD),
              child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: _primary, fontWeight: FontWeight.bold, fontSize: 20)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.name,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(c.isWalkIn ? 'Walk-in (regular) customer' : 'Registered customer',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF8A8FA3))),
              ]),
            ),
            const SizedBox(width: 28),
          ]),
          const SizedBox(height: 20),
          _section('Details'),
          _row('Phone', c.phoneNumber.isEmpty ? '—' : c.phoneNumber),
          _row('Email', c.email.isEmpty ? '—' : c.email),
          _row('Address', c.address.isEmpty ? '—' : c.address),
          _row('Opening Balance', 'Rs. ${_fmt(c.openingBalance)}'),
          _row('Loyalty Points', '${c.loyaltyPoints}'),
          const SizedBox(height: 16),
          _section('Monthly sales (last 12 months)'),
          const SizedBox(height: 8),
          salesAsync.when(
            loading: () => const SizedBox(
                height: 220, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
            error: (e, _) => Text(friendlyError(e),
                style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            data: (data) {
              final total = data.fold<double>(0, (a, m) => a + m.amount);
              final invoices = data.fold<int>(0, (a, m) => a + m.invoices);
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _SalesChart(data: data),
                const SizedBox(height: 12),
                _row('Total (12 months)', 'Rs. ${_fmt(total)}', bold: true, color: _primary),
                _row('Invoices', '$invoices'),
              ]);
            },
          ),
        ],
      ),
    );
  }

  Widget _section(String t) => Text(t.toUpperCase(),
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: Color(0xFF8A8FA3)));

  Widget _row(String label, String value, {bool bold = false, Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3))),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                    color: color ?? const Color(0xFF2D2D3A))),
          ),
        ]),
      );
}

class _SalesChart extends StatelessWidget {
  final List<MonthlySale> data;
  const _SalesChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxV = data.fold<double>(0, (a, m) => m.amount > a ? m.amount : a);
    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxV == 0 ? 100 : maxV * 1.2,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: Color(0xFFE7E9F0), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (v, meta) => v == meta.max
                    ? const SizedBox()
                    : Text(_short(v),
                        style: const TextStyle(fontSize: 10, color: Color(0xFF8A8FA3))),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final m = data[v.toInt()].month;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_months[m.month - 1],
                        style: const TextStyle(fontSize: 9, color: Color(0xFF8A8FA3))),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (g, _, rod, __) {
                final m = data[g.x];
                return BarTooltipItem(
                  '${_months[m.month.month - 1]} ${m.month.year}\nRs. ${_fmt(m.amount)}\n${m.invoices} invoice${m.invoices == 1 ? '' : 's'}',
                  const TextStyle(color: Colors.white, fontSize: 11),
                );
              },
            ),
          ),
          barGroups: [
            for (var i = 0; i < data.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: data[i].amount,
                  width: 12,
                  color: _primary,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ]),
          ],
        ),
      ),
    );
  }
}
