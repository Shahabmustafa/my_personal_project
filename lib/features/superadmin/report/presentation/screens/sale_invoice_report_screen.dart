import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/service/print/print_service.dart';
import '../../../../branch/sale_invoice/data/model/sale_invoice_model.dart';
import '../providers/sale_invoice_report_provider.dart';
import '../widgets/report_date_filter_dialog.dart';
import '../widgets/report_detail_panel.dart';
import '../widgets/report_pagination_bar.dart';
import '../widgets/report_summary_card.dart';

class SaleInvoiceReportScreen extends ConsumerStatefulWidget {
  const SaleInvoiceReportScreen({super.key});

  @override
  ConsumerState<SaleInvoiceReportScreen> createState() => _SaleInvoiceReportScreenState();
}

class _SaleInvoiceReportScreenState extends ConsumerState<SaleInvoiceReportScreen> {
  SaleInvoiceModel? _selected;

  static const _accent = Color(0xFF3E63DD);

  /// Report screen ke pas koi printer picker nahi hota — is liye invoice ki
  /// apni branch ko jo printer assign hai wahi resolve karke logo/header ke
  /// liye use karta hai.
  Future<void> _print(SaleInvoiceModel inv) async {
    final printer =
        await ref.read(saleReportRepositoryProvider).getBranchPrinter(inv.branchId);
    await ThermalPrintService.printSaleInvoice(inv, printer: printer);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(saleInvoiceReportProvider);
    final notifier = ref.read(saleInvoiceReportProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Sale Invoice Report',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              if (state.hasFilter)
                TextButton.icon(
                  onPressed: notifier.clearDateRange,
                  icon: const Icon(Icons.clear, size: 16),
                  label: Text(_rangeLabel(state.startDate, state.endDate)),
                ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.filter_alt_outlined, size: 18),
                label: const Text('Filter'),
                onPressed: () async {
                  final result = await showDialog<(DateTime?, DateTime?)?>(
                    context: context,
                    builder: (_) => ReportDateFilterDialog(
                        initialStart: state.startDate, initialEnd: state.endDate),
                  );
                  if (result != null) {
                    notifier.applyDateRange(result.$1, result.$2);
                  }
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: notifier.load,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: ReportSummaryCard(
                label: 'Total Invoices',
                value: '${state.totalCount}',
                icon: Icons.receipt_long_outlined,
                color: _accent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ReportSummaryCard(
                label: 'Total Quantity',
                value: '${state.totalQuantity}',
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFFE56A00),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ReportSummaryCard(
                label: 'Total Sale',
                value: 'Rs. ${state.totalAmount.toStringAsFixed(0)}',
                icon: Icons.point_of_sale_outlined,
                color: const Color(0xFF22A06B),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : state.error != null
                          ? Center(
                              child: Text('Error: ${state.error}',
                                  style: const TextStyle(color: Colors.red)))
                          : state.rows.isEmpty
                              ? const Center(child: Text('No sale invoices found'))
                              : Container(
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
                                        columns: const [
                                          DataColumn(label: Text('Invoice #')),
                                          DataColumn(label: Text('Branch')),
                                          DataColumn(label: Text('Customer')),
                                          DataColumn(label: Text('Date')),
                                          DataColumn(label: Text('Sub Total'), numeric: true),
                                          DataColumn(label: Text('Discount'), numeric: true),
                                          DataColumn(label: Text('Total'), numeric: true),
                                          DataColumn(label: Text('Actions')),
                                        ],
                                        rows: state.rows
                                            .map((inv) => DataRow(
                                                  selected: _selected?.id == inv.id,
                                                  cells: [
                                                    DataCell(Text(inv.invoiceNumber,
                                                        style: const TextStyle(
                                                            fontWeight: FontWeight.w600))),
                                                    DataCell(Text(inv.branchName ?? '—')),
                                                    DataCell(Text(inv.customerName ?? '—')),
                                                    DataCell(Text(_fmtDate(inv.createdAt))),
                                                    DataCell(Text(inv.subtotal.toStringAsFixed(0))),
                                                    DataCell(Text(
                                                        '- ${inv.totalDiscount.toStringAsFixed(0)}')),
                                                    DataCell(Text(inv.totalAmount.toStringAsFixed(0),
                                                        style: const TextStyle(
                                                            fontWeight: FontWeight.w700,
                                                            color: Colors.green))),
                                                    DataCell(Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(Icons.visibility_outlined,
                                                              size: 19),
                                                          tooltip: 'View',
                                                          onPressed: () =>
                                                              setState(() => _selected = inv),
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(Icons.print_outlined,
                                                              size: 19),
                                                          tooltip: 'Print',
                                                          onPressed: () => _print(inv),
                                                        ),
                                                      ],
                                                    )),
                                                  ],
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                ),
                ),
                if (_selected != null)
                  ReportDetailPanel(
                    title: _selected!.invoiceNumber,
                    subtitle: '${_selected!.branchName ?? '—'} · ${_fmtDate(_selected!.createdAt)}',
                    accent: _accent,
                    onClose: () => setState(() => _selected = null),
                    onPrint: () => _print(_selected!),
                    child: _InvoiceDetailBody(invoice: _selected!),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ReportPaginationBar(
            page: state.page,
            totalPages: state.totalPages,
            totalCount: state.totalCount,
            pageSize: state.pageSize,
            onPageChange: notifier.goToPage,
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _rangeLabel(DateTime? start, DateTime? end) {
    if (start == null && end == null) return '';
    final s = start == null ? '…' : _fmtStatic(start);
    final e = end == null ? '…' : _fmtStatic(end);
    return '$s – $e';
  }

  static String _fmtStatic(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _InvoiceDetailBody extends StatelessWidget {
  final SaleInvoiceModel invoice;
  const _InvoiceDetailBody({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailKV('Branch', invoice.branchName ?? '—'),
        DetailKV('Customer', invoice.customerName ?? '—'),
        DetailKV('Payment', invoice.paymentTypeLabel.toUpperCase()),
        if (invoice.hasReturn || invoice.hasExchange)
          DetailKV(
              'Status',
              [
                if (invoice.hasReturn) 'Returned',
                if (invoice.hasExchange) 'Exchanged',
              ].join(' · '),
              valueColor: Colors.red),
        const DetailDivider(),
        DetailSectionLabel('ITEMS (${invoice.items.length})'),
        for (final item in invoice.items)
          DetailProductRow(
            name: item.productName ?? 'Item',
            sizeName: item.sizeName,
            colorName: item.colorName,
            quantity: item.quantity,
            total: item.totalPrice,
          ),
        const DetailDivider(),
        DetailKV('Sub Total', 'Rs. ${invoice.subtotal.toStringAsFixed(0)}'),
        if (invoice.totalDiscount > 0)
          DetailKV('Discount', '- Rs. ${invoice.totalDiscount.toStringAsFixed(0)}',
              valueColor: Colors.orange),
        if (invoice.invoiceDiscount > 0)
          DetailKV('Invoice Discount', '- Rs. ${invoice.invoiceDiscount.toStringAsFixed(0)}',
              valueColor: Colors.orange),
        DetailKV('Total', 'Rs. ${invoice.totalAmount.toStringAsFixed(0)}',
            bold: true, valueColor: Colors.green.shade700),
        if (invoice.payments.isNotEmpty) ...[
          const DetailDivider(),
          DetailSectionLabel('PAYMENTS'),
          for (final p in invoice.payments)
            DetailKV(p.paymentType.toUpperCase(), 'Rs. ${p.amount.toStringAsFixed(0)}'),
        ],
      ],
    );
  }
}
