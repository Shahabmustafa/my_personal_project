import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safishoe_app/core/widget/qty_stepper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/warehouse_stock_model.dart';
import '../providers/purchase_invoice_provider.dart';
import '../../../head_office_stock/presentation/widgets/add_stock_inventory_dialog.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/widget/text_field_icon.dart';
import 'package:safishoe_app/core/utils/responsive.dart';

/// Ek hi searchable "Article" dropdown — har entry ek exact stock variant
/// (color/size/category/type ke sath) hai, is liye alag Size/Color/
/// Category/Type dropdowns ki zaroorat nahi.
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
  final _expenseCtrl = TextEditingController();
  final _expenseFocus = FocusNode();
  final _pPriceCtrl = TextEditingController();
  final _sPriceCtrl = TextEditingController();

  WarehouseStockModel? _selectedStock;
  bool _barcodeNotFound = false;

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _barcodeFocus.dispose();
    _qtyCtrl.dispose();
    _expenseCtrl.dispose();
    _expenseFocus.dispose();
    _pPriceCtrl.dispose();
    _sPriceCtrl.dispose();
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
      _fillPrices(stock);
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

  /// Article chunte hi uski purchase / sale price fields mein — badal sakte ho.
  void _fillPrices(WarehouseStockModel s) {
    _pPriceCtrl.text = _fmt(s.purchasePrice);
    _sPriceCtrl.text = _fmt(s.salePrice);
  }

  static String _fmt(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 2);

  void _addToCart() {
    if (_selectedStock == null) return;
    // Pehle expense — taa ke har article ki purchase price usi hisaab se bane.
    if (ref.read(purchaseInvoiceProvider).expense == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Enter the Expense first (0 if none).'),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
      ));
      _expenseFocus.requestFocus();
      return;
    }
    final qty = int.tryParse(_qtyCtrl.text) ?? 1;
    ref.read(purchaseInvoiceProvider.notifier).addCartItem(
          _selectedStock!,
          quantity: qty > 0 ? qty : 1,
          purchasePrice: double.tryParse(_pPriceCtrl.text.trim()),
          salePrice: double.tryParse(_sPriceCtrl.text.trim()),
        );
    _barcodeCtrl.clear();
    _qtyCtrl.text = '1';
    _pPriceCtrl.clear();
    _sPriceCtrl.clear();
    setState(() {
      _selectedStock = null;
      _barcodeNotFound = false;
    });
    _barcodeFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final stockAsync = ref.watch(warehouseStockCacheProvider);
    final companiesAsync = ref.watch(purchaseCompaniesProvider);
    final invoiceState = ref.watch(purchaseInvoiceProvider);
    final primary = Theme.of(context).colorScheme.primary;
    // Nayi invoice (reset) par expense field bhi khali.
    ref.listen(purchaseInvoiceProvider.select((s) => s.expense), (_, next) {
      if (next == null && _expenseCtrl.text.isNotEmpty) _expenseCtrl.clear();
    });

    return stockAsync.when(
      // Realtime reload par purani list dikhti rahe — spinner/focus loss nahi.
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
      data: (allStock) {
        // Taza list se selected article — purchase/return/assign ke baad qty purani na rahe.
        final sel = _selectedStock;
        final stock = _selectedStock = sel == null
            ? null
            : allStock.firstWhere((s) => s.id == sel.id, orElse: () => sel);
        final totalQty = stock?.quantity ?? 0;
        final isMobile = Responsive(context).isMobile;

        final companyDropdown = companiesAsync.when(
          loading: () => const SizedBox(
              height: 48, child: Center(child: LinearProgressIndicator())),
          error: (e, _) => Text('Error: $e',
              style: const TextStyle(color: Colors.red, fontSize: 12)),
          data: (companies) => DropdownSearch<StockLookupItem>(
            items: (filter, _) => companies
                .where((c) =>
                    c.label.toLowerCase().contains(filter.toLowerCase()))
                .toList(),
            selectedItem: invoiceState.selectedCompany,
            itemAsString: (c) => c.label,
            compareFn: (a, b) => a.id == b.id,
            onSelected: (c) =>
                ref.read(purchaseInvoiceProvider.notifier).selectCompany(c),
            decoratorProps:
                DropDownDecoratorProps(decoration: _dropDecor('Company')),
            popupProps: PopupProps.menu(
              fit: FlexFit.loose,
              showSearchBox: true,
              constraints: const BoxConstraints(maxHeight: 260),
              searchFieldProps: const TextFieldProps(
                decoration: InputDecoration(
                  hintText: 'Search company...',
                  prefixIcon: TextFieldIcon(AppIcons.search, size: 24),
                  isDense: true,
                ),
              ),
            ),
          ),
        );

        final barcodeField = TextField(
          controller: _barcodeCtrl,
          focusNode: _barcodeFocus,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Bar Code',
            hintText: 'Scan barcode...',
            prefixIcon: const TextFieldIcon(AppIcons.qrCodeScanner, size: 24),
            errorText: _barcodeNotFound ? 'Not found' : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
          onSubmitted: (_) => _onBarcodeSubmit(allStock),
        );

        final articleDropdown = DropdownSearch<WarehouseStockModel>(
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
            if (s != null) _fillPrices(s);
            _selectedStock = s;
            _barcodeCtrl.clear();
            _barcodeNotFound = false;
          }),
          decoratorProps: DropDownDecoratorProps(decoration: _dropDecor('Article')),
          popupProps: PopupProps.menu(
            fit: FlexFit.loose,
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
        );

        // Poori invoice ka kharcha — articles se pehle; sab articles ki
        // purchase price mein bat jata hai.
        final expenseField = TextField(
          controller: _expenseCtrl,
          focusNode: _expenseFocus,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
          ],
          decoration: InputDecoration(
            labelText: 'Expense *',
            hintText: '0',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
          onChanged: (v) => ref
              .read(purchaseInvoiceProvider.notifier)
              .setExpense(v.trim().isEmpty ? null : double.tryParse(v.trim())),
        );

        final pPriceBox = _PriceField(
          label: 'P.Price',
          controller: _pPriceCtrl,
          enabled: stock != null,
          color: Colors.purple.shade600,
          onSubmit: (_) => _addToCart(),
        );
        final sPriceBox = _PriceField(
          label: 'S.Price',
          controller: _sPriceCtrl,
          enabled: stock != null,
          onSubmit: (_) => _addToCart(),
        );
        final tQtyBox = _InfoBox(
          label: 'T.Quantity',
          value: stock != null ? '$totalQty' : null,
          valueColor:
              (stock != null && totalQty == 0) ? Colors.red : Colors.green.shade700,
        );
        final qtyStepper = _QtyStepperInput(
          controller: _qtyCtrl,
          enabled: stock != null,
          primaryColor: primary,
          onSubmit: (_) => _addToCart(),
        );
        final addButton = FilledButton.icon(
          icon: const AppIcon(AppIcons.addShoppingCart, size: 18),
          label: const Text('Add Product'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF43A047),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
          ),
          onPressed: stock != null ? _addToCart : null,
        );
        final stockButton = OutlinedButton.icon(
          icon: AppIcon(AppIcons.inventory2Outlined, size: 18, color: primary),
          label: const Text('Stock Inventory'),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          ),
          onPressed: _openAddStock,
        );

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
              // ── ROW 1: Company | Barcode | Article ──────────────────────
              isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        companyDropdown,
                        const SizedBox(height: 10),
                        barcodeField,
                        const SizedBox(height: 10),
                        articleDropdown,
                        const SizedBox(height: 10),
                        expenseField,
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: companyDropdown),
                        const SizedBox(width: 10),
                        Expanded(flex: 2, child: barcodeField),
                        const SizedBox(width: 10),
                        Expanded(flex: 3, child: articleDropdown),
                        const SizedBox(width: 10),
                        Expanded(flex: 1, child: expenseField),
                      ],
                    ),

              const SizedBox(height: 10),

              // ── ROW 2: P.Price | S.Price | T.Qty | Qty | Add ──
              isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(child: pPriceBox),
                            const SizedBox(width: 10),
                            Expanded(child: sPriceBox),
                            const SizedBox(width: 10),
                            Expanded(child: tQtyBox),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            qtyStepper,
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: addButton,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 48,
                          width: double.infinity,
                          child: stockButton,
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(flex: 2, child: pPriceBox),
                        const SizedBox(width: 10),
                        Expanded(flex: 2, child: sPriceBox),
                        const SizedBox(width: 10),
                        Expanded(flex: 2, child: tQtyBox),
                        const SizedBox(width: 10),
                        qtyStepper,
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 48,
                          child: addButton,
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 48,
                          child: stockButton,
                        ),
                      ],
                    ),
            ],
          ),
        );
      },
    );
  }

  /// Article inventory mein na ho to yahin se Stock Inventory mein add —
  /// dialog band hone par Article dropdown taza list ke sath.
  Future<void> _openAddStock() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AddStockInventoryDialog(),
    );
    if (mounted) ref.invalidate(warehouseStockCacheProvider);
  }

  InputDecoration _dropDecor(String label, {bool enabled = true}) {
    return InputDecoration(
      labelText: label,
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

/// Label ke neeche editable price — [_InfoBox] jaisi shakal.
class _PriceField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final Color? color;
  final ValueChanged<String> onSubmit;

  const _PriceField({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.onSubmit,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        const SizedBox(height: 4),
        SizedBox(
          height: 48,
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
            ],
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color ?? Colors.black87),
            decoration: InputDecoration(
              hintText: '—',
              isDense: true,
              filled: !enabled,
              fillColor: Colors.grey.shade50,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            onSubmitted: onSubmit,
          ),
        ),
      ],
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
          width: 132,
          child: QtyStepperField(
            controller: controller,
            enabled: enabled,
            color: primaryColor,
            height: 48,
            onSubmitted: onSubmit,
          ),
        ),
      ],
    );
  }
}
