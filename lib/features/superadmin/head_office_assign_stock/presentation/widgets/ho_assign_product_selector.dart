import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../head_office_purchase/data/models/warehouse_stock_model.dart';
import '../providers/ho_assign_stock_provider.dart';

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
    return seen.values.toList()..sort((a, b) => a.name.compareTo(b.name));
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
    final safeQty = rawQty.clamp(1, stock.quantity > 0 ? stock.quantity : 1);

    final error = ref
        .read(hoAssignStockProvider.notifier)
        .addCartItem(stock, quantity: safeQty);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
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
    final stockAsync = ref.watch(hoAssignStockListProvider);
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
                                ? const Icon(Icons.error_outline,
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
                      icon: const Icon(Icons.add_shopping_cart, size: 18),
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
            prefixIcon: Icon(Icons.search, size: 18),
            isDense: true,
          ),
        ),
      ),
    );
  }
}

// ── Data classes ──────────────────────────────────────────────────────────

class _ProductItem {
  final String id;
  final String name;

  const _ProductItem({required this.id, required this.name});

  @override
  bool operator ==(Object other) => other is _ProductItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
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
/// changes so the −/+ buttons dim at their bounds and the field + "max N"
/// hint turn red when a typed value exceeds stock.
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
    final canDec = enabled && _value > 1;
    final canInc = enabled && _value < widget.max;

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
                  style:
                      TextStyle(fontSize: 11, color: Colors.grey.shade500)),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _btn(
                icon: Icons.remove_rounded,
                bg: canDec
                    ? color.withValues(alpha: 0.10)
                    : Colors.grey.shade100,
                fg: canDec ? color : Colors.grey.shade400,
                radius: const BorderRadius.horizontal(
                    left: Radius.circular(9)),
                onTap: canDec ? () => _setValue(_value - 1) : null,
              ),
              SizedBox(
                width: 58,
                child: TextField(
                  controller: widget.controller,
                  enabled: enabled,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
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
              _btn(
                icon: Icons.add_rounded,
                bg: canInc ? color : Colors.grey.shade100,
                fg: canInc ? Colors.white : Colors.grey.shade400,
                radius: const BorderRadius.horizontal(
                    right: Radius.circular(9)),
                onTap: canInc ? () => _setValue(_value + 1) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _btn({
    required IconData icon,
    required Color bg,
    required Color fg,
    required BorderRadius radius,
    required VoidCallback? onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          width: 42,
          height: double.infinity,
          decoration: BoxDecoration(color: bg, borderRadius: radius),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: fg),
        ),
      );
}
