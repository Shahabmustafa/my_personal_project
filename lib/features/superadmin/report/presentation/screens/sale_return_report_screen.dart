import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/service/print/print_service.dart';
import '../../../../branch/sale_return/data/model/sale_return_model.dart';
import '../providers/sale_invoice_report_provider.dart' show saleReportRepositoryProvider;
import '../providers/sale_return_report_provider.dart';
import '../widgets/report_date_filter_dialog.dart';
import '../widgets/report_detail_panel.dart';
import '../widgets/report_table_shell.dart';
import '../widgets/report_pagination_bar.dart';
import '../widgets/report_summary_card.dart';
import '../widgets/report_branch_filter_dropdown.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
class SaleReturnReportScreen extends ConsumerStatefulWidget {
  const SaleReturnReportScreen({super.key});

  @override
  ConsumerState<SaleReturnReportScreen> createState() => _SaleReturnReportScreenState();
}

class _SaleReturnReportScreenState extends ConsumerState<SaleReturnReportScreen> {
  SaleReturnModel? _selected;

  static const _accent = Colors.red;

  Future<void> _print(SaleReturnModel r) async {
    final printer =
        await ref.read(saleReportRepositoryProvider).getBranchPrinter(r.branchId);
    await ThermalPrintService.printSaleReturn(r, printer: printer);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(saleReturnReportProvider);
    final notifier = ref.read(saleReturnReportProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Sale Return Report',
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
                label: 'Total Returns',
                value: '${state.totalCount}',
                icon: AppIcons.assignmentReturnOutlined,
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
                label: 'Total Return',
                value: 'Rs. ${state.totalAmount.toStringAsFixed(0)}',
                icon: AppIcons.currencyExchange,
                color: _accent,
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
                              ? const Center(child: Text('No sale returns found'))
                              : ReportTableShell(
                                  columns: const [
                                    DataColumn(label: Text('Return #')),
                                    DataColumn(label: Text('Against Invoice')),
                                    DataColumn(label: Text('Branch')),
                                    DataColumn(label: Text('Customer')),
                                    DataColumn(label: Text('Date')),
                                    DataColumn(label: Text('Total'), numeric: true),
                                    DataColumn(label: Text('Actions')),
                                  ],
                                  rows: state.rows
                                      .map((r) => DataRow(
                                            selected: _selected?.id == r.id,
                                            cells: [
                                              DataCell(Text(r.returnNumber,
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.w600))),
                                              DataCell(Text(r.originalInvoiceNumber ?? '—')),
                                              DataCell(Text(r.branchName ?? '—')),
                                              DataCell(Text(r.customerName ?? '—')),
                                              DataCell(Text(_fmtDate(r.createdAt))),
                                              DataCell(Text(r.totalAmount.toStringAsFixed(0),
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.w700,
                                                      color: _accent))),
                                              DataCell(Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const AppIcon(AppIcons.visibilityOutlined,
                                                        size: 19),
                                                    tooltip: 'View',
                                                    onPressed: () =>
                                                        setState(() => _selected = r),
                                                  ),
                                                  IconButton(
                                                    icon: const AppIcon(AppIcons.printOutlined,
                                                        size: 19),
                                                    tooltip: 'Print',
                                                    onPressed: () => _print(r),
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
                    title: _selected!.returnNumber,
                    subtitle: '${_selected!.branchName ?? '—'} · ${_fmtDate(_selected!.createdAt)}',
                    accent: _accent,
                    onClose: () => setState(() => _selected = null),
                    onPrint: () => _print(_selected!),
                    child: ReturnDetailBody(saleReturn: _selected!),
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
