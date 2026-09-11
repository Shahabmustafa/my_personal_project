import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/pagination/pagination.dart';
import '../../data/barcode_printer_service.dart';
import '../../data/models/warehouse_stock_model.dart';
import '../providers/stock_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
class StockTable extends ConsumerWidget {
  final bool readOnly;
  const StockTable({super.key, this.readOnly = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        return isWide
            ? _DesktopTable(readOnly: readOnly)
            : _MobileList(readOnly: readOnly);
      },
    );
  }
}

// ── Desktop: horizontal data table ───────────────────────────────────────

class _DesktopTable extends ConsumerWidget {
  final bool readOnly;
  const _DesktopTable({this.readOnly = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const headerStyle = TextStyle(
        fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white);
    final state = ref.watch(stockProvider);
    final notifier = ref.read(stockProvider.notifier);

    return Column(
      children: [
        // Header
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            children: [
              _hcell('Barcode', flex: 3, style: headerStyle),
              _hcell('Article', flex: 2, style: headerStyle),
              _hcell('Size', style: headerStyle),
              _hcell('Color', style: headerStyle),
              _hcell('Brand', style: headerStyle),
              _hcell('Category', style: headerStyle),
              _hcell('Type', style: headerStyle),
              _hcell('Qty', flex: 1, style: headerStyle),
              _hcell('Discount', flex: 1, style: headerStyle),
              // Actions header — wider to fit 4 icons
              _hcell('Actions', flex: 3, style: headerStyle),
            ],
          ),
        ),
        // Rows
        Expanded(
          child: PaginatedListView<WarehouseStockModel>(
            state: state,
            padding: EdgeInsets.zero,
            onLoadMore: notifier.loadMore,
            onRefresh: notifier.refresh,
            emptyText: 'No stock entries found',
            itemBuilder: (context, stock, i) => _DesktopRow(
                stock: stock, isEven: i.isEven, readOnly: readOnly),
          ),
        ),
      ],
    );
  }

  Widget _hcell(String text, {int flex = 2, TextStyle? style}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Text(text, style: style),
      ),
    );
  }
}

class _DesktopRow extends ConsumerWidget {
  final WarehouseStockModel stock;
  final bool isEven;
  final bool readOnly;

  const _DesktopRow(
      {required this.stock, required this.isEven, this.readOnly = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: isEven ? Colors.grey.shade50 : Colors.white,
      child: Row(
        children: [
          _cell(stock.barcode, flex: 3),
          _cell(stock.productName ?? '—', flex: 2),
          _cell(stock.sizeName ?? '—'),
          _cell(stock.colorName ?? '—'),
          _cell(stock.brandName ?? '—'),
          _cell(stock.categoryName ?? '—'),
          _cell(stock.typeName ?? '—'),
          _cell('${stock.quantity}', flex: 1),
          _cell(
            '${stock.discount.toStringAsFixed(0)}%',
            flex: 1,
          ),
          // Actions: Edit | Copy | Print | Delete
          Expanded(
            flex: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit quantity & discount
                if (!readOnly)
                  IconButton(
                    icon: AppIcon(AppIcons.editOutlined,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary),
                    tooltip: 'Edit',
                    onPressed: () => showEditStockDialog(context, ref, stock),
                  ),
                // Copy barcode
                IconButton(
                  icon: const AppIcon(AppIcons.copyOutlined,
                      size: 18, color: Colors.blueGrey),
                  tooltip: 'Copy barcode',
                  onPressed: () => _copyBarcode(context),
                ),
                // Print label
                IconButton(
                  icon: AppIcon(AppIcons.printOutlined,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary),
                  tooltip: 'Print label',
                  onPressed: () => _showPrintDialog(context),
                ),
                // Delete
                if (!readOnly)
                  IconButton(
                    icon: const AppIcon(AppIcons.deleteOutline,
                        size: 18, color: Colors.red),
                    tooltip: 'Delete',
                    onPressed: () => _confirmDelete(context, ref),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(String text, {int flex = 2}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Text(text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  // ── Copy barcode to clipboard ─────────────────────────────────────────
  void _copyBarcode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: stock.barcode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const AppIcon(AppIcons.checkCircleOutline,
                color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text('Barcode copied: ${stock.barcode}'),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ── Print label dialog ────────────────────────────────────────────────
  void _showPrintDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _BarcodeLabel(stock: stock),
    );
  }

  // ── Delete confirm ────────────────────────────────────────────────────
  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Stock Entry'),
        content: Text('Delete barcode "${stock.barcode}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final err =
              await ref.read(stockProvider.notifier).deleteStock(stock.id);
              if (err != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Error: $err'),
                      backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Edit quantity & discount dialog ─────────────────────────────────────────

void showEditStockDialog(
    BuildContext context, WidgetRef ref, WarehouseStockModel stock) {
  final qtyCtrl = TextEditingController(text: stock.quantity.toString());
  final discountCtrl =
      TextEditingController(text: stock.discount.toStringAsFixed(0));
  final formKey = GlobalKey<FormState>();
  bool saving = false;

  showDialog(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (dialogCtx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Stock',
            style: TextStyle(fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: 360,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(stock.productName ?? stock.barcode,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantity *',
                    prefixIcon: const AppIcon(AppIcons.numbersOutlined, size: 18),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    if (n == null || n < 0) return 'Enter a valid quantity';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: discountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Discount %',
                    prefixIcon: const AppIcon(AppIcons.percentOutlined, size: 18),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').trim());
                    if (n == null || n < 0) return 'Enter a valid discount';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: saving
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    setDialogState(() => saving = true);
                    final notifier = ref.read(stockProvider.notifier);
                    final qtyErr = await notifier.updateQuantity(
                        stock.id, int.parse(qtyCtrl.text.trim()));
                    final discErr = await notifier.updateDiscount(
                        stock.id, double.parse(discountCtrl.text.trim()));
                    final err = qtyErr ?? discErr;
                    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(err == null
                            ? 'Stock updated successfully!'
                            : 'Error: $err'),
                        backgroundColor:
                            err == null ? Colors.green : Colors.red,
                      ));
                    }
                  },
            child: saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

// ── Barcode label dialog ──────────────────────────────────────────────────

class _BarcodeLabel extends StatelessWidget {
  final WarehouseStockModel stock;
  const _BarcodeLabel({required this.stock});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Dialog title ──────────────────────────────────────
              Row(
                children: [
                  AppIcon(AppIcons.printOutlined, color: primary),
                  const SizedBox(width: 8),
                  const Text('Barcode Label',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    icon: const AppIcon(AppIcons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Label preview card ────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Shop name
                    Text(
                      'Safi Shoe',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Barcode bars (visual representation)
                    _BarcodeBars(barcode: stock.barcode),
                    const SizedBox(height: 6),

                    // Barcode number
                    Text(
                      stock.barcode,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Divider
                    Divider(color: Colors.grey.shade200, height: 1),
                    const SizedBox(height: 12),

                    // Details grid
                    _LabelDetail(
                        icon: AppIcons.formatSizeOutlined,
                        label: 'Size',
                        value: stock.sizeName ?? '—'),
                    const SizedBox(height: 6),
                    _LabelDetail(
                        icon: AppIcons.colorLensOutlined,
                        label: 'Color',
                        value: stock.colorName ?? '—'),
                    const SizedBox(height: 6),
                    _LabelDetail(
                        icon: AppIcons.categoryOutlined,
                        label: 'Category',
                        value: stock.categoryName ?? '—'),
                    const SizedBox(height: 6),
                    _LabelDetail(
                        icon: AppIcons.styleOutlined,
                        label: 'Type',
                        value: stock.typeName ?? '—'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Action buttons ────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const AppIcon(AppIcons.copyOutlined, size: 16),
                      label: const Text('Copy'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: stock.barcode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Barcode copied!'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const AppIcon(AppIcons.printOutlined, size: 16),
                      label: const Text('Print'),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await BarcodePrintService.printLabel(stock);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Barcode visual bars ───────────────────────────────────────────────────

class _BarcodeBars extends StatelessWidget {
  final String barcode;
  const _BarcodeBars({required this.barcode});

  @override
  Widget build(BuildContext context) {
    // Generate pseudo-bar widths from barcode digits for visual effect
    final digits = barcode.split('').map((c) => int.tryParse(c) ?? 1).toList();

    return SizedBox(
      height: 48,
      width: double.infinity,
      child: CustomPaint(
        painter: _BarcodePainter(digits: digits),
      ),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  final List<int> digits;
  const _BarcodePainter({required this.digits});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final totalBars = digits.length * 4;
    final barWidth = size.width / (totalBars * 1.6);
    double x = 0;

    for (int i = 0; i < digits.length; i++) {
      final d = digits[i];
      // Alternate filled / gap based on digit value
      for (int j = 0; j < 4; j++) {
        final w = barWidth * (1 + ((d + j) % 3) * 0.5);
        if (j.isEven) {
          canvas.drawRect(
            Rect.fromLTWH(x, 0, w, size.height),
            paint,
          );
        }
        x += w + barWidth * 0.4;
      }
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter old) => old.digits != digits;
}

// ── Label detail row ──────────────────────────────────────────────────────

class _LabelDetail extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _LabelDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIcon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Text(
          '$label:',
          style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Mobile: card list ─────────────────────────────────────────────────────

class _MobileList extends ConsumerWidget {
  final bool readOnly;
  const _MobileList({this.readOnly = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stockProvider);
    final notifier = ref.read(stockProvider.notifier);
    return PaginatedListView<WarehouseStockModel>(
      state: state,
      padding: const EdgeInsets.all(12),
      onLoadMore: notifier.loadMore,
      onRefresh: notifier.refresh,
      emptyText: 'No stock entries found',
      itemBuilder: (context, stock, i) {
        return Card(
          elevation: 1,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        stock.barcode,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    // Edit
                    if (!readOnly)
                      IconButton(
                        icon: AppIcon(AppIcons.editOutlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 18),
                        onPressed: () =>
                            showEditStockDialog(context, ref, stock),
                      ),
                    // Copy
                    IconButton(
                      icon: const AppIcon(AppIcons.copyOutlined,
                          color: Colors.blueGrey, size: 18),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: stock.barcode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Barcode copied!'),
                              duration: Duration(seconds: 1)),
                        );
                      },
                    ),
                    // Print
                    IconButton(
                      icon: AppIcon(AppIcons.printOutlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 18),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => _BarcodeLabel(stock: stock),
                      ),
                    ),
                    // Delete
                    if (!readOnly)
                      IconButton(
                        icon: const AppIcon(AppIcons.deleteOutline,
                            color: Colors.red, size: 20),
                        onPressed: () async {
                          final err = await ref
                              .read(stockProvider.notifier)
                              .deleteStock(stock.id);
                          if (err != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Error: $err'),
                                  backgroundColor: Colors.red),
                            );
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _chip('Article', stock.productName ?? '—'),
                    _chip('Size', stock.sizeName ?? '—'),
                    _chip('Color', stock.colorName ?? '—'),
                    _chip('Brand', stock.brandName ?? '—'),
                    _chip('Category', stock.categoryName ?? '—'),
                    _chip('Type', stock.typeName ?? '—'),
                    _chip('Qty', '${stock.quantity}',
                        color: Colors.blue.shade700),
                    _chip('Discount', '${stock.discount.toStringAsFixed(0)}%',
                        color: Colors.orange.shade800),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _chip(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11),
          children: [
            TextSpan(
                text: '$label: ',
                style: const TextStyle(color: Colors.grey)),
            TextSpan(
              text: value,
              style: TextStyle(
                  color: color ?? Colors.black87,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}