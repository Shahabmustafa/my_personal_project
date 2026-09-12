import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/warehouse_stock_model.dart';
import '../providers/purchase_invoice_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/widget/text_field_icon.dart';
class PurchaseProductSelector extends ConsumerStatefulWidget {
  const PurchaseProductSelector({super.key});

  @override
  ConsumerState<PurchaseProductSelector> createState() =>
      _PurchaseProductSelectorState();
}

class _PurchaseProductSelectorState
    extends ConsumerState<PurchaseProductSelector> {
  final _barcodeCtrl = TextEditingController();
  final _barcodeFocus = FocusNode();
  final _qtyCtrl = TextEditingController(text: '1');

  WarehouseStockModel? _selectedStock;
  _ProductItem? _selectedProduct;
  WarehouseStockModel? _selectedSizeStock;
  WarehouseStockModel? _selectedColorStock;
  WarehouseStockModel? _selectedTypeStock;
  WarehouseStockModel? _selectedCategoryStock;
  bool _barcodeNotFound = false;

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _barcodeFocus.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  // ── Build unique product list ─────────────────────────────────────────────

  List<_ProductItem> _buildProducts(List<WarehouseStockModel> all) {
    final seen = <String, _ProductItem>{};
    for (final s in all) {
      seen.putIfAbsent(
          s.productId,
          () => _ProductItem(
                id: s.productId,
                name: s.productName ?? s.productId,
                salePrice: s.salePrice,
                purchasePrice: s.purchasePrice,
              ));
    }
    return seen.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  // ── Cascade helpers ───────────────────────────────────────────────────────

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
    for (final s
        in all.where((s) => s.productId == productId && s.sizeId == sizeId)) {
      seen.putIfAbsent(s.colorId, () => s);
    }
    return seen.values.toList();
  }

  List<WarehouseStockModel> _categoriesFor(
      List<WarehouseStockModel> all,
      String productId,
      String sizeId,
      String colorId) {
    final seen = <String, WarehouseStockModel>{};
    for (final s in all.where((s) =>
        s.productId == productId &&
        s.sizeId == sizeId &&
        s.colorId == colorId)) {
      seen.putIfAbsent(s.categoryId, () => s);
    }
    return seen.values.toList();
  }

  List<WarehouseStockModel> _typesFor(
      List<WarehouseStockModel> all,
      String productId,
      String sizeId,
      String colorId,
      String categoryId) {
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

  // ── Barcode submit ────────────────────────────────────────────────────────

  void _onBarcodeSubmit(List<WarehouseStockModel> allStock) {
    final barcode = _barcodeCtrl.text.trim();
    if (barcode.isEmpty) return;
    try {
      final stock = allStock.firstWhere((s) => s.barcode == barcode);
      setState(() {
        _barcodeNotFound = false;
        _selectedStock = stock;
        _selectedProduct = _ProductItem(
          id: stock.productId,
          name: stock.productName ?? stock.productId,
          salePrice: stock.salePrice,
          purchasePrice: stock.purchasePrice,
        );
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

  // ── Add to cart ───────────────────────────────────────────────────────────

  void _addToCart() {
    if (_selectedStock == null) return;
    final qty = int.tryParse(_qtyCtrl.text) ?? 1;
    ref
        .read(purchaseInvoiceProvider.notifier)
        .addCartItem(_selectedStock!, quantity: qty > 0 ? qty : 1);
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
    final stockAsync = ref.watch(warehouseStockCacheProvider);
    final primary = Theme.of(context).colorScheme.primary;

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

        // Resolve final stock
        if (_selectedProduct != null &&
            _selectedSizeStock != null &&
            _selectedColorStock != null &&
            _selectedCategoryStock != null &&
            _selectedTypeStock != null &&
            _selectedStock == null) {
          _selectedStock = _findStock(
            allStock,
            _selectedProduct!.id,
            _selectedSizeStock!.sizeId,
            _selectedColorStock!.colorId,
            _selectedCategoryStock!.categoryId,
            _selectedTypeStock!.typeId,
          );
        }

        final stock = _selectedStock;
        final totalQty = stock?.quantity ?? 0;
        final salePrice = stock?.salePrice ?? 0.0;
        final purchasePrice = stock?.purchasePrice ?? 0.0;
        final discountPct = stock?.discountPct ?? 0.0;
        final discountAmt = salePrice * discountPct / 100;
        final netPrice = salePrice - discountAmt;

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
              // ── ROW 1: Barcode | Product | Size | Color | Category | Type ─
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barcode
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _barcodeCtrl,
                      focusNode: _barcodeFocus,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Bar Code',
                        hintText: 'Scan barcode...',
                        prefixIcon: const TextFieldIcon(AppIcons.qrCodeScanner, size: 14),
                        errorText:
                            _barcodeNotFound ? 'Not found' : null,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 12),
                      ),
                      onSubmitted: (_) => _onBarcodeSubmit(allStock),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Product
                  Expanded(
                    flex: 3,
                    child: DropdownSearch<_ProductItem>(
                      items: (f, _) => products
                          .where((p) => p.name
                              .toLowerCase()
                              .contains(f.toLowerCase()))
                          .toList(),
                      selectedItem: _selectedProduct,
                      itemAsString: (p) => p.name,
                      compareFn: (a, b) => a.id == b.id,
                      onSelected: (p) => setState(() {
                        _selectedProduct = p;
                        _selectedSizeStock = null;
                        _selectedColorStock = null;
                        _selectedCategoryStock = null;
                        _selectedTypeStock = null;
                        _selectedStock = null;
                        _barcodeCtrl.clear();
                        _barcodeNotFound = false;
                      }),
                      decoratorProps: DropDownDecoratorProps(
                          decoration: _dropDecor('Product')),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        constraints:
                            const BoxConstraints(maxHeight: 260),
                        searchFieldProps: const TextFieldProps(
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            prefixIcon: TextFieldIcon(AppIcons.search, size: 14),
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Size
                  Expanded(
                    flex: 2,
                    child: DropdownSearch<WarehouseStockModel>(
                      enabled: _selectedProduct != null,
                      items: (f, _) => sizes
                          .where((s) => (s.sizeName ?? '')
                              .toLowerCase()
                              .contains(f.toLowerCase()))
                          .toList(),
                      selectedItem: _selectedSizeStock,
                      itemAsString: (s) => s.sizeName ?? s.sizeId,
                      compareFn: (a, b) => a.sizeId == b.sizeId,
                      onSelected: (s) => setState(() {
                        _selectedSizeStock = s;
                        _selectedColorStock = null;
                        _selectedCategoryStock = null;
                        _selectedTypeStock = null;
                        _selectedStock = null;
                      }),
                      decoratorProps: DropDownDecoratorProps(
                          decoration: _dropDecor('Size',
                              enabled: _selectedProduct != null)),
                      popupProps: const PopupProps.menu(
                          constraints: BoxConstraints(maxHeight: 260)),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Color
                  Expanded(
                    flex: 2,
                    child: DropdownSearch<WarehouseStockModel>(
                      enabled: _selectedProduct != null &&
                          _selectedSizeStock != null,
                      items: (f, _) => colors
                          .where((s) => (s.colorName ?? '')
                              .toLowerCase()
                              .contains(f.toLowerCase()))
                          .toList(),
                      selectedItem: _selectedColorStock,
                      itemAsString: (s) => s.colorName ?? s.colorId,
                      compareFn: (a, b) => a.colorId == b.colorId,
                      onSelected: (s) => setState(() {
                        _selectedColorStock = s;
                        _selectedCategoryStock = null;
                        _selectedTypeStock = null;
                        _selectedStock = null;
                      }),
                      decoratorProps: DropDownDecoratorProps(
                          decoration: _dropDecor('Color',
                              enabled: _selectedProduct != null &&
                                  _selectedSizeStock != null)),
                      popupProps: const PopupProps.menu(
                          constraints: BoxConstraints(maxHeight: 260)),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Category
                  Expanded(
                    flex: 2,
                    child: DropdownSearch<WarehouseStockModel>(
                      enabled: _selectedProduct != null &&
                          _selectedSizeStock != null &&
                          _selectedColorStock != null,
                      items: (f, _) => categories
                          .where((s) => (s.categoryName ?? '')
                              .toLowerCase()
                              .contains(f.toLowerCase()))
                          .toList(),
                      selectedItem: _selectedCategoryStock,
                      itemAsString: (s) =>
                          s.categoryName ?? s.categoryId,
                      compareFn: (a, b) =>
                          a.categoryId == b.categoryId,
                      onSelected: (s) => setState(() {
                        _selectedCategoryStock = s;
                        _selectedTypeStock = null;
                        _selectedStock = null;
                      }),
                      decoratorProps: DropDownDecoratorProps(
                          decoration: _dropDecor('Category',
                              enabled: _selectedProduct != null &&
                                  _selectedSizeStock != null &&
                                  _selectedColorStock != null)),
                      popupProps: const PopupProps.menu(
                          constraints: BoxConstraints(maxHeight: 260)),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Type
                  Expanded(
                    flex: 2,
                    child: DropdownSearch<WarehouseStockModel>(
                      enabled: _selectedProduct != null &&
                          _selectedSizeStock != null &&
                          _selectedColorStock != null &&
                          _selectedCategoryStock != null,
                      items: (f, _) => types
                          .where((s) => (s.typeName ?? '')
                              .toLowerCase()
                              .contains(f.toLowerCase()))
                          .toList(),
                      selectedItem: _selectedTypeStock,
                      itemAsString: (s) => s.typeName ?? s.typeId,
                      compareFn: (a, b) => a.typeId == b.typeId,
                      onSelected: (s) => setState(() {
                        _selectedTypeStock = s;
                        _selectedStock = null;
                      }),
                      decoratorProps: DropDownDecoratorProps(
                          decoration: _dropDecor('Type',
                              enabled: _selectedProduct != null &&
                                  _selectedSizeStock != null &&
                                  _selectedColorStock != null &&
                                  _selectedCategoryStock != null)),
                      popupProps: const PopupProps.menu(
                          constraints: BoxConstraints(maxHeight: 260)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── ROW 2: S.Price | P.Price | T.Qty | Discount | Net | Qty | Add ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // S.Price
                  Expanded(
                    flex: 2,
                    child: _InfoBox(
                      label: 'S.Price',
                      value: stock != null
                          ? salePrice.toStringAsFixed(0)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // P.Price
                  Expanded(
                    flex: 2,
                    child: _InfoBox(
                      label: 'P.Price',
                      value: stock != null
                          ? purchasePrice.toStringAsFixed(0)
                          : null,
                      valueColor: Colors.purple.shade600,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // T.Quantity
                  Expanded(
                    flex: 2,
                    child: _InfoBox(
                      label: 'T.Quantity',
                      value: stock != null ? '$totalQty' : null,
                      valueColor: (stock != null && totalQty == 0)
                          ? Colors.red
                          : Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Discount
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

                  // Net Price
                  Expanded(
                    flex: 2,
                    child: _InfoBox(
                      label: 'Net Price',
                      value: stock != null
                          ? netPrice.toStringAsFixed(0)
                          : null,
                      valueColor: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Quantity stepper
                  _QtyStepperInput(
                    controller: _qtyCtrl,
                    enabled: stock != null,
                    primaryColor: primary,
                    onSubmit: (_) => _addToCart(),
                  ),
                  const SizedBox(width: 10),

                  // Add Product button
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      icon:
                          const AppIcon(AppIcons.addShoppingCart, size: 18),
                      label: const Text('Add Product'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF43A047),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 0),
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
    );
  }
}

// ── Data classes ──────────────────────────────────────────────────────────

class _ProductItem {
  final String id;
  final String name;
  final double salePrice;
  final double purchasePrice;

  const _ProductItem({
    required this.id,
    required this.name,
    required this.salePrice,
    required this.purchasePrice,
  });

  @override
  bool operator ==(Object other) =>
      other is _ProductItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// ── Read-only info box ────────────────────────────────────────────────────

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
          width: double.infinity,
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
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Quantity stepper ──────────────────────────────────────────────────────

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

  void _inc() {
    final v = int.tryParse(controller.text) ?? 0;
    controller.text = '${v + 1}';
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
              InkWell(
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(7)),
                onTap: enabled ? _dec : null,
                child: Container(
                  width: 36,
                  height: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: enabled
                        ? primaryColor.withOpacity(0.08)
                        : Colors.grey.shade100,
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(7)),
                  ),
                  child: AppIcon(AppIcons.remove,
                      size: 16,
                      color: enabled
                          ? primaryColor
                          : Colors.grey.shade400),
                ),
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
                    color:
                        enabled ? primaryColor : Colors.grey.shade400,
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
              InkWell(
                borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(7)),
                onTap: enabled ? _inc : null,
                child: Container(
                  width: 36,
                  height: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                        enabled ? primaryColor : Colors.grey.shade100,
                    borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(7)),
                  ),
                  child: AppIcon(AppIcons.add,
                      size: 16,
                      color: enabled
                          ? Colors.white
                          : Colors.grey.shade400),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
