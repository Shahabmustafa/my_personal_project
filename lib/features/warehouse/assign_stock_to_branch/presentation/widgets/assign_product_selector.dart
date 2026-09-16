import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../purchase_invoice/data/models/warehouse_stock_model.dart';
import '../providers/assign_stock_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/widget/text_field_icon.dart';

/// Ek hi searchable "Article" dropdown — har entry ek exact stock variant
/// (color/size/category/type ke sath) hai, is liye alag Size/Color/
/// Category/Type dropdowns ki zaroorat nahi.
class AssignProductSelector extends ConsumerStatefulWidget {
  const AssignProductSelector({super.key});

  @override
  ConsumerState<AssignProductSelector> createState() =>
      _AssignProductSelectorState();
}

class _AssignProductSelectorState
    extends ConsumerState<AssignProductSelector> {
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

  List<WarehouseStockModel> _filterStock(List<WarehouseStockModel> all, String query) {
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
        .read(assignStockProvider.notifier)
        .addCartItem(stock, quantity: safeQty);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const AppIcon(AppIcons.warningAmberRounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(error)),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return; // selector reset mat karo
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
    final stockAsync = ref.watch(assignWarehouseStockProvider);
    const primary = Color(0xFF1565C0);

    return stockAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
      data: (allStock) {
        final stock = _selectedStock;
        final totalQty = stock?.quantity ?? 0;
        final salePrice = stock?.salePrice ?? 0.0;
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
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _barcodeCtrl,
                          focusNode: _barcodeFocus,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Scan barcode...',
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: _barcodeNotFound ? Colors.red : Colors.grey.shade300),
                            ),
                            suffixIcon: _barcodeNotFound
                                ? const AppIcon(AppIcons.errorOutline, color: Colors.red, size: 18)
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
                      decoratorProps: DropDownDecoratorProps(decoration: _dropDecor('Article')),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        constraints: const BoxConstraints(maxHeight: 320),
                        searchFieldProps: const TextFieldProps(
                          decoration: InputDecoration(
                            hintText: 'Search article, color, size, category...',
                            prefixIcon: TextFieldIcon(AppIcons.search, size: 24),
                            isDense: true,
                          ),
                        ),
                        itemBuilder: (context, s, isSelected, isFocused) {
                          final variant = _variantLine(s);
                          return ListTile(
                            dense: true,
                            selected: isSelected,
                            title: Text(s.productName ?? s.productId,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            subtitle: Text(
                              variant.isEmpty ? 'Barcode: ${s.barcode}' : '$variant  •  Barcode: ${s.barcode}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                            trailing: Text('Qty ${s.quantity}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: s.quantity > 0 ? Colors.green.shade700 : Colors.red)),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Row 2: Info + Qty + Add ──────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _InfoBox(
                    label: 'Warehouse Stock',
                    value: stock != null ? '$totalQty pairs' : null,
                    valueColor: totalQty > 0 ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                  const SizedBox(width: 10),
                  _InfoBox(
                    label: 'Sale Price',
                    value: stock != null ? 'PKR ${salePrice.toStringAsFixed(0)}' : null,
                    valueColor: primary,
                  ),
                  const SizedBox(width: 10),
                  _InfoBox(
                    label: 'Discount',
                    value: stock != null ? '${discountPct.toStringAsFixed(0)}%' : null,
                    valueColor: Colors.orange.shade800,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 100,
                    child: _QtyStepperInput(
                      controller: _qtyCtrl,
                      enabled: stock != null && totalQty > 0,
                      primaryColor: primary,
                      onSubmit: (_) => _addToCart(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      icon: const AppIcon(AppIcons.addShoppingCart, size: 18),
                      label: const Text('Add Product'),
                      style: FilledButton.styleFrom(
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                      ),
                      onPressed: (stock != null && totalQty > 0) ? _addToCart : null,
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
        borderSide: BorderSide(color: enabled ? Colors.grey.shade300 : Colors.grey.shade200),
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

class _InfoBox extends StatelessWidget {
  final String label;
  final String? value;
  final Color? valueColor;

  const _InfoBox({required this.label, this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == null || value!.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        const SizedBox(height: 4),
        Container(
          width: 130,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            isEmpty ? '—' : value!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: (!isEmpty && valueColor != null) ? FontWeight.w600 : FontWeight.normal,
              color: isEmpty ? Colors.grey.shade400 : (valueColor ?? Colors.black87),
            ),
          ),
        ),
      ],
    );
  }
}

class _QtyStepperInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final Color primaryColor;
  final void Function(String) onSubmit;

  const _QtyStepperInput({
    required this.controller,
    required this.enabled,
    required this.primaryColor,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Quantity', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        const SizedBox(height: 4),
        SizedBox(
          height: 48,
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: enabled ? primaryColor : Colors.grey.shade400,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: !enabled,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
            ),
            onSubmitted: onSubmit,
          ),
        ),
      ],
    );
  }
}
