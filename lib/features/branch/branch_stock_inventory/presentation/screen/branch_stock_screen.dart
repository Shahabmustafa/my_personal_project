import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/pagination/pagination.dart';
import 'package:safishoe_app/core/utils/responsive.dart';
import '../../data/model/branch_stock_model.dart';
import '../povider/branch_stock_provider.dart';
import 'package:safishoe_app/core/service/print/stock_report_printer.dart';
import 'package:safishoe_app/core/widget/stock_filter_dropdown.dart';
import '../../../shared/current_branch_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/widget/text_field_icon.dart';
import 'package:safishoe_app/core/widget/stock_level_filter.dart';
import 'package:safishoe_app/core/widget/stock_size_variants.dart';

class BranchStockScreen extends ConsumerStatefulWidget {
  const BranchStockScreen({super.key});

  @override
  ConsumerState<BranchStockScreen> createState() => _BranchStockScreenState();
}

class _BranchStockScreenState extends ConsumerState<BranchStockScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  static const _primary = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      if (!_scrollCtrl.hasClients) return;
      final pos = _scrollCtrl.position;
      if (pos.pixels >= pos.maxScrollExtent - 400) {
        ref.read(branchStockProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.read(branchStockProvider.notifier).refresh();
    ref.invalidate(branchStockStatsProvider);
  }

  bool _printing = false;

  /// Article whose sizes are open in the right-side slider (null = closed).
  BranchStockModel? _selected;

  static String _key(BranchStockModel s) =>
      '${s.productId}|${s.colorId}|${s.brandId}|${s.categoryId}|${s.typeId}';

  String _subtitle(BranchStockModel s) => [
    s.colorName,
    s.brandName,
    s.categoryName,
    s.typeName,
  ].whereType<String>().join(' · ');

  StockSizesBody<BranchStockModel> _sizesBody(
    BranchStockModel s,
    Object? refreshToken,
  ) => StockSizesBody<BranchStockModel>(
    key: ValueKey(_key(s)),
    loader: () => ref
        .read(branchStockRepositoryProvider)
        .fetchVariants(s, branchId: ref.read(currentBranchIdProvider)),
    refreshToken: refreshToken,
    sizeOf: (i) => i.sizeName ?? '—',
    barcodeOf: (i) => i.barcode,
    qtyOf: (i) => i.quantity,
    salePriceOf: (i) => i.salePrice,
    discountOf: (i) => i.discount,
  );

  PaginatedListState<_Grp> _groupedState(
    PaginatedListState<BranchStockModel> st,
  ) => PaginatedListState<_Grp>(
    rows: groupStock<BranchStockModel>(st.rows, _key).map(_Grp.new).toList(),
    totalCount: st.totalCount,
    page: st.page,
    pageSize: st.pageSize,
    isFirstLoad: st.isFirstLoad,
    isLoadingMore: st.isLoadingMore,
    isRefreshing: st.isRefreshing,
    error: st.error,
    loadMoreError: st.loadMoreError,
    search: st.search,
    filters: st.filters,
  );

  void _open(BranchStockModel s, bool isMobile, Object? refreshToken) {
    if (isMobile) {
      showStockSizesSheet<BranchStockModel>(
        context,
        title: s.productName ?? '—',
        subtitle: _subtitle(s),
        body: _sizesBody(s, refreshToken),
      );
    } else {
      setState(() => _selected = s);
    }
  }

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
      final rows = await ref
          .read(branchStockRepositoryProvider)
          .fetchAllStock(
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Print failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  /// Phone layout: the whole page is one scrolling list (header, cards and
  /// filters first, then a card per stock row) so the rows always get room.
  Widget _buildMobileList(
    dynamic state,
    dynamic notifier,
    BranchStockStats stats,
    List<Widget> top,
  ) {
    final rows = groupStock<BranchStockModel>(
      state.rows as List<BranchStockModel>,
      _key,
    ).map(_Grp.new).toList();
    Widget? status;
    if (state.showInitialLoader) {
      status = const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (state.showFirstError) {
      status = Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              Text('${state.error}', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
            ],
          ),
        ),
      );
    } else if (state.showEmpty) {
      status = SizedBox(
        height: 240,
        child: _EmptyView(isSearch: state.search.isNotEmpty),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: ListView.builder(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: 2 + (status == null ? rows.length : 0),
        itemBuilder: (context, i) {
          if (i == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [...top, const SizedBox(height: 4)],
            );
          }
          if (status != null) return status;
          if (i == rows.length + 1) {
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: state.isLoadingMore
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Center(
                      child: Text(
                        '${rows.length} articles · ${groupThousands(state.totalCount)} products · '
                        'Total: ${groupThousands(stats.totalQuantity)} pairs',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8A8FA3),
                        ),
                      ),
                    ),
            );
          }
          final g = rows[i - 1];
          return _StockCard(
            item: g,
            onTap: () => _open(g.first, true, state.rows),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(branchStockProvider);
    final notifier = ref.read(branchStockProvider.notifier);
    final stats =
        ref.watch(branchStockStatsProvider).asData?.value ??
        const BranchStockStats();

    final options =
        ref.watch(stockFilterOptionsProvider).asData?.value ??
        const StockFilterOptions();
    const filterKeys = [
      'category_id',
      'type_id',
      'brand_id',
      'size_id',
      'stock_level',
    ];
    final hasFilters =
        filterKeys.any((k) => state.filters[k] != null) ||
        state.search.isNotEmpty;

    final isMobile = Responsive(context).isMobile;

    final top = <Widget>[
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
            child: const AppIcon(
              AppIcons.inventory2Outlined,
              color: _primary,
              size: 22,
            ),
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
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                TotalCountLabel(label: 'Products', count: state.totalCount),
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
                child: const AppIcon(
                  AppIcons.refresh,
                  color: _primary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),

      // ── Summary Cards ─────────────────────────────────────────────
      if (isMobile) ...[
        Row(
          children: [
            _SummaryCard(
              label: 'Total Pairs',
              value: groupThousands(stats.totalQuantity),
              icon: AppIcons.straightenOutlined,
              color: Colors.green.shade700,
            ),
            const SizedBox(width: 10),
            _SummaryCard(
              label: 'Low Stock (<5)',
              value: groupThousands(stats.lowCount),
              icon: AppIcons.warningAmberOutlined,
              color: stats.lowCount > 0
                  ? Colors.orange.shade700
                  : Colors.grey.shade400,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _SummaryCard(
              label: 'Total Sale Price',
              value: 'Rs. ${groupThousands(stats.totalSalePrice.round())}',
              icon: AppIcons.sellOutlined,
              color: const Color(0xFF6C4DE0),
            ),
          ],
        ),
      ] else
        Row(
          children: [
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
              constraints: BoxConstraints(
                maxWidth: isMobile ? double.infinity : 230,
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: notifier.setSearch,
                decoration: InputDecoration(
                  hintText: 'Search by article, barcode, size, color, brand...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8A8FA3),
                  ),
                  prefixIcon: const TextFieldIcon(
                    AppIcons.search,
                    color: Color(0xFF8A8FA3),
                    size: 18,
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const AppIcon(
                            AppIcons.clear,
                            size: 18,
                            color: Color(0xFF8A8FA3),
                          ),
                          onPressed: () {
                            _searchCtrl.clear();
                            notifier.setSearch('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE7E9F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE7E9F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _primary, width: 1.5),
                  ),
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
            OutlinedButton.icon(
              onPressed: _printing ? null : () => _print(options),
              icon: _printing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const AppIcon(
                      AppIcons.printOutlined,
                      size: 18,
                      color: _primary,
                    ),
              label: const Text('Print'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: const BorderSide(color: Color(0xFFE7E9F0)),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
                icon: const AppIcon(
                  AppIcons.clear,
                  size: 18,
                  color: Colors.red,
                ),
                label: const Text('Clear'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  side: BorderSide(color: Colors.red.shade200),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 14),
      ],
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: isMobile
          ? _buildMobileList(state, notifier, stats, top)
          : Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...top,

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
                                    horizontal: 16,
                                    vertical: 13,
                                  ),
                                  color: _primary,
                                  child: const Row(
                                    children: [
                                      Expanded(flex: 1, child: _TH('#')),
                                      Expanded(flex: 3, child: _TH('Barcode')),
                                      Expanded(flex: 3, child: _TH('Article')),
                                      Expanded(flex: 2, child: _TH('Brand')),
                                      Expanded(flex: 2, child: _TH('Size')),
                                      Expanded(flex: 2, child: _TH('Color')),
                                      Expanded(flex: 2, child: _TH('Category')),
                                      Expanded(flex: 2, child: _TH('Type')),
                                      Expanded(flex: 2, child: _TH('Stock')),
                                      Expanded(
                                        flex: 2,
                                        child: _TH('Sale Price'),
                                      ),
                                      Expanded(flex: 2, child: _TH('Discount')),
                                    ],
                                  ),
                                ),
                                // Table Body
                                Expanded(
                                  child: PaginatedListView<_Grp>(
                                    state: _groupedState(state),
                                    padding: EdgeInsets.zero,
                                    onLoadMore: notifier.loadMore,
                                    onRefresh: () async => _refresh(),
                                    emptyState: _EmptyView(
                                      isSearch: state.search.isNotEmpty,
                                    ),
                                    separatorBuilder: (_, __) => const Divider(
                                      height: 1,
                                      color: Color(0xFFEEF0F6),
                                    ),
                                    itemBuilder: (_, item, i) => _StockRow(
                                      item: item,
                                      index: i,
                                      onTap: () =>
                                          _open(item.first, false, state.rows),
                                    ),
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
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE7E9F0)),
                          ),
                          child: Row(
                            children: [
                              const AppIcon(
                                AppIcons.infoOutline,
                                size: 14,
                                color: Color(0xFF8A8FA3),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Showing ${groupStock<BranchStockModel>(state.rows, _key).length} articles (${state.rows.length} of ${groupThousands(state.totalCount)} products)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8A8FA3),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAEFFD),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Total: ${groupThousands(stats.totalQuantity)} pairs',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (_selected != null)
                  StockSizesOverlay<BranchStockModel>(
                    title: _selected!.productName ?? '—',
                    subtitle: _subtitle(_selected!),
                    onClose: () => setState(() => _selected = null),
                    body: _sizesBody(_selected!, state.rows),
                  ),
              ],
            ),
    );
  }
}

// ── Stock Row ─────────────────────────────────────────────────────────────────

class _StockRow extends StatelessWidget {
  final _Grp item;
  final int index;
  final VoidCallback onTap;

  const _StockRow({
    required this.item,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
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
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Barcode
            Expanded(
              flex: 3,
              child: Text(
                item.barcodeLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: Color(0xFF5A5F73),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Article
            Expanded(
              flex: 3,
              child: Text(
                item.first.productName ?? '—',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Brand
            Expanded(
              flex: 2,
              child: Text(
                item.first.brandName ?? '—',
                style: const TextStyle(fontSize: 12, color: Color(0xFF5A5F73)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Size
            Expanded(
              flex: 2,
              child: Text(
                item.sizesLabel,
                style: const TextStyle(fontSize: 12, color: Color(0xFF5A5F73)),
              ),
            ),
            // Color
            Expanded(
              flex: 2,
              child: Text(
                item.first.colorName ?? '—',
                style: const TextStyle(fontSize: 12, color: Color(0xFF5A5F73)),
              ),
            ),
            // Category
            Expanded(
              flex: 2,
              child: Text(
                item.first.categoryName ?? '—',
                style: const TextStyle(fontSize: 12, color: Color(0xFF5A5F73)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Type
            Expanded(
              flex: 2,
              child: Text(
                item.first.typeName ?? '—',
                style: const TextStyle(fontSize: 12, color: Color(0xFF5A5F73)),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Stock
            Expanded(
              flex: 2,
              child: Text(
                '${item.qty}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),

            // Sale Price
            Expanded(
              flex: 2,
              child: Text(
                'PKR ${item.priceText}',
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
                item.hasDiscount ? item.discountText : '—',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stock Card (phone layout) ─────────────────────────────────────────────────

class _StockCard extends StatelessWidget {
  final _Grp item;
  final VoidCallback onTap;
  const _StockCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final low = item.qty < 5;
    final detail = [
      item.first.brandName,
      item.sizesLabel,
      item.first.colorName,
    ].whereType<String>().join(' · ');
    final group = [
      item.first.categoryName,
      item.first.typeName,
    ].whereType<String>().join(' · ');
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7E9F0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.first.productName ?? '—',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.barcodeLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: Color(0xFF8A8FA3),
                    ),
                  ),
                  if (detail.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      detail,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5A5F73),
                      ),
                    ),
                  ],
                  if (group.isNotEmpty)
                    Text(
                      group,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8A8FA3),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (low ? Colors.orange : Colors.green).withValues(
                      alpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Stock ${item.qty}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: low
                          ? Colors.orange.shade800
                          : Colors.green.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'PKR ${item.priceText}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade700,
                  ),
                ),
                if (item.hasDiscount)
                  Text(
                    '${item.discountText} off',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade800,
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

/// One list row = every size of an article (same product, color, brand,
/// category and type) rolled together.
class _Grp {
  final StockGroup<BranchStockModel> group;
  const _Grp(this.group);

  List<BranchStockModel> get _items => group.items;
  BranchStockModel get first => group.first;

  int get qty => _items.fold(0, (s, i) => s + i.quantity);
  String get sizesLabel =>
      _items.length == 1 ? (first.sizeName ?? '—') : '${_items.length} sizes';
  String get barcodeLabel =>
      _items.length == 1 ? first.barcode : '${_items.length} barcodes';
  String get priceText =>
      sameOrRange(_items.map((i) => i.salePrice), (v) => v.toStringAsFixed(0));
  bool get hasDiscount => _items.any((i) => i.discount > 0);
  String get discountText => sameOrRange(
    _items.map((i) => i.discount),
    (v) => '${v.toStringAsFixed(0)}%',
  );
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    fontSize: 11,
                    color: Color(0xFF8A8FA3),
                  ),
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
        letterSpacing: 0.3,
      ),
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
            isSearch ? 'No results found' : 'No stock in branch inventory',
            style: const TextStyle(
              color: Color(0xFF8A8FA3),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isSearch) ...[
            const SizedBox(height: 6),
            const Text(
              'Try searching with different keywords',
              style: TextStyle(color: Color(0xFFB0B5C8), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
