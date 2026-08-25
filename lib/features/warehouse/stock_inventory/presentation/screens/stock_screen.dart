import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stock_provider.dart';
import '../widgets/add_stock_dialog.dart';
import '../widgets/stock_table.dart';

class StockScreen extends ConsumerStatefulWidget {
  final bool readOnly;
  const StockScreen({super.key, this.readOnly = false});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(stockProvider.notifier).loadStock();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openAddDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AddStockDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stockProvider);
    final total = state.items.length;
    final totalQty =
        state.items.fold<int>(0, (sum, s) => sum + s.quantity);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Stock Inventory',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      '$total SKUs  •  $totalQty total units',
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (!widget.readOnly)
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Stock'),
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  onPressed: _openAddDialog,
                ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Search ───────────────────────────────────────────────────
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => ref.read(stockProvider.notifier).search(v),
            decoration: InputDecoration(
              hintText:
                  'Search by barcode, article, brand, size, color...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        ref.read(stockProvider.notifier).search('');
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              filled: true,
              fillColor: Colors.white,
            ),
          ),

          const SizedBox(height: 16),

          // ── Table ────────────────────────────────────────────────────
          Expanded(child: StockTable(readOnly: widget.readOnly)),
        ],
      ),
    );
  }
}
