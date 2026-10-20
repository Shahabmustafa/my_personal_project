import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/pagination/pagination.dart';
import '../../data/model/branch_stock_model.dart';
import '../povider/branch_stock_provider.dart';
import 'package:safishoe_app/core/service/print/stock_report_printer.dart';
import 'package:safishoe_app/core/widget/stock_filter_dropdown.dart';
import '../../../shared/current_branch_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/widget/text_field_icon.dart';
import 'package:safishoe_app/core/widget/stock_level_filter.dart';
class BranchStockScreen extends ConsumerStatefulWidget {
  const BranchStockScreen({super.key});

  @override
  ConsumerState<BranchStockScreen> createState() =>
      _BranchStockScreenState();
}

class _BranchStockScreenState extends ConsumerState<BranchStockScreen> {
  final _searchCtrl = TextEditingController();
  static const _primary = Color(0xFF1565C0);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.read(branchStockProvider.notifier).refresh();
    ref.invalidate(branchStockStatsProvider);
  }

  bool _printing = false;

  Future<void> _print(StockFilterOptions options) async {
    final state = ref.read(branchStockProvider);
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
      final rows = await ref.read(branchStockRepositoryProvider).fetchAllStock(
            branchId: ref.read(currentBranchIdProvider),
            search: state.search,
            filters: state.filters,
          );
      await StockReportPrinter.print(
        title: 'Branch Stock Inventory',
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(branchStockProvider);
    final notifier = ref.read(branchStockProvider.notifier);
    final stats = ref.watch(branchStockStatsProvider).asData?.value ??
        const BranchStockStats();

    final options = ref.watch(stockFilterOptionsProvider).asData?.value ??
        const StockFilterOptions();
    const filterKeys = [
      'category_id',
      'type_id',
      'brand_id',
      'size_id',
      'stock_level'
    ];
    final hasFilters =
        filterKeys.any((k) => state.filters[k] != null) ||
            state.search.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const AppIcon(AppIcons.inventory2Outlined,
                      color: _primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Branch Stock Inventory',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E)),
                      ),
                      TotalCountLabel(
                        label: 'Products',
                        count: state.totalCount,
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: 'Refresh',
                  child: InkWell(
                    onTap: _refresh,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE7E9F0)),
                      ),
                      child: const AppIcon(AppIcons.refresh,
                          color: _primary, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Summary Cards ─────────────────────────────────────────────
            Row(
              children: [
                _SummaryCard(
                  label: 'Total Products',
                  value: groupThousands(state.totalCount),
                  icon: AppIcons.inventory2Outlined,
                  color: _primary,
                ),
                const SizedBox(width: 12),
                _SummaryCard(
                  label: 'Total Pairs',
                  value: groupThousands(stats.totalQuantity),
                  icon: AppIcons.straightenOutlined,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 12),
                _SummaryCard(
                  label: 'Low Stock (<5)',
                  value: groupThousands(stats.lowCount),
                  icon: AppIcons.warningAmberOutlined,
                  color: stats.lowCount > 0
                      ? Colors.orange.shade700
                      : Colors.grey.shade400,
                ),
                const SizedBox(width: 12),
                _SummaryCard(
                  label: 'Total Sale Price',
                  value: 'Rs. ${groupThousands(stats.totalSalePrice.round())}',
                  icon: AppIcons.sellOutlined,
                  color: const Color(0xFF6C4DE0),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Search Bar ────────────────────────────────────────────────
            ...[
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: notifier.setSearch,
                      decoration: InputDecoration(
                        hintText:
                        'Search by article, barcode, size, color, brand...',
                        hintStyle: const TextStyle(
                            fontSize: 13, color: Color(0xFF8A8FA3)),
                        prefixIcon: const TextFieldIcon(AppIcons.search,
                            color: Color(0xFF8A8FA3), size: 18),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                          icon: const AppIcon(AppIcons.clear,
                              size: 18, color: Color(0xFF8A8FA3)),
                          onPressed: () {
                            _searchCtrl.clear();
                            notifier.setSearch('');
                          },
                        )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                            const BorderSide(color: Color(0xFFE7E9F0))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                            const BorderSide(color: Color(0xFFE7E9F0))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: _primary, width: 1.5)),
                      ),
                    ),
                  ),
                  StockLevelFilter(
                    level: state.filters['stock_level'] as String?,
                    lowCount: stats.lowCount,
                    outCount: stats.outCount,
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
                            size: 18, color: _primary),
                    label: const Text('Print'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primary,
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

              const SizedBox(height: 14),
            ],

            // ── Table ─────────────────────────────────────────────────────
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE7E9F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    children: [
                      // Table Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        color: _primary,
                        child: const Row(
                          children: [
                            Expanded(flex: 1,  child: _TH('#')),
                            Expanded(flex: 3,  child: _TH('Barcode')),
                            Expanded(flex: 3,  child: _TH('Article')),
                            Expanded(flex: 2,  child: _TH('Brand')),
                            Expanded(flex: 2,  child: _TH('Size')),
                            Expanded(flex: 2,  child: _TH('Color')),
                            Expanded(flex: 2,  child: _TH('Category')),
                            Expanded(flex: 2,  child: _TH('Type')),
                            Expanded(flex: 2,  child: _TH('Stock')),
                            Expanded(flex: 2,  child: _TH('Sale Price')),
                            Expanded(flex: 2,  child: _TH('Discount')),
                          ],
                        ),
                      ),
                      // Table Body
                      Expanded(
                        child: PaginatedListView<BranchStockModel>(
                          state: state,
                          padding: EdgeInsets.zero,
                          onLoadMore: notifier.loadMore,
                          onRefresh: () async => _refresh(),
                          emptyState:
                              _EmptyView(isSearch: state.search.isNotEmpty),
                          separatorBuilder: (_, __) => const Divider(
                              height: 1, color: Color(0xFFEEF0F6)),
                          itemBuilder: (_, item, i) =>
                              _StockRow(item: item, index: i),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Footer ────────────────────────────────────────────────────
            if (state.rows.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE7E9F0)),
                ),
                child: Row(
                  children: [
                    const AppIcon(AppIcons.infoOutline,
                        size: 14, color: Color(0xFF8A8FA3)),
                    const SizedBox(width: 6),
                    Text(
                      'Showing ${state.rows.length} of ${groupThousands(state.totalCount)} products',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF8A8FA3)),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAEFFD),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Total: ${groupThousands(stats.totalQuantity)} pairs',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _primary),
                      ),
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

// ── Stock Row ─────────────────────────────────────────────────────────────────

class _StockRow extends StatelessWidget {
  final BranchStockModel item;
  final int index;

  const _StockRow({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: index.isEven ? const Color(0xFFFAFBFF) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // #
          Expanded(
            flex: 1,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8A8FA3),
                  fontWeight: FontWeight.w500),
            ),
          ),
          // Barcode
          Expanded(
            flex: 3,
            child: Text(
              item.barcode,
              style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: Color(0xFF5A5F73)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Article
          Expanded(
            flex: 3,
            child: Text(
              item.productName ?? '—',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Brand
          Expanded(
            flex: 2,
            child: Text(
              item.brandName ?? '—',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF5A5F73)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Size
          Expanded(
            flex: 2,
            child: Text(
              item.sizeName ?? '—',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF5A5F73)),
            ),
          ),
          // Color
          Expanded(
            flex: 2,
            child: Text(
              item.colorName ?? '—',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF5A5F73)),
            ),
          ),
          // Category
          Expanded(
            flex: 2,
            child: Text(
              item.categoryName ?? '—',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF5A5F73)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Type
          Expanded(
            flex: 2,
            child: Text(
              item.typeName ?? '—',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF5A5F73)),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Stock
          Expanded(
            flex: 2,
            child: Text(
              '${item.quantity}',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E)),
            ),
          ),

          // Sale Price
          Expanded(
            flex: 2,
            child: Text(
              'PKR ${item.salePrice.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
            ),
          ),

          // Discount
          Expanded(
            flex: 2,
            child: Text(
              item.discount > 0
                  ? '${item.discount.toStringAsFixed(0)}%'
                  : '—',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary Card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7E9F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: AppIcon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF8A8FA3)),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Table Header Cell ─────────────────────────────────────────────────────────

class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.3),
    );
  }
}

// ── Empty View ────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final bool isSearch;
  const _EmptyView({required this.isSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F4FF),
              shape: BoxShape.circle,
            ),
            child: AppIcon(
              isSearch
                  ? AppIcons.searchOffOutlined
                  : AppIcons.inventory2Outlined,
              size: 48,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearch
                ? 'No results found'
                : 'No stock in branch inventory',
            style: const TextStyle(
                color: Color(0xFF8A8FA3),
                fontSize: 15,
                fontWeight: FontWeight.w500),
          ),
          if (isSearch) ...[
            const SizedBox(height: 6),
            const Text(
              'Try searching with different keywords',
              style: TextStyle(
                  color: Color(0xFFB0B5C8), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}