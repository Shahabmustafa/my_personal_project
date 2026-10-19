import 'package:flutter/material.dart';
import 'package:safishoe_app/core/widget/min_width_scroll.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../superadmin/report/presentation/widgets/report_detail_panel.dart';
import '../../../../superadmin/report/presentation/widgets/report_summary_card.dart';
import '../../data/model/branch_stock_return_model.dart';
import '../providers/branch_stock_return_provider.dart';
import 'branch_stock_return_screen.dart' show StatusChip;

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';

const _primary = Color(0xFF3E63DD);

/// Receiving branch's screen for accepting/rejecting stock returns sent by
/// other branches — same layout as assign_stock_to_my_branch's
/// BranchAssignListScreen (summary cards, filter chips, table with a View
/// icon that opens the detail panel), backed by branch_stock_returns.
class IncomingStockReturnsScreen extends ConsumerStatefulWidget {
  const IncomingStockReturnsScreen({super.key});

  @override
  ConsumerState<IncomingStockReturnsScreen> createState() =>
      _IncomingStockReturnsScreenState();
}

class _IncomingStockReturnsScreenState
    extends ConsumerState<IncomingStockReturnsScreen> {
  String _filterStatus = 'all'; // all | pending | accepted | rejected

  BranchStockReturnModel? _selected; // list row (brief)
  BranchStockReturnModel? _detail; // loaded detail (items with names)
  bool _loadingDetail = false;

  /// Accept/Reject ke baad detail side panel band (agar wahi row khuli ho).
  void _closePanel([String? id]) {
    if (!mounted) return;
    if (id != null && _selected?.id != id) return;
    setState(() {
      _selected = null;
      _detail = null;
    });
  }

  Future<void> _openDetail(BranchStockReturnModel r) async {
    setState(() {
      _selected = r;
      _detail = null;
      _loadingDetail = true;
    });
    BranchStockReturnModel? d;
    try {
      d = await ref
          .read(branchStockReturnRepositoryProvider)
          .getReturnDetail(r.id);
    } catch (_) {
      d = null;
    }
    if (!mounted || _selected?.id != r.id) return;
    setState(() {
      _detail = d;
      _loadingDetail = false;
    });
    if (d == null) {
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
    final returnsAsync = ref.watch(incomingStockReturnsProvider);
    final all = returnsAsync.value ?? const <BranchStockReturnModel>[];

    final filtered = _filterStatus == 'all'
        ? all
        : all.where((r) => r.status == _filterStatus).toList();
    final pendingCount = all.where((r) => r.status == 'pending').length;
    final filteredItems = filtered.expand((r) => r.items);
    final totalQuantity = filteredItems.fold<int>(0, (s, i) => s + i.quantity);
    final totalSalePrice = filteredItems.fold<double>(
      0,
      (s, i) => s + (i.salePrice * i.quantity),
    );

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Incoming Stock Returns',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              if (pendingCount > 0)
                Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade600,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppIcon(
                        AppIcons.hourglassEmpty,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$pendingCount Pending',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              IconButton(
                tooltip: 'Refresh',
                icon: const AppIcon(AppIcons.refresh, size: 18),
                onPressed: () => ref.invalidate(incomingStockReturnsProvider),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Summary cards ────────────────────────────────────────────
          ReportSummaryCards(
            children: [
              ReportSummaryCard(
                label: 'Total Returns',
                value: '${filtered.length}',
                icon: AppIcons.moveToInboxOutlined,
                color: _primary,
              ),
              ReportSummaryCard(
                label: 'Total Quantity',
                value: '$totalQuantity',
                icon: AppIcons.inventory2Outlined,
                color: const Color(0xFFE56A00),
              ),
              ReportSummaryCard(
                label: 'Total Sale Price',
                value: 'Rs. ${_fmtAmt(totalSalePrice)}',
                icon: AppIcons.sellOutlined,
                color: const Color(0xFF22A06B),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Status filter chips ─────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('All', 'all', all.length),
                const SizedBox(width: 8),
                _chip('Pending', 'pending', pendingCount),
                const SizedBox(width: 8),
                _chip(
                  'Accepted',
                  'accepted',
                  all.where((r) => r.status == 'accepted').length,
                ),
                const SizedBox(width: 8),
                _chip(
                  'Rejected',
                  'rejected',
                  all.where((r) => r.status == 'rejected').length,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Table + detail panel ────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: returnsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (e, _) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppIcon(
                            AppIcons.errorOutline,
                            color: Colors.red,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Error: $e',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                    data: (_) => filtered.isEmpty
                        ? _EmptyView(status: _filterStatus)
                        : _ReturnsTable(
                            rows: filtered,
                            selectedId: _selected?.id,
                            onView: _openDetail,
                            onActionDone: _closePanel,
                          ),
                  ),
                ),
                if (_selected != null)
                  ReportDetailOverlay(
                    title: _selected!.returnNumber,
                    subtitle:
                        '${_selected!.fromBranchName ?? _selected!.fromBranchId} · ${_fmtDate(_selected!.returnedAt)}',
                    accent: _primary,
                    onClose: () => setState(() {
                      _selected = null;
                      _detail = null;
                    }),
                    child: _ReturnDetailBody(
                      brief: _selected!,
                      detail: _detail,
                      loading: _loadingDetail,
                      onDone: _closePanel,
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
    String chipIcon;
    switch (value) {
      case 'pending':
        chipColor = Colors.orange;
        chipIcon = AppIcons.hourglassEmptyOutlined;
        break;
      case 'accepted':
        chipColor = Colors.green;
        chipIcon = AppIcons.checkCircleOutline;
        break;
      case 'rejected':
        chipColor = Colors.red;
        chipIcon = AppIcons.cancelOutlined;
        break;
      default:
        chipColor = _primary;
        chipIcon = AppIcons.listOutlined;
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
            AppIcon(
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

// ── Table (flex-based — poori width par phailti hai) ─────────────────────

const _colFlex = <int>[1, 3, 5, 3, 2, 2, 3, 3];
const _colLabels = <String>[
  '#',
  'Return #',
  'From Branch',
  'Date',
  'Items',
  'Qty',
  'Status',
  'Actions',
];

class _ReturnsTable extends ConsumerWidget {
  final List<BranchStockReturnModel> rows;
  final String? selectedId;
  final void Function(BranchStockReturnModel) onView;
  final void Function(String id) onActionDone;

  const _ReturnsTable({
    required this.rows,
    required this.selectedId,
    required this.onView,
    required this.onActionDone,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MinWidthScroll(
      child: Container(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
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
                  itemBuilder: (context, i) => _row(context, ref, rows[i], i),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    WidgetRef ref,
    BranchStockReturnModel r,
    int index,
  ) {
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
              child: Text(
                '${index + 1}',
                style: const TextStyle(color: Color(0xFF8A8FA3)),
              ),
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
              child: Text(
                r.fromBranchName ?? r.fromBranchId,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
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
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    _ActionIcon(
                      icon: AppIcons.visibilityOutlined,
                      tooltip: 'View',
                      color: _primary,
                      onTap: () => onView(r),
                    ),
                    if (r.status == 'pending') ...[
                      const SizedBox(width: 4),
                      _ActionIcon(
                        icon: AppIcons.checkCircleOutline,
                        tooltip: 'Accept',
                        color: Colors.green.shade600,
                        onTap: () => _confirmAccept(
                          context,
                          ref,
                          r,
                          onDone: () => onActionDone(r.id),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _ActionIcon(
                        icon: AppIcons.cancelOutlined,
                        tooltip: 'Reject',
                        color: Colors.red.shade600,
                        onTap: () => _confirmReject(
                          context,
                          ref,
                          r,
                          onDone: () => onActionDone(r.id),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final String icon;
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
        child: AppIcon(icon, size: 19, color: color),
      ),
    ),
  );
}

// ── Detail panel body ─────────────────────────────────────────────────────

class _ReturnDetailBody extends ConsumerWidget {
  final BranchStockReturnModel brief;
  final BranchStockReturnModel? detail;
  final bool loading;
  final VoidCallback onDone;

  const _ReturnDetailBody({
    required this.brief,
    required this.detail,
    required this.loading,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = detail?.items ?? const <BranchStockReturnItemModel>[];
    final totalQty = items.fold<int>(0, (s, i) => s + i.quantity);
    final totalValue = items.fold<double>(
      0,
      (s, i) => s + (i.salePrice * i.quantity),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailKV('Returned By', brief.fromBranchName ?? brief.fromBranchId),
        DetailKV('Returned On', _fmtDate(brief.returnedAt)),
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
        if (brief.status == 'pending') ...[
          const DetailDivider(),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const AppIcon(AppIcons.checkRounded, size: 16),
                  label: const Text('Accept'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                  ),
                  onPressed: () =>
                      _confirmAccept(context, ref, brief, onDone: onDone),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const AppIcon(AppIcons.closeRounded, size: 16),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    side: BorderSide(color: Colors.red.shade300),
                  ),
                  onPressed: () =>
                      _confirmReject(context, ref, brief, onDone: onDone),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Accept / Reject confirm flows ─────────────────────────────────────────

Future<void> _confirmAccept(
  BuildContext context,
  WidgetRef ref,
  BranchStockReturnModel item, {
  VoidCallback? onDone,
}) async {
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
        'Stock will be added to your branch inventory.\n\nThis action cannot be undone.',
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
  try {
    await ref.read(branchStockReturnRepositoryProvider).acceptReturn(item.id);
    ref.invalidate(incomingStockReturnsProvider);
    onDone?.call();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

Future<void> _confirmReject(
  BuildContext context,
  WidgetRef ref,
  BranchStockReturnModel item, {
  VoidCallback? onDone,
}) async {
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
        'This return will be marked as rejected. Stock goes back to the sending branch.',
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
  try {
    await ref.read(branchStockReturnRepositoryProvider).rejectReturn(item.id);
    ref.invalidate(incomingStockReturnsProvider);
    onDone?.call();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

class _EmptyView extends StatelessWidget {
  final String status;
  const _EmptyView({required this.status});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFFF0F4FF),
            shape: BoxShape.circle,
          ),
          child: AppIcon(
            AppIcons.moveToInboxOutlined,
            size: 48,
            color: Colors.grey.shade300,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          status == 'all' ? 'No returns received yet' : 'No $status returns',
          style: const TextStyle(
            color: Color(0xFF8A8FA3),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'When another branch returns stock to you, it shows up here.',
          style: TextStyle(color: Color(0xFFB0B5C8), fontSize: 12),
        ),
      ],
    ),
  );
}
