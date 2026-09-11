import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/pagination/pagination.dart';
import '../../data/model/product_model.dart';
import '../providers/product_provider.dart';
import '../widgets/product_form_dialog.dart';

import 'package:safishoe_app/core/widget/app_icon.dart';
import 'package:safishoe_app/core/constants/app_icons.dart';
class ProductsScreen extends ConsumerStatefulWidget {
  final bool readOnly;
  const ProductsScreen({super.key, this.readOnly = false});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  void _showForm({ProductModel? product}) {
    showDialog(
      context: context,
      builder: (_) => ProductFormDialog(
        product: product,
        onSaved: () => ref.read(productProvider.notifier).refresh(),
      ),
    );
  }

  void _confirmDelete(ProductModel product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Product'),
        content: Text('Delete "${product.articleName}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final error = await ref
                  .read(productProvider.notifier)
                  .delete(product.id, product.imageUrl);
              if (error != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(error),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productProvider);
    final notifier = ref.read(productProvider.notifier);
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
                    const Text('Products',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    TotalCountLabel(label: 'Products', count: state.totalCount),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showForm(),
                  icon: const AppIcon(AppIcons.add, size: 18),
                  label: const Text('Add Product'),
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
                hintText: 'Search products...',
                hintStyle:
                    const TextStyle(fontSize: 13, color: Color(0xFF8A8FA3)),
                prefixIcon:
                    const AppIcon(AppIcons.search, color: Color(0xFF8A8FA3)),
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
                ? _MobileList(
                    state: state,
                    notifier: notifier,
                    readOnly: widget.readOnly,
                    onEdit: (p) => _showForm(product: p),
                    onDelete: _confirmDelete,
                  )
                : _DesktopTable(
                    state: state,
                    notifier: notifier,
                    readOnly: widget.readOnly,
                    onEdit: (p) => _showForm(product: p),
                    onDelete: _confirmDelete,
                  ),
          ),
        ],
      ),
    );
  }
}

class _DesktopTable extends StatelessWidget {
  final PaginatedListState<ProductModel> state;
  final ProductNotifier notifier;
  final bool readOnly;
  final Function(ProductModel) onEdit;
  final Function(ProductModel) onDelete;

  const _DesktopTable({
    required this.state,
    required this.notifier,
    this.readOnly = false,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
                child: Row(children: [
                  const _TH('image', flex: 2),
                  const _TH('Article Name', flex: 4),
                  const _TH('Sale Price', flex: 2),
                  const _TH('Purchase Price', flex: 2),
                  if (!readOnly) const _TH('Actions', flex: 2),
                ]),
              ),
              Expanded(
                child: PaginatedListView<ProductModel>(
                  state: state,
                  padding: EdgeInsets.zero,
                  onLoadMore: notifier.loadMore,
                  onRefresh: notifier.refresh,
                  emptyText: 'No products found',
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFE7E9F0)),
                  itemBuilder: (_, p, __) => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(children: [
                      Expanded(
                        flex: 2,
                        child: p.imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  p.imageUrl,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _placeholder(40),
                                ),
                              )
                            : _placeholder(40),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(p.articleName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                                color: Color(0xFF1A1D2E)),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('Rs. ${p.salePrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.w500)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                            'Rs. ${p.purchasePrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF5A5F7A))),
                      ),
                      if (!readOnly)
                        Expanded(
                          flex: 2,
                          child: Row(children: [
                            _IconBtn(
                              icon: AppIcons.editOutlined,
                              color: const Color(0xFF3E63DD),
                              tooltip: 'Edit',
                              onTap: () => onEdit(p),
                            ),
                            const SizedBox(width: 8),
                            _IconBtn(
                              icon: AppIcons.deleteOutline,
                              color: Colors.redAccent,
                              tooltip: 'Delete',
                              onTap: () => onDelete(p),
                            ),
                          ]),
                        ),
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

  static Widget _placeholder(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFEAEFFD),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const AppIcon(AppIcons.inventory2Outlined,
            size: 18, color: Color(0xFF3E63DD)),
      );
}

class _MobileList extends StatelessWidget {
  final PaginatedListState<ProductModel> state;
  final ProductNotifier notifier;
  final bool readOnly;
  final Function(ProductModel) onEdit;
  final Function(ProductModel) onDelete;

  const _MobileList({
    required this.state,
    required this.notifier,
    this.readOnly = false,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PaginatedListView<ProductModel>(
      state: state,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      onLoadMore: notifier.loadMore,
      onRefresh: notifier.refresh,
      emptyText: 'No products found',
      itemBuilder: (_, p, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7E9F0)),
        ),
        child: Row(
          children: [
            p.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(p.imageUrl,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder()),
                  )
                : _placeholder(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.articleName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                      'Sale: Rs. ${p.salePrice.toStringAsFixed(0)}  |  Purchase: Rs. ${p.purchasePrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF8A8FA3))),
                ],
              ),
            ),
            if (!readOnly)
              Column(
                children: [
                  _IconBtn(
                      icon: AppIcons.editOutlined,
                      color: const Color(0xFF3E63DD),
                      tooltip: 'Edit',
                      onTap: () => onEdit(p)),
                  const SizedBox(height: 6),
                  _IconBtn(
                      icon: AppIcons.deleteOutline,
                      color: Colors.redAccent,
                      tooltip: 'Delete',
                      onTap: () => onDelete(p)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  static Widget _placeholder() => Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFEAEFFD),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const AppIcon(AppIcons.inventory2Outlined,
            size: 22, color: Color(0xFF3E63DD)),
      );
}

class _TH extends StatelessWidget {
  final String text;
  final int flex;
  const _TH(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8A8FA3),
                letterSpacing: 0.3)),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final String icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _IconBtn(
      {required this.icon,
      required this.color,
      required this.tooltip,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6)),
          child: AppIcon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
