import 'package:flutter/material.dart';
import 'package:safishoe_app/core/widget/qty_stepper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/sale_exchange_model.dart';
import '../provider/sale_exchange_provider.dart';

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
            child: Text(
                item.alreadyReturned > 0
                    ? 'Sold: ${item.soldQuantity} · Left: ${item.maxQuantity}'
                    : 'Sold: ${item.soldQuantity}',
                style: TextStyle(
                    fontSize: 12,
                    color: item.maxQuantity == 0
                        ? Colors.red.shade400
                        : Colors.grey.shade600)),
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

class _QtyStepper extends StatelessWidget {
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
  Widget build(BuildContext context) => QtyStepper(
        value: value,
        max: maxValue,
        color: primaryColor,
        onChanged: onChanged,
      );
}
