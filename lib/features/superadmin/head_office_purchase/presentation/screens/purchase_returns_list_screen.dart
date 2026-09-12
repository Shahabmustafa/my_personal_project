import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/purchase_return_model.dart';
import '../providers/purchase_return_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
class PurchaseReturnsListScreen extends ConsumerStatefulWidget {
  const PurchaseReturnsListScreen({super.key});

  @override
  ConsumerState<PurchaseReturnsListScreen> createState() =>
      _PurchaseReturnsListScreenState();
}

class _PurchaseReturnsListScreenState
    extends ConsumerState<PurchaseReturnsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(returnListProvider.notifier).loadReturns();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(returnListProvider);
    final counter = ref.watch(cashCounterProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppIcon(AppIcons.keyboardReturn,
                            size: 20, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        const Text('Purchase Returns',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text('All purchase return records',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              // Cash counter summary
              if (counter != null) _CounterSummaryCard(counter: counter),
              const SizedBox(width: 12),
              FilledButton.icon(
                icon: const AppIcon(AppIcons.add, color: Colors.white),
                label: const Text('New Return'),
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange.shade700),
                onPressed: () {
                  // Navigate to purchase return screen
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Content ───────────────────────────────────────────────────
          if (state.isLoading)
            const Expanded(
                child: Center(child: CircularProgressIndicator()))
          else if (state.error != null)
            Expanded(
              child: Center(
                  child: Text('Error: ${state.error}',
                      style: const TextStyle(color: Colors.red))),
            )
          else if (state.returns.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(AppIcons.keyboardReturnOutlined,
                        size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('No purchase returns yet',
                        style: TextStyle(
                            color: Colors.grey, fontSize: 15)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: LayoutBuilder(builder: (context, constraints) {
                return constraints.maxWidth > 700
                    ? _DesktopReturnTable(returns: state.returns)
                    : _MobileReturnList(returns: state.returns);
              }),
            ),
        ],
      ),
    );
  }
}

// ── Counter summary card ──────────────────────────────────────────────────

class _CounterSummaryCard extends StatelessWidget {
  final WarehouseCashCounter counter;
  const _CounterSummaryCard({required this.counter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _stat('Cash in Hand',
              'PKR ${counter.netAmount.toStringAsFixed(0)}',
              color: Colors.green.shade700),
          const SizedBox(width: 20),
          _stat('Today Purchase',
              'PKR ${counter.totalPurchase.toStringAsFixed(0)}',
              color: Colors.blue.shade700),
          const SizedBox(width: 20),
          _stat('Today Return',
              'PKR ${counter.totalReturnPurchase.toStringAsFixed(0)}',
              color: Colors.orange.shade700),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, {Color? color}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color ?? Colors.black87)),
        ],
      );
}

// ── Desktop table ─────────────────────────────────────────────────────────

class _DesktopReturnTable extends StatelessWidget {
  final List<PurchaseReturnModel> returns;
  const _DesktopReturnTable({required this.returns});

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
        fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white);

    return Column(
      children: [
        // Header
        Container(
          decoration: BoxDecoration(
            color: Colors.orange.shade700,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(children: [
            _hcell('Return #', flex: 2, style: headerStyle),
            _hcell('Ref Invoice', flex: 2, style: headerStyle),
            _hcell('Company', flex: 3, style: headerStyle),
            _hcell('Date', flex: 2, style: headerStyle),
            _hcell('Sub Total', flex: 2, style: headerStyle),
            _hcell('Discount', flex: 2, style: headerStyle),
            _hcell('Net Amount', flex: 2, style: headerStyle),
          ]),
        ),
        // Rows
        Expanded(
          child: ListView.builder(
            itemCount: returns.length,
            itemBuilder: (context, i) {
              final ret = returns[i];
              return Container(
                color:
                    i.isEven ? Colors.orange.shade50 : Colors.white,
                child: Row(children: [
                  _dcell(ret.returnNumber,
                      flex: 2,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700)),
                  _dcell(ret.originalInvoiceId != null ? 'Linked' : '—',
                      flex: 2,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                  _dcell(ret.companyName ?? '—', flex: 3),
                  _dcell(_formatDate(ret.returnDate), flex: 2),
                  _dcell(ret.totalAmount.toStringAsFixed(0), flex: 2),
                  _dcell(
                    '- ${ret.totalDiscount.toStringAsFixed(0)}',
                    flex: 2,
                    style: const TextStyle(color: Colors.orange),
                  ),
                  _dcell(
                    ret.netAmount.toStringAsFixed(0),
                    flex: 2,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.green),
                  ),
                ]),
              );
            },
          ),
        ),
        // Footer
        Container(
          color: Colors.grey.shade100,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Expanded(
                  flex: 9,
                  child: Text('TOTALS',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12))),
              Expanded(
                flex: 2,
                child: Text(
                  returns
                      .fold(0.0, (s, r) => s + r.totalAmount)
                      .toStringAsFixed(0),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '- ${returns.fold(0.0, (s, r) => s + r.totalDiscount).toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  returns
                      .fold(0.0, (s, r) => s + r.netAmount)
                      .toStringAsFixed(0),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.green),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _hcell(String text, {int flex = 2, TextStyle? style}) =>
      Expanded(
        flex: flex,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text(text, style: style),
        ),
      );

  Widget _dcell(String text, {int flex = 2, TextStyle? style}) =>
      Expanded(
        flex: flex,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text(text,
              overflow: TextOverflow.ellipsis,
              style: style ??
                  const TextStyle(fontSize: 13)),
        ),
      );

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}

// ── Mobile list ───────────────────────────────────────────────────────────

class _MobileReturnList extends StatelessWidget {
  final List<PurchaseReturnModel> returns;
  const _MobileReturnList({required this.returns});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: returns.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final ret = returns[i];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      ret.returnNumber,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.orange.shade700),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(ret.returnDate),
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                if (ret.companyName != null) ...[
                  const SizedBox(height: 4),
                  Text(ret.companyName!,
                      style: const TextStyle(fontSize: 13)),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _stat('Sub Total',
                        ret.totalAmount.toStringAsFixed(0)),
                    _stat(
                        'Discount',
                        '- ${ret.totalDiscount.toStringAsFixed(0)}',
                        color: Colors.orange.shade700),
                    _stat(
                        'Net Amount',
                        ret.netAmount.toStringAsFixed(0),
                        color: Colors.green.shade700),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _stat(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color ?? Colors.black87)),
      ],
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}
