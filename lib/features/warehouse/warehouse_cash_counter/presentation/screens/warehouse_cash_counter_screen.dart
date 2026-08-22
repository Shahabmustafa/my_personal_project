import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/current_warehouse_provider.dart';
import '../../data/model/warehouse_cash_counter_model.dart';
import '../providers/warehouse_cash_counter_provider.dart';
import '../providers/warehouse_cash_counter_state.dart';


class WarehouseCashCounterScreen extends ConsumerStatefulWidget {
  const WarehouseCashCounterScreen({super.key});

  @override
  ConsumerState<WarehouseCashCounterScreen> createState() =>
      _WarehouseCashCounterScreenState();
}

class _WarehouseCashCounterScreenState
    extends ConsumerState<WarehouseCashCounterScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final warehouseId = _currentWarehouseId;
      if (warehouseId.isEmpty) return;
      ref
          .read(cashCounterProvider.notifier)
          .loadByWarehouse(warehouseId);
    });
  }

  String get _currentWarehouseId => ref.read(currentWarehouseIdProvider);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cashCounterProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;

    ref.listen<WarehouseCashCounterState>(cashCounterProvider, (_, next) {
      if (next.status == CashCounterStatus.error &&
          next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    // Filter by date search
    final filtered = state.records.where((r) {
      final q = _searchQuery.toLowerCase();
      if (q.isEmpty) return true;
      final dateStr =
          '${r.counterDate.day.toString().padLeft(2, '0')}/${r.counterDate.month.toString().padLeft(2, '0')}/${r.counterDate.year}';
      return dateStr.contains(q) ||
          r.netAmount.toString().contains(q) ||
          r.totalPurchase.toString().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cash Counter',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    Text(
                        '${state.records.length} record${state.records.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF8A8FA3))),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),

          // ── Summary Cards ─────────────────────────────────────────────────
          if (!state.isLoading && state.records.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: isMobile
                  ? Column(
                      children: [
                        Row(children: [
                          Expanded(
                              child: _SummaryCard(
                                  label: 'Net Amount',
                                  amount: state.totalNetAmount,
                                  icon: Icons.monetization_on_outlined,
                                  color: const Color(0xFF3E63DD))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _SummaryCard(
                                  label: 'Total Purchase',
                                  amount: state.totalPurchase,
                                  icon: Icons.shopping_cart_outlined,
                                  color: const Color(0xFF22A06B))),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                              child: _SummaryCard(
                                  label: 'Total Return',
                                  amount: state.totalReturn,
                                  icon: Icons.assignment_return_outlined,
                                  color: const Color(0xFFE2483D))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _SummaryCard(
                                  label: 'Total Expense',
                                  amount: state.totalExpense,
                                  icon: Icons.receipt_long_outlined,
                                  color: const Color(0xFFE56A00))),
                        ]),
                      ],
                    )
                  : Row(children: [
                      Expanded(
                          child: _SummaryCard(
                              label: 'Net Amount',
                              amount: state.totalNetAmount,
                              icon: Icons.monetization_on_outlined,
                              color: const Color(0xFF3E63DD))),
                      const SizedBox(width: 14),
                      Expanded(
                          child: _SummaryCard(
                              label: 'Total Purchase',
                              amount: state.totalPurchase,
                              icon: Icons.shopping_cart_outlined,
                              color: const Color(0xFF22A06B))),
                      const SizedBox(width: 14),
                      Expanded(
                          child: _SummaryCard(
                              label: 'Total Return',
                              amount: state.totalReturn,
                              icon: Icons.assignment_return_outlined,
                              color: const Color(0xFFE2483D))),
                      const SizedBox(width: 14),
                      Expanded(
                          child: _SummaryCard(
                              label: 'Total Expense',
                              amount: state.totalExpense,
                              icon: Icons.receipt_long_outlined,
                              color: const Color(0xFFE56A00))),
                    ]),
            ),

          // ── Search ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration:
                  _searchDecor('Search by date or amount...'),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.status == CashCounterStatus.error
                    ? _ErrorView(
                        message:
                            state.errorMessage ?? 'Error loading records',
                        onRetry: () => ref
                            .read(cashCounterProvider.notifier)
                            .loadByWarehouse(_currentWarehouseId),
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
  final IconData icon;
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
            child: Icon(icon, color: color, size: 20),
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
                  'Rs. ${_fmt(amount)}',
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

  String _fmt(double v) {
    if (v == v.truncate()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }
}

// ── Desktop Table ─────────────────────────────────────────────────────────────

class _DesktopTable extends StatelessWidget {
  final List<WarehouseCashCounterModel> records;

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
          child: Column(
            children: [
              // Header row
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F8FC),
                  border: Border(
                      bottom: BorderSide(color: Color(0xFFE7E9F0))),
                ),
                child: const Row(children: [
                  _TH('Date', flex: 2),
                  _TH('Net Amount', flex: 2),
                  _TH('Total Purchase', flex: 2),
                  _TH('Total Return', flex: 2),
                  _TH('Expense', flex: 2),
                ]),
              ),
              // Data rows
              Expanded(
                child: ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (_, i) {
                    final r = records[i];
                    final isLast = i == records.length - 1;
                    return Container(
                      decoration: BoxDecoration(
                        border: isLast
                            ? null
                            : const Border(
                                bottom: BorderSide(
                                    color: Color(0xFFE7E9F0))),
                      ),
                      child: Row(children: [
                        // Date
                        Expanded(
                          flex: 2,
                          child: _TD(
                              child: Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAEFFD),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _fmtDate(r.counterDate),
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF3E63DD)),
                              ),
                            ),
                          ])),
                        ),
                        // Net Amount
                        Expanded(
                          flex: 2,
                          child: _TD(
                              child: Text(
                            'Rs. ${_fmtAmt(r.netAmount)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF3E63DD)),
                          )),
                        ),
                        // Purchase
                        Expanded(
                          flex: 2,
                          child: _TD(
                              child: Text(
                            'Rs. ${_fmtAmt(r.totalPurchase)}',
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF22A06B),
                                fontWeight: FontWeight.w500),
                          )),
                        ),
                        // Return
                        Expanded(
                          flex: 2,
                          child: _TD(
                              child: Text(
                            'Rs. ${_fmtAmt(r.totalReturnPurchase)}',
                            style: TextStyle(
                                fontSize: 13,
                                color: r.totalReturnPurchase > 0
                                    ? const Color(0xFFE2483D)
                                    : const Color(0xFF8A8FA3),
                                fontWeight: FontWeight.w500),
                          )),
                        ),
                        // Expense
                        Expanded(
                          flex: 2,
                          child: _TD(
                              child: Text(
                            'Rs. ${_fmtAmt(r.expense)}',
                            style: TextStyle(
                                fontSize: 13,
                                color: r.expense > 0
                                    ? const Color(0xFFE56A00)
                                    : const Color(0xFF8A8FA3),
                                fontWeight: FontWeight.w500),
                          )),
                        ),
                      ]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mobile List ───────────────────────────────────────────────────────────────

class _MobileList extends StatelessWidget {
  final List<WarehouseCashCounterModel> records;

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
              // Date
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEFFD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _fmtDate(r.counterDate),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF3E63DD)),
                ),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFE7E9F0)),
              const SizedBox(height: 12),
              // Amount rows
              _MobileRow(
                icon: Icons.monetization_on_outlined,
                label: 'Net Amount',
                value: 'Rs. ${_fmtAmt(r.netAmount)}',
                valueColor: const Color(0xFF3E63DD),
              ),
              const SizedBox(height: 8),
              _MobileRow(
                icon: Icons.shopping_cart_outlined,
                label: 'Purchase',
                value: 'Rs. ${_fmtAmt(r.totalPurchase)}',
                valueColor: const Color(0xFF22A06B),
              ),
              const SizedBox(height: 8),
              _MobileRow(
                icon: Icons.assignment_return_outlined,
                label: 'Return',
                value: 'Rs. ${_fmtAmt(r.totalReturnPurchase)}',
                valueColor: r.totalReturnPurchase > 0
                    ? const Color(0xFFE2483D)
                    : const Color(0xFF8A8FA3),
              ),
              const SizedBox(height: 8),
              _MobileRow(
                icon: Icons.receipt_long_outlined,
                label: 'Expense',
                value: 'Rs. ${_fmtAmt(r.expense)}',
                valueColor: r.expense > 0
                    ? const Color(0xFFE56A00)
                    : const Color(0xFF8A8FA3),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MobileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _MobileRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF8A8FA3)),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF8A8FA3))),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor)),
      ],
    );
  }
}

// ── Helper functions ──────────────────────────────────────────────────────────

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String _fmtAmt(double v) {
  if (v == v.truncate()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(2);
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _TH extends StatelessWidget {
  final String text;
  final int flex;
  const _TH(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8A8FA3),
                letterSpacing: 0.3)),
      ),
    );
  }
}

class _TD extends StatelessWidget {
  final Widget child;
  const _TD({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: child,
    );
  }
}



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
            const Icon(Icons.error_outline,
                size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message,
                style: const TextStyle(color: Color(0xFF8A8FA3))),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: onRetry, child: const Text('Retry')),
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
            Icon(Icons.account_balance_wallet_outlined,
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
      prefixIcon: const Icon(Icons.search, color: Color(0xFF8A8FA3)),
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
