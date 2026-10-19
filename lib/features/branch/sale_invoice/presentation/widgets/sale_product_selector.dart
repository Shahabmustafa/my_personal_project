import 'package:flutter/material.dart';
import 'package:safishoe_app/core/utils/responsive.dart';
import 'package:safishoe_app/core/widget/qty_stepper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../branch_stock_inventory/data/model/branch_stock_model.dart';
import '../provider/sale_invoice_provider.dart';
import '../shortcuts/sale_invoice_shortcuts.dart';
import 'package:safishoe_app/core/widget/keyboard_dropdown.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/widget/text_field_icon.dart';

/// Ek hi searchable "Article" dropdown — har entry ek exact stock variant
/// (color/size/category/type ke sath) hai, is liye alag Size/Color/
/// Category/Type dropdowns ki zaroorat nahi. Search karte hi neeche list
/// mein har variant apne color/size/category/type ke sath dikhta hai,
/// jo chahiye wahi select kar lo.
///
/// Default mein sale invoice ke cart mein add karta hai; Sale Exchange
/// apna [onAdd] (new items cart) aur [buttonLabel] deta hai.
class SaleProductSelector extends ConsumerStatefulWidget {
  /// Cart mein add karo — kitna asal mein add hua wo return karo.
  final int Function(WidgetRef ref, BranchStockModel stock, int quantity)? onAdd;
  final String buttonLabel;
  /// Bar Code se pehle isi row mein dikhne wale fields (jaise exchange ka
  /// Salesman / Printer) — har ek ko Expanded(flex: 3) milta hai.
  final List<Widget> leading;

  /// Sale Invoice screen par barcode/article ke neeche shortcut hint.
  final bool showShortcutHints;

  const SaleProductSelector({
    super.key,
    this.showShortcutHints = false,
    this.onAdd,
    this.buttonLabel = 'Add Product',
    this.leading = const [],
  });

  @override
  ConsumerState<SaleProductSelector> createState() =>
      _SaleProductSelectorState();
}

class _SaleProductSelectorState extends ConsumerState<SaleProductSelector> {
  final _barcodeCtrl = TextEditingController();
  final _barcodeFocus = FocusNode();
  final _qtyFocus = FocusNode();
  final _articleKey = GlobalKey<KeyboardDropdownState<BranchStockModel>>();
  bool _focusedOnce = false;
  final _qtyCtrl = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    // Qty badalte hi Add button enable/disable ho.
    _qtyCtrl.addListener(_onQtyChanged);
  }

  void _onQtyChanged() {
    if (mounted) setState(() {});
  }

  /// Add tabhi jab 1..stock ke beech ho — stock se zyada par button off.
  bool _qtyFits(int max) {
    final q = int.tryParse(_qtyCtrl.text) ?? 0;
    return q >= 1 && q <= max;
  }

  BranchStockModel? _selectedStock;
  bool _barcodeNotFound = false;

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _barcodeFocus.dispose();
    _qtyFocus.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  /// Article dropdown ki search — product name ke sath color/size/category/
  /// type/barcode se bhi match ho jaye, taaki "Red" ya "42" jaise search se
  /// bhi seedha sahi variant mil jaye.
  List<BranchStockModel> _filterStock(List<BranchStockModel> all, String query) {
    final available = all.where((s) => s.quantity > 0);
    if (query.trim().isEmpty) return available.toList();
    final q = query.toLowerCase();
    return available.where((s) {
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

  String _variantLine(BranchStockModel s) {
    final parts = [
      if ((s.colorName ?? '').isNotEmpty) s.colorName!,
      if ((s.sizeName ?? '').isNotEmpty) 'Size ${s.sizeName!}',
      if ((s.categoryName ?? '').isNotEmpty) s.categoryName!,
      if ((s.typeName ?? '').isNotEmpty) s.typeName!,
    ];
    return parts.join(' • ');
  }

  void _onBarcodeSubmit(List<BranchStockModel> allStock) {
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

  /// Article chunte hi cursor quantity mein, value select — Enter se cart mein.
  void _focusQty() {
    // Dropdown band hone / qty field enable hone ke baad (focus wapas
    // dropdown par na chala jaye).
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      final stock = _selectedStock;
      if (stock == null || stock.quantity <= 0) return;
      _qtyFocus.requestFocus();
      _qtyCtrl.selection =
          TextSelection(baseOffset: 0, extentOffset: _qtyCtrl.text.length);
    });
  }

  void _addToCart() {
    final stock = _selectedStock;
    if (stock == null) return;
    final requested = int.tryParse(_qtyCtrl.text) ?? 1;

    if (stock.quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${stock.productName ?? 'Item'} is out of stock'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final qty = requested > 0 ? requested : 1;
    final added = widget.onAdd != null
        ? widget.onAdd!(ref, stock, qty)
        : ref.read(saleInvoiceProvider.notifier).addCartItem(stock, quantity: qty);

    if (added < requested) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(added <= 0
            ? 'Only ${stock.quantity} in stock — already in cart'
            : 'Only ${stock.quantity} in stock — added $added instead of $requested'),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
      ));
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
    final stockAsync = ref.watch(branchStockCacheProvider);
    final primary = Theme.of(context).colorScheme.primary;

    // Ctrl+B barcode / Ctrl+F article (sale invoice screen ke shortcuts).
    ref.listen(saleShortcutProvider, (_, e) {
      if (e?.action == SaleShortcut.barcode) {
        _barcodeFocus.requestFocus();
      } else if (e?.action == SaleShortcut.article) {
        _articleKey.currentState?.open();
      }
    });

    return stockAsync.when(
      // Realtime reload par purani list dikhti rahe — spinner/focus loss nahi.
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
      data: (allStock) {
        // Taza list se selected article — sale/return ke baad qty purani na rahe.
        final sel = _selectedStock;
        final stock = _selectedStock = sel == null
            ? null
            : allStock.firstWhere((s) => s.id == sel.id, orElse: () => sel);
        final totalQty = stock?.quantity ?? 0;

        // Pehli baar list aate hi barcode par cursor (scanner ke liye).
        if (!_focusedOnce) {
          _focusedOnce = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _barcodeFocus.requestFocus();
          });
        }

        final isMobile = Responsive(context).isMobile;

        final barcodeField = TextField(
                  controller: _barcodeCtrl,
                  focusNode: _barcodeFocus,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Bar Code',
                    hintText: 'Scan barcode...',
                    helperText: widget.showShortcutHints ? 'Shortcut: Ctrl + B' : null,
                    helperStyle: const TextStyle(fontSize: 11, color: Color(0xFF8A8FA3)),
                    prefixIcon: const TextFieldIcon(AppIcons.qrCodeScanner, size: 18),
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

        final articleField = KeyboardDropdown<BranchStockModel>(
                  key: _articleKey,
                  filter: (f) => _filterStock(allStock, f),
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
                  onSelected: (s) {
                    setState(() {
                      _selectedStock = s;
                      _barcodeCtrl.clear();
                      _barcodeNotFound = false;
                    });
                    _focusQty();
                  },
                  decoration: _dropDecor('Article').copyWith(
                    helperText: widget.showShortcutHints ? 'Shortcut: Ctrl + F' : null,
                    helperStyle: const TextStyle(fontSize: 11, color: Color(0xFF8A8FA3)),
                  ),
                  maxHeight: 320,
                  searchHint: 'Search article, color, size, category...',
                  itemBuilder: (context, s, isSelected) {
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
                );

        final stockInfo = _InfoBox(
                  label: 'In Stock',
                  value: stock != null ? '$totalQty' : null,
                  valueColor:
                      (stock != null && totalQty == 0) ? Colors.red : Colors.green.shade700,
                );

        final qtyField = _QtyStepperInput(
                controller: _qtyCtrl,
                focusNode: _qtyFocus,
                max: totalQty,
                enabled: stock != null && totalQty > 0,
                primaryColor: primary,
                onSubmit: (_) {
            if (_qtyFits(totalQty)) _addToCart();
          },
              );

        final addButton = SizedBox(
                height: 48,
                child: FilledButton.icon(
                  icon: const AppIcon(AppIcons.addShoppingCart, size: 18),
                  label: Text(widget.buttonLabel),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF43A047),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                  ),
                  onPressed: (stock != null && totalQty > 0 && _qtyFits(totalQty))
                        ? _addToCart
                        : null,
                ),
              );

        return Container(
          padding: EdgeInsets.fromLTRB(isMobile ? 12 : 16, 8, isMobile ? 12 : 16, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final w in widget.leading) ...[
                      w,
                      const SizedBox(height: 10),
                    ],
                    barcodeField,
                    const SizedBox(height: 10),
                    articleField,
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: stockInfo),
                        const SizedBox(width: 10),
                        qtyField,
                      ],
                    ),
                    const SizedBox(height: 10),
                    addButton,
                  ],
                )
              : Row(
                  // Hint ke sath fields lambe hote hain — baqi cheezein upar se.
                  crossAxisAlignment: widget.showShortcutHints
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.end,
                  children: [
                    for (final w in widget.leading) ...[
                      Expanded(flex: 3, child: w),
                      const SizedBox(width: 10),
                    ],
                    Expanded(flex: 3, child: barcodeField),
                    const SizedBox(width: 10),
                    Expanded(flex: 5, child: articleField),
                    const SizedBox(width: 10),
                    Expanded(flex: 2, child: stockInfo),
                    const SizedBox(width: 10),
                    qtyField,
                    const SizedBox(width: 10),
                    addButton,
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
  final FocusNode? focusNode;
  final bool enabled;
  final Color primaryColor;
  final void Function(String) onSubmit;
  final int? max;

  const _QtyStepperInput({
    required this.controller,
    this.focusNode,
    required this.enabled,
    required this.primaryColor,
    required this.onSubmit,
    this.max,
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
            focusNode: focusNode,
            enabled: enabled,
            color: primaryColor,
            height: 48,
            max: max,
            onSubmitted: onSubmit,
          ),
        ),
      ],
    );
  }
}
