import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../superadmin/report/presentation/widgets/report_detail_panel.dart';
import '../../../../superadmin/report/presentation/widgets/report_summary_card.dart';
import '../../../return_stock_to_other_branch/presentation/screens/branch_stock_return_screen.dart'
    show StatusChip;
import '../../data/model/branch_warehouse_return_model.dart';
import '../providers/branch_warehouse_return_provider.dart';
import '../widgets/branch_warehouse_return_cart_table.dart';
import '../widgets/branch_warehouse_return_product_selector.dart';

const _primary = Color(0xFF1565C0);

String _fmtAmt(double v) =>
    v == v.truncate() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

/// Branch's screen for returning stock back to Admin (Head Office) — own
/// tables (branch_return_to_warehouse). Default view is the sent list; "New
/// Return" in the header pushes the return-building form as its own page.
/// Destination is always the system's single Head Office, auto-resolved —
/// there is no destination picker.
class BranchWarehouseReturnScreen extends ConsumerStatefulWidget {
  const BranchWarehouseReturnScreen({super.key});

  @override
  ConsumerState<BranchWarehouseReturnScreen> createState() =>
      _BranchWarehouseReturnScreenState();
}

class _BranchWarehouseReturnScreenState
    extends ConsumerState<BranchWarehouseReturnScreen> {
  String _filterStatus = 'all';

  BranchWarehouseReturnModel? _selected; // list row (brief)
  BranchWarehouseReturnModel? _detail; // loaded detail (items with names)
  bool _loadingDetail = false;

  Future<void> _openDetail(BranchWarehouseReturnModel r) async {
    setState(() {
      _selected = r;
      _detail = null;
      _loadingDetail = true;
    });
    BranchWarehouseReturnModel? d;
    try {
      d = await ref
          .read(branchWarehouseReturnRepositoryProvider)
          .getReturnDetail(r.id);
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
    final returnsAsync = ref.watch(sentWarehouseReturnsProvider);

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
                      'Return Stock to Admin',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Stock returns sent from this branch back to Admin (Head Office)',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: 'Refresh',
                child: IconButton(
                  onPressed: () => ref.invalidate(sentWarehouseReturnsProvider),
                  icon: const Icon(Icons.refresh),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('New Return'),
                style: FilledButton.styleFrom(backgroundColor: _primary),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(
                          title: const Text('New Return to Admin'),
                        ),
                        body: const _NewReturnForm(),
                      ),
                    ),
                  );
                  if (context.mounted) {
                    ref.invalidate(sentWarehouseReturnsProvider);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          returnsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
            data: (returns) {
              final filtered = returns.where((t) {
                if (_filterStatus == 'all') return true;
                return t.status == _filterStatus;
              }).toList();
              final filteredItems = filtered.expand((t) => t.items);
              final totalQuantity =
                  filteredItems.fold<int>(0, (s, i) => s + i.quantity);
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
                          label: 'Total Returns',
                          value: '${filtered.length}',
                          icon: Icons.assignment_return_outlined,
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
                      _chip('All', 'all', returns.length),
                      const SizedBox(width: 8),
                      _chip(
                        'Pending',
                        'pending',
                        returns.where((t) => t.status == 'pending').length,
                      ),
                      const SizedBox(width: 8),
                      _chip(
                        'Accepted',
                        'accepted',
                        returns.where((t) => t.status == 'accepted').length,
                      ),
                      const SizedBox(width: 8),
                      _chip(
                        'Rejected',
                        'rejected',
                        returns.where((t) => t.status == 'rejected').length,
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
                  child: returnsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (e, _) => Center(
                      child: Text(
                        'Error: $e',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    data: (returns) {
                      final filtered = returns.where((t) {
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
                                    ? 'No returns sent yet'
                                    : 'No $_filterStatus returns found',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap "New Return" to return stock to Admin.',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return _ReturnTable(
                        rows: filtered,
                        selectedId: _selected?.id,
                        onView: _openDetail,
                      );
                    },
                  ),
                ),
                if (_selected != null)
                  ReportDetailPanel(
                    title: _selected!.returnNumber,
                    subtitle:
                        '${_selected!.destinationLabel} · ${_fmtDate(_selected!.returnedAt)}',
                    accent: _primary,
                    onClose: () => setState(() {
                      _selected = null;
                      _detail = null;
                    }),
                    child: _ReturnDetailBody(
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
            Icon(chipIcon,
                size: 15, color: isSelected ? Colors.white : chipColor),
            const SizedBox(width: 6),
            Text(
              '$label ($count)',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF5A5F73),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _fmtDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

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

// ── History table + detail body ────────────────────────────────────────────

const _colFlex = <int>[1, 3, 5, 3, 2, 2, 3, 2];
const _colLabels = <String>[
  '#',
  'Return #',
  'To Admin',
  'Date',
  'Items',
  'Qty',
  'Status',
  'Actions',
];

class _ReturnTable extends StatelessWidget {
  final List<BranchWarehouseReturnModel> rows;
  final String? selectedId;
  final void Function(BranchWarehouseReturnModel) onView;

  const _ReturnTable({
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

  Widget _row(BranchWarehouseReturnModel r, int index) {
    final qty = r.items.fold<int>(0, (s, it) => s + it.quantity);
    final selected = selectedId == r.id;
    return InkWell(
      onTap: () => onView(r),
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
              child: Text(
                r.returnNumber,
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
                  const Icon(Icons.business_outlined,
                      size: 14, color: Color(0xFF8A8FA3)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      r.destinationLabel,
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
                _fmtDate(r.returnedAt),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Color(0xFF5A5F73)),
              ),
            ),
            Expanded(flex: _colFlex[4], child: Text('${r.items.length}')),
            Expanded(flex: _colFlex[5], child: Text('$qty')),
            Expanded(
              flex: _colFlex[6],
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: StatusChip(r.status),
              ),
            ),
            Expanded(
              flex: _colFlex[7],
              child: Tooltip(
                message: 'View',
                child: InkWell(
                  onTap: () => onView(r),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(Icons.visibility_outlined,
                        size: 19, color: _primary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReturnDetailBody extends StatelessWidget {
  final BranchWarehouseReturnModel brief;
  final BranchWarehouseReturnModel? detail;
  final bool loading;

  const _ReturnDetailBody({
    required this.brief,
    required this.detail,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final items = detail?.items ?? const [];
    final totalQty = items.fold<int>(0, (s, i) => s + i.quantity);
    final totalValue =
        items.fold<double>(0, (s, i) => s + (i.salePrice * i.quantity));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailKV('To Admin', brief.destinationLabel),
        DetailKV('Sent On', _fmtDate(brief.returnedAt)),
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
          DetailKV(
            'Total Value',
            'Rs. ${_fmtAmt(totalValue)}',
            bold: true,
            valueColor: Colors.green.shade700,
          ),
        ],
      ],
    );
  }
}

// ── New Return form (pushed as its own page) ────────────────────────────────

class _NewReturnForm extends ConsumerWidget {
  const _NewReturnForm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(branchWarehouseReturnProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
                      'Return No :',
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
                                state.returnNumber.isEmpty
                                    ? '...'
                                    : state.returnNumber,
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
                              .read(branchWarehouseReturnProvider.notifier)
                              .resetReturn(),
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
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Return To',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.business_outlined,
                            size: 16,
                            color: _primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            state.destinationHeadOffice?.headOfficeName ??
                                'Admin (Head Office)',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
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
          const BranchWarehouseReturnProductSelector(),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const BranchWarehouseReturnCartTable(),
            ),
          ),
          const SizedBox(height: 12),
          const _ReturnFooter(),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

// ── Footer ────────────────────────────────────────────────────────────────

class _ReturnFooter extends ConsumerWidget {
  const _ReturnFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(branchWarehouseReturnProvider);

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
          if (state.destinationHeadOffice != null)
            Row(
              children: [
                const Icon(Icons.business_outlined, size: 16, color: _primary),
                const SizedBox(width: 6),
                Text(
                  state.destinationHeadOffice!.headOfficeName,
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
                : () => ref
                      .read(branchWarehouseReturnProvider.notifier)
                      .clearCart(),
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
                  icon: const Icon(Icons.assignment_return_outlined, size: 18),
                  label: const Text('Send Return'),
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
    final state = ref.read(branchWarehouseReturnProvider);

    if (state.destinationHeadOffice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin (Head Office) not found. Please add one first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmSendDialog(
        headOfficeName: state.destinationHeadOffice!.headOfficeName,
        totalQty: state.totalQuantity,
        totalItems: state.cartItems.length,
      ),
    );
    if (confirm != true) return;

    final headOfficeName =
        state.destinationHeadOffice?.headOfficeName ?? 'Admin';
    final error = await ref
        .read(branchWarehouseReturnProvider.notifier)
        .saveReturn();

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
              Text('Stock returned to $headOfficeName successfully'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
      ref.read(branchWarehouseReturnProvider.notifier).clearCart();
      ref.invalidate(sentWarehouseReturnsProvider);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
      );
    }
  }
}

// ── Confirm send dialog ───────────────────────────────────────────────────

class _ConfirmSendDialog extends StatelessWidget {
  final String headOfficeName;
  final int totalQty;
  final int totalItems;

  const _ConfirmSendDialog({
    required this.headOfficeName,
    required this.totalQty,
    required this.totalItems,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.assignment_return_outlined, color: _primary, size: 22),
          SizedBox(width: 8),
          Text('Confirm Return'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('You are about to return stock to:'),
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
                    const Icon(
                      Icons.business_outlined,
                      size: 16,
                      color: _primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      headOfficeName,
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
            'Stock is deducted from your branch now; Admin must accept it before it lands in Head Office inventory.',
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

