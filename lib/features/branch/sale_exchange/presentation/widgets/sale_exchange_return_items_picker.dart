import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/sale_exchange_model.dart';
import '../provider/sale_exchange_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
/// Selected invoice ki lines dikhata hai — har line par checkbox + qty
/// stepper (max = us line ki original sold quantity). Cashier jo lines
/// opt-in karega wahi customer se wapas li ja rahi hain.
class SaleExchangeReturnItemsPicker extends ConsumerWidget {
  const SaleExchangeReturnItemsPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(saleExchangeProvider).returnCartItems;
    final primary = Theme.of(context).colorScheme.primary;

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: Text('This invoice has no items', style: TextStyle(color: Colors.grey.shade500)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Text('Items being returned',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey.shade700)),
          ),
          ...items.map((item) => _ReturnItemRow(item: item, primary: primary)),
        ],
      ),
    );
  }
}

class _ReturnItemRow extends ConsumerWidget {
  final ReturnCartItem item;
  final Color primary;
  const _ReturnItemRow({required this.item, required this.primary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(saleExchangeProvider.notifier);
    final selected = item.quantity > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            onChanged: item.maxQuantity > 0
                ? (v) => notifier.toggleReturnItem(item.originalItemId, v ?? false)
                : null,
          ),
          Expanded(
            flex: 3,
            child: Text(item.productName,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 2,
            child: Text('${item.sizeName} · ${item.colorName}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 2,
            child: Text('Sold: ${item.maxQuantity}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ),
          Expanded(
            flex: 2,
            child: Text('Rs. ${item.salePrice.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          SizedBox(
            width: 120,
            child: selected
                ? _QtyStepper(
                    value: item.quantity,
                    maxValue: item.maxQuantity,
                    primaryColor: primary,
                    onChanged: (v) => notifier.setReturnQuantity(item.originalItemId, v),
                  )
                : const SizedBox(),
          ),
          SizedBox(
            width: 80,
            child: Text(
              selected ? 'Rs. ${item.lineTotal.toStringAsFixed(0)}' : '—',
              textAlign: TextAlign.end,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.red.shade700 : Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatefulWidget {
  final int value;
  final int maxValue;
  final Color primaryColor;
  final void Function(int) onChanged;

  const _QtyStepper({
    required this.value,
    required this.maxValue,
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
    final v = int.tryParse(_ctrl.text) ?? widget.value;
    final capped = v.clamp(1, widget.maxValue <= 0 ? 1 : widget.maxValue);
    widget.onChanged(capped);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.primaryColor;
    return Container(
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              final v = int.tryParse(_ctrl.text) ?? 1;
              if (v > 1) {
                _ctrl.text = '${v - 1}';
                widget.onChanged(v - 1);
              }
            },
            child: Container(
              width: 28,
              height: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color.withOpacity(0.08)),
              child: AppIcon(AppIcons.remove, size: 14, color: color),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _commit(),
              onTapOutside: (_) => _commit(),
            ),
          ),
          InkWell(
            onTap: () {
              final v = int.tryParse(_ctrl.text) ?? 0;
              final next = v + 1;
              if (widget.maxValue <= 0 || next <= widget.maxValue) {
                _ctrl.text = '$next';
                widget.onChanged(next);
              }
            },
            child: Container(
              width: 28,
              height: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color),
              child: const AppIcon(AppIcons.add, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
