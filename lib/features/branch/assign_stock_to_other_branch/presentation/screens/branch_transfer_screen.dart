import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../superadmin/report/presentation/widgets/report_detail_panel.dart';
import '../../../../superadmin/report/presentation/widgets/report_summary_card.dart';
import '../../../../warehouse/assign_stock_to_branch/data/models/assign_stock_model.dart';
import '../providers/branch_transfer_provider.dart';
import '../widgets/branch_transfer_cart_table.dart';
import '../widgets/branch_transfer_product_selector.dart';

const _primary = Color(0xFF1565C0);

/// Sending branch's screen for transferring stock directly to another
/// branch (bypassing the warehouse) — reuses the same `assign_stock_to_branch`
/// tables/accept-reject flow the warehouse->branch feature already has, so
/// the destination branch sees and accepts these from its existing
/// "Assign Stock My Branch" screen with no changes there.
///
/// Default view is the sent-transfers list; "New Transfer" in the app bar
/// pushes the transfer-building form as its own page (same pattern as
/// Sale Invoices' list + "New Invoice" button).
class BranchTransferScreen extends ConsumerStatefulWidget {
  const BranchTransferScreen({super.key});

  @override
  ConsumerState<BranchTransferScreen> createState() =>
      _BranchTransferScreenState();
}

class _BranchTransferScreenState extends ConsumerState<BranchTransferScreen> {
  String _filterStatus = 'all';

  AssignStockModel? _selected; // list row (brief)
  AssignStockModel? _detail; // loaded detail (items with names)
  bool _loadingDetail = false;

  Future<void> _openDetail(AssignStockModel a) async {
    setState(() {
      _selected = a;
      _detail = null;
      _loadingDetail = true;
    });
    AssignStockModel? d;
    try {
      d = await ref
          .read(branchTransferRepositoryProvider)
          .getTransferDetail(a.id);
    } catch (_) {
      d = null;
    }
    if (!mounted) return;
    setState(() {
      _detail = d;
      _loadingDetail = false;
    });
    if (d == null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load items. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final transfersAsync = ref.watch(sentTransfersProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assign Stock to Other Branch',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Stock transfers sent from this branch to other branches',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: 'Refresh',
                child: IconButton(
                  onPressed: () => ref.invalidate(sentTransfersProvider),
                  icon: const Icon(Icons.refresh),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('New Transfer'),
                style: FilledButton.styleFrom(backgroundColor: _primary),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('New Stock Transfer')),
                        body: const _NewTransferForm(),
                      ),
                    ),
                  );
                  if (context.mounted) ref.invalidate(sentTransfersProvider);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          transfersAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
            data: (transfers) {
              final filtered = transfers.where((t) {
                if (_filterStatus == 'all') return true;
                return t.status == _filterStatus;
              }).toList();
              final filteredItems = filtered.expand((t) => t.items);
              final totalQuantity = filteredItems.fold<int>(
                0,
                (s, i) => s + i.quantity,
              );
              final totalValue = filteredItems.fold<double>(
                0,
                (s, i) => s + (i.salePrice * i.quantity),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Summary cards ────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: ReportSummaryCard(
                          label: 'Total Transfers',
                          value: '${filtered.length}',
                          icon: Icons.compare_arrows_outlined,
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
                          label: 'Total Value',
                          value: 'Rs. ${_fmtAmt(totalValue)}',
                          icon: Icons.sell_outlined,
                          color: const Color(0xFF22A06B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Status filter chips ──────────────────────────────
                  Row(
                    children: [
                      _chip('All', 'all', transfers.length),
                      const SizedBox(width: 8),
                      _chip(
                        'Pending',
                        'pending',
                        transfers.where((t) => t.status == 'pending').length,
                      ),
                      const SizedBox(width: 8),
                      _chip(
                        'Accepted',
                        'accepted',
                        transfers.where((t) => t.status == 'accepted').length,
                      ),
                      const SizedBox(width: 8),
                      _chip(
                        'Rejected',
                        'rejected',
                        transfers.where((t) => t.status == 'rejected').length,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),

          // ── Table + detail panel ───────────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: transfersAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (e, _) => Center(
                      child: Text(
                        'Error: $e',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    data: (transfers) {
                      final filtered = transfers.where((t) {
                        if (_filterStatus == 'all') return true;
                        return t.status == _filterStatus;
                      }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _filterStatus == 'all'
                                    ? 'No transfers sent yet'
                                    : 'No $_filterStatus transfers found',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap "New Transfer" to send stock to another branch.',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return _TransferTable(
                        rows: filtered,
                        selectedId: _selected?.id,
                        onView: _openDetail,
                      );
                    },
                  ),
                ),
                if (_selected != null)
                  ReportDetailPanel(
                    title: _selected!.assignmentNumber,
                    subtitle:
                        '${_selected!.branchName ?? '—'} · ${_fmtDate(_selected!.assignedAt)}',
                    accent: _primary,
                    onClose: () => setState(() {
                      _selected = null;
                      _detail = null;
                    }),
                    child: _TransferDetailBody(
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
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              chipIcon,
              size: 14,
              color: isSelected ? Colors.white : const Color(0xFF8A8FA3),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF5A5F73),
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white24 : const Color(0xFFF0F1F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF5A5F73),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _fmtAmt(double v) =>
    v == v.truncate() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

// ── New Transfer form (pushed as its own page) ─────────────────────────────

class _NewTransferForm extends ConsumerWidget {
  const _NewTransferForm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(branchTransferProvider);
    final branchesAsync = ref.watch(otherBranchesProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header card ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                // Transfer number
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Transfer No :',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        state.numberLoading
                            ? const SizedBox(
                                width: 100,
                                child: LinearProgressIndicator(minHeight: 2),
                              )
                            : Text(
                                state.transferNumber.isEmpty
                                    ? '...'
                                    : state.transferNumber,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: _primary,
                                ),
                              ),
                        const SizedBox(width: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () => ref
                              .read(branchTransferProvider.notifier)
                              .resetTransfer(),
                          child: const Icon(
                            Icons.refresh,
                            size: 17,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 20),

                // Destination branch dropdown
                Expanded(
                  flex: 4,
                  child: branchesAsync.when(
                    loading: () => const SizedBox(
                      height: 48,
                      child: Center(child: LinearProgressIndicator()),
                    ),
                    error: (e, _) => Text(
                      'Error: $e',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                    data: (branches) => DropdownSearch<BranchModel>(
                      items: (filter, _) => branches
                          .where(
                            (b) => b.label.toLowerCase().contains(
                              filter.toLowerCase(),
                            ),
                          )
                          .toList(),
                      selectedItem: state.destinationBranch,
                      itemAsString: (b) => b.label,
                      compareFn: (a, b) => a.id == b.id,
                      onSelected: (b) => ref
                          .read(branchTransferProvider.notifier)
                          .selectDestinationBranch(b),
                      decoratorProps: DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: 'Send To Branch *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        constraints: const BoxConstraints(maxHeight: 260),
                        searchFieldProps: const TextFieldProps(
                          decoration: InputDecoration(
                            hintText: 'Search branch...',
                            prefixIcon: Icon(Icons.search, size: 18),
                            isDense: true,
                          ),
                        ),
                        itemBuilder: (ctx, branch, isSelected, _) => ListTile(
                          leading: const Icon(
                            Icons.store_outlined,
                            size: 18,
                            color: _primary,
                          ),
                          title: Text(
                            branch.branchName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: branch.city != null
                              ? Text(
                                  branch.city!,
                                  style: const TextStyle(fontSize: 11),
                                )
                              : null,
                          selected: isSelected,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const BranchTransferProductSelector(),
          const SizedBox(height: 12),

          // ── Cart Table ─────────────────────────────────────────────────
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const BranchTransferCartTable(),
            ),
          ),

          const SizedBox(height: 12),
          const _TransferFooter(),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

// ── Footer ────────────────────────────────────────────────────────────────

class _TransferFooter extends ConsumerWidget {
  const _TransferFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(branchTransferProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total Pairs',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 2),
              Text(
                '${state.totalQuantity}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _primary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          if (state.destinationBranch != null)
            Row(
              children: [
                const Icon(Icons.store_outlined, size: 16, color: _primary),
                const SizedBox(width: 6),
                Text(
                  state.destinationBranch!.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          const Spacer(),
          OutlinedButton.icon(
            icon: const Icon(Icons.clear_all, size: 18),
            label: const Text('Clear'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: state.cartItems.isEmpty
                ? null
                : () => ref.read(branchTransferProvider.notifier).clearCart(),
          ),
          const SizedBox(width: 12),
          state.isSaving
              ? const SizedBox(
                  width: 180,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : FilledButton.icon(
                  icon: const Icon(Icons.send_outlined, size: 18),
                  label: const Text('Send Stock'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: state.cartItems.isEmpty
                      ? null
                      : () => _onSend(context, ref),
                ),
        ],
      ),
    );
  }

  Future<void> _onSend(BuildContext context, WidgetRef ref) async {
    final state = ref.read(branchTransferProvider);

    if (state.destinationBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a destination branch first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmSendDialog(
        branchName: state.destinationBranch!.branchName,
        totalQty: state.totalQuantity,
        totalItems: state.cartItems.length,
      ),
    );
    if (confirm != true) return;

    final branchName = state.destinationBranch?.branchName ?? 'branch';
    final error = await ref
        .read(branchTransferProvider.notifier)
        .saveTransfer();

    if (!context.mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text('Stock sent to $branchName successfully'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
      ref.read(branchTransferProvider.notifier).clearCart();
      ref.invalidate(sentTransfersProvider);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
      );
    }
  }
}

// ── Confirm send dialog ───────────────────────────────────────────────────

class _ConfirmSendDialog extends StatelessWidget {
  final String branchName;
  final int totalQty;
  final int totalItems;

  const _ConfirmSendDialog({
    required this.branchName,
    required this.totalQty,
    required this.totalItems,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.compare_arrows_outlined, color: _primary, size: 22),
          SizedBox(width: 8),
          Text('Confirm Transfer'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('You are about to send stock to:'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF90CAF9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.store_outlined, size: 16, color: _primary),
                    const SizedBox(width: 6),
                    Text(
                      branchName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _chip('$totalItems Products', Icons.inventory_2_outlined),
                    const SizedBox(width: 12),
                    _chip('$totalQty Pairs', Icons.straighten_outlined),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Stock is deducted from your branch now; the destination branch must accept it before it lands in their inventory.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: _primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Confirm & Send'),
        ),
      ],
    );
  }

  Widget _chip(String text, IconData icon) => Row(
    children: [
      Icon(icon, size: 14, color: _primary),
      const SizedBox(width: 4),
      Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ],
  );
}

String _fmtDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

// ── Table (flex-based — poori width par phailti hai) ─────────────────────

const _colFlex = <int>[1, 3, 5, 3, 2, 2, 3, 2];
const _colLabels = <String>[
  '#',
  'Transfer #',
  'To Branch',
  'Date',
  'Items',
  'Qty',
  'Status',
  'Actions',
];

class _TransferTable extends StatelessWidget {
  final List<AssignStockModel> rows;
  final String? selectedId;
  final void Function(AssignStockModel) onView;

  const _TransferTable({
    required this.rows,
    required this.selectedId,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
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
                      child: Text(
                        _colLabels[c],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5A5F73),
                          letterSpacing: 0.3,
                        ),
                      ),
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
                itemBuilder: (context, i) => _row(rows[i], i),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(AssignStockModel a, int index) {
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
              child: Text(
                '${index + 1}',
                style: const TextStyle(color: Color(0xFF8A8FA3)),
              ),
            ),
            Expanded(
              flex: _colFlex[1],
              child: Text(
                a.assignmentNumber,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _primary,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            Expanded(
              flex: _colFlex[2],
              child: Row(
                children: [
                  const Icon(
                    Icons.store_outlined,
                    size: 14,
                    color: Color(0xFF8A8FA3),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      a.branchName ?? a.branchId,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: _colFlex[3],
              child: Text(
                _fmtDate(a.assignedAt),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Color(0xFF5A5F73)),
              ),
            ),
            Expanded(flex: _colFlex[4], child: Text('${a.items.length}')),
            Expanded(flex: _colFlex[5], child: Text('$qty')),
            Expanded(
              flex: _colFlex[6],
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: _StatusChip(a.status),
              ),
            ),
            Expanded(
              flex: _colFlex[7],
              child: _ActionIcon(
                icon: Icons.visibility_outlined,
                tooltip: 'View',
                color: _primary,
                onTap: () => onView(a),
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
  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

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

// ── Detail panel body ─────────────────────────────────────────────────────

class _TransferDetailBody extends StatelessWidget {
  final AssignStockModel brief;
  final AssignStockModel? detail;
  final bool loading;

  const _TransferDetailBody({
    required this.brief,
    required this.detail,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final items = detail?.items ?? const [];
    final totalQty = items.fold<int>(0, (s, i) => s + i.quantity);
    final totalValue = items.fold<double>(
      0,
      (s, i) => s + (i.salePrice * i.quantity),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailKV('To Branch', brief.branchName ?? '—'),
        DetailKV('Sent On', _fmtDate(brief.assignedAt)),
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
            child: Text(
              'Could not load items.',
              style: TextStyle(color: Color(0xFF8A8FA3)),
            ),
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
          DetailKV(
            'Total Value',
            'Rs. ${totalValue.toStringAsFixed(0)}',
            bold: true,
            valueColor: Colors.green.shade700,
          ),
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

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case 'accepted':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        label = 'Accepted';
        icon = Icons.check_circle_outline;
        break;
      case 'rejected':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        label = 'Rejected';
        icon = Icons.cancel_outlined;
        break;
      default:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
        label = 'Pending';
        icon = Icons.hourglass_empty_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
