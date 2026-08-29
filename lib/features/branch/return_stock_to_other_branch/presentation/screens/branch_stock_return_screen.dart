import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/branch_stock_return_model.dart';
import '../providers/branch_stock_return_provider.dart';
import '../widgets/branch_return_cart_table.dart';
import '../widgets/branch_return_product_selector.dart';

const _primary = Color(0xFF1565C0);

/// Sending branch's screen for returning stock directly to another branch —
/// own tables (branch_stock_returns) so it's tracked as a distinct
/// transaction type from a plain assign/transfer. Default view is the sent
/// list; "New Return" in the header pushes the return-building form as its
/// own page.
class BranchStockReturnScreen extends ConsumerWidget {
  const BranchStockReturnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final returnsAsync = ref.watch(sentStockReturnsProvider);

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
                    Text('Return Stock to Other Branch',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text('Stock returns sent from this branch to other branches',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              Tooltip(
                message: 'Refresh',
                child: IconButton(
                  onPressed: () => ref.invalidate(sentStockReturnsProvider),
                  icon: const Icon(Icons.refresh),
                ),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('New Return'),
                style: FilledButton.styleFrom(backgroundColor: _primary),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('New Stock Return')),
                        body: const _NewReturnForm(),
                      ),
                    ),
                  );
                  if (context.mounted) ref.invalidate(sentStockReturnsProvider);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: returnsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) =>
                  Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
              data: (returns) {
                if (returns.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No returns sent yet',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Tap "New Return" to return stock to another branch.',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                      ],
                    ),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          color: _primary,
                          child: const Row(children: [
                            _Th('Return No', flex: 3),
                            _Th('To Branch', flex: 4),
                            _Th('Date', flex: 2),
                            _Th('Status', flex: 2),
                          ]),
                        ),
                        Expanded(
                          child: ListView.separated(
                            itemCount: returns.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: Colors.grey.shade100),
                            itemBuilder: (_, i) => _HistoryRow(item: returns[i], index: i),
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
}

// ── New Return form (pushed as its own page) ────────────────────────────────

class _NewReturnForm extends ConsumerWidget {
  const _NewReturnForm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(branchStockReturnProvider);
    final branchesAsync = ref.watch(otherBranchesForReturnProvider);

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
                    Text('Return No :',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        state.numberLoading
                            ? const SizedBox(
                                width: 100, child: LinearProgressIndicator(minHeight: 2))
                            : Text(
                                state.returnNumber.isEmpty ? '...' : state.returnNumber,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w700, color: _primary),
                              ),
                        const SizedBox(width: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () => ref.read(branchStockReturnProvider.notifier).resetReturn(),
                          child: const Icon(Icons.refresh, size: 17, color: Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 4,
                  child: branchesAsync.when(
                    loading: () => const SizedBox(
                        height: 48, child: Center(child: LinearProgressIndicator())),
                    error: (e, _) => Text('Error: $e',
                        style: const TextStyle(color: Colors.red, fontSize: 12)),
                    data: (branches) => DropdownSearch<BranchModel>(
                      items: (filter, _) => branches
                          .where((b) => b.label.toLowerCase().contains(filter.toLowerCase()))
                          .toList(),
                      selectedItem: state.destinationBranch,
                      itemAsString: (b) => b.label,
                      compareFn: (a, b) => a.id == b.id,
                      onSelected: (b) => ref
                          .read(branchStockReturnProvider.notifier)
                          .selectDestinationBranch(b),
                      decoratorProps: DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: 'Return To Branch *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                          leading: const Icon(Icons.store_outlined, size: 18, color: _primary),
                          title: Text(branch.branchName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: branch.city != null
                              ? Text(branch.city!, style: const TextStyle(fontSize: 11))
                              : null,
                          selected: isSelected,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Date', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Text(_formatDate(DateTime.now()),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const BranchReturnProductSelector(),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const BranchReturnCartTable(),
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
    final state = ref.watch(branchStockReturnProvider);

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
              Text('Total Pairs', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Text('${state.totalQuantity}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _primary)),
            ],
          ),
          const SizedBox(width: 24),
          if (state.destinationBranch != null)
            Row(
              children: [
                const Icon(Icons.store_outlined, size: 16, color: _primary),
                const SizedBox(width: 6),
                Text(state.destinationBranch!.label,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: state.cartItems.isEmpty
                ? null
                : () => ref.read(branchStockReturnProvider.notifier).clearCart(),
          ),
          const SizedBox(width: 12),
          state.isSaving
              ? const SizedBox(
                  width: 180, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
              : FilledButton.icon(
                  icon: const Icon(Icons.assignment_return_outlined, size: 18),
                  label: const Text('Send Return'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: state.cartItems.isEmpty ? null : () => _onSend(context, ref),
                ),
        ],
      ),
    );
  }

  Future<void> _onSend(BuildContext context, WidgetRef ref) async {
    final state = ref.read(branchStockReturnProvider);

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
    final error = await ref.read(branchStockReturnProvider.notifier).saveReturn();

    if (!context.mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Stock returned to $branchName successfully'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
      ref.read(branchStockReturnProvider.notifier).clearCart();
      ref.invalidate(sentStockReturnsProvider);
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
                    const Icon(Icons.store_outlined, size: 16, color: _primary),
                    const SizedBox(width: 6),
                    Text(branchName,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: _primary)),
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
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: _primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      );
}

// ── Shared row/table widgets ────────────────────────────────────────────────

class _Th extends StatelessWidget {
  final String text;
  final int flex;
  const _Th(this.text, {this.flex = 2});

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Text(text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
      );
}

class _HistoryRow extends StatelessWidget {
  final BranchStockReturnModel item;
  final int index;
  const _HistoryRow({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: index.isEven ? Colors.grey.shade50 : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(item.returnNumber,
                style: const TextStyle(
                    fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 13, color: _primary)),
          ),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                const Icon(Icons.store_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(item.toBranchName ?? item.toBranchId,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(_fmtDate(item.returnedAt),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ),
          Expanded(flex: 2, child: StatusChip(item.status)),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

/// Shared pending/accepted/rejected badge — also used by the receiving
/// branch's Incoming Stock Returns screen.
class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});

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
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}
