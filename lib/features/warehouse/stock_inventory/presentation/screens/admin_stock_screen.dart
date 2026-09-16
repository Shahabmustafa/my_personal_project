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
                    TotalCountLabel(
                        label: 'SKUs (all warehouses)',
                        count: state.totalCount),
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
                hintText: 'Search by barcode, article, brand, warehouse...',
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

class _DesktopTable extends StatelessWidget {
  final PaginatedListState<WarehouseStockModel> state;
  final AdminStockNotifier notifier;
  const _DesktopTable({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF8A8FA3),
        letterSpacing: 0.3);

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
                  border:
                      Border(bottom: BorderSide(color: Color(0xFFE7E9F0))),
                ),
                child: const Row(children: [
                  _TH('Warehouse', flex: 2, style: headerStyle),
                  _TH('Barcode', flex: 2, style: headerStyle),
                  _TH('Article', flex: 2, style: headerStyle),
                  _TH('Size', flex: 1, style: headerStyle),
                  _TH('Color', flex: 1, style: headerStyle),
                  _TH('Brand', flex: 1, style: headerStyle),
                  _TH('Category', flex: 1, style: headerStyle),
                  _TH('Type', flex: 1, style: headerStyle),
                  _TH('Qty', flex: 1, style: headerStyle),
                  _TH('Discount', flex: 1, style: headerStyle),
                ]),
              ),
              Expanded(
                child: PaginatedListView<WarehouseStockModel>(
                  state: state,
                  padding: EdgeInsets.zero,
                  onLoadMore: notifier.loadMore,
                  onRefresh: notifier.refresh,
                  emptyText: 'No stock entries found',
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFE7E9F0)),
                  itemBuilder: (_, s, __) => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(children: [
                      _cell(s.warehouseName ?? '—', flex: 2, bold: true),
                      _cell(s.barcode, flex: 2),
                      _cell(s.productName ?? '—', flex: 2),
                      _cell(s.sizeName ?? '—', flex: 1),
                      _cell(s.colorName ?? '—', flex: 1),
                      _cell(s.brandName ?? '—', flex: 1),
                      _cell(s.categoryName ?? '—', flex: 1),
                      _cell(s.typeName ?? '—', flex: 1),
                      _cell('${s.quantity}', flex: 1),
                      _cell('${s.discount.toStringAsFixed(0)}%', flex: 1),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(String text, {int flex = 1, bool bold = false}) => Expanded(
        flex: flex,
        child: Text(text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 13,
                color: const Color(0xFF1A1D2E),
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
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
  const _MobileList({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return PaginatedListView<WarehouseStockModel>(
      state: state,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      onLoadMore: notifier.loadMore,
      onRefresh: notifier.refresh,
      emptyText: 'No stock entries found',
      itemBuilder: (_, s, __) => Container(
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
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAEFFD),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(s.warehouseName ?? '—',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3E63DD))),
                ),
              ],
            ),
            const SizedBox(height: 6),
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
                _chip('Qty', '${s.quantity}', color: const Color(0xFF2E7D32)),
                _chip('Discount', '${s.discount.toStringAsFixed(0)}%',
                    color: Colors.orange.shade800),
              ],
            ),
          ],
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

class _PickWarehouseDialog extends StatelessWidget {
  final List<WarehouseModel> warehouses;
  const _PickWarehouseDialog({required this.warehouses});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Select Warehouse',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      content: SizedBox(
        width: 340,
        child: warehouses.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No warehouses available',
                    style:
                        TextStyle(color: Color(0xFF8A8FA3), fontSize: 13)),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: warehouses
                      .map((w) => ListTile(
                            leading: const AppIcon(AppIcons.warehouseOutlined,
                                color: Color(0xFF3E63DD)),
                            title: Text(w.warehouseName,
                                style: const TextStyle(fontSize: 14)),
                            onTap: () => Navigator.pop(context, w.id),
                          ))
                      .toList(),
                ),
              ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
      ],
    );
  }
}
