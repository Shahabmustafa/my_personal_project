import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/pagination/pagination.dart';
import '../../../../auth/presentation/providers/workspace_selection_provider.dart';
import '../../../../superadmin/warehouse/data/model/warehouse_model.dart';
import '../../../../superadmin/warehouse/presentation/providers/warehouse_provider.dart';
import '../../data/models/warehouse_stock_model.dart';
import '../providers/stock_provider.dart';
import '../widgets/add_stock_dialog.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
import 'package:safishoe_app/core/widget/text_field_icon.dart';
import 'package:safishoe_app/core/widget/stock_size_variants.dart';

/// Admin-only stock view — shows inventory across ALL warehouses (unlike
/// [StockScreen] which is scoped to the logged-in user's single assigned
/// warehouse). Server-paginated; admin can add new stock (picking which
/// warehouse it goes into); edit/delete stay off-limits here.
class AdminStockScreen extends ConsumerStatefulWidget {
  const AdminStockScreen({super.key});

  @override
  ConsumerState<AdminStockScreen> createState() => _AdminStockScreenState();
}

class _AdminStockScreenState extends ConsumerState<AdminStockScreen> {
  /// Article whose sizes are open in the right-side slider (null = closed).
  WarehouseStockModel? _selected;

  static String _key(WarehouseStockModel s) =>
      '${s.warehouseId}|${s.productId}|${s.colorId}|${s.brandId}|${s.categoryId}|${s.typeId}';

  static String _subtitle(WarehouseStockModel s) => [
    s.warehouseName,
    s.colorName,
    s.brandName,
    s.categoryName,
    s.typeName,
  ].whereType<String>().where((e) => e.isNotEmpty).join(' · ');

  StockSizesBody<WarehouseStockModel> _sizesBody(
    WarehouseStockModel s,
    Object? refreshToken,
  ) => StockSizesBody<WarehouseStockModel>(
    key: ValueKey(_key(s)),
    loader: () => ref.read(stockRepositoryProvider).fetchVariants(s),
    refreshToken: refreshToken,
    sizeOf: (i) => i.sizeName ?? '—',
    barcodeOf: (i) => i.barcode,
    qtyOf: (i) => i.quantity,
    salePriceOf: (i) => i.salePrice,
    discountOf: (i) => i.discount,
  );

  void _open(WarehouseStockModel s, bool isMobile, Object? refreshToken) {
    if (isMobile) {
      showStockSizesSheet<WarehouseStockModel>(
        context,
        title: s.productName ?? '—',
        subtitle: _subtitle(s),
        body: _sizesBody(s, refreshToken),
      );
    } else {
      setState(() => _selected = s);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(warehouseProvider.notifier).loadAllWarehouses();
    });
  }

  Future<void> _openAddStock() async {
    final warehouses = ref.read(warehouseProvider).warehouses;
    final currentSelection = ref.read(selectedWarehouseIdProvider);
    var targetWarehouseId = currentSelection;

    if (targetWarehouseId.isEmpty ||
        !warehouses.any((w) => w.id == targetWarehouseId)) {
      final picked = await showDialog<String>(
        context: context,
        builder: (_) => _PickWarehouseDialog(warehouses: warehouses),
      );
      if (picked == null) return;
      targetWarehouseId = picked;
    }

    await ref
        .read(selectedWarehouseIdProvider.notifier)
        .select(targetWarehouseId);
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AddStockDialog(),
    );

    ref.read(adminStockProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminStockProvider);
    final notifier = ref.read(adminStockProvider.notifier);
    final isMobile = MediaQuery.of(context).size.width < 768;

    final top = <Widget>[
      Padding(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 16 : 24,
          isMobile ? 16 : 28,
          isMobile ? 16 : 24,
          20,
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stock Inventory',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                TotalCountLabel(
                  label: 'SKUs (all warehouses)',
                  count: state.totalCount,
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              onPressed: notifier.refresh,
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
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 16 : 24,
          0,
          isMobile ? 16 : 24,
          16,
        ),
        child: TextField(cursorHeight: 16, 
          onChanged: notifier.setSearch,
          decoration: InputDecoration(
            hintText: 'Search by barcode, article, brand, warehouse...',
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
            prefixIcon: const TextFieldIcon(
              AppIcons.search,
              size: 18,
              color: Color(0xFF8A8FA3),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
              borderSide: const BorderSide(
                color: Color(0xFF3E63DD),
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...top,
                Expanded(
                  child: _MobileList(
                    state: state,
                    notifier: notifier,
                    onOpen: (s) => _open(s, true, state.rows),
                  ),
                ),
              ],
            )
          : Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...top,
                    Expanded(
                      child: _DesktopTable(
                        state: state,
                        notifier: notifier,
                        onOpen: (s) => _open(s, false, state.rows),
                      ),
                    ),
                  ],
                ),
                if (_selected != null)
                  StockSizesOverlay<WarehouseStockModel>(
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

/// One list row = every size of an article in a warehouse (same product,
/// color, brand, category and type) rolled together.
class _Grp {
  final StockGroup<WarehouseStockModel> group;
  const _Grp(this.group);

  List<WarehouseStockModel> get _items => group.items;
  WarehouseStockModel get first => group.first;

  int get qty => _items.fold(0, (s, i) => s + i.quantity);
  String get sizesLabel => _items.length == 1
      ? 'Size ${first.sizeName ?? '—'}'
      : '${_items.length} sizes';
  String get barcodeLabel =>
      _items.length == 1 ? first.barcode : '${_items.length} barcodes';
  String get articleLine => [
    first.colorName,
    first.brandName,
    first.categoryName,
    first.typeName,
  ].whereType<String>().where((e) => e.isNotEmpty).join(' • ');
  String get saleText =>
      sameOrRange(_items.map((i) => i.salePrice), (v) => v.toStringAsFixed(0));
  String get discountText => sameOrRange(
    _items.map((i) => i.discount),
    (v) => '${v.toStringAsFixed(0)}%',
  );
}

String _groupKey(WarehouseStockModel s) =>
    '${s.warehouseId}|${s.productId}|${s.colorId}|${s.brandId}|${s.categoryId}|${s.typeId}';

/// Same state with the loaded rows rolled up into one entry per article.
PaginatedListState<_Grp> _groupState(
  PaginatedListState<WarehouseStockModel> st,
) => PaginatedListState<_Grp>(
  rows: groupStock<WarehouseStockModel>(
    st.rows,
    _groupKey,
  ).map(_Grp.new).toList(),
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

class _DesktopTable extends StatelessWidget {
  final PaginatedListState<WarehouseStockModel> state;
  final AdminStockNotifier notifier;
  final void Function(WarehouseStockModel) onOpen;
  const _DesktopTable({
    required this.state,
    required this.notifier,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Color(0xFF8A8FA3),
      letterSpacing: 0.3,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7E9F0)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F8FC),
                  border: Border(bottom: BorderSide(color: Color(0xFFE7E9F0))),
                ),
                child: const Row(
                  children: [
                    _TH('Warehouse', flex: 2, style: headerStyle),
                    _TH('Barcode', flex: 2, style: headerStyle),
                    _TH('Article', flex: 3, style: headerStyle),
                    _TH('Sale Price', flex: 2, style: headerStyle),
                    _TH('Qty', flex: 1, style: headerStyle),
                    _TH('Discount', flex: 1, style: headerStyle),
                    _TH('Sizes', flex: 2, style: headerStyle),
                  ],
                ),
              ),
              Expanded(
                child: PaginatedListView<_Grp>(
                  state: _groupState(state),
                  padding: EdgeInsets.zero,
                  onLoadMore: notifier.loadMore,
                  onRefresh: notifier.refresh,
                  emptyText: 'No stock entries found',
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFE7E9F0)),
                  itemBuilder: (_, g, __) => InkWell(
                    onTap: () => onOpen(g.first),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          _cell(
                            g.first.warehouseName ?? '—',
                            flex: 2,
                            bold: true,
                          ),
                          _cell(g.barcodeLabel, flex: 2),
                          _articleCell(g, flex: 3),
                          _cell('Rs ${g.saleText}', flex: 2, bold: true),
                          _cell('${g.qty}', flex: 1),
                          _cell(g.discountText, flex: 1),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () => onOpen(g.first),
                                icon: const AppIcon(
                                  AppIcons.visibilityOutlined,
                                  size: 16,
                                ),
                                label: Text(g.sizesLabel),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _articleCell(_Grp g, {int flex = 1}) => Expanded(
    flex: flex,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          g.first.productName ?? '—',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF1A1D2E),
            fontWeight: FontWeight.w600,
          ),
        ),
        if (g.articleLine.isNotEmpty)
          Text(
            g.articleLine,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xFF8A8FA3)),
          ),
      ],
    ),
  );

  Widget _cell(String text, {int flex = 1, bool bold = false}) => Expanded(
    flex: flex,
    child: Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13,
        color: const Color(0xFF1A1D2E),
        fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
      ),
    ),
  );
}

class _TH extends StatelessWidget {
  final String text;
  final int flex;
  final TextStyle style;
  const _TH(this.text, {required this.flex, required this.style});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(text, style: style),
      ),
    );
  }
}

class _MobileList extends StatelessWidget {
  final PaginatedListState<WarehouseStockModel> state;
  final AdminStockNotifier notifier;
  final void Function(WarehouseStockModel) onOpen;
  const _MobileList({
    required this.state,
    required this.notifier,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return PaginatedListView<_Grp>(
      state: _groupState(state),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      onLoadMore: notifier.loadMore,
      onRefresh: notifier.refresh,
      emptyText: 'No stock entries found',
      itemBuilder: (_, g, __) => InkWell(
        onTap: () => onOpen(g.first),
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
                    child: Text(
                      g.first.productName ?? g.first.barcode,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAEFFD),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      g.first.warehouseName ?? '—',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3E63DD),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const AppIcon(
                    AppIcons.chevronRight,
                    size: 18,
                    color: Color(0xFF8A8FA3),
                  ),
                ],
              ),
              if (g.articleLine.isNotEmpty)
                Text(
                  g.articleLine,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5A5F73),
                  ),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _chip('Sizes', g.sizesLabel),
                  _chip(
                    'Sale',
                    'Rs ${g.saleText}',
                    color: const Color(0xFF3E63DD),
                  ),
                  _chip('Qty', '${g.qty}', color: const Color(0xFF2E7D32)),
                  _chip(
                    'Discount',
                    g.discountText,
                    color: Colors.orange.shade800,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
            style: const TextStyle(color: Color(0xFF8A8FA3)),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: color ?? const Color(0xFF1A1D2E),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

class _PickWarehouseDialog extends StatelessWidget {
  final List<WarehouseModel> warehouses;
  const _PickWarehouseDialog({required this.warehouses});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Select Warehouse',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      content: SizedBox(
        width: 340,
        child: warehouses.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No warehouses available',
                  style: TextStyle(color: Color(0xFF8A8FA3), fontSize: 13),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: warehouses
                      .map(
                        (w) => ListTile(
                          leading: const AppIcon(
                            AppIcons.warehouseOutlined,
                            color: Color(0xFF3E63DD),
                          ),
                          title: Text(
                            w.warehouseName,
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () => Navigator.pop(context, w.id),
                        ),
                      )
                      .toList(),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
