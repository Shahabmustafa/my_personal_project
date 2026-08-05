import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/warehouse_stock_model.dart';
import '../providers/stock_provider.dart';

class StockTable extends ConsumerWidget {
  const StockTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stockProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 8),
            Text('Error: ${state.error}',
                style: const TextStyle(color: Colors.red)),
          ],
        ),
      );
    }

    final items = state.filtered;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              state.searchQuery.isEmpty
                  ? 'No stock entries found'
                  : 'No results for "${state.searchQuery}"',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        return isWide
            ? _DesktopTable(items: items)
            : _MobileList(items: items);
      },
    );
  }
}

// ── Desktop: horizontal data table ───────────────────────────────────────

class _DesktopTable extends ConsumerWidget {
  final List<WarehouseStockModel> items;
  const _DesktopTable({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const headerStyle = TextStyle(
        fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white);

    return Column(
      children: [
        // Header
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            children: [
              _hcell('Barcode', flex: 3, style: headerStyle),
              _hcell('Article', flex: 2, style: headerStyle),
              _hcell('Size', style: headerStyle),
              _hcell('Color', style: headerStyle),
              _hcell('Brand', style: headerStyle),
              _hcell('Category', style: headerStyle),
              _hcell('Type', style: headerStyle),
              _hcell('Qty', flex: 1, style: headerStyle),
              _hcell('Actions', flex: 1, style: headerStyle),
            ],
          ),
        ),
        // Rows
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final stock = items[i];
              return _DesktopRow(stock: stock, isEven: i.isEven);
            },
          ),
        ),
      ],
    );
  }

  Widget _hcell(String text,
      {int flex = 2, TextStyle? style}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Text(text, style: style),
      ),
    );
  }
}

class _DesktopRow extends ConsumerWidget {
  final WarehouseStockModel stock;
  final bool isEven;

  const _DesktopRow({required this.stock, required this.isEven});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: isEven ? Colors.grey.shade50 : Colors.white,
      child: Row(
        children: [
          _cell(stock.barcode, flex: 3),
          _cell(stock.productName ?? '—', flex: 2),
          _cell(stock.sizeName ?? '—'),
          _cell(stock.colorName ?? '—'),
          _cell(stock.brandName ?? '—'),
          _cell(stock.categoryName ?? '—'),
          _cell(stock.typeName ?? '—'),
          // Editable quantity
          Expanded(
            flex: 1,
            child: _InlineQtyEditor(stock: stock),
          ),
          // Delete
          Expanded(
            flex: 1,
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(String text, {int flex = 2}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Text(text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Stock Entry'),
        content: Text('Delete barcode "${stock.barcode}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final err = await ref
                  .read(stockProvider.notifier)
                  .deleteStock(stock.id);
              if (err != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Error: $err'),
                      backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Inline quantity editor ────────────────────────────────────────────────

class _InlineQtyEditor extends ConsumerStatefulWidget {
  final WarehouseStockModel stock;
  const _InlineQtyEditor({required this.stock});

  @override
  ConsumerState<_InlineQtyEditor> createState() =>
      _InlineQtyEditorState();
}

class _InlineQtyEditorState extends ConsumerState<_InlineQtyEditor> {
  late TextEditingController _ctrl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _ctrl =
        TextEditingController(text: widget.stock.quantity.toString());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_editing) {
      return GestureDetector(
        onTap: () => setState(() => _editing = true),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Text(widget.stock.quantity.toString(),
                  style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              const Icon(Icons.edit_outlined, size: 14, color: Colors.grey),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.check, size: 16, color: Colors.green),
          onPressed: _submit,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final qty = int.tryParse(_ctrl.text);
    if (qty == null || qty < 0) {
      setState(() => _editing = false);
      return;
    }
    setState(() => _editing = false);
    await ref
        .read(stockProvider.notifier)
        .updateQuantity(widget.stock.id, qty);
  }
}

// ── Mobile: card list ─────────────────────────────────────────────────────

class _MobileList extends ConsumerWidget {
  final List<WarehouseStockModel> items;
  const _MobileList({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final stock = items[i];
        return Card(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        stock.barcode,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 20),
                      onPressed: () async {
                        final err = await ref
                            .read(stockProvider.notifier)
                            .deleteStock(stock.id);
                        if (err != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error: $err'),
                                backgroundColor: Colors.red),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _chip('Article', stock.productName ?? '—'),
                    _chip('Size', stock.sizeName ?? '—'),
                    _chip('Color', stock.colorName ?? '—'),
                    _chip('Brand', stock.brandName ?? '—'),
                    _chip('Category', stock.categoryName ?? '—'),
                    _chip('Type', stock.typeName ?? '—'),
                    _chip('Qty', '${stock.quantity}',
                        color: Colors.blue.shade700),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _chip(String label, String value,
      {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11),
          children: [
            TextSpan(
                text: '$label: ',
                style: const TextStyle(color: Colors.grey)),
            TextSpan(
              text: value,
              style: TextStyle(
                  color: color ?? Colors.black87,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
