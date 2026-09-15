import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasource/branch_transfer_cart_item.dart';
import '../providers/branch_transfer_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
class BranchTransferCartTable extends ConsumerWidget {
  const BranchTransferCartTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(branchTransferProvider).cartItems;

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
  final List<BranchTransferCartItem> items;
  const _DesktopTable({required this.items});

  static const _hs = TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white);
  static const _primary = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
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
  final BranchTransferCartItem item;
  final int index;
  const _CartRow({required this.item, required this.index});

  static const _primary = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(branchTransferProvider.notifier);

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
                primaryColor: _primary,
                onChanged: (v) => notifier.updateItemQuantity(item.stockId, v),
              ),
            ),
          ),
          _c(item.lineTotal.toStringAsFixed(0), flex: 2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          Expanded(
            flex: 1,
            child: Center(
              child: IconButton(
                icon: const AppIcon(AppIcons.deleteOutline, size: 17, color: Colors.red),
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
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(6),
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
  final List<BranchTransferCartItem> items;
  const _Footer({required this.items});

  @override
  Widget build(BuildContext context) {
    final totalQty = items.fold(0, (s, i) => s + i.quantity);
    final net = items.fold(0.0, (s, i) => s + i.lineTotal);
    const primary = Color(0xFF1565C0);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          const Expanded(
            flex: 13, // 1+3+3+1+2+2+2 (label spans up to S.Price)
            child: Text('TOTALS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ),
          Expanded(
            flex: 3,
            child: Text('$totalQty',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: primary)),
          ),
          Expanded(
            flex: 2,
            child: Text(net.toStringAsFixed(0),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: primary)),
          ),
          const Expanded(flex: 1, child: SizedBox()),
        ],
      ),
    );
  }
}

// ── Mobile list ───────────────────────────────────────────────────────────

class _MobileList extends ConsumerWidget {
  final List<BranchTransferCartItem> items;
  const _MobileList({required this.items});

  static const _primary = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(branchTransferProvider.notifier);

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
                      icon: const AppIcon(AppIcons.deleteOutline, color: Colors.red, size: 18),
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
                    _lbl('Stock', '${item.availableStock}',
                        color: item.availableStock <= 0 ? Colors.red : Colors.grey.shade700),
                    const Spacer(),
                    _QtyRowStepper(
                      value: item.quantity,
                      maxValue: item.availableStock,
                      primaryColor: _primary,
                      onChanged: (v) => notifier.updateItemQuantity(item.stockId, v),
                    ),
                    const SizedBox(width: 10),
                    Text(item.lineTotal.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _primary)),
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
