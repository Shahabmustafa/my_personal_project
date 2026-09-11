import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../purchase_invoice/data/models/warehouse_stock_model.dart';
import '../providers/assign_stock_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
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
  _ProductItem? _selectedProduct;
  WarehouseStockModel? _selectedSizeStock;
  WarehouseStockModel? _selectedColorStock;
  WarehouseStockModel? _selectedCategoryStock;
  WarehouseStockModel? _selectedTypeStock;
  bool _barcodeNotFound = false;

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _barcodeFocus.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  List<_ProductItem> _buildProducts(List<WarehouseStockModel> all) {
    final seen = <String, _ProductItem>{};
    for (final s in all) {
      seen.putIfAbsent(
          s.productId,
          () => _ProductItem(
                id: s.productId,
                name: s.productName ?? s.productId,
              ));
    }
    return seen.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  List<WarehouseStockModel> _sizesFor(
      List<WarehouseStockModel> all, String productId) {
    final seen = <String, WarehouseStockModel>{};
    for (final s in all.where((s) => s.productId == productId)) {
      seen.putIfAbsent(s.sizeId, () => s);
    }
    return seen.values.toList()
      ..sort((a, b) => (a.sizeName ?? '').compareTo(b.sizeName ?? ''));
  }

  List<WarehouseStockModel> _colorsFor(
      List<WarehouseStockModel> all, String productId, String sizeId) {
    final seen = <String, WarehouseStockModel>{};
    for (final s in all
        .where((s) => s.productId == productId && s.sizeId == sizeId)) {
      seen.putIfAbsent(s.colorId, () => s);
    }
    return seen.values.toList();
  }

  List<WarehouseStockModel> _categoriesFor(List<WarehouseStockModel> all,
      String productId, String sizeId, String colorId) {
    final seen = <String, WarehouseStockModel>{};
    for (final s in all.where((s) =>
        s.productId == productId &&
        s.sizeId == sizeId &&
        s.colorId == colorId)) {
      seen.putIfAbsent(s.categoryId, () => s);
    }
    return seen.values.toList();
  }

  List<WarehouseStockModel> _typesFor(List<WarehouseStockModel> all,
      String productId, String sizeId, String colorId, String categoryId) {
    final seen = <String, WarehouseStockModel>{};
    for (final s in all.where((s) =>
        s.productId == productId &&
        s.sizeId == sizeId &&
        s.colorId == colorId &&
        s.categoryId == categoryId)) {
      seen.putIfAbsent(s.typeId, () => s);
    }
    return seen.values.toList();
  }

  WarehouseStockModel? _findStock(
      List<WarehouseStockModel> all,
      String productId,
      String sizeId,
      String colorId,
      String categoryId,
      String typeId) {
    try {
      return all.firstWhere((s) =>
          s.productId == productId &&
          s.sizeId == sizeId &&
          s.colorId == colorId &&
          s.categoryId == categoryId &&
          s.typeId == typeId);
    } catch (_) {
      return null;
    }
  }

  void _onBarcodeSubmit(List<WarehouseStockModel> allStock) {
    final barcode = _barcodeCtrl.text.trim();
    if (barcode.isEmpty) return;
    try {
      final stock = allStock.firstWhere((s) => s.barcode == barcode);
      setState(() {
        _barcodeNotFound = false;
        _selectedStock = stock;
        _selectedProduct = _ProductItem(
            id: stock.productId, name: stock.productName ?? stock.productId);
        _selectedSizeStock = stock;
        _selectedColorStock = stock;
        _selectedCategoryStock = stock;
        _selectedTypeStock = stock;
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
    // ✅ qty ko clamp karo max stock ke andar
    final safeQty = rawQty.clamp(1, stock.quantity > 0 ? stock.quantity : 1);

    // ✅ addCartItem ab String? return karta hai — null = success
    final error = ref
        .read(assignStockProvider.notifier)
        .addCartItem(stock, quantity: safeQty);

    if (error != null) {
      // Validation fail — orange snackbar dikhao
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
      return; // selector reset mat karo
    }

    // Success — selector reset karo
    _barcodeCtrl.clear();
    _qtyCtrl.text = '1';
    setState(() {
      _selectedStock = null;
      _selectedProduct = null;
      _selectedSizeStock = null;
      _selectedColorStock = null;
      _selectedCategoryStock = null;
      _selectedTypeStock = null;
      _barcodeNotFound = false;
    });
    _barcodeFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final stockAsync = ref.watch(assignWarehouseStockProvider);
    const primary = Color(0xFF1565C0);

    return stockAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) =>
          Text('Error: $e', style: const TextStyle(color: Colors.red)),
      data: (allStock) {
        final products = _buildProducts(allStock);

        final sizes = _selectedProduct != null
            ? _sizesFor(allStock, _selectedProduct!.id)
            : <WarehouseStockModel>[];

        final colors =
            (_selectedProduct != null && _selectedSizeStock != null)
                ? _colorsFor(allStock, _selectedProduct!.id,
                    _selectedSizeStock!.sizeId)
                : <WarehouseStockModel>[];

        final categories = (_selectedProduct != null &&
                _selectedSizeStock != null &&
                _selectedColorStock != null)
            ? _categoriesFor(allStock, _selectedProduct!.id,
                _selectedSizeStock!.sizeId, _selectedColorStock!.colorId)
            : <WarehouseStockModel>[];

        final types = (_selectedProduct != null &&
                _selectedSizeStock != null &&
                _selectedColorStock != null &&
                _selectedCategoryStock != null)
            ? _typesFor(
                allStock,
                _selectedProduct!.id,
                _selectedSizeStock!.sizeId,
                _selectedColorStock!.colorId,
                _selectedCategoryStock!.categoryId)
            : <WarehouseStockModel>[];

        // ✅ FIX: build() mein direct assign hata diya —
        // ab _selectedStock sirf onSelected aur barcode mein set hota hai.

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
              // ── Row 1: Barcode + Dropdowns ──────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Barcode
                  SizedBox(
                    width: 180,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Barcode',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500)),
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

                  // Product
                  Expanded(
                    flex: 3,
                    child: _dd<_ProductItem>(
                      label: 'Article',
                      items: products,
                      selected: _selectedProduct,
                      itemAsString: (p) => p.name,
                      compareFn: (a, b) => a.id == b.id,
                      enabled: true,
                      onSelected: (p) {
                        setState(() {
                          _selectedProduct = p;
                          _selectedSizeStock = null;
                          _selectedColorStock = null;
                          _selectedCategoryStock = null;
                          _selectedTypeStock = null;
                          _selectedStock = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Size
                  Expanded(
                    flex: 2,
                    child: _dd<WarehouseStockModel>(
                      label: 'Size',
                      items: sizes,
                      selected: _selectedSizeStock,
                      itemAsString: (s) => s.sizeName ?? '',
                      compareFn: (a, b) => a.sizeId == b.sizeId,
                      enabled: _selectedProduct != null,
                      onSelected: (s) {
                        setState(() {
                          _selectedSizeStock = s;
                          _selectedColorStock = null;
                          _selectedCategoryStock = null;
                          _selectedTypeStock = null;
                          _selectedStock = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Color
                  Expanded(
                    flex: 2,
                    child: _dd<WarehouseStockModel>(
                      label: 'Color',
                      items: colors,
                      selected: _selectedColorStock,
                      itemAsString: (s) => s.colorName ?? '',
                      compareFn: (a, b) => a.colorId == b.colorId,
                      enabled: _selectedSizeStock != null,
                      onSelected: (s) {
                        setState(() {
                          _selectedColorStock = s;
                          _selectedCategoryStock = null;
                          _selectedTypeStock = null;
                          _selectedStock = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Category
                  Expanded(
                    flex: 2,
                    child: _dd<WarehouseStockModel>(
                      label: 'Category',
                      items: categories,
                      selected: _selectedCategoryStock,
                      itemAsString: (s) => s.categoryName ?? '',
                      compareFn: (a, b) => a.categoryId == b.categoryId,
                      enabled: _selectedColorStock != null,
                      onSelected: (s) {
                        setState(() {
                          _selectedCategoryStock = s;
                          _selectedTypeStock = null;
                          _selectedStock = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),

                  // ✅ FIX: Type onSelected mein ab _findStock call hota hai
                  // taa ke _selectedStock immediately set ho jaye setState ke andar
                  Expanded(
                    flex: 2,
                    child: _dd<WarehouseStockModel>(
                      label: 'Type',
                      items: types,
                      selected: _selectedTypeStock,
                      itemAsString: (s) => s.typeName ?? '',
                      compareFn: (a, b) => a.typeId == b.typeId,
                      enabled: _selectedCategoryStock != null,
                      onSelected: (s) {
                        setState(() {
                          _selectedTypeStock = s;
                          // ✅ Immediately resolve stock inside setState
                          if (s != null &&
                              _selectedProduct != null &&
                              _selectedSizeStock != null &&
                              _selectedColorStock != null &&
                              _selectedCategoryStock != null) {
                            _selectedStock = _findStock(
                              allStock,
                              _selectedProduct!.id,
                              _selectedSizeStock!.sizeId,
                              _selectedColorStock!.colorId,
                              _selectedCategoryStock!.categoryId,
                              s.typeId,
                            );
                          } else {
                            _selectedStock = null;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Row 2: Info + Qty + Add ──────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // In Stock info
                  _InfoBox(
                    label: 'Warehouse Stock',
                    value: stock != null ? '$totalQty pairs' : null,
                    valueColor: totalQty > 0
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                  const SizedBox(width: 10),
                  _InfoBox(
                    label: 'Sale Price',
                    value: stock != null
                        ? 'PKR ${salePrice.toStringAsFixed(0)}'
                        : null,
                    valueColor: primary,
                  ),
                  const SizedBox(width: 10),
                  _InfoBox(
                    label: 'Discount',
                    value: stock != null
                        ? '${discountPct.toStringAsFixed(0)}%'
                        : null,
                    valueColor: Colors.orange.shade800,
                  ),
                  const Spacer(),

                  // ✅ Qty stepper — stock 0 ho to disable, max = warehouse qty
                  SizedBox(
                    width: 140,
                    child: _QtyStepperInput(
                      controller: _qtyCtrl,
                      enabled: stock != null && totalQty > 0,
                      max: totalQty,
                      primaryColor: primary,
                      onSubmit: (_) => _addToCart(),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // ✅ Add button — stock 0 ho to disable
                  SizedBox(
                    height: 48,
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

  Widget _dd<T>({
    required String label,
    required List<T> items,
    required T? selected,
    required String Function(T) itemAsString,
    required bool Function(T, T) compareFn,
    required bool enabled,
    required void Function(T?) onSelected,
  }) {
    return DropdownSearch<T>(
      items: (filter, _) => items
          .where((i) =>
              itemAsString(i).toLowerCase().contains(filter.toLowerCase()))
          .toList(),
      selectedItem: selected,
      itemAsString: itemAsString,
      compareFn: compareFn,
      enabled: enabled,
      onSelected: onSelected,
      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
                color: enabled
                    ? Colors.grey.shade300
                    : Colors.grey.shade200),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          filled: !enabled,
          fillColor: Colors.grey.shade50,
        ),
      ),
      popupProps: PopupProps.menu(
        showSearchBox: true,
        constraints: const BoxConstraints(maxHeight: 240),
        searchFieldProps: const TextFieldProps(
          decoration: InputDecoration(
            hintText: 'Search...',
            prefixIcon: AppIcon(AppIcons.search, size: 18),
            isDense: true,
          ),
        ),
      ),
    );
  }

  InputDecoration _dropDecor(String label, {bool enabled = true}) {
    return InputDecoration(
      labelText: label,
      border:
          OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
            color:
                enabled ? Colors.grey.shade300 : Colors.grey.shade200),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      filled: !enabled,
      fillColor: Colors.grey.shade50,
    );
  }
}

// ── Data classes ──────────────────────────────────────────────────────────

class _ProductItem {
  final String id;
  final String name;

  const _ProductItem({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      other is _ProductItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// ── Info Box ──────────────────────────────────────────────────────────────

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
        Text(label,
            style:
                TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        const SizedBox(height: 4),
        Container(
          width: 130,
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            isEmpty ? '—' : value!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: (!isEmpty && valueColor != null)
                  ? FontWeight.w600
                  : FontWeight.normal,
              color: isEmpty
                  ? Colors.grey.shade400
                  : (valueColor ?? Colors.black87),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Qty Stepper Input ─────────────────────────────────────────────────────

class _QtyStepperInput extends StatelessWidget {
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

  void _inc() {
    final v = int.tryParse(controller.text) ?? 0;
    if (v < max) controller.text = '${v + 1}';
  }

  void _dec() {
    final v = int.tryParse(controller.text) ?? 2;
    if (v > 1) controller.text = '${v - 1}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Quantity',
            style:
                TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        const SizedBox(height: 4),
        Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled
                  ? primaryColor.withOpacity(0.5)
                  : Colors.grey.shade200,
            ),
            color: enabled ? Colors.white : Colors.grey.shade50,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _btn(
                icon: AppIcons.remove,
                color: enabled
                    ? primaryColor.withOpacity(0.08)
                    : Colors.grey.shade100,
                iconColor: enabled ? primaryColor : Colors.grey.shade400,
                radius: const BorderRadius.horizontal(
                    left: Radius.circular(7)),
                onTap: enabled ? _dec : null,
              ),
              SizedBox(
                width: 48,
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: enabled
                        ? primaryColor
                        : Colors.grey.shade400,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 13),
                  ),
                  onSubmitted: onSubmit,
                ),
              ),
              _btn(
                icon: AppIcons.add,
                color: enabled ? primaryColor : Colors.grey.shade100,
                iconColor:
                    enabled ? Colors.white : Colors.grey.shade400,
                radius: const BorderRadius.horizontal(
                    right: Radius.circular(7)),
                onTap: enabled ? _inc : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _btn({
    required String icon,
    required Color color,
    required Color iconColor,
    required BorderRadius radius,
    required VoidCallback? onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          width: 36,
          height: double.infinity,
          decoration: BoxDecoration(color: color, borderRadius: radius),
          alignment: Alignment.center,
          child: AppIcon(icon, size: 16, color: iconColor),
        ),
      );
}
