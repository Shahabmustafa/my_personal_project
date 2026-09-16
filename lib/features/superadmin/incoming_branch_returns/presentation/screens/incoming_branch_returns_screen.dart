import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../branch/return_stock_to_other_branch/presentation/screens/branch_stock_return_screen.dart'
    show StatusChip;
import '../../../../branch/return_stock_to_warehouse/data/model/branch_warehouse_return_model.dart';
import '../../../../branch/return_stock_to_warehouse/presentation/providers/branch_warehouse_return_provider.dart'
    show branchWarehouseReturnRepositoryProvider;
import '../providers/incoming_branch_return_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
const _primary = Color(0xFF3E63DD);

/// Admin's screen for accepting/rejecting stock returns sent by branches —
/// same accept/reject pattern as the head-office->branch assignment screen,
/// backed by branch_return_to_warehouse (head_office_id destination).
class IncomingBranchReturnsScreen extends ConsumerStatefulWidget {
  const IncomingBranchReturnsScreen({super.key});

  @override
  ConsumerState<IncomingBranchReturnsScreen> createState() =>
      _IncomingBranchReturnsScreenState();
}

class _IncomingBranchReturnsScreenState
    extends ConsumerState<IncomingBranchReturnsScreen> {
  String _filterStatus = 'all'; // all | pending | accepted | rejected

  @override
  Widget build(BuildContext context) {
    final returnsAsync = ref.watch(incomingBranchReturnsProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIcon(
                AppIcons.moveToInboxOutlined,
                color: _primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Incoming Branch Returns',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => ref.invalidate(incomingBranchReturnsProvider),
                icon: const AppIcon(AppIcons.refresh, color: _primary),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 14),
          returnsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (returns) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterChip('All', 'all', returns.length),
                _filterChip(
                  'Pending',
                  'pending',
                  returns.where((r) => r.status == 'pending').length,
                ),
                _filterChip(
                  'Accepted',
                  'accepted',
                  returns.where((r) => r.status == 'accepted').length,
                ),
                _filterChip(
                  'Rejected',
                  'rejected',
                  returns.where((r) => r.status == 'rejected').length,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
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
              data: (returns) {
                final filtered = _filterStatus == 'all'
                    ? returns
                    : returns.where((r) => r.status == _filterStatus).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIcon(
                          AppIcons.inboxOutlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _filterStatus == 'all'
                              ? 'No returns received yet'
                              : 'No $_filterStatus returns',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (isMobile) {
                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _ReturnCard(item: filtered[i]),
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          color: _primary,
                          child: const Row(
                            children: [
                              _Th('Return No', flex: 3),
                              _Th('From Branch', flex: 4),
                              _Th('Date', flex: 2),
                              _Th('Items', flex: 1),
                              _Th('Status', flex: 2),
                              _Th('Actions', flex: 3),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: Colors.grey.shade100,
                            ),
                            itemBuilder: (_, i) =>
                                _ListRow(item: filtered[i], index: i),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
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
        chipColor = _primary;
    }

    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : Colors.grey.shade300,
          ),
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
}

class _Th extends StatelessWidget {
  final String text;
  final int flex;
  const _Th(this.text, {this.flex = 2});

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  );
}

class _ListRow extends ConsumerWidget {
  final BranchWarehouseReturnModel item;
  final int index;
  const _ListRow({required this.item, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: index.isEven ? Colors.grey.shade50 : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              item.returnNumber,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: _primary,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                const AppIcon(AppIcons.storeOutlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.branchName ?? item.branchId,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _fmtDate(item.returnedAt),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${item.items.fold<int>(0, (s, i) => s + i.quantity)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(flex: 2, child: StatusChip(item.status)),
          Expanded(
            flex: 3,
            child: item.status == 'pending'
                ? Row(
                    children: [
                      SizedBox(
                        height: 32,
                        child: FilledButton(
                          onPressed: () => _onAccept(context, ref, item),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Accept',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 32,
                        child: OutlinedButton(
                          onPressed: () => _onReject(context, ref, item),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Reject',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  )
                : Text(
                    item.status == 'accepted'
                        ? 'Accepted ${_fmtDate(item.acceptedAt ?? item.returnedAt)}'
                        : 'Rejected',
                    style: TextStyle(
                      fontSize: 11,
                      color: item.status == 'accepted'
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile Card ───────────────────────────────────────────────────────────────

class _ReturnCard extends ConsumerWidget {
  final BranchWarehouseReturnModel item;
  const _ReturnCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.returnNumber,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _primary,
                  ),
                ),
              ),
              StatusChip(item.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const AppIcon(AppIcons.storeOutlined, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.branchName ?? item.branchId,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_fmtDate(item.returnedAt)} · '
            '${item.items.fold<int>(0, (s, i) => s + i.quantity)} items',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          if (item.status == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: FilledButton(
                      onPressed: () => _onAccept(context, ref, item),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text('Accept', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: OutlinedButton(
                      onPressed: () => _onReject(context, ref, item),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text('Reject', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              item.status == 'accepted'
                  ? 'Accepted ${_fmtDate(item.acceptedAt ?? item.returnedAt)}'
                  : 'Rejected',
              style: TextStyle(
                fontSize: 11,
                color: item.status == 'accepted'
                    ? Colors.green.shade700
                    : Colors.red.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _onAccept(
    BuildContext context, WidgetRef ref, BranchWarehouseReturnModel item) async {
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

    if (confirm == true) {
      try {
        await ref
            .read(branchWarehouseReturnRepositoryProvider)
            .acceptReturn(item.id);
        ref.invalidate(incomingBranchReturnsProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
}

Future<void> _onReject(
    BuildContext context, WidgetRef ref, BranchWarehouseReturnModel item) async {
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

    if (confirm == true) {
      try {
        await ref
            .read(branchWarehouseReturnRepositoryProvider)
            .rejectReturn(item.id);
        ref.invalidate(incomingBranchReturnsProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
}

String _fmtDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
