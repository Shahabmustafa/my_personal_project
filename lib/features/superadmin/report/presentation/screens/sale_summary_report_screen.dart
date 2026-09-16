import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/sale_transaction_row.dart';
import '../providers/sale_report_providers.dart' show saleReportRepositoryProvider;
import '../providers/sale_summary_provider.dart';
import '../widgets/report_branch_filter_dropdown.dart';
import '../widgets/report_date_filter_dialog.dart';
import '../widgets/report_detail_panel.dart';
import '../widgets/report_summary_card.dart';
import '../widgets/report_table_shell.dart';
import '../../../../branch/shared/current_branch_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/utils/responsive.dart';

/// Sale Invoice, Sale Return aur Sale Exchange teeno — ek hi combined list
/// mein (newest first), top par Total Sale / Total Return / Exchange /
/// Net Total Sale cards ke sath.
class SaleSummaryReportScreen extends ConsumerStatefulWidget {
  /// Branch-role users ke liye: true hone par sirf apni branch ka data
  /// dikhta hai — branch filter dropdown aur "Branch" column hide ho jate
  /// hain, aur data hamesha [currentBranchIdProvider] tak restricted rehta hai.
  final bool restrictToOwnBranch;

  const SaleSummaryReportScreen({super.key, this.restrictToOwnBranch = false});

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

  @override
  void initState() {
    super.initState();
    if (widget.restrictToOwnBranch) {
      final branchId = ref.read(currentBranchIdProvider);
      ref.read(saleSummaryProvider.notifier).setBranch(branchId);
    }
  }

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
      setState(() => _loadingId = null);
      final subtitle = '${t.branchName ?? '—'} · ${_fmtDateTime(t.createdAt)}';
      if (Responsive(context).isMobile) {
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => _MobileDetailScreen(
            title: t.number,
            subtitle: subtitle,
            accent: _rowColor(t.type),
            child: body,
          ),
        ));
      } else {
        setState(() {
          _selectedRow = t;
          _selectedBody = body;
        });
      }
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
    final isMobile = Responsive(context).isMobile;

    Future<void> openDateFilter() async {
      final result = await showDialog<(DateTime?, DateTime?)?>(
        context: context,
        builder: (_) => ReportDateFilterDialog(
            initialStart: state.startDate, initialEnd: state.endDate),
      );
      if (result != null) {
        notifier.applyDateRange(result.$1, result.$2);
      }
    }

    final header = isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Sale Summary',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const AppIcon(AppIcons.refresh, size: 18),
                    onPressed: notifier.load,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (state.hasFilter)
                    TextButton.icon(
                      onPressed: notifier.clearDateRange,
                      icon: const AppIcon(AppIcons.clear, size: 16),
                      label: Text(_rangeLabel(state.startDate, state.endDate)),
                    ),
                  if (!widget.restrictToOwnBranch)
                    ReportBranchFilterDropdown(value: state.branchId, onChanged: notifier.setBranch),
                  OutlinedButton.icon(
                    icon: const AppIcon(AppIcons.filterAltOutlined, size: 18),
                    label: const Text('Filter'),
                    onPressed: openDateFilter,
                  ),
                ],
              ),
            ],
          )
        : Row(
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
              if (!widget.restrictToOwnBranch) ...[
                ReportBranchFilterDropdown(value: state.branchId, onChanged: notifier.setBranch),
                const SizedBox(width: 8),
              ],
              OutlinedButton.icon(
                icon: const AppIcon(AppIcons.filterAltOutlined, size: 18),
                label: const Text('Filter'),
                onPressed: openDateFilter,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const AppIcon(AppIcons.refresh, size: 18),
                onPressed: notifier.load,
              ),
            ],
          );

    final summaryCards = isMobile
        ? LayoutBuilder(
            builder: (context, c) {
              const gap = 12.0;
              final cardW = (c.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  SizedBox(
                    width: cardW,
                    child: ReportSummaryCard(
                      label: 'Total Sale',
                      value: 'Rs. ${totals.totalSale.toStringAsFixed(0)}',
                      icon: AppIcons.pointOfSaleOutlined,
                      color: _saleColor,
                    ),
                  ),
                  SizedBox(
                    width: cardW,
                    child: ReportSummaryCard(
                      label: 'Total Return',
                      value: 'Rs. ${totals.totalReturn.toStringAsFixed(0)}',
                      icon: AppIcons.assignmentReturnOutlined,
                      color: _returnColor,
                    ),
                  ),
                  SizedBox(
                    width: cardW,
                    child: ReportSummaryCard(
                      label: totals.exchangeChange < 0
                          ? 'Exchange (Refunded)'
                          : 'Exchange (Collected)',
                      value: 'Rs. ${totals.exchangeChange.abs().toStringAsFixed(0)}',
                      icon: AppIcons.swapHorizOutlined,
                      color: _exchangeColor,
                    ),
                  ),
                  SizedBox(
                    width: cardW,
                    child: ReportSummaryCard(
                      label: 'Net Total Sale',
                      value: 'Rs. ${totals.netTotalSale.toStringAsFixed(0)}',
                      icon: AppIcons.accountBalanceWalletOutlined,
                      color: _netColor,
                    ),
                  ),
                ],
              );
            },
          )
        : Row(children: [
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
          ]);

    final content = isMobile
        ? (state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.transactions.isEmpty
                ? const Center(child: Text('No transactions found'))
                : _MobileTransactionList(
                    transactions: state.transactions,
                    restrictToOwnBranch: widget.restrictToOwnBranch,
                    loadingId: _loadingId,
                    rowColor: _rowColor,
                    fmtDateTime: _fmtDateTime,
                    onView: _viewDetail,
                  ))
        : Stack(
            children: [
              Positioned.fill(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state.transactions.isEmpty
                        ? const Center(child: Text('No transactions found'))
                        : SingleChildScrollView(
                            child: ReportTableShell(
                              columns: [
                                const DataColumn(label: Text('Type')),
                                const DataColumn(label: Text('Number')),
                                if (!widget.restrictToOwnBranch)
                                  const DataColumn(label: Text('Branch')),
                                const DataColumn(label: Text('Customer')),
                                const DataColumn(label: Text('Date')),
                                const DataColumn(label: Text('Amount'), numeric: true),
                                const DataColumn(label: Text('Actions')),
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
                                          if (!widget.restrictToOwnBranch)
                                            DataCell(Text(t.branchName ?? '—')),
                                          DataCell(Text(t.customerName ?? '—')),
                                          DataCell(Text(_fmtDateTime(t.createdAt))),
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
                      '${_selectedRow!.branchName ?? '—'} · ${_fmtDateTime(_selectedRow!.createdAt)}',
                  accent: _rowColor(_selectedRow!.type),
                  onClose: () => setState(() {
                    _selectedRow = null;
                    _selectedBody = null;
                  }),
                  child: _selectedBody!,
                ),
            ],
          );

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 16),
          summaryCards,
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Error: ${state.error}', style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 16),
          Expanded(child: content),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtDateTime(DateTime d) {
    final local = d.toLocal();
    final hour24 = local.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final period = hour24 < 12 ? 'AM' : 'PM';
    final time =
        '${hour12.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')} $period';
    return '${_fmtDate(local)} $time';
  }

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

/// Mobile-width fallback for the transactions table — one compact card per
/// row instead of a horizontally-cramped DataTable. Tapping a card opens the
/// same detail as the desktop "View" action.
class _MobileTransactionList extends StatelessWidget {
  final List<SaleTransactionRow> transactions;
  final bool restrictToOwnBranch;
  final String? loadingId;
  final Color Function(SaleTransactionType) rowColor;
  final String Function(DateTime) fmtDateTime;
  final ValueChanged<SaleTransactionRow> onView;

  const _MobileTransactionList({
    required this.transactions,
    required this.restrictToOwnBranch,
    required this.loadingId,
    required this.rowColor,
    required this.fmtDateTime,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final t = transactions[i];
        final color = rowColor(t.type);
        final isLoading = loadingId == t.id;
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isLoading ? null : () => onView(t),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE7E9F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _TypeBadge(type: t.type, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(t.number,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const AppIcon(AppIcons.chevronRight, size: 18, color: Color(0xFF8A8FA3)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    if (!restrictToOwnBranch) t.branchName ?? '—',
                    t.customerName ?? '—',
                  ].join(' · '),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF8A8FA3)),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(fmtDateTime(t.createdAt),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF8A8FA3))),
                    Text(
                      '${t.amount < 0 ? '- ' : ''}Rs. ${t.amount.abs().toStringAsFixed(0)}',
                      style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Full-screen route used for the transaction detail on mobile, replacing
/// the desktop's fixed-width [ReportDetailOverlay] side panel.
class _MobileDetailScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final Widget child;

  const _MobileDetailScreen({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FC),
        foregroundColor: const Color(0xFF2D2D3A),
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: accent)),
            Text(subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF8A8FA3)),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}
