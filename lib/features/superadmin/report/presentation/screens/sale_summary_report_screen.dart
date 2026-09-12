import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/sale_transaction_row.dart';
import '../providers/sale_invoice_report_provider.dart' show saleReportRepositoryProvider;
import '../providers/sale_summary_provider.dart';
import '../widgets/report_branch_filter_dropdown.dart';
import '../widgets/report_date_filter_dialog.dart';
import '../widgets/report_detail_panel.dart';
import '../widgets/report_summary_card.dart';
import '../widgets/report_table_shell.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';

/// Sale Invoice, Sale Return aur Sale Exchange teeno — ek hi combined list
/// mein (newest first), top par Total Sale / Total Return / Exchange /
/// Net Total Sale cards ke sath.
class SaleSummaryReportScreen extends ConsumerStatefulWidget {
  const SaleSummaryReportScreen({super.key});

  @override
  ConsumerState<SaleSummaryReportScreen> createState() => _SaleSummaryReportScreenState();
}

class _SaleSummaryReportScreenState extends ConsumerState<SaleSummaryReportScreen> {
  static const _saleColor = Color(0xFF22A06B);
  static const _returnColor = Colors.red;
  static const _exchangeColor = Color(0xFF6C4DE0);
  static const _netColor = Color(0xFF3E63DD);

  SaleTransactionRow? _selectedRow;
  Widget? _selectedBody;
  String? _loadingId;

  Color _rowColor(SaleTransactionType type) => switch (type) {
        SaleTransactionType.sale => _saleColor,
        SaleTransactionType.saleReturn => _returnColor,
        SaleTransactionType.exchange => _exchangeColor,
      };

  Future<void> _viewDetail(SaleTransactionRow t) async {
    setState(() => _loadingId = t.id);
    final repo = ref.read(saleReportRepositoryProvider);
    try {
      final Widget body = switch (t.type) {
        SaleTransactionType.sale =>
          InvoiceDetailBody(invoice: await repo.getInvoiceById(t.id)),
        SaleTransactionType.saleReturn =>
          ReturnDetailBody(saleReturn: await repo.getReturnById(t.id)),
        SaleTransactionType.exchange =>
          ExchangeDetailBody(exchange: await repo.getExchangeById(t.id)),
      };
      if (!mounted) return;
      setState(() {
        _selectedRow = t;
        _selectedBody = body;
        _loadingId = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load detail: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(saleSummaryProvider);
    final notifier = ref.read(saleSummaryProvider.notifier);
    final totals = state.totals;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Sale Summary',
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
                label: 'Total Sale',
                value: 'Rs. ${totals.totalSale.toStringAsFixed(0)}',
                icon: AppIcons.pointOfSaleOutlined,
                color: _saleColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ReportSummaryCard(
                label: 'Total Return',
                value: 'Rs. ${totals.totalReturn.toStringAsFixed(0)}',
                icon: AppIcons.assignmentReturnOutlined,
                color: _returnColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ReportSummaryCard(
                label:
                    totals.exchangeChange < 0 ? 'Exchange (Refunded)' : 'Exchange (Collected)',
                value: 'Rs. ${totals.exchangeChange.abs().toStringAsFixed(0)}',
                icon: AppIcons.swapHorizOutlined,
                color: _exchangeColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ReportSummaryCard(
                label: 'Net Total Sale',
                value: 'Rs. ${totals.netTotalSale.toStringAsFixed(0)}',
                icon: AppIcons.accountBalanceWalletOutlined,
                color: _netColor,
              ),
            ),
          ]),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Error: ${state.error}', style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : state.transactions.isEmpty
                          ? const Center(child: Text('No transactions found'))
                          : SingleChildScrollView(
                              child: ReportTableShell(
                                columns: const [
                                  DataColumn(label: Text('Type')),
                                  DataColumn(label: Text('Number')),
                                  DataColumn(label: Text('Branch')),
                                  DataColumn(label: Text('Customer')),
                                  DataColumn(label: Text('Date')),
                                  DataColumn(label: Text('Amount'), numeric: true),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: state.transactions
                                    .map((t) => DataRow(
                                          selected: _selectedRow?.id == t.id,
                                          cells: [
                                            DataCell(
                                                _TypeBadge(type: t.type, color: _rowColor(t.type))),
                                            DataCell(Text(t.number,
                                                style:
                                                    const TextStyle(fontWeight: FontWeight.w600))),
                                            DataCell(Text(t.branchName ?? '—')),
                                            DataCell(Text(t.customerName ?? '—')),
                                            DataCell(Text(_fmtDate(t.createdAt))),
                                            DataCell(Text(
                                              '${t.amount < 0 ? '- ' : ''}Rs. ${t.amount.abs().toStringAsFixed(0)}',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: _rowColor(t.type)),
                                            )),
                                            DataCell(
                                              _loadingId == t.id
                                                  ? const SizedBox(
                                                      width: 19,
                                                      height: 19,
                                                      child:
                                                          CircularProgressIndicator(strokeWidth: 2),
                                                    )
                                                  : IconButton(
                                                      icon: const AppIcon(
                                                          AppIcons.visibilityOutlined,
                                                          size: 19),
                                                      tooltip: 'View',
                                                      onPressed: () => _viewDetail(t),
                                                    ),
                                            ),
                                          ],
                                        ))
                                    .toList(),
                              ),
                            ),
                ),
                if (_selectedRow != null && _selectedBody != null)
                  ReportDetailOverlay(
                    title: _selectedRow!.number,
                    subtitle:
                        '${_selectedRow!.branchName ?? '—'} · ${_fmtDate(_selectedRow!.createdAt)}',
                    accent: _rowColor(_selectedRow!.type),
                    onClose: () => setState(() {
                      _selectedRow = null;
                      _selectedBody = null;
                    }),
                    child: _selectedBody!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _rangeLabel(DateTime? start, DateTime? end) {
    if (start == null && end == null) return '';
    final s = start == null ? '…' : _fmtDate(start);
    final e = end == null ? '…' : _fmtDate(end);
    return '$s – $e';
  }
}

class _TypeBadge extends StatelessWidget {
  final SaleTransactionType type;
  final Color color;
  const _TypeBadge({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      SaleTransactionType.sale => 'Sale',
      SaleTransactionType.saleReturn => 'Return',
      SaleTransactionType.exchange => 'Exchange',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
