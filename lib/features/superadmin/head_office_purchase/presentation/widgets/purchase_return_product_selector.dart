import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/warehouse_stock_model.dart';
import '../providers/purchase_return_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/widget/text_field_icon.dart';

/// Ek hi searchable "Article" dropdown — har entry ek exact stock variant
/// (color/size/category/type ke sath) hai, is liye alag Size/Color/
/// Category/Type dropdowns ki zaroorat nahi.
class PurchaseReturnProductSelector extends ConsumerStatefulWidget {
  const PurchaseReturnProductSelector({super.key});

  @override
  ConsumerState<PurchaseReturnProductSelector> createState() =>
      _PurchaseReturnProductSelectorState();
}

class _PurchaseReturnProductSelectorState
    extends ConsumerState<PurchaseReturnProductSelector> {
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
    if (_selectedStock == null) return;
    final qty = int.tryParse(_qtyCtrl.text) ?? 1;
    ref
        .read(purchaseReturnProvider.notifier)
        .addCartItem(_selectedStock!, quantity: qty > 0 ? qty : 1);
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
    final stockAsync = ref.watch(returnWarehouseStockProvider);

    return stockAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
      data: (allStock) {
        final stock = _selectedStock;
        final totalQty = stock?.quantity ?? 0;
        final purchasePrice = stock?.purchasePrice ?? 0.0;
        final salePrice = stock?.salePrice ?? 0.0;
        final discountPct = stock?.discountPct ?? 0.0;
        final discountAmt = purchasePrice * discountPct / 100;
        final netPrice = purchasePrice - discountAmt;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── ROW 1: Barcode | Article ────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _barcodeCtrl,
                      focusNode: _barcodeFocus,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Bar Code',
                        hintText: 'Scan barcode...',
                        prefixIcon: const TextFieldIcon(AppIcons.qrCodeScanner, size: 12),
                        errorText: _barcodeNotFound ? 'Not found' : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.orange.shade200),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      ),
                      onSubmitted: (_) => _onBarcodeSubmit(allStock),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
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
                            prefixIcon: TextFieldIcon(AppIcons.search, size: 12),
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

              const SizedBox(height: 10),

              // ── ROW 2: S.Price | P.Price | T.Qty | Discount | Net | Qty | Add ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 2,
                    child: _InfoBox(
                      label: 'S.Price',
                      value: stock != null ? salePrice.toStringAsFixed(0) : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _InfoBox(
                      label: 'P.Price',
                      value: stock != null ? purchasePrice.toStringAsFixed(0) : null,
                      valueColor: Colors.purple.shade600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _InfoBox(
                      label: 'T.Quantity',
                      value: stock != null ? '$totalQty' : null,
                      valueColor:
                          (stock != null && totalQty == 0) ? Colors.red : Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: _InfoBox(
                      label: 'Discount',
                      value: stock != null
                          ? '${discountPct.toStringAsFixed(0)}%  (- ${discountAmt.toStringAsFixed(0)})'
                          : null,
                      valueColor: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _InfoBox(
                      label: 'Net Price',
                      value: stock != null ? netPrice.toStringAsFixed(0) : null,
                      valueColor: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _QtyStepperInput(
                    controller: _qtyCtrl,
                    enabled: stock != null,
                    primaryColor: Colors.orange.shade700,
                    onSubmit: (_) => _addToCart(),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      icon: const AppIcon(AppIcons.keyboardReturn, size: 18),
                      label: const Text('Add Return'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                      ),
                      onPressed: stock != null ? _addToCart : null,
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: enabled ? Colors.orange.shade200 : Colors.grey.shade200),
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
          width: double.infinity,
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
            overflow: TextOverflow.ellipsis,
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
          width: 64,
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
