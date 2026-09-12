import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safishoe_app/core/widget/app_dropdown.dart';
import 'package:safishoe_app/features/warehouse/stock_inventory/data/models/warehouse_stock_model.dart'
    show StockLookupItem;
import 'package:safishoe_app/features/warehouse/stock_inventory/presentation/providers/stock_provider.dart'
    show
        stockProductsProvider,
        stockSizesProvider,
        stockBrandsProvider,
        stockCompaniesProvider,
        stockColorsProvider,
        stockCategoriesProvider,
        stockTypesProvider;
import '../../data/model/stock_inventory_model.dart';
import '../providers/stock_inventory_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/widget/text_field_icon.dart';
// ── Per-size entry model ──────────────────────────────────────────────────
class _SizeQtyEntry {
  StockLookupItem? size;
  int quantity = 1;
  final TextEditingController qtyCtrl = TextEditingController(text: '1');

  void dispose() => qtyCtrl.dispose();
}

class AddStockInventoryDialog extends ConsumerStatefulWidget {
  const AddStockInventoryDialog({super.key});

  @override
  ConsumerState<AddStockInventoryDialog> createState() =>
      _AddStockInventoryDialogState();
}

class _AddStockInventoryDialogState
    extends ConsumerState<AddStockInventoryDialog> {
  StockLookupItem? _product;
  StockLookupItem? _brand;
  StockLookupItem? _company;
  final _discountCtrl = TextEditingController(text: '0');

  final List<_SizeQtyEntry> _sizeRows = [_SizeQtyEntry()];

  StockLookupItem? _color;
  StockLookupItem? _category;
  StockLookupItem? _type;

  List<_StockRow> _previewRows = [];
  bool _previewed = false;
  bool _saving = false;

  String? _productError;
  String? _brandError;
  String? _sizesError;
  String? _colorsError;
  String? _categoriesError;
  String? _typesError;

  @override
  void dispose() {
    for (final row in _sizeRows) {
      row.dispose();
    }
    _discountCtrl.dispose();
    super.dispose();
  }

  String _generateBarcode(int index) {
    final rng = Random();
    final digits = List.generate(12, (_) => rng.nextInt(10));
    final idx = index % 10000;
    digits[8] = idx ~/ 1000;
    digits[9] = (idx ~/ 100) % 10;
    digits[10] = (idx ~/ 10) % 10;
    digits[11] = idx % 10;

    int sum = 0;
    for (int i = 0; i < 12; i++) {
      sum += digits[i] * (i.isEven ? 1 : 3);
    }
    final check = (10 - (sum % 10)) % 10;
    return digits.join() + check.toString();
  }

  bool _validate() {
    bool ok = true;
    final hasSizeError = _sizeRows.any((r) => r.size == null || r.quantity <= 0);

    setState(() {
      _productError = _product == null ? 'Required' : null;
      _brandError = _brand == null ? 'Required' : null;
      _sizesError = hasSizeError ? 'Each size row must have a size & qty' : null;
      _colorsError = _color == null ? 'Required' : null;
      _categoriesError = _category == null ? 'Required' : null;
      _typesError = _type == null ? 'Required' : null;
    });

    if (_productError != null ||
        _brandError != null ||
        _sizesError != null ||
        _colorsError != null ||
        _categoriesError != null ||
        _typesError != null) {
      ok = false;
    }

    return ok;
  }

  void _generatePreview() {
    if (!_validate()) {
      return;
    }
    final discount = double.tryParse(_discountCtrl.text.trim()) ?? 0;
    final rows = <_StockRow>[];
    int counter = 1;

    for (final sizeEntry in _sizeRows) {
      rows.add(_StockRow(
        barcode: _generateBarcode(counter),
        product: _product!,
        size: sizeEntry.size!,
        color: _color!,
        category: _category!,
        type: _type!,
        brand: _brand!,
        company: _company,
        quantity: sizeEntry.quantity,
        discount: discount,
      ));
      counter++;
    }

    setState(() {
      _previewRows = rows;
      _previewed = true;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final stocks = _previewRows
        .map((row) => StockInventoryModel(
              id: '',
              barcode: row.barcode,
              productId: row.product.id,
              sizeId: row.size.id,
              brandId: row.brand.id,
              companyId: row.company?.id,
              colorId: row.color.id,
              categoryId: row.category.id,
              typeId: row.type.id,
              quantity: row.quantity,
              discount: row.discount,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ))
        .toList();

    final result =
        await ref.read(headOfficeStockActionsProvider).addBatchStock(stocks);
    setState(() => _saving = false);

    if (!mounted) return;

    if (result.error != null) {
      _showSnack('Error: ${result.error}', Colors.red);
      return;
    }

    ref.invalidate(headOfficeStockProvider);

    final saved = stocks.length - result.skipped.length;
    if (result.skipped.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Partial Success'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✅ $saved entries added.'),
              const SizedBox(height: 8),
              Text('⚠️ ${result.skipped.length} skipped (already exist):',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              ...result.skipped.take(5).map((s) => Text('• $s',
                  style: const TextStyle(fontSize: 12, color: Colors.grey))),
              if (result.skipped.length > 5)
                Text('...and ${result.skipped.length - 5} more',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK')),
          ],
        ),
      );
    } else {
      _showSnack('$saved stock entries added!', Colors.green);
    }
    if (mounted) Navigator.pop(context);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  void _addSizeRow() {
    setState(() {
      _sizeRows.add(_SizeQtyEntry());
      _previewed = false;
    });
  }

  void _removeSizeRow(int index) {
    if (_sizeRows.length == 1) return;
    setState(() {
      _sizeRows[index].dispose();
      _sizeRows.removeAt(index);
      _previewed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(stockProductsProvider);
    final sizesAsync = ref.watch(stockSizesProvider);
    final brandsAsync = ref.watch(stockBrandsProvider);
    final companiesAsync = ref.watch(stockCompaniesProvider);
    final colorsAsync = ref.watch(stockColorsProvider);
    final categoriesAsync = ref.watch(stockCategoriesProvider);
    final typesAsync = ref.watch(stockTypesProvider);
    final theme = Theme.of(context);

    final isLoading = [
      productsAsync,
      sizesAsync,
      brandsAsync,
      companiesAsync,
      colorsAsync,
      categoriesAsync,
      typesAsync,
    ].any((a) => a.isLoading);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 760),
        child: Column(
          children: [
            _DialogHeader(
              title: 'Add Stock Entry',
              subtitle: _previewed
                  ? '${_previewRows.length} entries ready to save'
                  : 'Fill details then preview',
              onClose: () => Navigator.pop(context),
            ),
            if (isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(
                          icon: AppIcons.inventory2Outlined,
                          label: 'Product & Brand'),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: AppSearchDropdown<StockLookupItem>(
                            label: 'Product (Article)',
                            items: productsAsync.value ?? [],
                            selectedItem: _product,
                            itemLabel: (p) => p.label,
                            errorText: _productError,
                            isRequired: true,
                            prefixIcon: const TextFieldIcon(AppIcons.inventory2Outlined,
                                size: 12),
                            onChanged: (p) => setState(() {
                              _product = p;
                              _previewed = false;
                            }),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppSearchDropdown<StockLookupItem>(
                            label: 'Brand',
                            items: brandsAsync.value ?? [],
                            selectedItem: _brand,
                            itemLabel: (b) => b.label,
                            errorText: _brandError,
                            isRequired: true,
                            prefixIcon: const TextFieldIcon(
                                AppIcons.brandingWatermarkOutlined,
                                size: 12),
                            onChanged: (b) => setState(() {
                              _brand = b;
                              _previewed = false;
                            }),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: AppSearchDropdown<StockLookupItem>(
                              label: 'Company (optional)',
                              items: companiesAsync.value ?? [],
                              selectedItem: _company,
                              itemLabel: (c) => c.label,
                              prefixIcon: const TextFieldIcon(AppIcons.businessOutlined,
                                  size: 12),
                              onChanged: (c) => setState(() {
                                _company = c;
                                _previewed = false;
                              }),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _discountCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Discount %',
                                prefixIcon: const TextFieldIcon(AppIcons.percentOutlined,
                                    size: 12),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              onChanged: (_) =>
                                  setState(() => _previewed = false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _SectionLabel(
                              icon: AppIcons.formatSizeOutlined,
                              label: 'Sizes & Quantities  —  one size per row',
                            ),
                          ),
                          TextButton.icon(
                            icon: const AppIcon(AppIcons.add, size: 16),
                            label: const Text('Add Size',
                                style: TextStyle(fontSize: 13)),
                            onPressed: _addSizeRow,
                          ),
                        ],
                      ),
                      if (_sizesError != null) ...[
                        const SizedBox(height: 4),
                        Text(_sizesError!,
                            style: TextStyle(
                                color: theme.colorScheme.error, fontSize: 12)),
                      ],
                      const SizedBox(height: 8),
                      ..._sizeRows.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final row = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SizeQtyRow(
                            index: idx,
                            entry: row,
                            allSizes: sizesAsync.value ?? [],
                            canRemove: _sizeRows.length > 1,
                            onSizeChanged: (size) => setState(() {
                              row.size = size;
                              _previewed = false;
                            }),
                            onQtyChanged: (qty) {
                              row.quantity = qty;
                              _previewed = false;
                            },
                            onRemove: () => _removeSizeRow(idx),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      _SectionLabel(
                          icon: AppIcons.tuneOutlined,
                          label:
                              'Variations  —  each combination = 1 stock entry'),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: AppSearchDropdown<StockLookupItem>(
                            label: 'Color',
                            items: colorsAsync.value ?? [],
                            selectedItem: _color,
                            itemLabel: (c) => c.label,
                            errorText: _colorsError,
                            isRequired: true,
                            prefixIcon: const TextFieldIcon(AppIcons.colorLensOutlined, size: 12),
                            onChanged: (c) => setState(() {
                              _color = c;
                              _previewed = false;
                            }),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppSearchDropdown<StockLookupItem>(
                            label: 'Category',
                            items: categoriesAsync.value ?? [],
                            selectedItem: _category,
                            itemLabel: (c) => c.label,
                            errorText: _categoriesError,
                            isRequired: true,
                            prefixIcon: const TextFieldIcon(AppIcons.categoryOutlined, size: 12),
                            onChanged: (c) => setState(() {
                              _category = c;
                              _previewed = false;
                            }),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      AppSearchDropdown<StockLookupItem>(
                        label: 'Type',
                        items: typesAsync.value ?? [],
                        selectedItem: _type,
                        itemLabel: (t) => t.label,
                        errorText: _typesError,
                        isRequired: true,
                        prefixIcon: const TextFieldIcon(AppIcons.styleOutlined, size: 12),
                        onChanged: (t) => setState(() {
                          _type = t;
                          _previewed = false;
                        }),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          icon: const AppIcon(AppIcons.visibilityOutlined),
                          label: const Text('Preview Stock Entries'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _generatePreview,
                        ),
                      ),
                      if (_previewed && _previewRows.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_previewRows.length} entries will be created',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        _PreviewTable(rows: _previewRows),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border:
                    Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : AppIcon(_previewed
                            ? AppIcons.saveOutlined
                            : AppIcons.visibilityOutlined),
                    label: Text(_previewed
                        ? 'Save ${_previewRows.length} Entries'
                        : 'Preview First'),
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    onPressed: _saving
                        ? null
                        : (_previewed ? _save : _generatePreview),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Size + Qty row widget ─────────────────────────────────────────────────

class _SizeQtyRow extends StatelessWidget {
  final int index;
  final _SizeQtyEntry entry;
  final List<StockLookupItem> allSizes;
  final bool canRemove;
  final ValueChanged<StockLookupItem?> onSizeChanged;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onRemove;

  const _SizeQtyRow({
    required this.index,
    required this.entry,
    required this.allSizes,
    required this.canRemove,
    required this.onSizeChanged,
    required this.onQtyChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: AppSearchDropdown<StockLookupItem>(
            label: 'Size ${index + 1}',
            items: allSizes,
            selectedItem: entry.size,
            itemLabel: (s) => s.label,
            isRequired: true,
            prefixIcon: const TextFieldIcon(AppIcons.formatSizeOutlined, size: 12),
            onChanged: onSizeChanged,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: entry.qtyCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Quantity *',
              prefixIcon: const TextFieldIcon(AppIcons.numbersOutlined, size: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 14),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (v) {
              final parsed = int.tryParse(v);
              if (parsed != null && parsed > 0) {
                onQtyChanged(parsed);
              }
            },
          ),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: IconButton(
            icon: AppIcon(
              AppIcons.removeCircleOutline,
              color: canRemove ? Colors.red.shade400 : Colors.grey.shade300,
            ),
            tooltip: canRemove ? 'Remove row' : 'At least one size required',
            onPressed: canRemove ? onRemove : null,
          ),
        ),
      ],
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onClose;

  const _DialogHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const AppIcon(AppIcons.addBoxOutlined,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const AppIcon(AppIcons.close, color: Colors.white),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIcon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ── Preview table ─────────────────────────────────────────────────────────

class _StockRow {
  final String barcode;
  final StockLookupItem product;
  final StockLookupItem size;
  final StockLookupItem color;
  final StockLookupItem category;
  final StockLookupItem type;
  final StockLookupItem brand;
  final StockLookupItem? company;
  final int quantity;
  final double discount;

  const _StockRow({
    required this.barcode,
    required this.product,
    required this.size,
    required this.color,
    required this.category,
    required this.type,
    required this.brand,
    this.company,
    required this.quantity,
    this.discount = 0,
  });
}

class _PreviewTable extends StatelessWidget {
  final List<_StockRow> rows;
  const _PreviewTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Container(
              color: primary,
              child: Row(children: [
                _hcell('Barcode', flex: 3),
                _hcell('Size'),
                _hcell('Color'),
                _hcell('Category'),
                _hcell('Type'),
                _hcell('Qty', flex: 1),
                _hcell('Disc.', flex: 1),
              ]),
            ),
            ...rows.take(10).toList().asMap().entries.map((e) {
              final row = e.value;
              final even = e.key.isEven;
              return Container(
                color: even ? Colors.grey.shade50 : Colors.white,
                child: Row(children: [
                  _dcell(row.barcode,
                      flex: 3,
                      style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          letterSpacing: 0.5)),
                  _dcell(row.size.label),
                  _dcell(row.color.label),
                  _dcell(row.category.label),
                  _dcell(row.type.label),
                  _dcell('${row.quantity}', flex: 1),
                  _dcell('${row.discount.toStringAsFixed(0)}%', flex: 1),
                ]),
              );
            }),
            if (rows.length > 10)
              Container(
                width: double.infinity,
                color: Colors.grey.shade50,
                padding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 12),
                child: Text(
                  '+ ${rows.length - 10} more entries...',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _hcell(String text, {int flex = 2}) => Expanded(
        flex: flex,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
      );

  Widget _dcell(String text, {int flex = 2, TextStyle? style}) => Expanded(
        flex: flex,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Text(text,
              style: style ??
                  const TextStyle(fontSize: 12, color: Colors.black87),
              overflow: TextOverflow.ellipsis),
        ),
      );
}
