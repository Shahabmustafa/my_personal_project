import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../branch/branch_stock_inventory/data/model/branch_stock_model.dart';
import '../../../branch/presentation/providers/branch_provider.dart';
import '../providers/branch_stock_discount_provider.dart';

const _primary = Color(0xFF3E63DD);

/// Superadmin: pehle branch chuno, phir us branch ka poora stock — har article
/// par discount % (branch_stock_inventory.discount) yahin edit ho sakta hai.
/// Yeh discount Sale Invoice par article add karte hi apply ho jata hai.
class BranchStockDiscountScreen extends ConsumerStatefulWidget {
  const BranchStockDiscountScreen({super.key});

  @override
  ConsumerState<BranchStockDiscountScreen> createState() =>
      _BranchStockDiscountScreenState();
}

class _BranchStockDiscountScreenState
    extends ConsumerState<BranchStockDiscountScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(branchProvider.notifier).loadAllBranches();
    });
  }

  @override
  Widget build(BuildContext context) {
    final branches = ref.watch(branchProvider).branches;
    final state = ref.watch(branchStockDiscountProvider);
    final notifier = ref.read(branchStockDiscountProvider.notifier);

    ref.listen<BranchStockDiscountState>(branchStockDiscountProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Branch Stock Discount',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              'Branch chuno aur us branch ke kisi bhi article par discount % set karo. Yeh discount us branch ki Sale Invoice par apne aap lagta hai.',
              style: TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
            ),
            const SizedBox(height: 18),

            // ── Branch + search ──────────────────────────────────────────
            Row(
              children: [
                SizedBox(
                  width: 320,
                  child: DropdownButtonFormField<String>(
                    value: state.branchId,
                    isExpanded: true,
                    decoration: _decor('Branch'),
                    hint: const Text('Select a branch'),
                    items: [
                      for (final b in branches)
                        DropdownMenuItem(
                          value: b.id,
                          child: Text(
                            b.city.isEmpty
                                ? b.branchName
                                : '${b.branchName} — ${b.city}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) notifier.selectBranch(v);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    enabled: state.branchId != null,
                    onChanged: notifier.search,
                    decoration: _decor('Search article, barcode, brand...')
                        .copyWith(
                            prefixIcon: const Icon(Icons.search,
                                color: Color(0xFF8A8FA3))),
                  ),
                ),
                if (state.branchId != null) ...[
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: notifier.refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            Expanded(child: _body(state)),
          ],
        ),
      ),
    );
  }

  Widget _body(BranchStockDiscountState state) {
    if (state.branchId == null) {
      return const _Hint(
          icon: Icons.storefront_outlined,
          text: 'Select a branch to view its stock');
    }
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final rows = state.filtered;
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              color: _primary,
              child: const Row(
                children: [
                  Expanded(flex: 1, child: _TH('#')),
                  Expanded(flex: 3, child: _TH('Barcode')),
                  Expanded(flex: 4, child: _TH('Article')),
                  Expanded(flex: 3, child: _TH('Brand')),
                  Expanded(flex: 2, child: _TH('Size')),
                  Expanded(flex: 2, child: _TH('Color')),
                  Expanded(flex: 2, child: _TH('Stock')),
                  Expanded(flex: 3, child: _TH('Sale Price')),
                  Expanded(flex: 4, child: _TH('Discount %')),
                ],
              ),
            ),
            Expanded(
              child: rows.isEmpty
                  ? _Hint(
                      icon: Icons.inventory_2_outlined,
                      text: state.searchQuery.isNotEmpty
                          ? 'No matching articles'
                          : 'This branch has no stock')
                  : ListView.separated(
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, color: Color(0xFFEEF0F6)),
                      itemBuilder: (_, i) => _DiscountRow(
                        key: ValueKey(rows[i].id),
                        index: i,
                        item: rows[i],
                        saving: state.savingIds.contains(rows[i].id),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decor(String label) => InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
      );
}

class _DiscountRow extends ConsumerStatefulWidget {
  final int index;
  final BranchStockModel item;
  final bool saving;
  const _DiscountRow(
      {super.key,
      required this.index,
      required this.item,
      required this.saving});

  @override
  ConsumerState<_DiscountRow> createState() => _DiscountRowState();
}

class _DiscountRowState extends ConsumerState<_DiscountRow> {
  late final TextEditingController _ctrl;

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  String get _savedText => _fmt(widget.item.discount);
  bool get _dirty => _ctrl.text.trim() != _savedText;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _savedText);
  }

  @override
  void didUpdateWidget(covariant _DiscountRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dirty && oldWidget.item.discount != widget.item.discount) {
      _ctrl.text = _savedText;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    final pct = (double.tryParse(_ctrl.text.trim()) ?? 0).clamp(0, 100).toDouble();
    _ctrl.text = _fmt(pct);
    FocusScope.of(context).unfocus();
    ref
        .read(branchStockDiscountProvider.notifier)
        .updateDiscount(widget.item.id, pct);
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 1, child: _TD('${widget.index + 1}')),
          Expanded(flex: 3, child: _TD(it.barcode.isEmpty ? '—' : it.barcode)),
          Expanded(flex: 4, child: _TD(it.productName ?? '—', bold: true)),
          Expanded(flex: 3, child: _TD(it.brandName ?? '—')),
          Expanded(flex: 2, child: _TD(it.sizeName ?? '—')),
          Expanded(flex: 2, child: _TD(it.colorName ?? '—')),
          Expanded(flex: 2, child: _TD('${it.quantity}')),
          Expanded(flex: 3, child: _TD('Rs. ${it.salePrice.toStringAsFixed(0)}')),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _ctrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    textAlign: TextAlign.end,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _save(),
                    decoration: InputDecoration(
                      isDense: true,
                      suffixText: '%',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                widget.saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        tooltip: 'Save',
                        visualDensity: VisualDensity.compact,
                        onPressed: _dirty ? _save : null,
                        icon: Icon(Icons.check_circle,
                            color: _dirty
                                ? const Color(0xFF2E7D32)
                                : Colors.grey.shade300),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3));
}

class _TD extends StatelessWidget {
  final String text;
  final bool bold;
  const _TD(this.text, {this.bold = false});
  @override
  Widget build(BuildContext context) => Text(text,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
          fontSize: 12.5,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          color: const Color(0xFF1B1F3B)));
}

class _Hint extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Hint({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 46, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(text, style: const TextStyle(color: Color(0xFF8A8FA3))),
          ],
        ),
      );
}
