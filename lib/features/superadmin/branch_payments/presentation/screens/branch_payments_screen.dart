import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../branch/branch_payment/data/model/branch_payment_model.dart';
import '../../../../branch/branch_payment/presentation/providers/branch_payment_provider.dart';
import '../../../../branch/return_stock_to_other_branch/presentation/screens/branch_stock_return_screen.dart'
    show StatusChip;
import '../../../report/presentation/widgets/report_branch_filter_dropdown.dart';
import '../../../report/presentation/widgets/report_date_filter_dialog.dart';
import '../../../report/presentation/widgets/report_detail_panel.dart';
import '../../../report/presentation/widgets/report_pagination_bar.dart';
import '../../../report/presentation/widgets/report_summary_card.dart';
import '../../../report/presentation/widgets/report_table_shell.dart';
import '../providers/branch_payments_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/utils/responsive.dart';

/// Transaction report of the amounts branches have paid to Head Office.
/// Accepting a pending payment adds it to the Head Office cash counter's net
/// amount; rejecting it returns the money to the branch's cash counter.
/// Laid out like the other reports: summary cards, table, slide-in detail
/// panel on "View", and a pagination bar.
class BranchPaymentsScreen extends ConsumerStatefulWidget {
  const BranchPaymentsScreen({super.key});

  @override
  ConsumerState<BranchPaymentsScreen> createState() =>
      _BranchPaymentsScreenState();
}

class _BranchPaymentsScreenState extends ConsumerState<BranchPaymentsScreen> {
  static const _accent = Color(0xFF1565C0);
  static const _pageSize = 20;

  String _filterStatus = 'all'; // all | pending | accepted | rejected
  String? _branchId;
  DateTime? _startDate;
  DateTime? _endDate;
  int _page = 1;
  BranchPaymentModel? _selected;

  bool get _hasDateFilter => _startDate != null || _endDate != null;

  /// Branch + date scope. Status chips count within this, so they always add
  /// up to what the table can show.
  List<BranchPaymentModel> _applyScope(List<BranchPaymentModel> all) {
    DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
    final from = _startDate == null ? null : dayOf(_startDate!);
    final to = _endDate == null ? null : dayOf(_endDate!);
    return all.where((p) {
      if (_branchId != null && p.branchId != _branchId) return false;
      final d = dayOf(p.paidAt);
      if (from != null && d.isBefore(from)) return false;
      if (to != null && d.isAfter(to)) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(incomingBranchPaymentsProvider);
    final all = paymentsAsync.value ?? const <BranchPaymentModel>[];
    final isMobile = Responsive(context).isMobile;

    final scoped = _applyScope(all);
    final filtered = _filterStatus == 'all'
        ? scoped
        : scoped.where((p) => p.status == _filterStatus).toList();

    final totalCount = filtered.length;
    final totalPages = totalCount == 0 ? 1 : ((totalCount - 1) ~/ _pageSize) + 1;
    final page = _page.clamp(1, totalPages);
    final pageRows =
        filtered.skip((page - 1) * _pageSize).take(_pageSize).toList();

    double sum(Iterable<BranchPaymentModel> l) =>
        l.fold<double>(0, (s, p) => s + p.amount);
    final totalAmount = sum(filtered);
    final acceptedAmount = sum(filtered.where((p) => p.status == 'accepted'));
    final pendingAmount = sum(filtered.where((p) => p.status == 'pending'));

    final titleRow = Row(
      children: [
        const AppIcon(AppIcons.paymentsOutlined, color: _accent, size: 24),
        const SizedBox(width: 8),
        const Expanded(
          child: Text('Branch Payments',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ),
      ],
    );

    final headerActions = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ReportBranchFilterDropdown(
          value: _branchId,
          onChanged: (v) => setState(() {
            _branchId = v;
            _page = 1;
          }),
        ),
        if (_hasDateFilter)
          TextButton.icon(
            onPressed: () => setState(() {
              _startDate = null;
              _endDate = null;
              _page = 1;
            }),
            icon: const AppIcon(AppIcons.clear, size: 16),
            label: Text(_rangeLabel(_startDate, _endDate)),
          ),
        OutlinedButton.icon(
          icon: const AppIcon(AppIcons.filterAltOutlined, size: 18),
          label: const Text('Filter'),
          onPressed: () async {
            final result = await showDialog<(DateTime?, DateTime?)?>(
              context: context,
              builder: (_) => ReportDateFilterDialog(
                  initialStart: _startDate, initialEnd: _endDate),
            );
            if (result != null) {
              setState(() {
                _startDate = result.$1;
                _endDate = result.$2;
                _page = 1;
              });
            }
          },
        ),
        IconButton(
          icon: const AppIcon(AppIcons.refresh, size: 18),
          tooltip: 'Refresh',
          onPressed: () => ref.invalidate(incomingBranchPaymentsProvider),
        ),
      ],
    );

    final summaryCards = [
      ReportSummaryCard(
        label: 'Total Payments',
        value: '$totalCount',
        icon: AppIcons.receiptLongOutlined,
        color: _accent,
      ),
      ReportSummaryCard(
        label: 'Total Amount',
        value: 'Rs. ${_money(totalAmount)}',
        icon: AppIcons.accountBalanceWalletOutlined,
        color: const Color(0xFF6A1B9A),
      ),
      ReportSummaryCard(
        label: 'Accepted Amount',
        value: 'Rs. ${_money(acceptedAmount)}',
        icon: AppIcons.checkCircleOutline,
        color: const Color(0xFF22A06B),
      ),
      ReportSummaryCard(
        label: 'Pending Amount',
        value: 'Rs. ${_money(pendingAmount)}',
        icon: AppIcons.hourglassEmptyOutlined,
        color: const Color(0xFFE56A00),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [titleRow, const SizedBox(height: 8), headerActions],
                )
              : Row(
                  children: [
                    const AppIcon(AppIcons.paymentsOutlined,
                        color: _accent, size: 24),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Branch Payments',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                    ),
                    headerActions,
                  ],
                ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (ctx, c) {
              final w = c.maxWidth;
              final cols = w > 900 ? 4 : w > 560 ? 2 : 1;
              const gap = 14.0;
              final cardW = (w - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final card in summaryCards)
                    SizedBox(width: cardW, child: card),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', 'all', scoped.length),
                const SizedBox(width: 8),
                _filterChip('Pending', 'pending',
                    scoped.where((p) => p.status == 'pending').length),
                const SizedBox(width: 8),
                _filterChip('Accepted', 'accepted',
                    scoped.where((p) => p.status == 'accepted').length),
                const SizedBox(width: 8),
                _filterChip('Rejected', 'rejected',
                    scoped.where((p) => p.status == 'rejected').length),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: paymentsAsync.isLoading && !paymentsAsync.hasValue
                      ? const Center(child: CircularProgressIndicator())
                      : paymentsAsync.hasError && !paymentsAsync.hasValue
                          ? _ErrorView(
                              message: '${paymentsAsync.error}',
                              onRetry: () =>
                                  ref.invalidate(incomingBranchPaymentsProvider),
                            )
                          : pageRows.isEmpty
                              ? Center(
                                  child: Text(
                                    all.isEmpty
                                        ? 'No payments received yet'
                                        : 'No payments match this filter',
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 15),
                                  ),
                                )
                              : ReportTableShell(
                                  columns: const [
                                    DataColumn(label: Text('Payment No')),
                                    DataColumn(label: Text('From Branch')),
                                    DataColumn(
                                        label: Text('Amount'), numeric: true),
                                    DataColumn(label: Text('Date')),
                                    DataColumn(label: Text('Status')),
                                    DataColumn(label: Text('Actions')),
                                  ],
                                  rows: [
                                    for (final p in pageRows)
                                      DataRow(
                                        selected: _selected?.id == p.id,
                                        cells: [
                                          DataCell(Text(p.paymentNumber,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontFamily: 'monospace',
                                                  color: _accent))),
                                          DataCell(
                                              Text(p.branchName ?? p.branchId)),
                                          DataCell(Text(
                                              'Rs. ${_money(p.amount)}',
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600))),
                                          DataCell(Text(_fmtDate(p.paidAt))),
                                          DataCell(StatusChip(p.status)),
                                          DataCell(_rowActions(p)),
                                        ],
                                      ),
                                  ],
                                ),
                ),
                if (_selected != null)
                  ReportDetailOverlay(
                    title: _selected!.paymentNumber,
                    subtitle:
                        '${_selected!.branchName ?? '—'} · ${_fmtDate(_selected!.paidAt)}',
                    accent: _accent,
                    onClose: () => setState(() => _selected = null),
                    child: _PaymentDetailBody(payment: _selected!),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ReportPaginationBar(
            page: page,
            totalPages: totalPages,
            totalCount: totalCount,
            pageSize: _pageSize,
            onPageChange: (p) => setState(() => _page = p),
          ),
        ],
      ),
    );
  }

  Widget _rowActions(BranchPaymentModel p) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const AppIcon(AppIcons.visibilityOutlined, size: 19),
          tooltip: 'View',
          onPressed: () => setState(() => _selected = p),
        ),
        if (p.status == 'pending') ...[
          IconButton(
            icon: AppIcon(AppIcons.checkCircleOutline,
                size: 19, color: Colors.green.shade600),
            tooltip: 'Accept',
            onPressed: () => _onAccept(p),
          ),
          IconButton(
            icon: AppIcon(AppIcons.cancelOutlined,
                size: 19, color: Colors.red.shade600),
            tooltip: 'Reject',
            onPressed: () => _onReject(p),
          ),
        ],
      ],
    );
  }

  Future<void> _onAccept(BranchPaymentModel p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            AppIcon(AppIcons.checkCircleOutline, color: Colors.green, size: 22),
            SizedBox(width: 8),
            Text('Accept Payment?'),
          ],
        ),
        content: Text(
          'Rs. ${_money(p.amount)} will be added to the Head Office cash '
          'counter net amount.\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _run(() => ref
        .read(branchPaymentRepositoryProvider)
        .acceptPayment(p.id));
  }

  Future<void> _onReject(BranchPaymentModel p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            AppIcon(AppIcons.cancelOutlined, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('Reject Payment?'),
          ],
        ),
        content: Text(
          'This payment will be marked as rejected. Rs. ${_money(p.amount)} '
          'goes back to the branch cash counter.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _run(() => ref
        .read(branchPaymentRepositoryProvider)
        .rejectPayment(p.id));
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      if (!mounted) return;
      ref.invalidate(incomingBranchPaymentsProvider);
      setState(() => _selected = null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _filterChip(String label, String value, int count) {
    final isSelected = _filterStatus == value;
    Color chipColor;
    switch (value) {
      case 'pending':
        chipColor = Colors.orange;
        break;
      case 'accepted':
        chipColor = Colors.green;
        break;
      case 'rejected':
        chipColor = Colors.red;
        break;
      default:
        chipColor = _accent;
    }

    return GestureDetector(
      onTap: () => setState(() {
        _filterStatus = value;
        _page = 1;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: isSelected ? chipColor : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _rangeLabel(DateTime? start, DateTime? end) {
    final s = start == null ? '…' : _fmtDate(start);
    final e = end == null ? '…' : _fmtDate(end);
    return '$s – $e';
  }
}

// ── Detail panel body ─────────────────────────────────────────────────────

class _PaymentDetailBody extends StatelessWidget {
  final BranchPaymentModel payment;
  const _PaymentDetailBody({required this.payment});

  @override
  Widget build(BuildContext context) {
    final p = payment;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailKV('From Branch', p.branchName ?? '—'),
        DetailKV('Paid On', _fmtDate(p.paidAt)),
        DetailKV(
          'Status',
          p.status[0].toUpperCase() + p.status.substring(1),
          valueColor: _statusColor(p.status),
        ),
        if (p.acceptedAt != null) DetailKV('Accepted', _fmtDate(p.acceptedAt!)),
        if ((p.notes ?? '').isNotEmpty) DetailKV('Notes', p.notes!),
        const DetailDivider(),
        DetailKV('Amount', 'Rs. ${_money(p.amount)}',
            bold: true, valueColor: const Color(0xFF22A06B)),
      ],
    );
  }
}

// ── Small shared bits ─────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIcon(AppIcons.errorOutline, color: Colors.red, size: 40),
          const SizedBox(height: 8),
          Text('Error: $message', style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const AppIcon(AppIcons.refresh, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(String s) {
  switch (s) {
    case 'accepted':
      return Colors.green.shade700;
    case 'rejected':
      return Colors.red.shade700;
    default:
      return Colors.orange.shade700;
  }
}

String _fmtDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/'
    '${dt.month.toString().padLeft(2, '0')}/'
    '${dt.year}';

/// Rupee amount with thousands separators, e.g. 1875000 -> "1,875,000".
/// Paise are kept only when present, e.g. 1500.5 -> "1,500.50".
String _money(double v) {
  final fixed = v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2);
  final parts = fixed.split('.');
  final s = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i != 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return parts.length > 1 ? '$buf.${parts[1]}' : buf.toString();
}
