import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/pagination/pagination.dart';
import '../../data/model/branch_stock_model.dart';
import '../povider/branch_stock_provider.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/widget/text_field_icon.dart';
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(branchStockProvider);
    final notifier = ref.read(branchStockProvider.notifier);
    final stats = ref.watch(branchStockStatsProvider).asData?.value ??
        const BranchStockStats();

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
                    color: _primary.withOpacity(0.1),
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
                  label: 'Low Stock (≤5)',
                  value: groupThousands(stats.lowStockCount),
                  icon: AppIcons.warningAmberOutlined,
                  color: stats.lowStockCount > 0
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
                        color: Color(0xFF8A8FA3), size: 12),
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
                      color: Colors.black.withOpacity(0.04),
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
    final isLowStock = item.quantity <= 5;

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

          // ── Stock Badge (FIX: tight width, MainAxisSize.min) ─────────
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isLowStock
                      ? Colors.orange.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isLowStock
                        ? Colors.orange.shade300
                        : Colors.green.shade200,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min, // ← KEY FIX
                  children: [
                    if (isLowStock) ...[
                      AppIcon(AppIcons.warningAmberRounded,
                          size: 12,
                          color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      '${item.quantity}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isLowStock
                            ? Colors.orange.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
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
              color: Colors.black.withOpacity(0.03),
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
                color: color.withOpacity(0.1),
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