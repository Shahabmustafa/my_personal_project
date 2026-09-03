import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../warehouse/assign_stock_to_branch/data/models/assign_stock_model.dart';
import '../../../../superadmin/report/presentation/widgets/report_detail_panel.dart';
import '../../../../superadmin/report/presentation/widgets/report_summary_card.dart';
import '../provider/branch_assign_provider.dart';

class BranchAssignListScreen extends ConsumerStatefulWidget {
  const BranchAssignListScreen({super.key});

  @override
  ConsumerState<BranchAssignListScreen> createState() =>
      _BranchAssignListScreenState();
}

class _BranchAssignListScreenState
    extends ConsumerState<BranchAssignListScreen> {
  String _filterStatus = 'all';
  static const _primary = Color(0xFF3E63DD);

  AssignStockModel? _selected; // list row (brief)
  AssignStockModel? _detail; // loaded detail (items with names)
  bool _loadingDetail = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(branchAssignProvider.notifier).loadAssignments());
  }

  Future<void> _openDetail(AssignStockModel a) async {
    setState(() {
      _selected = a;
      _detail = null;
      _loadingDetail = true;
    });
    final d = await ref.read(branchAssignProvider.notifier).loadDetail(a.id);
    if (!mounted) return;
    setState(() {
      _detail = d;
      _loadingDetail = false;
    });
    if (d == null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not load items. Please try again.'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(branchAssignProvider);

    final filtered = listState.assignments.where((a) {
      if (_filterStatus == 'all') return true;
      return a.status == _filterStatus;
    }).toList();

    final pendingCount =
        listState.assignments.where((a) => a.status == 'pending').length;
    final filteredItems = filtered.expand((a) => a.items);
    final totalQuantity = filteredItems.fold<int>(0, (s, i) => s + i.quantity);
    final totalSalePrice =
        filteredItems.fold<double>(0, (s, i) => s + (i.salePrice * i.quantity));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────
          Row(children: [
            const Expanded(
              child: Text('Assign Stock to My Branch',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            if (pendingCount > 0)
              Container(
                margin: const EdgeInsets.only(right: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.orange.shade600,
                    borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.hourglass_empty, size: 13, color: Colors.white),
                  const SizedBox(width: 5),
                  Text('$pendingCount Pending',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  ref.read(branchAssignProvider.notifier).loadAssignments(),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Summary cards ────────────────────────────────────────────
          Row(children: [
            Expanded(
              child: ReportSummaryCard(
                label: 'Total Assignments',
                value: '${filtered.length}',
                icon: Icons.move_to_inbox_outlined,
                color: _primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ReportSummaryCard(
                label: 'Total Quantity',
                value: '$totalQuantity',
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFFE56A00),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ReportSummaryCard(
                label: 'Total Sale Price',
                value: 'Rs. ${_fmtAmt(totalSalePrice)}',
                icon: Icons.sell_outlined,
                color: const Color(0xFF22A06B),
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Status filter chips ─────────────────────────────────────
          Row(children: [
            _chip('All', 'all', listState.assignments.length),
            const SizedBox(width: 8),
            _chip('Pending', 'pending',
                listState.assignments.where((a) => a.status == 'pending').length),
            const SizedBox(width: 8),
            _chip('Accepted', 'accepted',
                listState.assignments.where((a) => a.status == 'accepted').length),
            const SizedBox(width: 8),
            _chip('Rejected', 'rejected',
                listState.assignments.where((a) => a.status == 'rejected').length),
          ]),
          const SizedBox(height: 16),

          // ── Table + detail panel ────────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: listState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : listState.error != null
                          ? _ErrorView(
                              error: listState.error!,
                              onRetry: () => ref
                                  .read(branchAssignProvider.notifier)
                                  .loadAssignments())
                          : filtered.isEmpty
                              ? _EmptyView(status: _filterStatus)
                              : _AssignTable(
                                  rows: filtered,
                                  selectedId: _selected?.id,
                                  onView: _openDetail,
                                ),
                ),
                if (_selected != null)
                  ReportDetailPanel(
                    title: _selected!.assignmentNumber,
                    subtitle:
                        '${_selected!.sourceLabel} · ${_fmtDate(_selected!.assignedAt)}',
                    accent: _primary,
                    onClose: () => setState(() {
                      _selected = null;
                      _detail = null;
                    }),
                    child: _AssignDetailBody(
                      brief: _selected!,
                      detail: _detail,
                      loading: _loadingDetail,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, int count) {
    final isSelected = _filterStatus == value;
    Color chipColor;
    IconData chipIcon;
    switch (value) {
      case 'pending':
        chipColor = Colors.orange;
        chipIcon = Icons.hourglass_empty_outlined;
        break;
      case 'accepted':
        chipColor = Colors.green;
        chipIcon = Icons.check_circle_outline;
        break;
      case 'rejected':
        chipColor = Colors.red;
        chipIcon = Icons.cancel_outlined;
        break;
      default:
        chipColor = _primary;
        chipIcon = Icons.list_outlined;
    }
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isSelected ? chipColor : const Color(0xFFE7E9F0),
              width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(chipIcon,
              size: 14,
              color: isSelected ? Colors.white : const Color(0xFF8A8FA3)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF5A5F73))),
          const SizedBox(width: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white24
                  : const Color(0xFFF0F1F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color:
                        isSelected ? Colors.white : const Color(0xFF5A5F73))),
          ),
        ]),
      ),
    );
  }
}

String _fmtAmt(double v) =>
    v == v.truncate() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

String _fmtDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

// ── Table (flex-based — poori width par phailti hai) ─────────────────────

const _colFlex = <int>[1, 3, 4, 3, 2, 2, 3, 5];
const _colLabels = <String>[
  '#',
  'Assignment #',
  'Assigned By',
  'Date',
  'Items',
  'Qty',
  'Status',
  'Actions',
];

class _AssignTable extends ConsumerWidget {
  final List<AssignStockModel> rows;
  final String? selectedId;
  final void Function(AssignStockModel) onView;

  const _AssignTable({
    required this.rows,
    required this.selectedId,
    required this.onView,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E9F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Header
            Container(
              color: const Color(0xFFF7F8FC),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  for (var c = 0; c < _colLabels.length; c++)
                    Expanded(
                      flex: _colFlex[c],
                      child: Text(_colLabels[c],
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5A5F73),
                              letterSpacing: 0.3)),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEF0F6)),
            // Body
            Expanded(
              child: ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFEEF0F6)),
                itemBuilder: (context, i) =>
                    _row(context, ref, rows[i], i),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
      BuildContext context, WidgetRef ref, AssignStockModel a, int index) {
    final qty = a.items.fold<int>(0, (s, it) => s + it.quantity);
    final selected = selectedId == a.id;
    return InkWell(
      onTap: () => onView(a),
      child: Container(
        color: selected
            ? const Color(0xFFEAEFFD)
            : (index.isEven ? const Color(0xFFFAFBFF) : Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: _colFlex[0],
              child: Text('${index + 1}',
                  style: const TextStyle(color: Color(0xFF8A8FA3))),
            ),
            Expanded(
              flex: _colFlex[1],
              child: Text(a.assignmentNumber,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3E63DD),
                      fontFamily: 'monospace')),
            ),
            Expanded(flex: _colFlex[2], child: _SourceLabel(a: a)),
            Expanded(
              flex: _colFlex[3],
              child: Text(_fmtDate(a.assignedAt),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF5A5F73))),
            ),
            Expanded(flex: _colFlex[4], child: Text('${a.items.length}')),
            Expanded(flex: _colFlex[5], child: Text('$qty')),
            Expanded(
                flex: _colFlex[6],
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: _StatusChip(a.status))),
            Expanded(
              flex: _colFlex[7],
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(children: [
                _ActionIcon(
                  icon: Icons.visibility_outlined,
                  tooltip: 'View',
                  color: const Color(0xFF3E63DD),
                  onTap: () => onView(a),
                ),
                if (a.status == 'pending') ...[
                  const SizedBox(width: 4),
                  _ActionIcon(
                    icon: Icons.check_circle_outline,
                    tooltip: 'Accept',
                    color: Colors.green.shade600,
                    onTap: () => _confirmAccept(context, ref, a),
                  ),
                  const SizedBox(width: 4),
                  _ActionIcon(
                    icon: Icons.cancel_outlined,
                    tooltip: 'Reject',
                    color: Colors.red.shade600,
                    onTap: () => _confirmReject(context, ref, a),
                  ),
                ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;
  const _ActionIcon(
      {required this.icon,
      required this.tooltip,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(icon, size: 19, color: color),
          ),
        ),
      );
}

class _SourceLabel extends StatelessWidget {
  final AssignStockModel a;
  const _SourceLabel({required this.a});

  @override
  Widget build(BuildContext context) {
    late final String tag;
    late final Color color;
    switch (a.sourceType) {
      case 'head_office':
        tag = 'Head Office';
        color = const Color(0xFF6C4DE0);
        break;
      case 'warehouse':
        tag = 'Warehouse';
        color = const Color(0xFF3E63DD);
        break;
      case 'branch':
        tag = 'Branch';
        color = const Color(0xFF22A06B);
        break;
      default:
        tag = '';
        color = const Color(0xFF8A8FA3);
    }
    return Row(children: [
      Flexible(
        child: Text(a.sourceLabel,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      if (tag.isNotEmpty) ...[
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(tag,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ),
      ],
    ]);
  }
}

// ── Detail panel body ─────────────────────────────────────────────────────

class _AssignDetailBody extends ConsumerWidget {
  final AssignStockModel brief;
  final AssignStockModel? detail;
  final bool loading;

  const _AssignDetailBody({
    required this.brief,
    required this.detail,
    required this.loading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = detail?.items ?? const [];
    final totalQty = items.fold<int>(0, (s, i) => s + i.quantity);
    final totalValue =
        items.fold<double>(0, (s, i) => s + (i.salePrice * i.quantity));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailKV('Assigned By', brief.sourceLabel),
        if (brief.assignedByName != null && brief.assignedByName!.isNotEmpty)
          DetailKV('Assigned By User', brief.assignedByName!),
        DetailKV('Assigned On', _fmtDate(brief.assignedAt)),
        DetailKV(
          'Status',
          brief.status[0].toUpperCase() + brief.status.substring(1),
          valueColor: _statusColor(brief.status),
        ),
        if (brief.status == 'accepted' && brief.acceptedAt != null)
          DetailKV('Accepted On', _fmtDate(brief.acceptedAt!)),
        if ((brief.notes ?? '').isNotEmpty) DetailKV('Notes', brief.notes!),
        const DetailDivider(),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (detail == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Could not load items.',
                style: TextStyle(color: Color(0xFF8A8FA3))),
          )
        else ...[
          DetailSectionLabel('ITEMS (${items.length})'),
          for (final item in items)
            DetailProductRow(
              name: item.productName ?? 'Item',
              sizeName: item.sizeName,
              colorName: item.colorName,
              quantity: item.quantity,
              total: item.salePrice * item.quantity,
            ),
          const DetailDivider(),
          DetailKV('Total Pairs', '$totalQty'),
          DetailKV('Total Value', 'Rs. ${totalValue.toStringAsFixed(0)}',
              bold: true, valueColor: Colors.green.shade700),
        ],
        if (brief.status == 'pending') ...[
          const DetailDivider(),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Accept'),
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade600),
                onPressed: () => _confirmAccept(context, ref, brief),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    side: BorderSide(color: Colors.red.shade300)),
                onPressed: () => _confirmReject(context, ref, brief),
              ),
            ),
          ]),
        ],
      ],
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'accepted':
      return const Color(0xFF2E7D32);
    case 'rejected':
      return const Color(0xFFC62828);
    default:
      return const Color(0xFFE65100);
  }
}

// ── Accept / Reject confirm flows ─────────────────────────────────────────

Future<void> _confirmAccept(
    BuildContext context, WidgetRef ref, AssignStockModel a) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [
        Icon(Icons.check_circle_outline, color: Colors.green, size: 22),
        SizedBox(width: 8),
        Text('Accept Assignment?',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(a.assignmentNumber,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: Color(0xFF3E63DD))),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade200)),
          child: const Text(
              'This stock will be added to your branch inventory.',
              style: TextStyle(fontSize: 13, height: 1.4)),
        ),
      ]),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.green.shade600),
          child: const Text('Accept'),
        ),
      ],
    ),
  );
  if (confirm != true || !context.mounted) return;
  final error =
      await ref.read(branchAssignProvider.notifier).acceptAssignment(a.id);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(error == null
        ? 'Stock accepted and added to branch inventory!'
        : 'Error: $error'),
    backgroundColor:
        error == null ? Colors.green.shade700 : Colors.red.shade700,
    behavior: SnackBarBehavior.floating,
  ));
}

Future<void> _confirmReject(
    BuildContext context, WidgetRef ref, AssignStockModel a) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [
        Icon(Icons.cancel_outlined, color: Colors.red, size: 22),
        SizedBox(width: 8),
        Text('Reject Assignment?',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(a.assignmentNumber,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: Color(0xFF3E63DD))),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200)),
          child: const Text(
              'Stock will be returned to the sender\'s inventory.',
              style: TextStyle(fontSize: 13, height: 1.4)),
        ),
      ]),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
          child: const Text('Reject'),
        ),
      ],
    ),
  );
  if (confirm != true || !context.mounted) return;
  final error =
      await ref.read(branchAssignProvider.notifier).rejectAssignment(a.id);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(error == null
        ? 'Assignment rejected. Stock returned to sender.'
        : 'Error: $error'),
    backgroundColor:
        error == null ? Colors.orange.shade700 : Colors.red.shade700,
    behavior: SnackBarBehavior.floating,
  ));
}

// ── Status chip ───────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    Color bg, fg, border;
    String label;
    IconData icon;
    switch (status) {
      case 'accepted':
        bg = const Color(0xFFEAF5E6);
        fg = const Color(0xFF2E7D32);
        border = const Color(0xFFA5D6A7);
        label = 'Accepted';
        icon = Icons.check_circle_outline;
        break;
      case 'rejected':
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        border = const Color(0xFFEF9A9A);
        label = 'Rejected';
        icon = Icons.cancel_outlined;
        break;
      default:
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFFE65100);
        border = const Color(0xFFFFCC80);
        label = 'Pending';
        icon = Icons.hourglass_empty_outlined;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: fg),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
      ]),
    );
  }
}

// ── Error / Empty views ──────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.red.shade50, shape: BoxShape.circle),
              child: Icon(Icons.error_outline,
                  color: Colors.red.shade400, size: 36)),
          const SizedBox(height: 12),
          Text('Error: $error',
              style: const TextStyle(color: Color(0xFF8A8FA3), fontSize: 13)),
          const SizedBox(height: 16),
          FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry')),
        ]),
      );
}

class _EmptyView extends StatelessWidget {
  final String status;
  const _EmptyView({required this.status});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                  color: Color(0xFFF0F4FF), shape: BoxShape.circle),
              child: Icon(Icons.move_to_inbox_outlined,
                  size: 48, color: Colors.grey.shade300)),
          const SizedBox(height: 16),
          Text(
              status == 'all'
                  ? 'No assignments found'
                  : 'No $status assignments found',
              style: const TextStyle(
                  color: Color(0xFF8A8FA3),
                  fontSize: 15,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          const Text('When stock is assigned to your branch, it shows up here.',
              style: TextStyle(color: Color(0xFFB0B5C8), fontSize: 12)),
        ]),
      );
}
