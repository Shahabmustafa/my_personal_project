import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../report/presentation/widgets/report_date_filter_dialog.dart';
import '../../../report/presentation/widgets/report_detail_panel.dart';
import '../../../report/presentation/widgets/report_pagination_bar.dart';
import '../../../report/presentation/widgets/report_summary_card.dart';
import '../../../report/presentation/widgets/report_table_shell.dart';
import '../../data/models/ho_assign_stock_model.dart';
import '../providers/ho_assign_stock_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/utils/responsive.dart';
/// Head office → branch stock assignment history. Lays the data out the same
/// way as the sale reports: summary cards, a scrollable [ReportTableShell]
/// table, a right slide-in detail panel on "View", and a pagination bar.
class HoAssignStockListScreen extends ConsumerStatefulWidget {
  const HoAssignStockListScreen({super.key});

  @override
  ConsumerState<HoAssignStockListScreen> createState() =>
      _HoAssignStockListScreenState();
}

class _HoAssignStockListScreenState
    extends ConsumerState<HoAssignStockListScreen> {
  static const _accent = Color(0xFF1565C0);
  static const _pageSize = 20;

  String _filterStatus = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  int _page = 1;
  HoAssignStockModel? _selected;

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(hoAssignListProvider.notifier).loadAssignments());
  }

  bool get _hasDateFilter => _startDate != null || _endDate != null;

  List<HoAssignStockModel> _applyFilters(List<HoAssignStockModel> all) {
    DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
    final from = _startDate == null ? null : dayOf(_startDate!);
    final to = _endDate == null ? null : dayOf(_endDate!);
    return all.where((a) {
      if (_filterStatus != 'all' && a.status != _filterStatus) return false;
      final d = dayOf(a.assignedAt);
      if (from != null && d.isBefore(from)) return false;
      if (to != null && d.isAfter(to)) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(hoAssignListProvider);
    final notifier = ref.read(hoAssignListProvider.notifier);

    final filtered = _applyFilters(listState.assignments);
    final totalCount = filtered.length;
    final totalPages = totalCount == 0 ? 1 : ((totalCount - 1) ~/ _pageSize) + 1;
    final page = _page.clamp(1, totalPages);
    final pageRows =
        filtered.skip((page - 1) * _pageSize).take(_pageSize).toList();

    final totalPairs = filtered.fold<int>(0, (s, a) => s + a.totalPairs);
    final totalValue = filtered.fold<double>(0, (s, a) => s + a.totalValue);
    final pendingCount =
        filtered.where((a) => a.status == 'pending').length;
    final isMobile = Responsive(context).isMobile;

    final titleRow = Row(
      children: [
        const AppIcon(AppIcons.history, color: _accent, size: 24),
        const SizedBox(width: 8),
        const Expanded(
          child: Text('Assignment History',
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
          onPressed: notifier.loadAssignments,
        ),
      ],
    );

    final summaryCards = [
      ReportSummaryCard(
        label: 'Total Assignments',
        value: '$totalCount',
        icon: AppIcons.assignmentOutlined,
        color: _accent,
      ),
      ReportSummaryCard(
        label: 'Pairs Assigned',
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
                  children: [
                    titleRow,
                    const SizedBox(height: 8),
                    headerActions,
                  ],
                )
              : Row(
                  children: [
                    const AppIcon(AppIcons.history, color: _accent, size: 24),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Assignment History',
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
                _filterChip('All', 'all', listState.assignments.length),
                const SizedBox(width: 8),
                _filterChip(
                    'Pending',
                    'pending',
                    listState.assignments
                        .where((a) => a.status == 'pending')
                        .length),
                const SizedBox(width: 8),
                _filterChip(
                    'Accepted',
                    'accepted',
                    listState.assignments
                        .where((a) => a.status == 'accepted')
                        .length),
                const SizedBox(width: 8),
                _filterChip(
                    'Rejected',
                    'rejected',
                    listState.assignments
                        .where((a) => a.status == 'rejected')
                        .length),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: listState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : listState.error != null
                          ? _ErrorView(
                              message: listState.error!,
                              onRetry: notifier.loadAssignments,
                            )
                          : pageRows.isEmpty
                              ? Center(
                                  child: Text(
                                    _filterStatus == 'all' && !_hasDateFilter
                                        ? 'No assignments yet'
                                        : 'No assignments match this filter',
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 15),
                                  ),
                                )
                              : ReportTableShell(
                                  columns: const [
                                    DataColumn(label: Text('Assignment No')),
                                    DataColumn(label: Text('Branch')),
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
                                    for (final a in pageRows)
                                      DataRow(
                                        selected: _selected?.id == a.id,
                                        cells: [
                                          DataCell(Text(a.assignmentNumber,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontFamily: 'monospace',
                                                  color: _accent))),
                                          DataCell(Text(
                                              a.branchName ?? a.branchId)),
                                          DataCell(Text('${a.totalPairs}')),
                                          DataCell(Text(
                                              a.totalValue.toStringAsFixed(0))),
                                          DataCell(
                                              Text(_fmtDate(a.assignedAt))),
                                          DataCell(_StatusChip(a.status)),
                                          DataCell(_rowActions(a)),
                                        ],
                                      ),
                                  ],
                                ),
                ),
                if (_selected != null)
                  ReportDetailOverlay(
                    title: _selected!.assignmentNumber,
                    subtitle:
                        '${_selected!.branchName ?? '—'} · ${_fmtDate(_selected!.assignedAt)}',
                    accent: _accent,
                    onClose: () => setState(() => _selected = null),
                    child: _AssignmentDetailBody(assignmentId: _selected!.id),
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

  Widget _rowActions(HoAssignStockModel a) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const AppIcon(AppIcons.visibilityOutlined, size: 19),
          tooltip: 'View',
          onPressed: () => setState(() => _selected = a),
        ),
        if (a.status == 'pending') ...[
          IconButton(
            icon: AppIcon(AppIcons.checkCircleOutline,
                size: 19, color: Colors.green.shade600),
            tooltip: 'Accept',
            onPressed: () => _onAccept(a),
          ),
          IconButton(
            icon: AppIcon(AppIcons.cancelOutlined,
                size: 19, color: Colors.red.shade600),
            tooltip: 'Reject',
            onPressed: () => _onReject(a),
          ),
        ],
      ],
    );
  }

  Future<void> _onAccept(HoAssignStockModel a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            AppIcon(AppIcons.checkCircleOutline, color: Colors.green, size: 22),
            SizedBox(width: 8),
            Text('Accept Assignment?'),
          ],
        ),
        content: const Text(
          'Stock branch inventory mein add ho jayega.\n\nYe action undo nahi ho sakta.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(hoAssignListProvider.notifier).acceptAssignment(a.id);
    if (!mounted) return;
    ref.invalidate(hoAssignStockListProvider);
    ref.invalidate(hoAssignmentDetailProvider(a.id));
    setState(() => _selected = null);
  }

  Future<void> _onReject(HoAssignStockModel a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            AppIcon(AppIcons.cancelOutlined, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('Reject Assignment?'),
          ],
        ),
        content: const Text(
          'Assignment rejected ho jayegi aur stock wapas head office mein aa jayega.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(hoAssignListProvider.notifier).rejectAssignment(a.id);
    if (!mounted) return;
    ref.invalidate(hoAssignStockListProvider);
    ref.invalidate(hoAssignmentDetailProvider(a.id));
    setState(() => _selected = null);
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
          border: Border.all(
              color: isSelected ? chipColor : Colors.grey.shade300),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

class _AssignmentDetailBody extends ConsumerWidget {
  final String assignmentId;
  const _AssignmentDetailBody({required this.assignmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(hoAssignmentDetailProvider(assignmentId));
    return detail.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) =>
          Text('Error: $e', style: const TextStyle(color: Colors.red)),
      data: (a) {
        final items = a.items;
        final pairs = items.fold<int>(0, (s, it) => s + it.quantity);
        final purchaseVal = items.fold<double>(
            0, (s, it) => s + it.purchasePrice * it.quantity);
        final saleVal = items.fold<double>(
            0, (s, it) => s + it.salePrice * it.quantity);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DetailKV('Branch', a.branchName ?? '—'),
            DetailKV('Assigned', _fmtDate(a.assignedAt)),
            DetailKV(
              'Status',
              a.status[0].toUpperCase() + a.status.substring(1),
              valueColor: _statusColor(a.status),
            ),
            if (a.acceptedAt != null)
              DetailKV('Accepted', _fmtDate(a.acceptedAt!)),
            if ((a.notes ?? '').isNotEmpty) DetailKV('Notes', a.notes!),
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
            DetailKV('Total Pairs', '$pairs'),
            DetailKV('Purchase Value', 'Rs. ${purchaseVal.toStringAsFixed(0)}',
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
          Text('Error: $message',
              style: const TextStyle(color: Colors.red)),
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

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    String icon;

    switch (status) {
      case 'accepted':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        label = 'Accepted';
        icon = AppIcons.checkCircleOutline;
        break;
      case 'rejected':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        label = 'Rejected';
        icon = AppIcons.cancelOutlined;
        break;
      default:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
        label = 'Pending';
        icon = AppIcons.hourglassEmptyOutlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
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
