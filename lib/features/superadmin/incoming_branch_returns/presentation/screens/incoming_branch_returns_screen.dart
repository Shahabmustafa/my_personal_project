import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../branch/return_stock_to_other_branch/presentation/screens/branch_stock_return_screen.dart'
    show StatusChip;
import '../../../../branch/return_stock_to_warehouse/data/model/branch_warehouse_return_model.dart';
import '../../../../branch/return_stock_to_warehouse/presentation/providers/branch_warehouse_return_provider.dart'
    show branchWarehouseReturnRepositoryProvider;
import '../../../report/presentation/widgets/report_date_filter_dialog.dart';
import '../../../report/presentation/widgets/report_detail_panel.dart';
import '../../../report/presentation/widgets/report_pagination_bar.dart';
import '../../../report/presentation/widgets/report_summary_card.dart';
import '../../../report/presentation/widgets/report_table_shell.dart';
import '../providers/incoming_branch_return_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/utils/responsive.dart';

/// Admin's screen for accepting/rejecting stock returns sent by branches —
/// same accept/reject pattern as the head-office->branch assignment history,
/// laid out the same way: summary cards, a scrollable [ReportTableShell]
/// table, a right slide-in detail panel on "View", and a pagination bar.
/// Backed by branch_return_to_warehouse (head_office_id destination).
class IncomingBranchReturnsScreen extends ConsumerStatefulWidget {
  const IncomingBranchReturnsScreen({super.key});

  @override
  ConsumerState<IncomingBranchReturnsScreen> createState() =>
      _IncomingBranchReturnsScreenState();
}

class _IncomingBranchReturnsScreenState
    extends ConsumerState<IncomingBranchReturnsScreen> {
  static const _accent = Color(0xFF1565C0);
  static const _pageSize = 20;

  String _filterStatus = 'all'; // all | pending | accepted | rejected
  DateTime? _startDate;
  DateTime? _endDate;
  int _page = 1;
  BranchWarehouseReturnModel? _selected;

  bool get _hasDateFilter => _startDate != null || _endDate != null;

  List<BranchWarehouseReturnModel> _applyFilters(
    List<BranchWarehouseReturnModel> all,
  ) {
    DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
    final from = _startDate == null ? null : dayOf(_startDate!);
    final to = _endDate == null ? null : dayOf(_endDate!);
    return all.where((r) {
      if (_filterStatus != 'all' && r.status != _filterStatus) return false;
      final d = dayOf(r.returnedAt);
      if (from != null && d.isBefore(from)) return false;
      if (to != null && d.isAfter(to)) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final returnsAsync = ref.watch(incomingBranchReturnsProvider);
    final all = returnsAsync.value ?? const <BranchWarehouseReturnModel>[];
    final isMobile = Responsive(context).isMobile;

    final filtered = _applyFilters(all);
    final totalCount = filtered.length;
    final totalPages = totalCount == 0 ? 1 : ((totalCount - 1) ~/ _pageSize) + 1;
    final page = _page.clamp(1, totalPages);
    final pageRows =
        filtered.skip((page - 1) * _pageSize).take(_pageSize).toList();

    final totalPairs = filtered.fold<int>(0, (s, r) => s + _pairs(r));
    final totalValue = filtered.fold<double>(0, (s, r) => s + _value(r));
    final pendingCount = filtered.where((r) => r.status == 'pending').length;

    final titleRow = Row(
      children: [
        const AppIcon(AppIcons.moveToInboxOutlined, color: _accent, size: 24),
        const SizedBox(width: 8),
        const Expanded(
          child: Text('Incoming Branch Returns',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ),
      ],
    );

    final headerActions = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
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
          onPressed: () => ref.invalidate(incomingBranchReturnsProvider),
        ),
      ],
    );

    final summaryCards = [
      ReportSummaryCard(
        label: 'Total Returns',
        value: '$totalCount',
        icon: AppIcons.assignmentReturnOutlined,
        color: _accent,
      ),
      ReportSummaryCard(
        label: 'Pairs Returned',
        value: '$totalPairs',
        icon: AppIcons.inventory2Outlined,
        color: const Color(0xFF6A1B9A),
      ),
      ReportSummaryCard(
        label: 'Total Purchase Value',
        value: 'Rs. ${_money(totalValue)}',
        icon: AppIcons.accountBalanceWalletOutlined,
        color: const Color(0xFF22A06B),
      ),
      ReportSummaryCard(
        label: 'Pending',
        value: '$pendingCount',
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
                    const AppIcon(AppIcons.moveToInboxOutlined,
                        color: _accent, size: 24),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Incoming Branch Returns',
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
                _filterChip('All', 'all', all.length),
                const SizedBox(width: 8),
                _filterChip('Pending', 'pending',
                    all.where((r) => r.status == 'pending').length),
                const SizedBox(width: 8),
                _filterChip('Accepted', 'accepted',
                    all.where((r) => r.status == 'accepted').length),
                const SizedBox(width: 8),
                _filterChip('Rejected', 'rejected',
                    all.where((r) => r.status == 'rejected').length),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: returnsAsync.isLoading && !returnsAsync.hasValue
                      ? const Center(child: CircularProgressIndicator())
                      : returnsAsync.hasError && !returnsAsync.hasValue
                          ? _ErrorView(
                              message: '${returnsAsync.error}',
                              onRetry: () =>
                                  ref.invalidate(incomingBranchReturnsProvider),
                            )
                          : pageRows.isEmpty
                              ? Center(
                                  child: Text(
                                    _filterStatus == 'all' && !_hasDateFilter
                                        ? 'No returns received yet'
                                        : 'No returns match this filter',
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 15),
                                  ),
                                )
                              : ReportTableShell(
                                  columns: const [
                                    DataColumn(label: Text('Return No')),
                                    DataColumn(label: Text('From Branch')),
                                    DataColumn(
                                        label: Text('Pairs'), numeric: true),
                                    DataColumn(
                                        label: Text('Purchase Value'),
                                        numeric: true),
                                    DataColumn(label: Text('Date')),
                                    DataColumn(label: Text('Status')),
                                    DataColumn(label: Text('Actions')),
                                  ],
                                  rows: [
                                    for (final r in pageRows)
                                      DataRow(
                                        selected: _selected?.id == r.id,
                                        cells: [
                                          DataCell(Text(r.returnNumber,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontFamily: 'monospace',
                                                  color: _accent))),
                                          DataCell(
                                              Text(r.branchName ?? r.branchId)),
                                          DataCell(Text('${_pairs(r)}')),
                                          DataCell(Text(
                                              _value(r).toStringAsFixed(0))),
                                          DataCell(Text(_fmtDate(r.returnedAt))),
                                          DataCell(StatusChip(r.status)),
                                          DataCell(_rowActions(r)),
                                        ],
                                      ),
                                  ],
                                ),
                ),
                if (_selected != null)
                  ReportDetailOverlay(
                    title: _selected!.returnNumber,
                    subtitle:
                        '${_selected!.branchName ?? '—'} · ${_fmtDate(_selected!.returnedAt)}',
                    accent: _accent,
                    onClose: () => setState(() => _selected = null),
                    child: _ReturnDetailBody(returnId: _selected!.id),
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

  Widget _rowActions(BranchWarehouseReturnModel r) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const AppIcon(AppIcons.visibilityOutlined, size: 19),
          tooltip: 'View',
          onPressed: () => setState(() => _selected = r),
        ),
        if (r.status == 'pending') ...[
          IconButton(
            icon: AppIcon(AppIcons.checkCircleOutline,
                size: 19, color: Colors.green.shade600),
            tooltip: 'Accept',
            onPressed: () => _onAccept(r),
          ),
          IconButton(
            icon: AppIcon(AppIcons.cancelOutlined,
                size: 19, color: Colors.red.shade600),
            tooltip: 'Reject',
            onPressed: () => _onReject(r),
          ),
        ],
      ],
    );
  }

  Future<void> _onAccept(BranchWarehouseReturnModel r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            AppIcon(AppIcons.checkCircleOutline, color: Colors.green, size: 22),
            SizedBox(width: 8),
            Text('Accept Return?'),
          ],
        ),
        content: const Text(
          'Stock will be added to Head Office inventory.\n\nThis action cannot be undone.',
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
        .read(branchWarehouseReturnRepositoryProvider)
        .acceptReturn(r.id), r.id);
  }

  Future<void> _onReject(BranchWarehouseReturnModel r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            AppIcon(AppIcons.cancelOutlined, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('Reject Return?'),
          ],
        ),
        content: const Text(
          'This return will be marked as rejected. Stock goes back to the branch.',
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
        .read(branchWarehouseReturnRepositoryProvider)
        .rejectReturn(r.id), r.id);
  }

  Future<void> _run(Future<void> Function() action, String returnId) async {
    try {
      await action();
      if (!mounted) return;
      ref.invalidate(incomingBranchReturnsProvider);
      ref.invalidate(incomingBranchReturnDetailProvider(returnId));
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

class _ReturnDetailBody extends ConsumerWidget {
  final String returnId;
  const _ReturnDetailBody({required this.returnId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(incomingBranchReturnDetailProvider(returnId));
    return detail.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) =>
          Text('Error: $e', style: const TextStyle(color: Colors.red)),
      data: (r) {
        final items = r.items;
        final saleVal = items.fold<double>(
            0, (s, it) => s + it.salePrice * it.quantity);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DetailKV('From Branch', r.branchName ?? '—'),
            DetailKV('Returned', _fmtDate(r.returnedAt)),
            DetailKV(
              'Status',
              r.status[0].toUpperCase() + r.status.substring(1),
              valueColor: _statusColor(r.status),
            ),
            if (r.acceptedAt != null)
              DetailKV('Accepted', _fmtDate(r.acceptedAt!)),
            if ((r.notes ?? '').isNotEmpty) DetailKV('Notes', r.notes!),
            const DetailDivider(),
            DetailSectionLabel('ITEMS (${items.length})'),
            for (final it in items)
              DetailProductRow(
                name: it.productName ?? 'Item',
                sizeName: it.sizeName,
                colorName: it.colorName,
                quantity: it.quantity,
                total: it.purchasePrice * it.quantity,
              ),
            const DetailDivider(),
            DetailKV('Total Pairs', '${_pairs(r)}'),
            DetailKV('Purchase Value', 'Rs. ${_value(r).toStringAsFixed(0)}',
                bold: true, valueColor: const Color(0xFF22A06B)),
            DetailKV('Sale Value', 'Rs. ${saleVal.toStringAsFixed(0)}'),
          ],
        );
      },
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

int _pairs(BranchWarehouseReturnModel r) =>
    r.items.fold<int>(0, (s, i) => s + i.quantity);

double _value(BranchWarehouseReturnModel r) =>
    r.items.fold<double>(0, (s, i) => s + i.purchasePrice * i.quantity);

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

/// Whole-rupee amount with thousands separators, e.g. 1875000 -> "1,875,000".
String _money(double v) {
  final s = v.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i != 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
