import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/purchase_invoice_model.dart';
import '../providers/purchase_invoice_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
class PurchaseCartTable extends ConsumerWidget {
  const PurchaseCartTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(purchaseInvoiceProvider).cartItems;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(AppIcons.shoppingCartOutlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Products is Empty',
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
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
  final List<PurchaseCartItem> items;
  const _DesktopTable({required this.items});

  static const _hs = TextStyle(
      fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        // ── Header ──────────────────────────────────────────────────────
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
            _h('Type', flex: 2),
            _h('Category', flex: 2),
            _h('S.Price', flex: 2),
            _h('P.Price', flex: 2),
            _h('Disc%', flex: 2),
            _h('Net Price', flex: 2),
            _h('Qty', flex: 3),
            _h('Total', flex: 2),
            _h('', flex: 1),
          ]),
        ),
        // ── Rows ────────────────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) => _CartRow(item: items[i], index: i),
          ),
        ),
        // ── Footer ──────────────────────────────────────────────────────
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

class _CartRow extends ConsumerStatefulWidget {
  final PurchaseCartItem item;
  final int index;
  const _CartRow({required this.item, required this.index});

  @override
  ConsumerState<_CartRow> createState() => _CartRowState();
}

class _CartRowState extends ConsumerState<_CartRow> {
  late TextEditingController _priceCtrl;
  late TextEditingController _ppCtrl;
  late TextEditingController _discCtrl;
  late TextEditingController _qtyCtrl;

  @override
  void initState() {
    super.initState();
    _priceCtrl =
        TextEditingController(text: widget.item.salePrice.toStringAsFixed(0));
    _ppCtrl = TextEditingController(
        text: widget.item.purchasePrice.toStringAsFixed(0));
    _discCtrl = TextEditingController(
        text: widget.item.discountPct.toStringAsFixed(0));
    _qtyCtrl =
        TextEditingController(text: widget.item.quantity.toString());
  }

  @override
  void didUpdateWidget(_CartRow old) {
    super.didUpdateWidget(old);
    if (old.item.salePrice != widget.item.salePrice)
      _priceCtrl.text = widget.item.salePrice.toStringAsFixed(0);
    if (old.item.purchasePrice != widget.item.purchasePrice)
      _ppCtrl.text = widget.item.purchasePrice.toStringAsFixed(0);
    if (old.item.discountPct != widget.item.discountPct)
      _discCtrl.text = widget.item.discountPct.toStringAsFixed(0);
    if (old.item.quantity != widget.item.quantity)
      _qtyCtrl.text = widget.item.quantity.toString();
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _ppCtrl.dispose();
    _discCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final notifier = ref.read(purchaseInvoiceProvider.notifier);
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      color: widget.index.isEven ? Colors.grey.shade50 : Colors.white,
      child: Row(
        children: [
          // #
          _c('${widget.index + 1}',
              flex: 1,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          // Barcode
          _c(item.barcode,
              flex: 3,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
          // Article
          _c(item.productName, flex: 3),
          // Size
          _c(item.sizeName, flex: 1),
          // Color
          _c(item.colorName, flex: 2),
          // Type
          _c(item.typeName, flex: 2),
          // Category
          _c(item.categoryName, flex: 2),

          // S.Price editable
          Expanded(
            flex: 2,
            child: _EditField(
              controller: _priceCtrl,
              onCommit: (v) {
                final p = double.tryParse(v);
                if (p != null && p >= 0)
                  notifier.updateItemSalePrice(item.stockId, p);
              },
            ),
          ),

          // P.Price editable
          Expanded(
            flex: 2,
            child: _EditField(
              controller: _ppCtrl,
              textColor: Colors.purple.shade600,
              onCommit: (v) {
                final p = double.tryParse(v);
                if (p != null && p >= 0)
                  notifier.updateItemPurchasePrice(item.stockId, p);
              },
            ),
          ),

          // Disc% editable
          Expanded(
            flex: 2,
            child: _EditField(
              controller: _discCtrl,
              suffix: '%',
              onCommit: (v) {
                final d = double.tryParse(v);
                if (d != null && d >= 0 && d <= 100)
                  notifier.updateItemDiscount(item.stockId, d);
              },
            ),
          ),

          // Net Price (purchase price - discount)
          _c(item.purchaseNetPrice.toStringAsFixed(0),
              flex: 2,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700)),

          // Qty stepper
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: _QtyRowStepper(
                value: item.quantity,
                primaryColor: primary,
                onChanged: (v) => notifier.updateItemQuantity(item.stockId, v),
              ),
            ),
          ),

          // Total (purchasePrice * qty - discount)
          _c(item.purchaseLineTotal.toStringAsFixed(0),
              flex: 2,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700)),

          // Delete
          Expanded(
            flex: 1,
            child: Center(
              child: IconButton(
                icon: const AppIcon(AppIcons.deleteOutline,
                    size: 17, color: Colors.red),
                onPressed: () => notifier.removeItem(item.stockId),
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
      child: Text(text,
          overflow: TextOverflow.ellipsis,
          style: style ?? const TextStyle(fontSize: 12)),
    ),
  );
}

// ── Inline edit field ─────────────────────────────────────────────────────

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String? suffix;
  final Color? textColor;
  final void Function(String) onCommit;

  const _EditField(
      {required this.controller,
        required this.onCommit,
        this.suffix,
        this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 12,
            color: textColor ?? Colors.black87),
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary, width: 1.5),
          ),
          suffixText: suffix,
          suffixStyle:
          const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        onSubmitted: onCommit,
        onTapOutside: (_) => onCommit(controller.text),
      ),
    );
  }
}

// ── Qty stepper inside row ────────────────────────────────────────────────

class _QtyRowStepper extends StatefulWidget {
  final int value;
  final Color primaryColor;
  final void Function(int) onChanged;

  const _QtyRowStepper({
    required this.value,
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
    if (old.value != widget.value) {
      _ctrl.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _commit() {
    final v = int.tryParse(_ctrl.text) ?? widget.value;
    widget.onChanged(v > 0 ? v : 1);
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
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final List<PurchaseCartItem> items;
  const _Footer({required this.items});

  @override
  Widget build(BuildContext context) {
    final totalQty = items.fold(0, (s, i) => s + i.quantity);
    // Purchase invoice: company ko purchasePrice pay karte hain
    final totalAmt = items.fold(0.0, (s, i) => s + i.purchasePrice * i.quantity);
    final totalDisc = items.fold(0.0, (s, i) => s + i.purchaseDiscountAmount * i.quantity);
    final net = items.fold(0.0, (s, i) => s + i.purchaseLineTotal);
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius:
        const BorderRadius.vertical(bottom: Radius.circular(10)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          // label spanning first 7 cols (#, Barcode, Article, Size, Color, Type, Category)
          const Expanded(
            flex: 14, // 1+3+3+1+2+2+2
            child: Text('TOTALS',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ),
          // S.Price total
          Expanded(
            flex: 2,
            child: Text(totalAmt.toStringAsFixed(0),
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12)),
          ),
          // P.Price (empty)
          const Expanded(flex: 2, child: SizedBox()),
          // Disc total
          Expanded(
            flex: 2,
            child: Text('- ${totalDisc.toStringAsFixed(0)}',
                style: TextStyle(
                    fontSize: 12, color: Colors.orange.shade700)),
          ),
          // Net price (empty)
          Expanded(
            flex: 2,
            child: Text(net.toStringAsFixed(0),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700)),
          ),
          // Qty total
          Expanded(
            flex: 3,
            child: Text('$totalQty',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: primary)),
          ),
          // Net total
          Expanded(
            flex: 2,
            child: Text(net.toStringAsFixed(0),
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: primary)),
          ),
          const Expanded(flex: 1, child: SizedBox()),
        ],
      ),
    );
  }
}

// ── Mobile list ───────────────────────────────────────────────────────────

class _MobileList extends ConsumerWidget {
  final List<PurchaseCartItem> items;
  const _MobileList({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(purchaseInvoiceProvider.notifier);
    final primary = Theme.of(context).colorScheme.primary;

    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final item = items[i];
        return Card(
          elevation: 1,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                fontFamily: 'monospace'))),
                    IconButton(
                      icon: const AppIcon(AppIcons.deleteOutline,
                          color: Colors.red, size: 18),
                      onPressed: () => notifier.removeItem(item.stockId),
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
                    _lbl('P.Price', item.purchasePrice.toStringAsFixed(0),
                        color: Colors.purple.shade600),
                    const Spacer(),
                    _QtyRowStepper(
                      value: item.quantity,
                      primaryColor: primary,
                      onChanged: (v) =>
                          notifier.updateItemQuantity(item.stockId, v),
                    ),
                    const SizedBox(width: 10),
                    Text(item.purchaseLineTotal.toStringAsFixed(0),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: primary)),
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
            style: TextStyle(
                color: color ?? Colors.black87,
                fontWeight: FontWeight.w600)),
      ],
    ),
  );
}