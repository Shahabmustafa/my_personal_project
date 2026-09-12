import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/purchase_invoice_model.dart';
import '../providers/purchase_invoice_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
class PurchaseInvoicesListScreen extends ConsumerStatefulWidget {
  const PurchaseInvoicesListScreen({super.key});

  @override
  ConsumerState<PurchaseInvoicesListScreen> createState() =>
      _PurchaseInvoicesListScreenState();
}

class _PurchaseInvoicesListScreenState
    extends ConsumerState<PurchaseInvoicesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(invoiceListProvider.notifier).loadInvoices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoiceListProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Purchase Invoices',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text('All purchase invoices',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              FilledButton.icon(
                icon: const AppIcon(AppIcons.add, color: Colors.white),
                label: const Text('New Invoice'),
                onPressed: () {
                  // Navigate to purchase invoice screen
                  // Navigator.push or tab switch depending on your nav structure
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
          else if (state.invoices.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(AppIcons.receiptLongOutlined,
                        size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('No purchase invoices yet',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 15)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: LayoutBuilder(builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                return isWide
                    ? _DesktopInvoiceTable(invoices: state.invoices)
                    : _MobileInvoiceList(invoices: state.invoices);
              }),
            ),
        ],
      ),
    );
  }
}

// ── Desktop table ─────────────────────────────────────────────────────────

class _DesktopInvoiceTable extends StatelessWidget {
  final List<PurchaseInvoiceModel> invoices;
  const _DesktopInvoiceTable({required this.invoices});

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
        fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white);

    return Column(
      children: [
        // Header
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(children: [
            _hcell('Invoice #', flex: 2, style: headerStyle),
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
            itemCount: invoices.length,
            itemBuilder: (context, i) {
              final inv = invoices[i];
              return Container(
                color: i.isEven ? Colors.grey.shade50 : Colors.white,
                child: Row(children: [
                  _dcell(inv.invoiceNumber, flex: 2,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color:
                              Theme.of(context).colorScheme.primary)),
                  _dcell(inv.companyName ?? '—', flex: 3),
                  _dcell(_formatDate(inv.invoiceDate), flex: 2),
                  _dcell(inv.totalAmount.toStringAsFixed(0), flex: 2),
                  _dcell(
                    '- ${inv.totalDiscount.toStringAsFixed(0)}',
                    flex: 2,
                    style: const TextStyle(color: Colors.orange),
                  ),
                  _dcell(
                    inv.netAmount.toStringAsFixed(0),
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
                  flex: 7,
                  child: Text('TOTALS',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12))),
              Expanded(
                flex: 2,
                child: Text(
                  invoices
                      .fold(0.0, (s, i) => s + i.totalAmount)
                      .toStringAsFixed(0),
                  style:
                      const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '- ${invoices.fold(0.0, (s, i) => s + i.totalDiscount).toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  invoices
                      .fold(0.0, (s, i) => s + i.netAmount)
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text(text, style: style),
        ),
      );

  Widget _dcell(String text, {int flex = 2, TextStyle? style}) =>
      Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text(text,
              overflow: TextOverflow.ellipsis,
              style: style ?? const TextStyle(fontSize: 13)),
        ),
      );

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}

// ── Mobile list ───────────────────────────────────────────────────────────

class _MobileInvoiceList extends StatelessWidget {
  final List<PurchaseInvoiceModel> invoices;
  const _MobileInvoiceList({required this.invoices});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: invoices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final inv = invoices[i];
        return Card(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      inv.invoiceNumber,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(inv.invoiceDate),
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                if (inv.companyName != null) ...[
                  const SizedBox(height: 4),
                  Text(inv.companyName!,
                      style: const TextStyle(fontSize: 13)),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _stat('Sub Total',
                        inv.totalAmount.toStringAsFixed(0)),
                    _stat(
                        'Discount',
                        '- ${inv.totalDiscount.toStringAsFixed(0)}',
                        color: Colors.orange),
                    _stat(
                        'Net Amount',
                        inv.netAmount.toStringAsFixed(0),
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
            style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
