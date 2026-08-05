import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/widget/app_dropdown.dart';
import '../../data/models/warehouse_stock_model.dart';
import '../providers/stock_provider.dart';

class AddStockDialog extends ConsumerStatefulWidget {
  const AddStockDialog({super.key});

  @override
  ConsumerState<AddStockDialog> createState() => _AddStockDialogState();
}

class _AddStockDialogState extends ConsumerState<AddStockDialog> {
  StockLookupItem? _product;
  StockLookupItem? _brand;
  StockLookupItem? _company;
  int _quantity = 1;
  final _qtyCtrl = TextEditingController(text: '1');

  List<StockLookupItem> _sizes = [];
  List<StockLookupItem> _colors = [];
  List<StockLookupItem> _categories = [];
  List<StockLookupItem> _types = [];

  List<_StockRow> _previewRows = [];
  bool _previewed = false;
  bool _saving = false;

  // Validation
  String? _productError;
  String? _brandError;
  String? _sizesError;
  String? _colorsError;
  String? _categoriesError;
  String? _typesError;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  // ── Generate 13-digit EAN-style barcode ───────────────────────────────
  String _generateBarcode(int index) {
    final rng = Random();
    // 12 random digits + Luhn-like check digit
    final digits = List.generate(12, (_) => rng.nextInt(10));
    // Make it more deterministic: embed index in last 4 digits
    final idx = index % 10000;
    digits[8] = idx ~/ 1000;
    digits[9] = (idx ~/ 100) % 10;
    digits[10] = (idx ~/ 10) % 10;
    digits[11] = idx % 10;

    // EAN-13 check digit
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      sum += digits[i] * (i.isEven ? 1 : 3);
    }
    final check = (10 - (sum % 10)) % 10;
    return digits.join() + check.toString();
  }

  bool _validate() {
    bool ok = true;
    setState(() {
      _productError = _product == null ? 'Required' : null;
      _brandError = _brand == null ? 'Required' : null;
      _sizesError = _sizes.isEmpty ? 'Select at least one' : null;
      _colorsError = _colors.isEmpty ? 'Select at least one' : null;
      _categoriesError = _categories.isEmpty ? 'Select at least one' : null;
      _typesError = _types.isEmpty ? 'Select at least one' : null;
    });
    if (_productError != null ||
        _brandError != null ||
        _sizesError != null ||
        _colorsError != null ||
        _categoriesError != null ||
        _typesError != null) ok = false;
    return ok;
  }

  void _generatePreview() {
    if (!_validate()) return;
    final rows = <_StockRow>[];
    int counter = 1;
    for (final size in _sizes) {
      for (final color in _colors) {
        for (final category in _categories) {
          for (final type in _types) {
            rows.add(_StockRow(
              barcode: _generateBarcode(counter),
              product: _product!,
              size: size,
              color: color,
              category: category,
              type: type,
              brand: _brand!,
              company: _company,
              quantity: _quantity,
            ));
            counter++;
          }
        }
      }
    }
    setState(() {
      _previewRows = rows;
      _previewed = true;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final stocks = _previewRows
        .map((row) => WarehouseStockModel(
              id: '',
              barcode: row.barcode,
              warehouseId: kWarehouseId,
              productId: row.product.id,
              sizeId: row.size.id,
              brandId: row.brand.id,
              companyId: row.company?.id,
              colorId: row.color.id,
              categoryId: row.category.id,
              typeId: row.type.id,
              quantity: row.quantity,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ))
        .toList();

    final result = await ref.read(stockProvider.notifier).addBatchStock(stocks);
    setState(() => _saving = false);

    if (!mounted) return;

    if (result.error != null) {
      _showSnack('Error: ${result.error}', Colors.red);
      return;
    }

    final saved = stocks.length - result.skipped.length;
    if (result.skipped.isNotEmpty) {
      // Show partial success dialog
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Partial Success'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✅ $saved entries added.'),
              if (result.skipped.isNotEmpty) ...[
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
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 720),
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────
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
                      // ── Section 1 ─────────────────────────────────
                      _SectionLabel(
                          icon: Icons.inventory_2_outlined,
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
                            prefixIcon:
                                const Icon(Icons.inventory_2_outlined, size: 20),
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
                            prefixIcon: const Icon(
                                Icons.branding_watermark_outlined,
                                size: 20),
                            onChanged: (b) => setState(() {
                              _brand = b;
                              _previewed = false;
                            }),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(
                          child: AppSearchDropdown<StockLookupItem>(
                            label: 'Company (optional)',
                            items: companiesAsync.value ?? [],
                            selectedItem: _company,
                            itemLabel: (c) => c.label,
                            prefixIcon:
                                const Icon(Icons.business_outlined, size: 20),
                            onChanged: (c) => setState(() {
                              _company = c;
                              _previewed = false;
                            }),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: _buildQtyField()),
                      ]),

                      const SizedBox(height: 24),

                      // ── Section 2 ─────────────────────────────────
                      _SectionLabel(
                          icon: Icons.tune_outlined,
                          label:
                              'Variations  —  each combination = 1 stock entry'),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: AppMultiSelectDropdown<StockLookupItem>(
                            label: 'Sizes',
                            allItems: sizesAsync.value ?? [],
                            selectedItems: _sizes,
                            itemLabel: (s) => s.label,
                            errorText: _sizesError,
                            isRequired: true,
                            prefixIcon: const Icon(
                                Icons.format_size_outlined,
                                size: 20),
                            onChanged: (list) => setState(() {
                              _sizes = list;
                              _previewed = false;
                            }),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppMultiSelectDropdown<StockLookupItem>(
                            label: 'Colors',
                            allItems: colorsAsync.value ?? [],
                            selectedItems: _colors,
                            itemLabel: (c) => c.label,
                            errorText: _colorsError,
                            isRequired: true,
                            prefixIcon: const Icon(Icons.color_lens_outlined,
                                size: 20),
                            onChanged: (list) => setState(() {
                              _colors = list;
                              _previewed = false;
                            }),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(
                          child: AppMultiSelectDropdown<StockLookupItem>(
                            label: 'Categories',
                            allItems: categoriesAsync.value ?? [],
                            selectedItems: _categories,
                            itemLabel: (c) => c.label,
                            errorText: _categoriesError,
                            isRequired: true,
                            prefixIcon:
                                const Icon(Icons.category_outlined, size: 20),
                            onChanged: (list) => setState(() {
                              _categories = list;
                              _previewed = false;
                            }),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppMultiSelectDropdown<StockLookupItem>(
                            label: 'Types',
                            allItems: typesAsync.value ?? [],
                            selectedItems: _types,
                            itemLabel: (t) => t.label,
                            errorText: _typesError,
                            isRequired: true,
                            prefixIcon:
                                const Icon(Icons.style_outlined, size: 20),
                            onChanged: (list) => setState(() {
                              _types = list;
                              _previewed = false;
                            }),
                          ),
                        ),
                      ]),

                      const SizedBox(height: 20),

                      // ── Preview button ─────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.visibility_outlined),
                          label: const Text('Preview Stock Entries'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _generatePreview,
                        ),
                      ),

                      // ── Preview table ──────────────────────────────
                      if (_previewed && _previewRows.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
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

            // ── Footer ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border:
                    Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
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
                        : Icon(_previewed
                            ? Icons.save_outlined
                            : Icons.visibility_outlined),
                    label: Text(_previewed
                        ? 'Save ${_previewRows.length} Entries'
                        : 'Preview First'),
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    onPressed:
                        _saving ? null : (_previewed ? _save : _generatePreview),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyField() {
    return TextFormField(
      controller: _qtyCtrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Quantity per entry *',
        prefixIcon: const Icon(Icons.numbers_outlined, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        filled: true,
        fillColor: Colors.white,
      ),
      onChanged: (v) {
        final parsed = int.tryParse(v);
        if (parsed != null && parsed >= 0) {
          setState(() {
            _quantity = parsed;
            _previewed = false;
          });
        }
      },
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
            Theme.of(context).colorScheme.primary.withOpacity(0.85),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add_box_outlined,
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
                        color: Colors.white.withOpacity(0.8), fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
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
            // Header
            Container(
              color: primary,
              child: Row(children: [
                _hcell('Barcode', flex: 3),
                _hcell('Size'),
                _hcell('Color'),
                _hcell('Category'),
                _hcell('Type'),
                _hcell('Qty', flex: 1),
              ]),
            ),
            // Rows (max 10 shown)
            ...rows.take(10).toList().asMap().entries.map((e) {
              final row = e.value;
              final even = e.key.isEven;
              return Container(
                color: even ? Colors.grey.shade50 : Colors.white,
                child: Row(children: [
                  _dcell(row.barcode, flex: 3,
                      style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          letterSpacing: 0.5)),
                  _dcell(row.size.label),
                  _dcell(row.color.label),
                  _dcell(row.category.label),
                  _dcell(row.type.label),
                  _dcell('${row.quantity}', flex: 1),
                ]),
              );
            }),
            if (rows.length > 10)
              Container(
                width: double.infinity,
                color: Colors.grey.shade50,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Text(
                  '+ ${rows.length - 10} more entries...',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
      );

  Widget _dcell(String text,
          {int flex = 2, TextStyle? style}) =>
      Expanded(
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
