import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/sale_exchange_model.dart';
import '../provider/sale_exchange_provider.dart';

/// SaleCartTable ka duplicate — new-item side ke liye, state.newCartItems pe.
class SaleExchangeNewCartTable extends ConsumerWidget {
  const SaleExchangeNewCartTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(saleExchangeProvider).newCartItems;

    if (items.isEmpty) {
      return LayoutBuilder(builder: (ctx, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('No new item selected yet',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text('Scan a barcode or select a product to give the customer',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                ],
              ),
            ),
          ),
        );
      });
    }

    return LayoutBuilder(builder: (ctx, constraints) {
      return constraints.maxWidth > 700
          ? _DesktopTable(items: items)
          : _MobileList(items: items);
    });
  }
}

// ── Desktop table ─────────────────────────────────────────────────────────

class _DesktopTable extends ConsumerWidget {
  final List<SaleCartItem> items;
  const _DesktopTable({required this.items});

  static const _hs = TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: primary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Row(children: [
            _h('#', flex: 1),
            _h('Barcode', flex: 3),
            _h('Article', flex: 3),
            _h('Size', flex: 1),
            _h('Color', flex: 2),
            _h('Category', flex: 2),
            _h('S.Price', flex: 2),
            _h('Disc%', flex: 2),
            _h('Net Price', flex: 2),
            _h('Stock', flex: 2),
            _h('Qty', flex: 3),
            _h('Total', flex: 2),
            _h('', flex: 1),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) => _CartRow(item: items[i], index: i),
          ),
        ),
        _Footer(items: items),
      ],
    );
  }

  Widget _h(String t, {int flex = 2}) => Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          child: Text(t, style: _hs),
        ),
      );
}

// ── Cart row ──────────────────────────────────────────────────────────────

class _CartRow extends ConsumerWidget {
  final SaleCartItem item;
  final int index;
  const _CartRow({required this.item, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(saleExchangeProvider.notifier);
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      color: index.isEven ? Colors.grey.shade50 : Colors.white,
      child: Row(
        children: [
          _c('${index + 1}', flex: 1, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          _c(item.barcode, flex: 3, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
          _c(item.productName, flex: 3),
          _c(item.sizeName, flex: 1),
          _c(item.colorName, flex: 2),
          _c(item.categoryName, flex: 2),
          _c(item.salePrice.toStringAsFixed(0), flex: 2),
          _c(item.discountPct > 0 ? '${item.discountPct.toStringAsFixed(0)}%' : '—',
              flex: 2, style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
          _c(item.netPrice.toStringAsFixed(0),
              flex: 2,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
          _c('${item.availableStock}',
              flex: 2,
              style: TextStyle(
                  fontSize: 12,
                  color: item.availableStock <= 0 ? Colors.red : Colors.grey.shade600)),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: _QtyRowStepper(
                value: item.quantity,
                maxValue: item.availableStock,
                primaryColor: primary,
                onChanged: (v) => notifier.updateNewItemQuantity(item.branchStockId, v),
              ),
            ),
          ),
          _c(item.lineTotal.toStringAsFixed(0), flex: 2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          Expanded(
            flex: 1,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.delete_outline, size: 17, color: Colors.red),
                onPressed: () => notifier.removeNewItem(item.branchStockId),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _c(String text, {int flex = 2, TextStyle? style}) => Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          child: Text(text, overflow: TextOverflow.ellipsis, style: style ?? const TextStyle(fontSize: 12)),
        ),
      );
}

// ── Qty stepper inside row ────────────────────────────────────────────────

class _QtyRowStepper extends StatefulWidget {
  final int value;
  final int maxValue;
  final Color primaryColor;
  final void Function(int) onChanged;

  const _QtyRowStepper({
    required this.value,
    required this.maxValue,
    required this.primaryColor,
    required this.onChanged,
  });

  @override
  State<_QtyRowStepper> createState() => _QtyRowStepperState();
}

class _QtyRowStepperState extends State<_QtyRowStepper> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(_QtyRowStepper old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _ctrl.text = widget.value.toString();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _commit() {
    final v = int.tryParse(_ctrl.text) ?? widget.value;
    final capped = widget.maxValue > 0 ? v.clamp(1, widget.maxValue) : v;
    widget.onChanged(capped > 0 ? capped : 1);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.primaryColor;

    return Container(
      height: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          _btn(
            icon: Icons.remove,
            color: color.withOpacity(0.08),
            iconColor: color,
            radius: const BorderRadius.horizontal(left: Radius.circular(6)),
            onTap: () {
              final v = int.tryParse(_ctrl.text) ?? 1;
              if (v > 1) {
                _ctrl.text = '${v - 1}';
                widget.onChanged(v - 1);
              }
            },
          ),
          Expanded(
            child: TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _commit(),
              onTapOutside: (_) => _commit(),
            ),
          ),
          _btn(
            icon: Icons.add,
            color: color,
            iconColor: Colors.white,
            radius: const BorderRadius.horizontal(right: Radius.circular(6)),
            onTap: () {
              final v = int.tryParse(_ctrl.text) ?? 0;
              final next = v + 1;
              if (widget.maxValue <= 0 || next <= widget.maxValue) {
                _ctrl.text = '$next';
                widget.onChanged(next);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _btn({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required BorderRadius radius,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          width: 30,
          height: double.infinity,
          decoration: BoxDecoration(color: color, borderRadius: radius),
          alignment: Alignment.center,
          child: Icon(icon, size: 15, color: iconColor),
        ),
      );
}

// ── Footer ────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final List<SaleCartItem> items;
  const _Footer({required this.items});

  @override
  Widget build(BuildContext context) {
    final totalQty = items.fold(0, (s, i) => s + i.quantity);
    final totalAmt = items.fold(0.0, (s, i) => s + i.salePrice * i.quantity);
    final totalDisc = items.fold(0.0, (s, i) => s + i.discountAmount * i.quantity);
    final net = items.fold(0.0, (s, i) => s + i.lineTotal);
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          const Expanded(
            flex: 12,
            child: Text('TOTALS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text(totalAmt.toStringAsFixed(0),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text('- ${totalDisc.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
          ),
          Expanded(
            flex: 2,
            child: Text(net.toStringAsFixed(0),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
          ),
          const Expanded(flex: 2, child: SizedBox()),
          Expanded(
            flex: 3,
            child: Text('$totalQty',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: primary)),
          ),
          Expanded(
            flex: 2,
            child: Text(net.toStringAsFixed(0),
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: primary)),
          ),
          const Expanded(flex: 1, child: SizedBox()),
        ],
      ),
    );
  }
}

// ── Mobile list ───────────────────────────────────────────────────────────

class _MobileList extends ConsumerWidget {
  final List<SaleCartItem> items;
  const _MobileList({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(saleExchangeProvider.notifier);
    final primary = Theme.of(context).colorScheme.primary;

    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final item = items[i];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(item.barcode,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12, fontFamily: 'monospace'))),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                      onPressed: () => notifier.removeNewItem(item.branchStockId),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('${item.productName} · ${item.sizeName} · ${item.colorName}',
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _lbl('S.Price', item.salePrice.toStringAsFixed(0)),
                    const SizedBox(width: 12),
                    _lbl('Stock', '${item.availableStock}',
                        color: item.availableStock <= 0 ? Colors.red : Colors.grey.shade700),
                    const Spacer(),
                    _QtyRowStepper(
                      value: item.quantity,
                      maxValue: item.availableStock,
                      primaryColor: primary,
                      onChanged: (v) => notifier.updateNewItemQuantity(item.branchStockId, v),
                    ),
                    const SizedBox(width: 10),
                    Text(item.lineTotal.toStringAsFixed(0),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primary)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _lbl(String label, String value, {Color? color}) => RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
                text: value,
                style: TextStyle(color: color ?? Colors.black87, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
