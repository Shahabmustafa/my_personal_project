import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../head_office_purchase/data/models/purchase_invoice_model.dart';
import '../../../head_office_purchase/data/models/purchase_return_model.dart';
import '../../data/model/purchase_transaction_row.dart';
import '../providers/purchase_summary_provider.dart';
import '../widgets/report_date_filter_dialog.dart';
import '../widgets/report_detail_panel.dart';
import '../widgets/report_pagination_bar.dart';
import '../widgets/report_summary_card.dart';
import '../widgets/report_table_shell.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/utils/responsive.dart';

/// Purchase Invoice aur Purchase Return dono — ek hi combined history list
/// mein (newest first), top par Total Purchase / Total Return / Net Purchase /
/// Credit cards ke sath. Sale Summary screen jaisa layout.
class PurchaseSummaryReportScreen extends ConsumerStatefulWidget {
  const PurchaseSummaryReportScreen({super.key});

  @override
  ConsumerState<PurchaseSummaryReportScreen> createState() =>
      _PurchaseSummaryReportScreenState();
}

class _PurchaseSummaryReportScreenState
    extends ConsumerState<PurchaseSummaryReportScreen> {
  static const _purchaseColor = Color(0xFF22A06B);
  static const _returnColor = Colors.red;
  static const _netColor = Color(0xFF3E63DD);
  static const _creditColor = Color(0xFFE08A00);

  PurchaseTransactionRow? _selectedRow;
  Widget? _selectedBody;
  String? _loadingId;

  Color _rowColor(PurchaseTransactionType type) => switch (type) {
    PurchaseTransactionType.purchase => _purchaseColor,
    PurchaseTransactionType.purchaseReturn => _returnColor,
  };

  Future<void> _viewDetail(PurchaseTransactionRow t) async {
    setState(() => _loadingId = t.id);
    final ds = ref.read(purchaseReportDatasourceProvider);
    try {
      final Widget body = switch (t.type) {
        PurchaseTransactionType.purchase => _PurchaseInvoiceDetailBody(
          invoice: await ds.fetchInvoiceById(t.id),
          source: t.source,
        ),
        PurchaseTransactionType.purchaseReturn => _PurchaseReturnDetailBody(
          purchaseReturn: await ds.fetchReturnById(t.id),
          source: t.source,
        ),
      };
      if (!mounted) return;
      setState(() => _loadingId = null);
      final subtitle = '${t.companyName ?? '—'} · ${_fmtDateTime(t.createdAt)}';
      if (Responsive(context).isMobile) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _MobileDetailScreen(
              title: t.number,
              subtitle: subtitle,
              accent: _rowColor(t.type),
              child: body,
            ),
          ),
        );
      } else {
        setState(() {
          _selectedRow = t;
          _selectedBody = body;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingId = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load detail: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseSummaryProvider);
    final notifier = ref.read(purchaseSummaryProvider.notifier);
    final totals = state.totals;
    final isMobile = Responsive(context).isMobile;

    Future<void> openDateFilter() async {
      final result = await showDialog<(DateTime?, DateTime?)?>(
        context: context,
        builder: (_) => ReportDateFilterDialog(
          initialStart: state.startDate,
          initialEnd: state.endDate,
        ),
      );
      if (result != null) {
        notifier.applyDateRange(result.$1, result.$2);
      }
    }

    final filters = [
      if (state.hasFilter)
        TextButton.icon(
          onPressed: notifier.clearDateRange,
          icon: const AppIcon(AppIcons.clear, size: 16),
          label: Text(_rangeLabel(state.startDate, state.endDate)),
        ),
      _CompanyFilterDropdown(
        value: state.companyId,
        onChanged: notifier.setCompany,
      ),
      OutlinedButton.icon(
        icon: const AppIcon(AppIcons.filterAltOutlined, size: 18),
        label: const Text('Filter'),
        onPressed: openDateFilter,
      ),
    ];

    final header = isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Purchase Summary',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const AppIcon(AppIcons.refresh, size: 18),
                    onPressed: notifier.load,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: filters),
            ],
          )
        : Row(
            children: [
              const Expanded(
                child: Text(
                  'Purchase Summary',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              for (final f in filters) ...[f, const SizedBox(width: 8)],
              IconButton(
                icon: const AppIcon(AppIcons.refresh, size: 18),
                onPressed: notifier.load,
              ),
            ],
          );

    final cards = [
      ReportSummaryCard(
        label: 'Total Purchase',
        value: 'Rs. ${totals.totalPurchase.toStringAsFixed(0)}',
        icon: AppIcons.shoppingCartCheckoutOutlined,
        color: _purchaseColor,
      ),
      ReportSummaryCard(
        label: 'Total Return',
        value: 'Rs. ${totals.totalReturn.toStringAsFixed(0)}',
        icon: AppIcons.assignmentReturnOutlined,
        color: _returnColor,
      ),
      ReportSummaryCard(
        label: 'Net Purchase',
        value: 'Rs. ${totals.netPurchase.toStringAsFixed(0)}',
        icon: AppIcons.accountBalanceWalletOutlined,
        color: _netColor,
      ),
      ReportSummaryCard(
        label: 'Credit (Payable)',
        value: 'Rs. ${totals.totalCredit.toStringAsFixed(0)}',
        icon: AppIcons.paymentsOutlined,
        color: _creditColor,
      ),
    ];

    final summaryCards = isMobile
        ? LayoutBuilder(
            builder: (context, c) {
              const gap = 12.0;
              final cardW = (c.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final card in cards) SizedBox(width: cardW, child: card),
                ],
              );
            },
          )
        : Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 14),
                Expanded(child: cards[i]),
              ],
            ],
          );

    final content = isMobile
        ? (state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.transactions.isEmpty
              ? const Center(child: Text('No transactions found'))
              : _MobileTransactionList(
                  transactions: state.pageRows,
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
                          columns: const [
                            DataColumn(label: Text('#'), numeric: true),
                            DataColumn(label: Text('Type')),
                            DataColumn(label: Text('Number')),
                            DataColumn(label: Text('Company')),
                            DataColumn(label: Text('Source')),
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Amount'), numeric: true),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: state.pageRows
                              .asMap()
                              .entries
                              .map(
                                (e) => (
                                  e.value,
                                  (state.page - 1) *
                                          PurchaseSummaryState.pageSize +
                                      e.key +
                                      1,
                                ),
                              )
                              .map((entry) {
                                final (t, serial) = entry;
                                return DataRow(
                                  selected: _selectedRow?.id == t.id,
                                  cells: [
                                    DataCell(
                                      Text(
                                        '$serial',
                                        style: const TextStyle(
                                          color: Color(0xFF8A8FA3),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      _TypeBadge(
                                        type: t.type,
                                        color: _rowColor(t.type),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        t.number,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(t.companyName ?? '—')),
                                    DataCell(Text(t.source)),
                                    DataCell(Text(_fmtDateTime(t.createdAt))),
                                    DataCell(
                                      Text(
                                        '${t.amount < 0 ? '- ' : ''}Rs. ${t.amount.abs().toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: _rowColor(t.type),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      _loadingId == t.id
                                          ? const SizedBox(
                                              width: 19,
                                              height: 19,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : IconButton(
                                              icon: const AppIcon(
                                                AppIcons.visibilityOutlined,
                                                size: 19,
                                              ),
                                              tooltip: 'View',
                                              onPressed: () => _viewDetail(t),
                                            ),
                                    ),
                                  ],
                                );
                              })
                              .toList(),
                        ),
                      ),
              ),
              if (_selectedRow != null && _selectedBody != null)
                ReportDetailOverlay(
                  title: _selectedRow!.number,
                  subtitle:
                      '${_selectedRow!.companyName ?? '—'} · ${_fmtDateTime(_selectedRow!.createdAt)}',
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
              child: Text(
                'Error: ${state.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 16),
          Expanded(child: content),
          if (!state.isLoading && state.transactions.isNotEmpty) ...[
            const SizedBox(height: 12),
            ReportPaginationBar(
              page: state.page,
              totalPages: state.totalPages,
              totalCount: state.transactions.length,
              pageSize: PurchaseSummaryState.pageSize,
              onPageChange: notifier.goToPage,
            ),
          ],
        ],
      ),
    );
  }

  String _rangeLabel(DateTime? start, DateTime? end) {
    if (start == null && end == null) return '';
    final s = start == null ? '…' : _fmtDate(start);
    final e = end == null ? '…' : _fmtDate(end);
    return '$s – $e';
  }
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String _fmtDateTime(DateTime d) {
  final local = d.toLocal();
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final period = local.hour < 12 ? 'AM' : 'PM';
  final time =
      '${hour12.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')} $period';
  return '${_fmtDate(local)} $time';
}

/// "All Companies" + har company — select karne par sirf usi company ki
/// purchases/returns dikhte hain.
class _CompanyFilterDropdown extends ConsumerWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  const _CompanyFilterDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companies =
        ref.watch(purchaseReportCompaniesProvider).value ?? const [];
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDADDE5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          hint: const Text('All Companies', style: TextStyle(fontSize: 13)),
          icon: const AppIcon(AppIcons.arrowDropDown, size: 18),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('All Companies'),
            ),
            for (final (id, name) in companies)
              DropdownMenuItem<String?>(value: id, child: Text(name)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final PurchaseTransactionType type;
  final Color color;
  const _TypeBadge({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      PurchaseTransactionType.purchase => 'Purchase',
      PurchaseTransactionType.purchaseReturn => 'Return',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PurchaseInvoiceDetailBody extends StatelessWidget {
  final PurchaseInvoiceModel invoice;
  final String source;
  const _PurchaseInvoiceDetailBody({
    required this.invoice,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailKV('Company', invoice.companyName ?? '—'),
        DetailKV('Source', source),
        DetailKV('Payment', invoice.paymentMode.toUpperCase()),
        if ((invoice.notes ?? '').isNotEmpty) DetailKV('Notes', invoice.notes!),
        const DetailDivider(),
        DetailSectionLabel('ITEMS (${invoice.items.length})'),
        for (final item in invoice.items)
          DetailProductRow(
            name: item.productName ?? 'Item',
            sizeName: item.sizeName,
            colorName: item.colorName,
            quantity: item.quantity,
            total: item.lineTotal,
          ),
        const DetailDivider(),
        DetailKV('Total', 'Rs. ${invoice.totalAmount.toStringAsFixed(0)}'),
        if (invoice.totalDiscount > 0)
          DetailKV(
            'Discount',
            '- Rs. ${invoice.totalDiscount.toStringAsFixed(0)}',
            valueColor: Colors.orange,
          ),
        DetailKV(
          'Net Amount',
          'Rs. ${invoice.netAmount.toStringAsFixed(0)}',
          bold: true,
          valueColor: Colors.green.shade700,
        ),
        DetailKV('Paid', 'Rs. ${invoice.paidAmount.toStringAsFixed(0)}'),
        if (invoice.creditAmount > 0)
          DetailKV(
            'Credit',
            'Rs. ${invoice.creditAmount.toStringAsFixed(0)}',
            valueColor: Colors.orange.shade800,
          ),
        // Transport / Barcode — cash counter se, company ke khate se alag.
        if (invoice.expenses.isNotEmpty) ...[
          const DetailDivider(),
          DetailSectionLabel('EXPENSES (${invoice.expenses.length})'),
          for (final e in invoice.expenses)
            DetailKV(e.headName ?? 'Expense',
                'Rs. ${e.amount.toStringAsFixed(0)}',
                valueColor: Colors.red),
          DetailKV(
            'Total Cost',
            'Rs. ${(invoice.netAmount + invoice.expenseAmount).toStringAsFixed(0)}',
            bold: true,
          ),
        ],
      ],
    );
  }
}

class _PurchaseReturnDetailBody extends StatelessWidget {
  final PurchaseReturnModel purchaseReturn;
  final String source;
  const _PurchaseReturnDetailBody({
    required this.purchaseReturn,
    required this.source,
  });

  @override
  Widget build(BuildContext context) {
    final r = purchaseReturn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailKV('Company', r.companyName ?? '—'),
        DetailKV('Source', source),
        if ((r.notes ?? '').isNotEmpty) DetailKV('Notes', r.notes!),
        const DetailDivider(),
        DetailSectionLabel('ITEMS (${r.items.length})'),
        for (final item in r.items)
          DetailProductRow(
            name: item.productName ?? 'Item',
            sizeName: item.sizeName,
            colorName: item.colorName,
            quantity: item.quantity,
            total: item.lineTotal,
          ),
        const DetailDivider(),
        DetailKV('Total', 'Rs. ${r.totalAmount.toStringAsFixed(0)}'),
        if (r.totalDiscount > 0)
          DetailKV(
            'Discount',
            '- Rs. ${r.totalDiscount.toStringAsFixed(0)}',
            valueColor: Colors.orange,
          ),
        DetailKV(
          'Net Return',
          'Rs. ${r.netAmount.toStringAsFixed(0)}',
          bold: true,
          valueColor: Colors.red,
        ),
      ],
    );
  }
}

/// Mobile-width fallback — har row ka ek compact card; tap par detail.
class _MobileTransactionList extends StatelessWidget {
  final List<PurchaseTransactionRow> transactions;
  final String? loadingId;
  final Color Function(PurchaseTransactionType) rowColor;
  final String Function(DateTime) fmtDateTime;
  final ValueChanged<PurchaseTransactionRow> onView;

  const _MobileTransactionList({
    required this.transactions,
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
                      child: Text(
                        t.number,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const AppIcon(
                        AppIcons.chevronRight,
                        size: 18,
                        color: Color(0xFF8A8FA3),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${t.companyName ?? '—'} · ${t.source}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A8FA3),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      fmtDateTime(t.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8A8FA3),
                      ),
                    ),
                    Text(
                      '${t.amount < 0 ? '- ' : ''}Rs. ${t.amount.abs().toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: color,
                        fontSize: 13,
                      ),
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

/// Mobile par detail ke liye full-screen route.
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
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8A8FA3)),
              overflow: TextOverflow.ellipsis,
            ),
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
