import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/service/print/print_service.dart';
import '../../../../branch/sale_exchange/data/model/sale_exchange_model.dart';
import '../providers/sale_exchange_report_provider.dart';
import '../providers/sale_invoice_report_provider.dart' show saleReportRepositoryProvider;
import '../widgets/report_date_filter_dialog.dart';
import '../widgets/report_detail_panel.dart';
import '../widgets/report_table_shell.dart';
import '../widgets/report_pagination_bar.dart';
import '../widgets/report_summary_card.dart';
import '../widgets/report_branch_filter_dropdown.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
class SaleExchangeReportScreen extends ConsumerStatefulWidget {
  const SaleExchangeReportScreen({super.key});

  @override
  ConsumerState<SaleExchangeReportScreen> createState() => _SaleExchangeReportScreenState();
}

class _SaleExchangeReportScreenState extends ConsumerState<SaleExchangeReportScreen> {
  SaleExchangeModel? _selected;

  static const _accent = Color(0xFF6C4DE0);

  Future<void> _print(SaleExchangeModel ex) async {
    final printer =
        await ref.read(saleReportRepositoryProvider).getBranchPrinter(ex.branchId);
    await ThermalPrintService.printSaleExchange(ex, printer: printer);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(saleExchangeReportProvider);
    final notifier = ref.read(saleExchangeReportProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Sale Exchange Report',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              if (state.hasFilter)
                TextButton.icon(
                  onPressed: notifier.clearDateRange,
                  icon: const AppIcon(AppIcons.clear, size: 16),
                  label: Text(_rangeLabel(state.startDate, state.endDate)),
                ),
              const SizedBox(width: 8),
              ReportBranchFilterDropdown(value: state.branchId, onChanged: notifier.setBranch),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const AppIcon(AppIcons.filterAltOutlined, size: 18),
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
                icon: const AppIcon(AppIcons.refresh),
                onPressed: notifier.load,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: ReportSummaryCard(
                label: 'Total Exchanges',
                value: '${state.totalCount}',
                icon: AppIcons.swapHorizOutlined,
                color: _accent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ReportSummaryCard(
                label: 'Total Quantity',
                value: '${state.totalQuantity}',
                icon: AppIcons.inventory2Outlined,
                color: const Color(0xFFE56A00),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ReportSummaryCard(
                label: 'Total Sale',
                value: 'Rs. ${state.totalAmount.toStringAsFixed(0)}',
                icon: AppIcons.pointOfSaleOutlined,
                color: const Color(0xFF22A06B),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : state.error != null
                          ? Center(
                              child: Text('Error: ${state.error}',
                                  style: const TextStyle(color: Colors.red)))
                          : state.rows.isEmpty
                              ? const Center(child: Text('No sale exchanges found'))
                              : ReportTableShell(
                                  columns: const [
                                    DataColumn(label: Text('Exchange #')),
                                    DataColumn(label: Text('Against Invoice')),
                                    DataColumn(label: Text('Branch')),
                                    DataColumn(label: Text('Customer')),
                                    DataColumn(label: Text('Date')),
                                    DataColumn(label: Text('New Total'), numeric: true),
                                    DataColumn(label: Text('Difference'), numeric: true),
                                    DataColumn(label: Text('Actions')),
                                  ],
                                  rows: state.rows
                                      .map((ex) => DataRow(
                                            selected: _selected?.id == ex.id,
                                            cells: [
                                              DataCell(Text(ex.exchangeNumber,
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.w600))),
                                              DataCell(Text(ex.originalInvoiceNumber ?? '—')),
                                              DataCell(Text(ex.branchName ?? '—')),
                                              DataCell(Text(ex.customerName ?? '—')),
                                              DataCell(Text(_fmtDate(ex.createdAt))),
                                              DataCell(Text(ex.newTotal.toStringAsFixed(0),
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.w700))),
                                              DataCell(Text(
                                                  '${ex.differenceAmount >= 0 ? '+' : ''}${ex.differenceAmount.toStringAsFixed(0)}',
                                                  style: TextStyle(
                                                      color: ex.differenceAmount > 0
                                                          ? Colors.green
                                                          : ex.differenceAmount < 0
                                                              ? Colors.red
                                                              : Colors.grey))),
                                              DataCell(Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const AppIcon(AppIcons.visibilityOutlined,
                                                        size: 19),
                                                    tooltip: 'View',
                                                    onPressed: () =>
                                                        setState(() => _selected = ex),
                                                  ),
                                                  IconButton(
                                                    icon: const AppIcon(AppIcons.printOutlined,
                                                        size: 19),
                                                    tooltip: 'Print',
                                                    onPressed: () => _print(ex),
                                                  ),
                                                ],
                                              )),
                                            ],
                                          ))
                                      .toList(),
                                ),
                ),
                if (_selected != null)
                  ReportDetailOverlay(
                    title: _selected!.exchangeNumber,
                    subtitle: '${_selected!.branchName ?? '—'} · ${_fmtDate(_selected!.createdAt)}',
                    accent: _accent,
                    onClose: () => setState(() => _selected = null),
                    onPrint: () => _print(_selected!),
                    child: _ExchangeDetailBody(exchange: _selected!),
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

class _ExchangeDetailBody extends StatelessWidget {
  final SaleExchangeModel exchange;
  const _ExchangeDetailBody({required this.exchange});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailKV('Branch', exchange.branchName ?? '—'),
        DetailKV('Customer', exchange.customerName ?? '—'),
        DetailKV('Against Invoice', exchange.originalInvoiceNumber ?? '—'),
        if (exchange.returnItems.isNotEmpty) ...[
          const DetailDivider(),
          DetailSectionLabel('RETURNED ITEMS (${exchange.returnItems.length})'),
          for (final item in exchange.returnItems)
            DetailProductRow(
              name: item.productName ?? 'Item',
              sizeName: item.sizeName,
              colorName: item.colorName,
              quantity: item.quantity,
              total: item.totalPrice,
            ),
          DetailKV('Return Total', 'Rs. ${exchange.returnTotal.toStringAsFixed(0)}'),
        ],
        const DetailDivider(),
        DetailSectionLabel('NEW ITEMS (${exchange.newItems.length})'),
        for (final item in exchange.newItems)
          DetailProductRow(
            name: item.productName ?? 'Item',
            sizeName: item.sizeName,
            colorName: item.colorName,
            quantity: item.quantity,
            total: item.totalPrice,
          ),
        DetailKV('New Total', 'Rs. ${exchange.newTotal.toStringAsFixed(0)}'),
        const DetailDivider(),
        DetailKV(
          exchange.differenceLabel == 'Refund'
              ? 'Refund To Customer'
              : exchange.differenceLabel == 'Collect'
                  ? 'Collect From Customer'
                  : 'Even Exchange',
          'Rs. ${exchange.differenceAmount.abs().toStringAsFixed(0)}',
          bold: true,
          valueColor: exchange.differenceAmount < 0
              ? Colors.red.shade400
              : exchange.differenceAmount > 0
                  ? Colors.green.shade700
                  : null,
        ),
        if (exchange.payments.isNotEmpty) ...[
          const DetailDivider(),
          DetailSectionLabel('PAYMENTS'),
          for (final p in exchange.payments)
            DetailKV('${p.direction == 'refund' ? 'Refunded' : 'Collected'} (${p.paymentType.toUpperCase()})',
                'Rs. ${p.amount.toStringAsFixed(0)}'),
        ],
      ],
    );
  }
}
