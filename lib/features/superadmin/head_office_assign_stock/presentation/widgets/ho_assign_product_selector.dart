import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../head_office_purchase/data/models/warehouse_stock_model.dart';
import '../providers/ho_assign_stock_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/widget/text_field_icon.dart';

/// Ek hi searchable "Article" dropdown — har entry ek exact stock variant
/// (color/size/category/type ke sath) hai, is liye alag Size/Color/
/// Category/Type dropdowns ki zaroorat nahi.
class HoAssignProductSelector extends ConsumerStatefulWidget {
  const HoAssignProductSelector({super.key});

  @override
  ConsumerState<HoAssignProductSelector> createState() =>
      _HoAssignProductSelectorState();
}

class _HoAssignProductSelectorState
    extends ConsumerState<HoAssignProductSelector> {
  final _barcodeCtrl = TextEditingController();
  final _barcodeFocus = FocusNode();
  final _qtyCtrl = TextEditingController(text: '1');

  WarehouseStockModel? _selectedStock;
  bool _barcodeNotFound = false;

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _barcodeFocus.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  List<WarehouseStockModel> _filterStock(
      List<WarehouseStockModel> all, String query) {
    if (query.trim().isEmpty) return all;
    final q = query.toLowerCase();
    return all.where((s) {
      final haystack = [
        s.productName ?? '',
        s.colorName ?? '',
        s.sizeName ?? '',
        s.categoryName ?? '',
        s.typeName ?? '',
        s.barcode,
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  String _variantLine(WarehouseStockModel s) {
    final parts = [
      if ((s.colorName ?? '').isNotEmpty) s.colorName!,
      if ((s.sizeName ?? '').isNotEmpty) 'Size ${s.sizeName!}',
      if ((s.categoryName ?? '').isNotEmpty) s.categoryName!,
      if ((s.typeName ?? '').isNotEmpty) s.typeName!,
    ];
    return parts.join(' • ');
  }

  void _onBarcodeSubmit(List<WarehouseStockModel> allStock) {
    final barcode = _barcodeCtrl.text.trim();
    if (barcode.isEmpty) return;
    try {
      final stock = allStock.firstWhere((s) => s.barcode == barcode);
      setState(() {
        _barcodeNotFound = false;
        _selectedStock = stock;
      });
    } catch (_) {
      setState(() {
        _barcodeNotFound = true;
        _selectedStock = null;
      });
    }
  }

  void _addToCart() {
    final stock = _selectedStock;
    if (stock == null) return;

    final rawQty = int.tryParse(_qtyCtrl.text) ?? 1;
    final safeQty = rawQty.clamp(1, stock.quantity > 0 ? stock.quantity : 1);

    final error = ref
        .read(hoAssignStockProvider.notifier)
        .addCartItem(stock, quantity: safeQty);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const AppIcon(AppIcons.warningAmberRounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(error)),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    _barcodeCtrl.clear();
    _qtyCtrl.text = '1';
    setState(() {
      _selectedStock = null;
      _barcodeNotFound = false;
    });
    _barcodeFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final stockAsync = ref.watch(hoAssignStockListProvider);
    const primary = Color(0xFF1565C0);

    return stockAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) =>
          Text('Error: $e', style: const TextStyle(color: Colors.red)),
      data: (allStock) {
        final stock = _selectedStock;
        final totalQty = stock?.quantity ?? 0;
        final salePrice = stock?.salePrice ?? 0.0;
        final purchasePrice = stock?.purchasePrice ?? 0.0;
        final discountPct = stock?.discountPct ?? 0.0;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: Barcode + Article ─────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 180,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Barcode',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _barcodeCtrl,
                          focusNode: _barcodeFocus,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Scan barcode...',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: _barcodeNotFound
                                      ? Colors.red
                                      : Colors.grey.shade300),
                            ),
                            suffixIcon: _barcodeNotFound
                                ? const AppIcon(AppIcons.errorOutline,
                                    color: Colors.red, size: 18)
                                : null,
                          ),
                          onSubmitted: (_) => _onBarcodeSubmit(allStock),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownSearch<WarehouseStockModel>(
                      items: (f, _) => _filterStock(allStock, f),
                      selectedItem: _selectedStock,
                      itemAsString: (s) {
                        final variant = _variantLine(s);
                        final name = s.productName ?? s.productId;
                        return variant.isEmpty ? name : '$name — $variant';
                      },
                      compareFn: (a, b) =>
                          a.productId == b.productId &&
                          a.sizeId == b.sizeId &&
                          a.colorId == b.colorId &&
                          a.categoryId == b.categoryId &&
                          a.typeId == b.typeId,
                      onSelected: (s) => setState(() {
                        _selectedStock = s;
                        _barcodeCtrl.clear();
                        _barcodeNotFound = false;
                      }),
                      decoratorProps:
                          DropDownDecoratorProps(decoration: _dropDecor('Article')),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        constraints: const BoxConstraints(maxHeight: 320),
                        searchFieldProps: const TextFieldProps(
                          decoration: InputDecoration(
                            hintText: 'Search article, color, size, category...',
                            prefixIcon: TextFieldIcon(AppIcons.search, size: 9),
                            isDense: true,
                          ),
                        ),
                        itemBuilder: (context, s, isSelected, isFocused) {
                          final variant = _variantLine(s);
                          return ListTile(
                            dense: true,
                            selected: isSelected,
                            title: Text(s.productName ?? s.productId,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                            subtitle: Text(
                              variant.isEmpty
                                  ? 'Barcode: ${s.barcode}'
                                  : '$variant  •  Barcode: ${s.barcode}',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                            trailing: Text('Qty ${s.quantity}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: s.quantity > 0
                                        ? Colors.green.shade700
                                        : Colors.red)),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 18,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        _MiniStat(
                          label: 'Head Office Stock',
                          value: stock != null ? '$totalQty pairs' : '—',
                          color: totalQty > 0
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                        _MiniStat(
                          label: 'Purchase Price',
                          value: stock != null
                              ? 'PKR ${purchasePrice.toStringAsFixed(0)}'
                              : '—',
                          color: Colors.blueGrey.shade700,
                        ),
                        _MiniStat(
                          label: 'Sale Price',
                          value: stock != null
                              ? 'PKR ${salePrice.toStringAsFixed(0)}'
                              : '—',
                          color: primary,
                        ),
                        _MiniStat(
                          label: 'Discount',
                          value: stock != null
                              ? '${discountPct.toStringAsFixed(0)}%'
                              : '—',
                          color: Colors.orange.shade800,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 208,
                    child: _QtyStepperInput(
                      controller: _qtyCtrl,
                      enabled: stock != null && totalQty > 0,
                      max: totalQty,
                      primaryColor: primary,
                      onSubmit: (_) => _addToCart(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 46,
                    child: FilledButton.icon(
                      icon: const AppIcon(AppIcons.addShoppingCart, size: 18),
                      label: const Text('Add Product'),
                      style: FilledButton.styleFrom(
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 0),
                      ),
                      onPressed:
                          (stock != null && totalQty > 0) ? _addToCart : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  InputDecoration _dropDecor(String label, {bool enabled = true}) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            BorderSide(color: enabled ? Colors.grey.shade300 : Colors.grey.shade200),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      filled: !enabled,
      fillColor: Colors.grey.shade50,
    );
  }
}

// ── Mini stat ─────────────────────────────────────────────────────────────

/// Compact label + value pair. Replaces the old tall bordered info boxes so
/// stock / price / discount fit on one row beside the quantity input, leaving
/// more vertical room for the cart below.
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == '—';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isEmpty ? Colors.grey.shade400 : color,
          ),
        ),
      ],
    );
  }
}

// ── Qty Stepper Input ─────────────────────────────────────────────────────

/// Quantity picker for "how many pairs to assign". Rebuilds as the value
/// changes so the field + "max N" hint turn red when a typed value exceeds
/// stock.
class _QtyStepperInput extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final int max;
  final Color primaryColor;
  final void Function(String) onSubmit;

  const _QtyStepperInput({
    required this.controller,
    required this.enabled,
    required this.max,
    required this.primaryColor,
    required this.onSubmit,
  });

  @override
  State<_QtyStepperInput> createState() => _QtyStepperInputState();
}

class _QtyStepperInputState extends State<_QtyStepperInput> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  int get _value => int.tryParse(widget.controller.text) ?? 0;
  int get _maxOr1 => widget.max < 1 ? 1 : widget.max;

  void _setValue(int v) {
    final safe = v.clamp(1, _maxOr1);
    widget.controller.text = '$safe';
    widget.controller.selection =
        TextSelection.collapsed(offset: widget.controller.text.length);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    final color = widget.primaryColor;
    final over = _value > widget.max;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 16,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Quantity to assign',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              if (enabled) ...[
                const SizedBox(width: 6),
                Text(over ? 'only ${widget.max} in stock' : 'max ${widget.max}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: over ? Colors.red.shade600 : color)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: !enabled
                  ? Colors.grey.shade200
                  : over
                      ? Colors.red
                      : color.withValues(alpha: 0.5),
              width: 1.4,
            ),
            color: enabled ? Colors.white : Colors.grey.shade50,
          ),
          child: TextField(
            controller: widget.controller,
            enabled: enabled,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: !enabled
                  ? Colors.grey.shade400
                  : over
                      ? Colors.red
                      : color,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 13),
            ),
            onSubmitted: widget.onSubmit,
            onTapOutside: (_) {
              if (!enabled) return;
              if (_value < 1 || _value > widget.max) {
                _setValue(_value);
              }
            },
          ),
        ),
      ],
    );
  }
}
