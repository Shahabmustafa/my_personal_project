import 'package:flutter/material.dart';
import 'package:safishoe_app/core/widget/qty_stepper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/sale_invoice_model.dart';
import '../provider/sale_invoice_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
class SaleCartTable extends ConsumerWidget {
  const SaleCartTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(saleInvoiceProvider).cartItems;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(AppIcons.shoppingCartOutlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Cart is Empty',
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('Scan a barcode or select a product to add',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          ],
        ),
      );
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
    final rows = _cartRows(items);

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
            _h('Stock', flex: 2),
            _h('Qty', flex: 3),
            _h('Total', flex: 2),
            _h('', flex: 1),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: rows.length,
            itemBuilder: (_, i) =>
                _CartRow(item: rows[i].item, free: rows[i].free, index: i),
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
  final bool free;
  final int index;
  const _CartRow({required this.item, required this.free, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(saleInvoiceProvider.notifier);
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      color: free
          ? const Color(0xFFF1F8F4)
          : index.isEven
              ? Colors.grey.shade50
              : Colors.white,
      child: Row(
        children: [
          _c('${index + 1}', flex: 1, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          _c(item.barcode, flex: 3, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                  if (free) const _B1g1Badge(),
                ],
              ),
            ),
          ),
          _c(item.sizeName, flex: 1),
          _c(item.colorName, flex: 2),
          _c(item.categoryName, flex: 2),
          _c(item.salePrice.toStringAsFixed(0),
              flex: 2,
              style: free
                  ? const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough)
                  : null),
          _c('${item.availableStock}',
              flex: 2,
              style: TextStyle(
                  fontSize: 12,
                  color: item.availableStock <= 0 ? Colors.red : Colors.grey.shade600)),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: free
                  ? Center(
                      child: Text('${item.b1g1FreeQty}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                    )
                  : _QtyRowStepper(
                      value: _paidQty(item),
                      maxValue: item.availableStock - item.b1g1FreeQty,
                      primaryColor: primary,
                      onChanged: (v) => _setPaidQty(notifier, item, v),
                    ),
            ),
          ),
          free
              ? _c('FREE',
                  flex: 2,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2E7D32)))
              : _c(item.lineTotal.toStringAsFixed(0), flex: 2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          Expanded(
            flex: 1,
            child: Center(
              child: IconButton(
                icon: const AppIcon(AppIcons.deleteOutline, size: 17, color: Colors.red),
                onPressed: () => free
                    ? notifier.updateItemQuantity(
                        item.branchStockId, item.quantity - item.b1g1FreeQty)
                    : notifier.removeItem(item.branchStockId),
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

/// Cart ki ek display row — B1G1 free units apni alag row mein.
typedef _RowEntry = ({SaleCartItem item, bool free});

List<_RowEntry> _cartRows(List<SaleCartItem> items) => [
      for (final i in items) ...[
        if (_paidQty(i) > 0) (item: i, free: false),
        if (i.b1g1FreeQty > 0) (item: i, free: true),
      ],
    ];

int _paidQty(SaleCartItem i) => i.quantity - i.b1g1FreeQty;

/// Paid row ka stepper — barhane par provider khud free unit jor deta hai;
/// ghatane par is line ka free unit bhi sath jata hai (jodi hi nikalti hai).
void _setPaidQty(SaleInvoiceNotifier notifier, SaleCartItem item, int paid) {
  final current = _paidQty(item);
  if (paid == current) return;
  final qty = paid > current
      ? item.quantity + (paid - current)
      : item.quantity - (current - paid) - (item.b1g1FreeQty > 0 ? 1 : 0);
  notifier.updateItemQuantity(item.branchStockId, qty);
}

// ── Qty stepper inside row ────────────────────────────────────────────────

class _QtyRowStepper extends StatelessWidget {
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
  Widget build(BuildContext context) => QtyStepper(
        value: value,
        max: maxValue,
        color: primaryColor,
        onChanged: onChanged,
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
            flex: 12, // 1+3+3+1+2+2
            child: Text('TOTALS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text(totalAmt.toStringAsFixed(0),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
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
    final notifier = ref.read(saleInvoiceProvider.notifier);
    final primary = Theme.of(context).colorScheme.primary;

    final rows = _cartRows(items);

    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final item = rows[i].item;
        final free = rows[i].free;
        return Card(
          color: free ? const Color(0xFFF1F8F4) : null,
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
                      icon: const AppIcon(AppIcons.deleteOutline, color: Colors.red, size: 18),
                      onPressed: () => free
                          ? notifier.updateItemQuantity(item.branchStockId,
                              item.quantity - item.b1g1FreeQty)
                          : notifier.removeItem(item.branchStockId),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('${item.productName} · ${item.sizeName} · ${item.colorName}',
                    style: const TextStyle(fontSize: 12)),
                if (free) const _B1g1Badge(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _lbl('S.Price', item.salePrice.toStringAsFixed(0)),
                    const SizedBox(width: 12),
                    _lbl('Stock', '${item.availableStock}',
                        color: item.availableStock <= 0 ? Colors.red : Colors.grey.shade700),
                    const Spacer(),
                    if (free)
                      Text('Qty ${item.b1g1FreeQty}',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700))
                    else
                      _QtyRowStepper(
                        value: _paidQty(item),
                        maxValue: item.availableStock - item.b1g1FreeQty,
                        primaryColor: primary,
                        onChanged: (v) => _setPaidQty(notifier, item, v),
                      ),
                    const SizedBox(width: 10),
                    Text(free ? 'FREE' : item.lineTotal.toStringAsFixed(0),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: free ? const Color(0xFF2E7D32) : primary)),
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

/// Free row par "Buy 1 Get 1 · Free" ka chhota label.
class _B1g1Badge extends StatelessWidget {
  const _B1g1Badge();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 3),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4EC),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('Buy 1 Get 1 · Free',
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E7D32))),
    );
  }
}
