import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../warehouse/assign_stock_to_branch/data/models/assign_stock_model.dart';
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
  static const _primary = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    Future.microtask(
            () => ref.read(branchAssignProvider.notifier).loadAssignments());
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
    final totalSalePrice = filteredItems.fold<double>(
        0, (s, i) => s + (i.salePrice * i.quantity));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.move_to_inbox_outlined, color: _primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Assign Stock to My Branch',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                    Text('${listState.assignments.length} total assignments',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3))),
                  ],
                ),
              ),
              if (pendingCount > 0)
                Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.orange.shade600, borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.hourglass_empty, size: 13, color: Colors.white),
                    const SizedBox(width: 5),
                    Text('$pendingCount Pending',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                ),
              Tooltip(
                message: 'Refresh',
                child: InkWell(
                  onTap: () => ref.read(branchAssignProvider.notifier).loadAssignments(),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE7E9F0)),
                    ),
                    child: const Icon(Icons.refresh, color: _primary, size: 20),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // Summary cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 700;
                final cards = [
                  _SummaryCard(
                    label: 'Total Assigned Invoices',
                    value: '${filtered.length}',
                    icon: Icons.receipt_long_outlined,
                    color: _primary,
                  ),
                  _SummaryCard(
                    label: 'Total Quantity',
                    value: '$totalQuantity',
                    icon: Icons.inventory_2_outlined,
                    color: const Color(0xFF22A06B),
                  ),
                  _SummaryCard(
                    label: 'Total Sale Price',
                    value: 'Rs. ${_fmtAmt(totalSalePrice)}',
                    icon: Icons.sell_outlined,
                    color: const Color(0xFF6C4DE0),
                  ),
                ];
                return isMobile
                    ? Column(
                        children: cards
                            .map((c) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: c,
                                ))
                            .toList(),
                      )
                    : Row(
                        children: [
                          for (int i = 0; i < cards.length; i++) ...[
                            Expanded(child: cards[i]),
                            if (i != cards.length - 1) const SizedBox(width: 14),
                          ],
                        ],
                      );
              },
            ),
            const SizedBox(height: 20),

            // Filter chips
            Row(children: [
              _chip('All',      'all',      listState.assignments.length),
              const SizedBox(width: 8),
              _chip('Pending',  'pending',  listState.assignments.where((a) => a.status == 'pending').length),
              const SizedBox(width: 8),
              _chip('Accepted', 'accepted', listState.assignments.where((a) => a.status == 'accepted').length),
              const SizedBox(width: 8),
              _chip('Rejected', 'rejected', listState.assignments.where((a) => a.status == 'rejected').length),
            ]),
            const SizedBox(height: 16),

            // Table
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE7E9F0)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Column(children: [
                    // Header row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: const BoxDecoration(color: _primary),
                      child: Row(children: [
                        _th('#',             flex: 1),
                        _th('Assignment No', flex: 3),
                        _th('Date',          flex: 3),
                        _th('Items',         flex: 2),
                        _th('Status',        flex: 3),
                        _th('Actions',       flex: 5),
                      ]),
                    ),
                    // Body
                    Expanded(
                      child: listState.isLoading
                          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                          : listState.error != null
                          ? _ErrorView(
                        error: listState.error!,
                        onRetry: () => ref.read(branchAssignProvider.notifier).loadAssignments(),
                      )
                          : filtered.isEmpty
                          ? _EmptyView(status: _filterStatus)
                          : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFEEF0F6)),
                        itemBuilder: (_, i) =>
                            _AssignRow(assignment: filtered[i], index: i),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value, int count) {
    final isSelected = _filterStatus == value;
    Color chipColor;
    IconData chipIcon;
    switch (value) {
      case 'pending':  chipColor = Colors.orange; chipIcon = Icons.hourglass_empty_outlined; break;
      case 'accepted': chipColor = Colors.green;  chipIcon = Icons.check_circle_outline;     break;
      case 'rejected': chipColor = Colors.red;    chipIcon = Icons.cancel_outlined;          break;
      default:         chipColor = _primary;      chipIcon = Icons.list_outlined;
    }
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? chipColor : const Color(0xFFE7E9F0), width: 1.5),
          boxShadow: isSelected ? [BoxShadow(color: chipColor.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))] : [],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(chipIcon, size: 14, color: isSelected ? Colors.white : const Color(0xFF8A8FA3)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF5A5F73))),
          const SizedBox(width: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withOpacity(0.25) : const Color(0xFFF0F1F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF5A5F73))),
          ),
        ]),
      ),
    );
  }

  Widget _th(String text, {int flex = 2}) => Expanded(
    flex: flex,
    child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.3)),
  );
}

// ── Summary card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E9F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8A8FA3),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _fmtAmt(double v) {
  if (v == v.truncate()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(2);
}

// ── Assignment row ────────────────────────────────────────────────────────────

class _AssignRow extends ConsumerStatefulWidget {
  final AssignStockModel assignment;
  final int index;
  const _AssignRow({required this.assignment, required this.index});

  @override
  ConsumerState<_AssignRow> createState() => _AssignRowState();
}

class _AssignRowState extends ConsumerState<_AssignRow> {
  bool _loadingDetail = false;
  AssignStockModel? _detail;
  AssignStockModel get assignment => widget.assignment;

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(branchAssignProvider.notifier);
    return Column(children: [
      Container(
        color: widget.index.isEven ? const Color(0xFFFAFBFF) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          // #
          Expanded(flex: 1,
              child: Text('${widget.index + 1}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3), fontWeight: FontWeight.w500))),

          // Assignment No — FIX: Align wrap
          Expanded(flex: 3,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFEAEFFD), borderRadius: BorderRadius.circular(6)),
                  child: Text(assignment.assignmentNumber,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                          color: Color(0xFF1565C0), fontFamily: 'monospace')),
                ),
              )),

          // Date
          Expanded(flex: 3,
              child: Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF8A8FA3)),
                const SizedBox(width: 5),
                Text(_fmtDate(assignment.assignedAt),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF5A5F73))),
              ])),

          // Items toggle — FIX: Align wrap
          Expanded(flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => _toggleDetail(notifier),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _detail != null ? const Color(0xFF1565C0) : const Color(0xFFEAEFFD),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _detail != null ? const Color(0xFF1565C0) : const Color(0xFFBBCBF0)),
                    ),
                    child: _loadingDetail
                        ? const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF1565C0)))
                        : Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                        _detail != null ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        size: 15,
                        color: _detail != null ? Colors.white : const Color(0xFF1565C0),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _detail != null ? '${_detail!.items.length} Items' : 'View',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                            color: _detail != null ? Colors.white : const Color(0xFF1565C0)),
                      ),
                    ]),
                  ),
                ),
              )),

          // Status chip — FIX: Align wrap
          Expanded(flex: 3,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _StatusChip(assignment.status),
              )),

          // Actions
          Expanded(flex: 5,
              child: assignment.status == 'pending'
                  ? _ActionButtons(assignment: assignment, notifier: notifier)
                  : _StatusText(assignment: assignment)),
        ]),
      ),

      if (_detail != null && _detail!.items.isNotEmpty)
        _ItemsDetail(items: _detail!.items, isPending: assignment.status == 'pending'),
    ]);
  }

  Future<void> _toggleDetail(BranchAssignNotifier notifier) async {
    if (_detail != null) { setState(() => _detail = null); return; }
    setState(() => _loadingDetail = true);
    final detail = await notifier.loadDetail(assignment.id);
    if (mounted) {
      setState(() { _detail = detail; _loadingDetail = false; });
      if (detail == null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not load items. Please try again.'),
          backgroundColor: Colors.red, behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

// ── Accept / Reject buttons ───────────────────────────────────────────────────

class _ActionButtons extends ConsumerWidget {
  final AssignStockModel assignment;
  final BranchAssignNotifier notifier;
  const _ActionButtons({required this.assignment, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(children: [
      SizedBox(height: 34,
          child: FilledButton.icon(
            icon: const Icon(Icons.check_rounded, size: 14),
            label: const Text('Accept', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => _onAccept(context),
          )),
      const SizedBox(width: 8),
      SizedBox(height: 34,
          child: OutlinedButton.icon(
            icon: Icon(Icons.close_rounded, size: 14, color: Colors.red.shade600),
            label: Text('Reject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red.shade600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade600,
              side: BorderSide(color: Colors.red.shade300, width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => _onReject(context),
          )),
    ]);
  }

  Future<void> _onAccept(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.check_circle_outline, color: Colors.green, size: 22),
          SizedBox(width: 8),
          Text('Accept Assignment?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.tag, size: 14, color: Color(0xFF8A8FA3)),
            const SizedBox(width: 6),
            Text(assignment.assignmentNumber,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1565C0))),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200)),
            child: const Row(children: [
              Icon(Icons.inventory_2_outlined, size: 16, color: Colors.green),
              SizedBox(width: 8),
              Expanded(child: Text('This stock will be added to your branch inventory.',
                  style: TextStyle(fontSize: 13, height: 1.4))),
            ]),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Accept'),
            style: FilledButton.styleFrom(backgroundColor: Colors.green.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!context.mounted) return;
    final error = await notifier.acceptAssignment(assignment.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(error == null ? Icons.check_circle_outline : Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(error == null ? 'Stock accepted and added to branch inventory!' : 'Error: $error')),
      ]),
      backgroundColor: error == null ? Colors.green.shade700 : Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _onReject(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.cancel_outlined, color: Colors.red, size: 22),
          SizedBox(width: 8),
          Text('Reject Assignment?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.tag, size: 14, color: Color(0xFF8A8FA3)),
            const SizedBox(width: 6),
            Text(assignment.assignmentNumber,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1565C0))),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200)),
            child: const Row(children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(child: Text('Stock will be returned to the warehouse inventory.',
                  style: TextStyle(fontSize: 13, height: 1.4))),
            ]),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.close_rounded, size: 16),
            label: const Text('Reject'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!context.mounted) return;
    final error = await notifier.rejectAssignment(assignment.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(error == null ? Icons.check_circle_outline : Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(error == null ? 'Assignment rejected. Stock returned to warehouse.' : 'Error: $error')),
      ]),
      backgroundColor: error == null ? Colors.orange.shade700 : Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 3),
    ));
  }
}

// ── Status text ───────────────────────────────────────────────────────────────

class _StatusText extends StatelessWidget {
  final AssignStockModel assignment;
  const _StatusText({required this.assignment});

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    final isAccepted = assignment.status == 'accepted';
    final color  = isAccepted ? Colors.green.shade700 : Colors.red.shade700;
    final icon   = isAccepted ? Icons.check_circle_outline : Icons.cancel_outlined;
    final text   = isAccepted
        ? 'Accepted on ${_fmtDate(assignment.acceptedAt ?? assignment.assignedAt)}'
        : 'Rejected';
    return Row(children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 5),
      Flexible(child: Text(text,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          overflow: TextOverflow.ellipsis)),
    ]);
  }
}

// ── Items detail ──────────────────────────────────────────────────────────────

class _ItemsDetail extends StatelessWidget {
  final List<AssignStockItemModel> items;
  final bool isPending;
  const _ItemsDetail({required this.items, required this.isPending});

  @override
  Widget build(BuildContext context) {
    final totalQty = items.fold(0, (s, i) => s + i.quantity);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBBCBF0)),
        boxShadow: [BoxShadow(color: const Color(0xFF1565C0).withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF1565C0),
            child: const Row(children: [
              Expanded(flex: 4, child: _IH('Article')),
              Expanded(flex: 2, child: _IH('Size')),
              Expanded(flex: 3, child: _IH('Color')),
              Expanded(flex: 3, child: _IH('Category')),
              Expanded(flex: 3, child: _IH('Type')),
              Expanded(flex: 2, child: _IH('Qty', center: true)),
              Expanded(flex: 3, child: _IH('Sale Price')),
            ]),
          ),
          // Rows
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Container(
              color: i.isEven ? const Color(0xFFF7F9FF) : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              child: Row(children: [
                Expanded(flex: 4,
                    child: Text(item.productName ?? '—',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
                        overflow: TextOverflow.ellipsis)),
                // Size — FIX: Align wrap
                Expanded(flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFEAEFFD), borderRadius: BorderRadius.circular(6)),
                        child: Text(item.sizeName ?? '—',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1565C0))),
                      ),
                    )),
                Expanded(flex: 3,
                    child: Text(item.colorName ?? '—',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF5A5F73)))),
                Expanded(flex: 3,
                    child: Text(item.categoryName ?? '—',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF5A5F73)))),
                Expanded(flex: 3,
                    child: Text(item.typeName ?? '—',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF5A5F73)))),
                Expanded(flex: 2,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF1565C0), borderRadius: BorderRadius.circular(6)),
                        child: Text('${item.quantity}', textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    )),
                Expanded(flex: 3,
                    child: Text('PKR ${item.salePrice.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade700))),
              ]),
            );
          }),
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EEF9),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(children: [
              const Expanded(flex: 15,
                  child: Text('TOTAL PAIRS',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF1565C0), letterSpacing: 0.5))),
              Expanded(flex: 2,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF1565C0), borderRadius: BorderRadius.circular(6)),
                      child: Text('$totalQty', textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  )),
              const Expanded(flex: 3, child: SizedBox()),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _IH extends StatelessWidget {
  final String text;
  final bool center;
  const _IH(this.text, {this.center = false});

  @override
  Widget build(BuildContext context) => Text(text,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3));
}

// ── Status chip ───────────────────────────────────────────────────────────────

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
        bg = const Color(0xFFEAF5E6); fg = const Color(0xFF2E7D32); border = const Color(0xFFA5D6A7);
        label = 'Accepted'; icon = Icons.check_circle_outline; break;
      case 'rejected':
        bg = const Color(0xFFFFEBEE); fg = const Color(0xFFC62828); border = const Color(0xFFEF9A9A);
        label = 'Rejected'; icon = Icons.cancel_outlined; break;
      default:
        bg = const Color(0xFFFFF8E1); fg = const Color(0xFFE65100); border = const Color(0xFFFFCC80);
        label = 'Pending'; icon = Icons.hourglass_empty_outlined;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: fg),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
      ]),
    );
  }
}

// ── Error / Empty views ───────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
          child: Icon(Icons.error_outline, color: Colors.red.shade400, size: 36)),
      const SizedBox(height: 12),
      Text('Error: $error', style: const TextStyle(color: Color(0xFF8A8FA3), fontSize: 13)),
      const SizedBox(height: 16),
      FilledButton.icon(onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 16), label: const Text('Retry'),
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1565C0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))),
    ]),
  );
}

class _EmptyView extends StatelessWidget {
  final String status;
  const _EmptyView({required this.status});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(color: Color(0xFFF0F4FF), shape: BoxShape.circle),
          child: Icon(Icons.move_to_inbox_outlined, size: 48, color: Colors.grey.shade300)),
      const SizedBox(height: 16),
      Text(status == 'all' ? 'No assignments found' : 'No $status assignments found',
          style: const TextStyle(color: Color(0xFF8A8FA3), fontSize: 15, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      const Text('When the warehouse assigns stock, it will show up here.',
          style: TextStyle(color: Color(0xFFB0B5C8), fontSize: 12)),
    ]),
  );
}