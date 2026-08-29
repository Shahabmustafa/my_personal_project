import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../return_stock_to_other_branch/presentation/screens/branch_stock_return_screen.dart'
    show StatusChip;
import '../../data/model/branch_warehouse_return_model.dart';
import '../providers/branch_warehouse_return_provider.dart';
import '../widgets/branch_warehouse_return_cart_table.dart';
import '../widgets/branch_warehouse_return_product_selector.dart';

const _primary = Color(0xFF1565C0);

/// Branch's screen for returning stock back to the warehouse — own tables
/// (branch_return_to_warehouse). Default view is the sent list; "New
/// Return" in the header pushes the return-building form as its own page.
class BranchWarehouseReturnScreen extends ConsumerWidget {
  const BranchWarehouseReturnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    Text('Return Stock to Warehouse',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text('Stock returns sent from this branch back to the warehouse',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
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
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('New Return'),
                style: FilledButton.styleFrom(backgroundColor: _primary),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('New Warehouse Return')),
                        body: const _NewReturnForm(),
                      ),
                    ),
                  );
                  if (context.mounted) ref.invalidate(sentWarehouseReturnsProvider);
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
                        Text('Tap "New Return" to return stock to the warehouse.',
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
                            _Th('Warehouse', flex: 4),
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
    final state = ref.watch(branchWarehouseReturnProvider);
    final warehousesAsync = ref.watch(activeWarehousesForReturnProvider);

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
                          onTap: () =>
                              ref.read(branchWarehouseReturnProvider.notifier).resetReturn(),
                          child: const Icon(Icons.refresh, size: 17, color: Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 4,
                  child: warehousesAsync.when(
                    loading: () => const SizedBox(
                        height: 48, child: Center(child: LinearProgressIndicator())),
                    error: (e, _) => Text('Error: $e',
                        style: const TextStyle(color: Colors.red, fontSize: 12)),
                    data: (warehouses) => DropdownSearch<WarehouseModel>(
                      items: (filter, _) => warehouses
                          .where((w) =>
                              w.warehouseName.toLowerCase().contains(filter.toLowerCase()))
                          .toList(),
                      selectedItem: state.destinationWarehouse,
                      itemAsString: (w) => w.warehouseName,
                      compareFn: (a, b) => a.id == b.id,
                      onSelected: (w) => ref
                          .read(branchWarehouseReturnProvider.notifier)
                          .selectDestinationWarehouse(w),
                      decoratorProps: DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: 'Return To Warehouse *',
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
                            hintText: 'Search warehouse...',
                            prefixIcon: Icon(Icons.search, size: 18),
                            isDense: true,
                          ),
                        ),
                        itemBuilder: (ctx, warehouse, isSelected, _) => ListTile(
                          leading:
                              const Icon(Icons.warehouse_outlined, size: 18, color: _primary),
                          title: Text(warehouse.warehouseName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: warehouse.city.isNotEmpty
                              ? Text(warehouse.city, style: const TextStyle(fontSize: 11))
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
              Text('Total Pairs', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Text('${state.totalQuantity}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _primary)),
            ],
          ),
          const SizedBox(width: 24),
          if (state.destinationWarehouse != null)
            Row(
              children: [
                const Icon(Icons.warehouse_outlined, size: 16, color: _primary),
                const SizedBox(width: 6),
                Text(state.destinationWarehouse!.warehouseName,
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
                : () => ref.read(branchWarehouseReturnProvider.notifier).clearCart(),
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
    final state = ref.read(branchWarehouseReturnProvider);

    if (state.destinationWarehouse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a destination warehouse first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmSendDialog(
        warehouseName: state.destinationWarehouse!.warehouseName,
        totalQty: state.totalQuantity,
        totalItems: state.cartItems.length,
      ),
    );
    if (confirm != true) return;

    final warehouseName = state.destinationWarehouse?.warehouseName ?? 'warehouse';
    final error = await ref.read(branchWarehouseReturnProvider.notifier).saveReturn();

    if (!context.mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Stock returned to $warehouseName successfully'),
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
  final String warehouseName;
  final int totalQty;
  final int totalItems;

  const _ConfirmSendDialog({
    required this.warehouseName,
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
                    const Icon(Icons.warehouse_outlined, size: 16, color: _primary),
                    const SizedBox(width: 6),
                    Text(warehouseName,
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
            'Stock is deducted from your branch now; the warehouse must accept it before it lands in warehouse inventory.',
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
  final BranchWarehouseReturnModel item;
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
                const Icon(Icons.warehouse_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(item.warehouseName ?? item.warehouseId,
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
