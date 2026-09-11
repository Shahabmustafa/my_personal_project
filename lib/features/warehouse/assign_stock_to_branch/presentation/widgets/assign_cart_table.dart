import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/assign_stock_model.dart';
import '../providers/assign_stock_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
class AssignCartTable extends ConsumerWidget {
  const AssignCartTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(assignStockProvider).cartItems;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(AppIcons.localShippingOutlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No Products Added',
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('Scan a barcode or select a product to assign',
                style:
                    TextStyle(color: Colors.grey.shade400, fontSize: 13)),
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
  final List<AssignCartItem> items;
  const _DesktopTable({required this.items});

  static const _hs = TextStyle(
      fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const headerColor = Color(0xFF1565C0); // blue — assign ka theme

    return Column(
      children: [
        // Header
        Container(
          decoration: const BoxDecoration(
            color: headerColor,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Row(children: [
            _h('#', flex: 1),
            _h('Barcode', flex: 3),
            _h('Article', flex: 3),
            _h('Size', flex: 1),
            _h('Color', flex: 2),
            _h('Type', flex: 2),
            _h('Category', flex: 2),
            _h('Sale Price', flex: 2),
            _h('Discount', flex: 2),
            _h('In Stock', flex: 2),
            _h('Qty to Send', flex: 3),
            _h('', flex: 1),
          ]),
        ),
        // Rows
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) => _AssignRow(item: items[i], index: i),
          ),
        ),
        // Footer
        _Footer(items: items),
      ],
    );
  }

  Widget _h(String t, {int flex = 2}) => Expanded(
        flex: flex,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          child: Text(t, style: _hs),
        ),
      );
}

// ── Row ───────────────────────────────────────────────────────────────────

class _AssignRow extends ConsumerStatefulWidget {
  final AssignCartItem item;
  final int index;
  const _AssignRow({required this.item, required this.index});

  @override
  ConsumerState<_AssignRow> createState() => _AssignRowState();
}

class _AssignRowState extends ConsumerState<_AssignRow> {
  late TextEditingController _qtyCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl =
        TextEditingController(text: widget.item.quantity.toString());
  }

  @override
  void didUpdateWidget(_AssignRow old) {
    super.didUpdateWidget(old);
    if (old.item.quantity != widget.item.quantity) {
      _qtyCtrl.text = widget.item.quantity.toString();
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final notifier = ref.read(assignStockProvider.notifier);
    const primary = Color(0xFF1565C0);

    return Container(
      color: widget.index.isEven ? Colors.grey.shade50 : Colors.white,
      child: Row(
        children: [
          _c('${widget.index + 1}',
              flex: 1,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          _c(item.barcode,
              flex: 3,
              style:
                  const TextStyle(fontSize: 11, fontFamily: 'monospace')),
          _c(item.productName, flex: 3),
          _c(item.sizeName, flex: 1),
          _c(item.colorName, flex: 2),
          _c(item.typeName, flex: 2),
          _c(item.categoryName, flex: 2),
          // Sale Price
          _c(item.salePrice.toStringAsFixed(0),
              flex: 2,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700)),
          // Discount
          _c(item.discount > 0 ? '${item.discount.toStringAsFixed(0)}%' : '—',
              flex: 2,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade800)),
          // In Stock (available)
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.warehouseStock > 0
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: item.warehouseStock > 0
                        ? Colors.green.shade200
                        : Colors.red.shade200,
                  ),
                ),
                child: Text(
                  '${item.warehouseStock}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: item.warehouseStock > 0
                          ? Colors.green.shade700
                          : Colors.red.shade700),
                ),
              ),
            ),
          ),
          // Qty stepper
          Expanded(
            flex: 3,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: _QtyStepper(
                value: item.quantity,
                max: item.warehouseStock,
                primaryColor: primary,
                onChanged: (v) =>
                    notifier.updateItemQuantity(item.stockId, v),
              ),
            ),
          ),
          // Delete
          Expanded(
            flex: 1,
            child: IconButton(
              icon: const AppIcon(AppIcons.deleteOutline,
                  color: Colors.red, size: 18),
              onPressed: () => notifier.removeItem(item.stockId),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _c(String text, {int flex = 2, TextStyle? style}) => Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Text(text,
              style: style ??
                  const TextStyle(fontSize: 12, color: Colors.black87),
              overflow: TextOverflow.ellipsis),
        ),
      );
}

// ── Qty Stepper ───────────────────────────────────────────────────────────

class _QtyStepper extends StatefulWidget {
  final int value;
  final int max;
  final Color primaryColor;
  final ValueChanged<int> onChanged;

  const _QtyStepper({
    required this.value,
    required this.max,
    required this.primaryColor,
    required this.onChanged,
  });

  @override
  State<_QtyStepper> createState() => _QtyStepperState();
}

class _QtyStepperState extends State<_QtyStepper> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(_QtyStepper old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _ctrl.text = widget.value.toString();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _commit() {
    final v = int.tryParse(_ctrl.text) ?? 1;
    final safe = v.clamp(1, widget.max);
    _ctrl.text = safe.toString();
    widget.onChanged(safe);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.primaryColor;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          _btn(
            icon: AppIcons.remove,
            color: color.withOpacity(0.08),
            iconColor: color,
            radius: const BorderRadius.horizontal(left: Radius.circular(5)),
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
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color),
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
            icon: AppIcons.add,
            color: color,
            iconColor: Colors.white,
            radius:
                const BorderRadius.horizontal(right: Radius.circular(5)),
            onTap: () {
              final v = int.tryParse(_ctrl.text) ?? 0;
              if (v < widget.max) {
                _ctrl.text = '${v + 1}';
                widget.onChanged(v + 1);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _btn({
    required String icon,
    required Color color,
    required Color iconColor,
    required BorderRadius radius,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          width: 28,
          height: double.infinity,
          decoration: BoxDecoration(color: color, borderRadius: radius),
          alignment: Alignment.center,
          child: AppIcon(icon, size: 14, color: iconColor),
        ),
      );
}

// ── Footer ────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final List<AssignCartItem> items;
  const _Footer({required this.items});

  @override
  Widget build(BuildContext context) {
    final totalQty = items.fold(0, (s, i) => s + i.quantity);
    const primary = Color(0xFF1565C0);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFE3F2FD),
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(10)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          const Expanded(
            flex: 17, // 1+3+3+1+2+2+2+2+ discount(2)
            child: Text('TOTALS',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12)),
          ),
          // In Stock (skip)
          const Expanded(flex: 2, child: SizedBox()),
          // Qty total
          Expanded(
            flex: 3,
            child: Text(
              '$totalQty pairs',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: primary),
            ),
          ),
          const Expanded(flex: 1, child: SizedBox()),
        ],
      ),
    );
  }
}

// ── Mobile list ───────────────────────────────────────────────────────────

class _MobileList extends ConsumerWidget {
  final List<AssignCartItem> items;
  const _MobileList({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(assignStockProvider.notifier);
    const primary = Color(0xFF1565C0);

    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final item = items[i];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
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
                Text(
                    '${item.productName} · ${item.sizeName} · ${item.colorName}',
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _lbl('In Stock', '${item.warehouseStock}',
                        color: Colors.green.shade700),
                    const SizedBox(width: 12),
                    _lbl('S.Price',
                        item.salePrice.toStringAsFixed(0)),
                    const SizedBox(width: 12),
                    _lbl('Discount',
                        item.discount > 0
                            ? '${item.discount.toStringAsFixed(0)}%'
                            : '—',
                        color: Colors.orange.shade800),
                    const Spacer(),
                    _QtyStepper(
                      value: item.quantity,
                      max: item.warehouseStock,
                      primaryColor: primary,
                      onChanged: (v) =>
                          notifier.updateItemQuantity(item.stockId, v),
                    ),
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
