import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safishoe_app/core/pagination/pagination.dart';
import 'package:safishoe_app/features/warehouse/stock_inventory/data/barcode_printer_service.dart';
import '../../data/model/stock_inventory_model.dart';
import '../providers/stock_inventory_provider.dart';
import '../widgets/add_stock_inventory_dialog.dart';

/// Superadmin stock view — head office ka stock (`stock_inventory` table).
/// Warehouse se koi taalluq nahi. Add / Edit / Delete + barcode print/copy.
class HeadOfficeStockScreen extends ConsumerStatefulWidget {
  const HeadOfficeStockScreen({super.key});

  @override
  ConsumerState<HeadOfficeStockScreen> createState() =>
      _HeadOfficeStockScreenState();
}

class _HeadOfficeStockScreenState extends ConsumerState<HeadOfficeStockScreen> {
  Future<void> _openAddStock() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AddStockInventoryDialog(),
    );
    ref.read(headOfficeStockProvider.notifier).refresh();
    ref.invalidate(headOfficeStockStatsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(headOfficeStockProvider);
    final notifier = ref.read(headOfficeStockProvider.notifier);
    final stats = ref.watch(headOfficeStockStatsProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Stock Inventory',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    Text(
                      stats.maybeWhen(
                        data: (s) =>
                            'Total SKUs: ${groupThousands(state.totalCount)}  •  ${groupThousands(s.totalQty)} units  •  ${groupThousands(s.lowStockCount)} low',
                        orElse: () =>
                            'Total SKUs: ${groupThousands(state.totalCount)}',
                      ),
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF8A8FA3)),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    notifier.refresh();
                    ref.invalidate(headOfficeStockStatsProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  color: const Color(0xFF3E63DD),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _openAddStock,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Stock'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3E63DD),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: TextField(
              onChanged: notifier.setSearch,
              decoration: InputDecoration(
                hintText: 'Search by barcode, article, brand...',
                hintStyle:
                    const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF8A8FA3)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE7E9F0))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFF3E63DD), width: 1.5)),
              ),
            ),
          ),
          Expanded(
            child: isMobile
                ? _MobileList(state: state, notifier: notifier)
                : _DesktopTable(state: state, notifier: notifier),
          ),
        ],
      ),
    );
  }
}

// ── Shared actions ───────────────────────────────────────────────────────

Future<void> _refresh(WidgetRef ref) async {
  await ref.read(headOfficeStockProvider.notifier).refresh();
  ref.invalidate(headOfficeStockStatsProvider);
}

void _copyBarcode(BuildContext context, String barcode) {
  Clipboard.setData(ClipboardData(text: barcode));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Barcode copied: $barcode'),
      backgroundColor: Colors.green.shade600,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

void _confirmDelete(
    BuildContext context, WidgetRef ref, StockInventoryModel s) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete Stock Entry'),
      content: Text('Delete barcode "${s.barcode}"?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            Navigator.pop(context);
            final err = await ref
                .read(headOfficeStockActionsProvider)
                .deleteStock(s.id);
            await _refresh(ref);
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

void _showEditDialog(
    BuildContext context, WidgetRef ref, StockInventoryModel s) {
  final qtyCtrl = TextEditingController(text: s.quantity.toString());
  final discountCtrl =
      TextEditingController(text: s.discount.toStringAsFixed(0));
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
                Text(s.productName ?? s.barcode,
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
                    prefixIcon: const Icon(Icons.numbers_outlined, size: 18),
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
                    prefixIcon: const Icon(Icons.percent_outlined, size: 18),
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
              backgroundColor: const Color(0xFF3E63DD),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: saving
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    setDialogState(() => saving = true);
                    final actions =
                        ref.read(headOfficeStockActionsProvider);
                    final qtyErr = await actions.updateQuantity(
                        s.id, int.parse(qtyCtrl.text.trim()));
                    final discErr = await actions.updateDiscount(
                        s.id, double.parse(discountCtrl.text.trim()));
                    final err = qtyErr ?? discErr;
                    await _refresh(ref);
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

void _showPrintDialog(BuildContext context, StockInventoryModel s) {
  showDialog(context: context, builder: (_) => _BarcodeLabel(stock: s));
}

class _RowActions extends ConsumerWidget {
  final StockInventoryModel stock;
  const _RowActions({required this.stock});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _actionBtn(
          icon: Icons.edit_outlined,
          color: const Color(0xFF3E63DD),
          tooltip: 'Edit',
          onPressed: () => _showEditDialog(context, ref, stock),
        ),
        _actionBtn(
          icon: Icons.copy_outlined,
          color: Colors.blueGrey,
          tooltip: 'Copy barcode',
          onPressed: () => _copyBarcode(context, stock.barcode),
        ),
        _actionBtn(
          icon: Icons.print_outlined,
          color: const Color(0xFF3E63DD),
          tooltip: 'Print label',
          onPressed: () => _showPrintDialog(context, stock),
        ),
        _actionBtn(
          icon: Icons.delete_outline,
          color: Colors.red,
          tooltip: 'Delete',
          onPressed: () => _confirmDelete(context, ref, stock),
        ),
      ],
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 18, color: color),
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      splashRadius: 18,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}

// ── Desktop table ────────────────────────────────────────────────────────

/// Fixed column widths — table horizontally scrolls jab screen choti ho,
/// aur bachi hui jagah trailing filler kha jaata hai (no overflow).
const _kColWidths = <double>[
  210, // Barcode
  180, // Article
  90, // Size
  120, // Color
  150, // Brand
  150, // Category
  130, // Type
  70, // Qty
  80, // Discount
  190, // Actions
];
const _kTableMinWidth = 1410; // sum(_kColWidths) 1370 + row padding 32 + slack

class _DesktopTable extends StatefulWidget {
  final PaginatedListState<StockInventoryModel> state;
  final HeadOfficeStockNotifier notifier;
  const _DesktopTable({required this.state, required this.notifier});

  @override
  State<_DesktopTable> createState() => _DesktopTableState();
}

class _DesktopTableState extends State<_DesktopTable> {
  final _hScroll = ScrollController();

  @override
  void dispose() {
    _hScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF8A8FA3),
        letterSpacing: 0.3);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7E9F0)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth =
                  constraints.maxWidth > _kTableMinWidth
                      ? constraints.maxWidth
                      : _kTableMinWidth.toDouble();
              return Scrollbar(
                controller: _hScroll,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _hScroll,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFF7F8FC),
                            border: Border(
                                bottom:
                                    BorderSide(color: Color(0xFFE7E9F0))),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: const Row(children: [
                            _TH('Barcode', w: 0, style: headerStyle),
                            _TH('Article', w: 1, style: headerStyle),
                            _TH('Size', w: 2, style: headerStyle),
                            _TH('Color', w: 3, style: headerStyle),
                            _TH('Brand', w: 4, style: headerStyle),
                            _TH('Category', w: 5, style: headerStyle),
                            _TH('Type', w: 6, style: headerStyle),
                            _TH('Qty', w: 7, style: headerStyle),
                            _TH('Discount', w: 8, style: headerStyle),
                            _TH('Actions', w: 9, style: headerStyle),
                            Expanded(child: SizedBox()),
                          ]),
                        ),
                        Expanded(
                          child: PaginatedListView<StockInventoryModel>(
                            state: widget.state,
                            padding: EdgeInsets.zero,
                            onLoadMore: widget.notifier.loadMore,
                            onRefresh: widget.notifier.refresh,
                            emptyText: 'No stock entries found',
                            separatorBuilder: (_, __) => const Divider(
                                height: 1, color: Color(0xFFE7E9F0)),
                            itemBuilder: (_, s, __) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                child: Row(children: [
                                  _cell(s.barcode, i: 0, mono: true),
                                  _cell(s.productName ?? '—',
                                      i: 1, bold: true),
                                  _cell(s.sizeName ?? '—', i: 2),
                                  _cell(s.colorName ?? '—', i: 3),
                                  _cell(s.brandName ?? '—', i: 4),
                                  _cell(s.categoryName ?? '—', i: 5),
                                  _cell(s.typeName ?? '—', i: 6),
                                  _cell('${s.quantity}', i: 7),
                                  _cell('${s.discount.toStringAsFixed(0)}%',
                                      i: 8),
                                  SizedBox(
                                      width: _kColWidths[9],
                                      child: _RowActions(stock: s)),
                                  const Expanded(child: SizedBox()),
                                ]),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _cell(String text,
          {required int i, bool bold = false, bool mono = false}) =>
      SizedBox(
        width: _kColWidths[i],
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Text(text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF1A1D2E),
                  fontFamily: mono ? 'monospace' : null,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
        ),
      );
}

class _TH extends StatelessWidget {
  final String text;
  final int w;
  final TextStyle style;
  const _TH(this.text, {required this.w, required this.style});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kColWidths[w],
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Text(text, style: style, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _MobileList extends StatelessWidget {
  final PaginatedListState<StockInventoryModel> state;
  final HeadOfficeStockNotifier notifier;
  const _MobileList({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return PaginatedListView<StockInventoryModel>(
      state: state,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      onLoadMore: notifier.loadMore,
      onRefresh: notifier.refresh,
      emptyText: 'No stock entries found',
      itemBuilder: (_, s, __) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE7E9F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(s.productName ?? s.barcode,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                  _RowActions(stock: s),
                ],
              ),
              Text(s.barcode,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8A8FA3),
                      fontFamily: 'monospace')),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _chip('Size', s.sizeName ?? '—'),
                  _chip('Color', s.colorName ?? '—'),
                  _chip('Brand', s.brandName ?? '—'),
                  _chip('Category', s.categoryName ?? '—'),
                  _chip('Type', s.typeName ?? '—'),
                  _chip('Qty', '${s.quantity}',
                      color: const Color(0xFF2E7D32)),
                  _chip('Discount', '${s.discount.toStringAsFixed(0)}%',
                      color: Colors.orange.shade800),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(String label, String value, {Color? color}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE7E9F0)),
        ),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 11),
            children: [
              TextSpan(
                  text: '$label: ',
                  style: const TextStyle(color: Color(0xFF8A8FA3))),
              TextSpan(
                text: value,
                style: TextStyle(
                    color: color ?? const Color(0xFF1A1D2E),
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
}

// ── Barcode label dialog ─────────────────────────────────────────────────

class _BarcodeLabel extends StatelessWidget {
  final StockInventoryModel stock;
  const _BarcodeLabel({required this.stock});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF3E63DD);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.print_outlined, color: primary),
                  const SizedBox(width: 8),
                  const Text('Barcode Label',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border:
                      Border.all(color: Colors.grey.shade300, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Safi Shoe',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _BarcodeBars(barcode: stock.barcode),
                    const SizedBox(height: 6),
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
                    Divider(color: Colors.grey.shade200, height: 1),
                    const SizedBox(height: 12),
                    _LabelDetail(
                        icon: Icons.format_size_outlined,
                        label: 'Size',
                        value: stock.sizeName ?? '—'),
                    const SizedBox(height: 6),
                    _LabelDetail(
                        icon: Icons.color_lens_outlined,
                        label: 'Color',
                        value: stock.colorName ?? '—'),
                    const SizedBox(height: 6),
                    _LabelDetail(
                        icon: Icons.category_outlined,
                        label: 'Category',
                        value: stock.categoryName ?? '—'),
                    const SizedBox(height: 6),
                    _LabelDetail(
                        icon: Icons.style_outlined,
                        label: 'Type',
                        value: stock.typeName ?? '—'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy_outlined, size: 16),
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
                      icon: const Icon(Icons.print_outlined, size: 16),
                      label: const Text('Print'),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await BarcodePrintService.printLabelFields(
                          barcode: stock.barcode,
                          sizeName: stock.sizeName,
                          colorName: stock.colorName,
                          categoryName: stock.categoryName,
                          typeName: stock.typeName,
                        );
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

class _BarcodeBars extends StatelessWidget {
  final String barcode;
  const _BarcodeBars({required this.barcode});

  @override
  Widget build(BuildContext context) {
    final digits = barcode.split('').map((c) => int.tryParse(c) ?? 1).toList();
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: CustomPaint(painter: _BarcodePainter(digits: digits)),
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
      for (int j = 0; j < 4; j++) {
        final w = barWidth * (1 + ((d + j) % 3) * 0.5);
        if (j.isEven) {
          canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), paint);
        }
        x += w + barWidth * 0.4;
      }
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter old) => old.digits != digits;
}

class _LabelDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _LabelDetail(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Text('$label:',
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
