import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safishoe_app/core/pagination/pagination.dart';
import 'package:safishoe_app/features/warehouse/stock_inventory/data/barcode_printer_service.dart';
import '../../data/model/stock_inventory_model.dart';
import '../providers/stock_inventory_provider.dart';
import '../widgets/add_stock_inventory_dialog.dart';
import '../../../report/presentation/widgets/report_pagination_bar.dart';
import '../../../report/presentation/widgets/report_summary_card.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/widget/text_field_icon.dart';
import 'package:safishoe_app/core/widget/stock_level_filter.dart';
import 'package:safishoe_app/core/widget/stock_filter_dropdown.dart';
import 'package:safishoe_app/core/service/print/stock_report_printer.dart';
/// Superadmin stock view — head office ka stock (`stock_inventory` table).
/// Warehouse se koi taalluq nahi. Add / Edit / Delete + barcode print/copy.
class HeadOfficeStockScreen extends ConsumerStatefulWidget {
  const HeadOfficeStockScreen({super.key});

  @override
  ConsumerState<HeadOfficeStockScreen> createState() =>
      _HeadOfficeStockScreenState();
}

class _HeadOfficeStockScreenState extends ConsumerState<HeadOfficeStockScreen> {
  final _searchCtrl = TextEditingController();
  bool _printing = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _print(StockFilterOptions options) async {
    final state = ref.read(headOfficeStockProvider);
    String? name(List<StockFilterOption> l, String key) {
      final id = state.filters[key];
      for (final o in l) {
        if (o.id == id) return o.label;
      }
      return null;
    }

    final labels = <String>[
      if (name(options.categories, 'category_id') case final v?) 'Category: $v',
      if (name(options.types, 'type_id') case final v?) 'Type: $v',
      if (name(options.brands, 'brand_id') case final v?) 'Brand: $v',
      if (name(options.sizes, 'size_id') case final v?) 'Size: $v',
      if (state.filters['stock_level'] == 'low') 'Low Stock',
      if (state.filters['stock_level'] == 'out') 'Out of Stock',
      if (state.search.isNotEmpty) 'Search: ${state.search}',
    ];
    setState(() => _printing = true);
    try {
      final rows = await ref
          .read(stockInventoryRepositoryProvider)
          .fetchAllStock(search: state.search, filters: state.filters);
      await StockReportPrinter.print(
        title: 'Stock Inventory',
        rows: [
          for (final r in rows)
            StockReportRow(
              barcode: r.barcode,
              article: r.productName,
              brand: r.brandName,
              size: r.sizeName,
              color: r.colorName,
              category: r.categoryName,
              type: r.typeName,
              quantity: r.quantity,
              salePrice: r.salePrice,
            ),
        ],
        filterLabels: labels,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Print failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

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
    final options = ref.watch(stockFilterOptionsProvider).asData?.value ??
        const StockFilterOptions();
    const filterKeys = [
      'category_id',
      'type_id',
      'brand_id',
      'size_id',
      'stock_level'
    ];
    final hasFilters = filterKeys.any((k) => state.filters[k] != null) ||
        state.search.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Row(
              children: [
                const Text('Stock Inventory',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    notifier.refresh();
                    ref.invalidate(headOfficeStockStatsProvider);
                  },
                  icon: const AppIcon(AppIcons.refresh, size: 18),
                  tooltip: 'Refresh',
                  color: const Color(0xFF3E63DD),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _openAddStock,
                  icon: const AppIcon(AppIcons.add, size: 18, color: Colors.white),
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
            child: _StatsCards(
              stats: stats.value ?? const HeadOfficeStockStats(),
              isMobile: isMobile,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: isMobile ? double.infinity : 360,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: notifier.setSearch,
                    decoration: InputDecoration(
                      hintText: 'Search by barcode, article, brand...',
                      hintStyle:
                          const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
                      prefixIcon: const TextFieldIcon(AppIcons.search, size: 24, color: Color(0xFF8A8FA3)),
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
                StockLevelFilter(
                  level: state.filters['stock_level'] as String?,
                  lowCount: stats.value?.lowCount ?? 0,
                  outCount: stats.value?.outCount ?? 0,
                  onChanged: (v) => notifier.setFilters({'stock_level': v}),
                ),
                StockFilterDropdown(
                  label: 'Category',
                  options: options.categories,
                  value: state.filters['category_id'] as String?,
                  onChanged: (v) => notifier.setFilters({'category_id': v}),
                ),
                StockFilterDropdown(
                  label: 'Type',
                  options: options.types,
                  value: state.filters['type_id'] as String?,
                  onChanged: (v) => notifier.setFilters({'type_id': v}),
                ),
                StockFilterDropdown(
                  label: 'Brand',
                  options: options.brands,
                  value: state.filters['brand_id'] as String?,
                  onChanged: (v) => notifier.setFilters({'brand_id': v}),
                ),
                StockFilterDropdown(
                  label: 'Size',
                  options: options.sizes,
                  value: state.filters['size_id'] as String?,
                  onChanged: (v) => notifier.setFilters({'size_id': v}),
                ),
                OutlinedButton.icon(
                  onPressed: _printing ? null : () => _print(options),
                  icon: _printing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const AppIcon(AppIcons.printOutlined,
                          size: 18, color: Color(0xFF3E63DD)),
                  label: const Text('Print'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF3E63DD),
                    side: const BorderSide(color: Color(0xFFE7E9F0)),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                if (hasFilters)
                  OutlinedButton.icon(
                    onPressed: () {
                      _searchCtrl.clear();
                      notifier.setSearch('');
                      notifier.setFilters({
                        'category_id': null,
                        'type_id': null,
                        'brand_id': null,
                        'size_id': null,
                        'stock_level': null,
                      });
                    },
                    icon: const AppIcon(AppIcons.clear,
                        size: 18, color: Colors.red),
                    label: const Text('Clear'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      side: BorderSide(color: Colors.red.shade200),
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: isMobile
                ? _MobileList(state: state, notifier: notifier)
                : _DesktopTable(state: state, notifier: notifier),
          ),
          if (state.totalCount > 0 && state.error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ReportPaginationBar(
                page: state.page,
                totalPages: notifier.totalPages,
                totalCount: state.totalCount,
                pageSize: state.pageSize,
                onPageChange: notifier.goToPage,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Summary cards ────────────────────────────────────────────────────────

/// Total Articles / Total Stock / Total Purchase Price / Total Sale Price —
/// desktop par ek hi row mein, mobile par 2 per row.
class _StatsCards extends StatelessWidget {
  final HeadOfficeStockStats stats;
  final bool isMobile;
  const _StatsCards({required this.stats, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final cards = [
      ReportSummaryCard(
        label: 'Total Articles',
        value: groupThousands(stats.totalSkus),
        icon: AppIcons.categoryOutlined,
        color: const Color(0xFF6C4DE0),
      ),
      ReportSummaryCard(
        label: 'Total Stock',
        value: '${groupThousands(stats.totalQty)} pairs',
        icon: AppIcons.warehouseOutlined,
        color: const Color(0xFF3E63DD),
      ),
      ReportSummaryCard(
        label: 'Total Purchase Price',
        value: 'Rs. ${groupThousands(stats.totalPurchaseValue.round())}',
        icon: AppIcons.shoppingCartCheckoutOutlined,
        color: const Color(0xFFE08A00),
      ),
      ReportSummaryCard(
        label: 'Total Sale Price',
        value: 'Rs. ${groupThousands(stats.totalValue.round())}',
        icon: AppIcons.pointOfSaleOutlined,
        color: const Color(0xFF22A06B),
      ),
    ];
    if (isMobile) {
      return LayoutBuilder(builder: (context, c) {
        const gap = 12.0;
        final w = (c.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final card in cards) SizedBox(width: w, child: card)],
        );
      });
    }
    return Row(children: [
      for (var i = 0; i < cards.length; i++) ...[
        if (i > 0) const SizedBox(width: 14),
        Expanded(child: cards[i]),
      ],
    ]);
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
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Quantity *',
                    prefixIcon: const TextFieldIcon(AppIcons.numbersOutlined, size: 24),
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
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Discount %',
                    prefixIcon: const TextFieldIcon(AppIcons.percentOutlined, size: 24),
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
          icon: AppIcons.editOutlined,
          color: const Color(0xFF3E63DD),
          tooltip: 'Edit',
          onPressed: () => _showEditDialog(context, ref, stock),
        ),
        _actionBtn(
          icon: AppIcons.copyOutlined,
          color: Colors.blueGrey,
          tooltip: 'Copy barcode',
          onPressed: () => _copyBarcode(context, stock.barcode),
        ),
        _actionBtn(
          icon: AppIcons.printOutlined,
          color: const Color(0xFF3E63DD),
          tooltip: 'Print label',
          onPressed: () => _showPrintDialog(context, stock),
        ),
        _actionBtn(
          icon: AppIcons.deleteOutline,
          color: Colors.red,
          tooltip: 'Delete',
          onPressed: () => _confirmDelete(context, ref, stock),
        ),
      ],
    );
  }

  Widget _actionBtn({
    required String icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: AppIcon(icon, size: 18, color: color),
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
  60, // #
  210, // Barcode
  340, // Article (neeche color / size / brand / category / type)
  130, // Purchase Price
  130, // Sale Price
  70, // Qty
  80, // Discount
  190, // Actions
];
const _kTableMinWidth = 1450; // sum(_kColWidths) 1410 + row padding 32 + slack

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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                            _TH('#', w: 0, style: headerStyle),
                            _TH('Barcode', w: 1, style: headerStyle),
                            _TH('Article', w: 2, style: headerStyle),
                            _TH('Purchase Price', w: 3, style: headerStyle),
                            _TH('Sale Price', w: 4, style: headerStyle),
                            _TH('Qty', w: 5, style: headerStyle),
                            _TH('Discount', w: 6, style: headerStyle),
                            _TH('Actions', w: 7, style: headerStyle),
                            Expanded(child: SizedBox()),
                          ]),
                        ),
                        Expanded(
                          child: PaginatedListView<StockInventoryModel>(
                            state: widget.state,
                            padding: EdgeInsets.zero,
                            // Page-by-page — scroll par aur rows load nahi hoti.
                            onLoadMore: () async {},
                            onRefresh: widget.notifier.refresh,
                            emptyText: 'No stock entries found',
                            separatorBuilder: (_, __) => const Divider(
                                height: 1, color: Color(0xFFE7E9F0)),
                            itemBuilder: (_, s, index) {
                              final serial = (widget.state.page - 1) *
                                      widget.state.pageSize +
                                  index +
                                  1;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                child: Row(children: [
                                  _cell('$serial', i: 0),
                                  _cell(s.barcode, i: 1, mono: true),
                                  _articleCell(s, i: 2),
                                  _cell('Rs ${s.purchasePrice.toStringAsFixed(0)}',
                                      i: 3),
                                  _cell('Rs ${s.salePrice.toStringAsFixed(0)}',
                                      i: 4, bold: true),
                                  _cell('${s.quantity}', i: 5),
                                  _cell('${s.discount.toStringAsFixed(0)}%',
                                      i: 6),
                                  SizedBox(
                                      width: _kColWidths[7],
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

  /// Sale Invoice ke Article dropdown jaisa — naam, neeche variant ki detail.
  Widget _articleCell(StockInventoryModel s, {required int i}) => SizedBox(
        width: _kColWidths[i],
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.productName ?? '—',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1A1D2E),
                      fontWeight: FontWeight.w600)),
              if (s.variantLine.isNotEmpty)
                Text(s.variantLine,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF8A8FA3))),
            ],
          ),
        ),
      );

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
      onLoadMore: () async {},
      onRefresh: notifier.refresh,
      emptyText: 'No stock entries found',
      itemBuilder: (_, s, index) {
        final serial = (state.page - 1) * state.pageSize + index + 1;
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
                    child: Text('$serial. ${s.productName ?? s.barcode}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                  _RowActions(stock: s),
                ],
              ),
              if (s.variantLine.isNotEmpty)
                Text(s.variantLine,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF5A5F73))),
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
                  _chip('Purchase',
                      'Rs ${s.purchasePrice.toStringAsFixed(0)}'),
                  _chip('Sale', 'Rs ${s.salePrice.toStringAsFixed(0)}',
                      color: const Color(0xFF3E63DD)),
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
                  const AppIcon(AppIcons.printOutlined, color: primary),
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
  final String icon;
  final String label;
  final String value;

  const _LabelDetail(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIcon(icon, size: 14, color: Colors.grey.shade500),
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
