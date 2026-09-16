import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/current_branch_provider.dart';
import '../../data/model/branch_cash_counter_model.dart';
import '../providers/branch_cash_counter_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/widget/text_field_icon.dart';
class BranchCashCounterScreen extends ConsumerStatefulWidget {
  const BranchCashCounterScreen({super.key});

  @override
  ConsumerState<BranchCashCounterScreen> createState() =>
      _BranchCashCounterScreenState();
}

class _BranchCashCounterScreenState
    extends ConsumerState<BranchCashCounterScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final branchId = ref.read(currentBranchIdProvider);
      if (branchId.isEmpty) return;
      ref.read(branchCashCounterProvider.notifier).loadByBranch(branchId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(branchCashCounterProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;

    final filtered = state.records.where((r) {
      final q = _searchQuery.toLowerCase();
      if (q.isEmpty) return true;
      final dateStr = _fmtDate(r.createdAt);
      return dateStr.contains(q) || r.totalSale.toString().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cash Counter',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                Text(
                    '${state.records.length} record${state.records.length == 1 ? '' : 's'} — read only',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF8A8FA3))),
              ],
            ),
          ),

          // ── Summary Cards ─────────────────────────────────────────────
          if (!state.isLoading && state.records.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: isMobile
                  ? Column(
                      children: [
                        Row(children: [
                          Expanded(
                              child: _SummaryCard(
                                  label: 'Total Sale',
                                  amount: state.totalSale,
                                  icon: AppIcons.pointOfSaleOutlined,
                                  color: const Color(0xFF3E63DD))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _SummaryCard(
                                  label: 'Net Sale',
                                  amount: state.totalNetSale,
                                  icon: AppIcons.publishedWithChangesOutlined,
                                  color: const Color(0xFF0F9D8F))),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                              child: _SummaryCard(
                                  label: 'Gross',
                                  amount: state.totalGross,
                                  icon: AppIcons.trendingUpOutlined,
                                  color: const Color(0xFF22A06B))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _SummaryCard(
                                  label: 'Expense',
                                  amount: state.totalExpense,
                                  icon: AppIcons.receiptLongOutlined,
                                  color: const Color(0xFFE56A00))),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                              child: _SummaryCard(
                                  label: 'Total Amount',
                                  amount: state.totalAmount,
                                  icon: AppIcons.accountBalanceWalletOutlined,
                                  color: const Color(0xFF6C4DE0))),
                        ]),
                      ],
                    )
                  : Row(children: [
                      Expanded(
                          child: _SummaryCard(
                              label: 'Total Sale',
                              amount: state.totalSale,
                              icon: AppIcons.pointOfSaleOutlined,
                              color: const Color(0xFF3E63DD))),
                      const SizedBox(width: 14),
                      Expanded(
                          child: _SummaryCard(
                              label: 'Net Sale',
                              amount: state.totalNetSale,
                              icon: AppIcons.publishedWithChangesOutlined,
                              color: const Color(0xFF0F9D8F))),
                      const SizedBox(width: 14),
                      Expanded(
                          child: _SummaryCard(
                              label: 'Gross',
                              amount: state.totalGross,
                              icon: AppIcons.trendingUpOutlined,
                              color: const Color(0xFF22A06B))),
                      const SizedBox(width: 14),
                      Expanded(
                          child: _SummaryCard(
                              label: 'Expense',
                              amount: state.totalExpense,
                              icon: AppIcons.receiptLongOutlined,
                              color: const Color(0xFFE56A00))),
                      const SizedBox(width: 14),
                      Expanded(
                          child: _SummaryCard(
                              label: 'Total Amount',
                              amount: state.totalAmount,
                              icon: AppIcons.accountBalanceWalletOutlined,
                              color: const Color(0xFF6C4DE0))),
                    ]),
            ),

          // ── Search ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: _searchDecor('Search by date or amount...'),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.status == BranchCashCounterStatus.error
                    ? _ErrorView(
                        message:
                            state.errorMessage ?? 'Error loading records',
                        onRetry: () => ref
                            .read(branchCashCounterProvider.notifier)
                            .loadByBranch(
                                ref.read(currentBranchIdProvider)),
                      )
                    : filtered.isEmpty
                        ? const _EmptyView()
                        : isMobile
                            ? _MobileList(records: filtered)
                            : _DesktopTable(records: filtered),
          ),
        ],
      ),
    );
  }
}

// ── Summary Card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final String icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E9F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: AppIcon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8A8FA3),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  'Rs. ${_fmtAmt(amount)}',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color),
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

// ── Desktop Table (horizontal scroll — many columns) ───────────────────────────

class _DesktopTable extends StatelessWidget {
  final List<BranchCashCounterModel> records;
  const _DesktopTable({required this.records});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7E9F0)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(const Color(0xFFF7F8FC)),
              headingTextStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8A8FA3)),
              dataTextStyle: const TextStyle(fontSize: 13),
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Cash Sale'), numeric: true),
                DataColumn(label: Text('Card Sale'), numeric: true),
                DataColumn(label: Text('Total Sale'), numeric: true),
                DataColumn(label: Text('Return Sale'), numeric: true),
                DataColumn(label: Text('Return in Exch.'), numeric: true),
                DataColumn(label: Text('Received in Exch.'), numeric: true),
                DataColumn(label: Text('Net Sale'), numeric: true),
                DataColumn(label: Text('Expense'), numeric: true),
                DataColumn(label: Text('Gross'), numeric: true),
                DataColumn(label: Text('Paid Amount'), numeric: true),
                DataColumn(label: Text('Total Amount'), numeric: true),
              ],
              rows: records
                  .map((r) => DataRow(cells: [
                        DataCell(Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAEFFD),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(_fmtDate(r.createdAt),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF3E63DD))),
                        )),
                        DataCell(Text('Rs. ${_fmtAmt(r.cashSale)}')),
                        DataCell(Text('Rs. ${_fmtAmt(r.cardSale)}')),
                        DataCell(Text('Rs. ${_fmtAmt(r.totalSale)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF3E63DD)))),
                        DataCell(Text('Rs. ${_fmtAmt(r.returnSale)}',
                            style: TextStyle(
                                color: r.returnSale > 0
                                    ? const Color(0xFFE2483D)
                                    : const Color(0xFF8A8FA3)))),
                        DataCell(Text(
                            'Rs. ${_fmtAmt(r.returnAmountInExchange)}')),
                        DataCell(Text(
                            'Rs. ${_fmtAmt(r.receivedAmountInExchange)}')),
                        DataCell(Text('Rs. ${_fmtAmt(r.netSale)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F9D8F)))),
                        DataCell(Text('Rs. ${_fmtAmt(r.expense)}',
                            style: TextStyle(
                                color: r.expense > 0
                                    ? const Color(0xFFE56A00)
                                    : const Color(0xFF8A8FA3)))),
                        DataCell(Text('Rs. ${_fmtAmt(r.gross)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF22A06B)))),
                        DataCell(Text('Rs. ${_fmtAmt(r.paidAmount)}')),
                        DataCell(Text('Rs. ${_fmtAmt(r.totalAmount)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6C4DE0)))),
                      ]))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Mobile List ───────────────────────────────────────────────────────────────

class _MobileList extends StatelessWidget {
  final List<BranchCashCounterModel> records;
  const _MobileList({required this.records});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: records.length,
      itemBuilder: (_, i) {
        final r = records[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE7E9F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEFFD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_fmtDate(r.createdAt),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF3E63DD))),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFE7E9F0)),
              const SizedBox(height: 12),
              _MobileRow(
                  label: 'Cash Sale', value: 'Rs. ${_fmtAmt(r.cashSale)}'),
              const SizedBox(height: 8),
              _MobileRow(
                  label: 'Card Sale', value: 'Rs. ${_fmtAmt(r.cardSale)}'),
              const SizedBox(height: 8),
              _MobileRow(
                  label: 'Total Sale',
                  value: 'Rs. ${_fmtAmt(r.totalSale)}',
                  valueColor: const Color(0xFF3E63DD)),
              const SizedBox(height: 8),
              _MobileRow(
                  label: 'Return Sale',
                  value: 'Rs. ${_fmtAmt(r.returnSale)}',
                  valueColor: r.returnSale > 0
                      ? const Color(0xFFE2483D)
                      : const Color(0xFF8A8FA3)),
              const SizedBox(height: 8),
              _MobileRow(
                  label: 'Return in Exchange',
                  value: 'Rs. ${_fmtAmt(r.returnAmountInExchange)}'),
              const SizedBox(height: 8),
              _MobileRow(
                  label: 'Received in Exchange',
                  value: 'Rs. ${_fmtAmt(r.receivedAmountInExchange)}'),
              const SizedBox(height: 8),
              _MobileRow(
                  label: 'Net Sale',
                  value: 'Rs. ${_fmtAmt(r.netSale)}',
                  valueColor: const Color(0xFF0F9D8F)),
              const SizedBox(height: 8),
              _MobileRow(
                  label: 'Expense',
                  value: 'Rs. ${_fmtAmt(r.expense)}',
                  valueColor: r.expense > 0
                      ? const Color(0xFFE56A00)
                      : const Color(0xFF8A8FA3)),
              const SizedBox(height: 8),
              _MobileRow(
                  label: 'Gross',
                  value: 'Rs. ${_fmtAmt(r.gross)}',
                  valueColor: const Color(0xFF22A06B)),
              const SizedBox(height: 8),
              _MobileRow(
                  label: 'Paid Amount',
                  value: 'Rs. ${_fmtAmt(r.paidAmount)}'),
              const SizedBox(height: 8),
              _MobileRow(
                  label: 'Total Amount',
                  value: 'Rs. ${_fmtAmt(r.totalAmount)}',
                  valueColor: const Color(0xFF6C4DE0)),
            ],
          ),
        );
      },
    );
  }
}

class _MobileRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MobileRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: Color(0xFF8A8FA3))),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF2D2D3A))),
      ],
    );
  }
}

// ── Helper functions ──────────────────────────────────────────────────────────

/// `created_at` UTC se aata hai (jaise "2026-08-24T19:00:00Z"), lekin har
/// row ka din pg_cron ke Pakistan-time midnight boundary (`0 19 * * *` UTC)
/// se decide hota hai — yani 19:00 UTC row asal mein *agle* din (00:00 PKT)
/// ki hai. Raw UTC date parts dikhana ek din peeche ki date deta tha, is
/// liye display se pehle hamesha PKT (UTC+5) mein shift karo.
String _fmtDate(DateTime d) {
  final pkt = d.toUtc().add(const Duration(hours: 5));
  return '${pkt.day.toString().padLeft(2, '0')}/${pkt.month.toString().padLeft(2, '0')}/${pkt.year}';
}

String _fmtAmt(double v) {
  if (v == v.truncate()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(2);
}

// ── Error / Empty views ─────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppIcon(AppIcons.errorOutline,
                size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(color: Color(0xFF8A8FA3))),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ]),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(AppIcons.accountBalanceWalletOutlined,
                size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text('No cash counter records found',
                style: TextStyle(color: Color(0xFF8A8FA3))),
          ]),
    );
  }
}

InputDecoration _searchDecor(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
      prefixIcon: const TextFieldIcon(AppIcons.search, size: 18, color: Color(0xFF8A8FA3)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF3E63DD), width: 1.5)),
    );
