import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/product_model.dart';
import '../providers/product_provider.dart';
import '../providers/product_state.dart';
import '../widgets/product_form_dialog.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productProvider.notifier).loadAll();
    });
  }

  void _showForm({ProductModel? product}) {
    showDialog(
      context: context,
      builder: (_) => ProductFormDialog(
        product: product,
        onSaved: () => ref.read(productProvider.notifier).loadAll(),
      ),
    );
  }

  void _confirmDelete(ProductModel product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Product'),
        content: Text('Delete "\${product.articleName}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              ref
                  .read(productProvider.notifier)
                  .delete(product.id, product.imageUrl);
              Navigator.pop(context);
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
    final isMobile = MediaQuery.of(context).size.width < 768;

    ref.listen<ProductState>(productProvider, (_, next) {
      if (next.status == ProductStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.errorMessage!),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    });

    final filtered = state.items
        .where((p) =>
            p.articleName.toLowerCase().contains(_search.toLowerCase()))
        .toList();

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
                    Text('\${state.items.length} total products',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF8A8FA3))),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showForm(),
                  icon: const Icon(Icons.add, size: 18),
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
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: const TextStyle(
                    fontSize: 13, color: Color(0xFF8A8FA3)),
                prefixIcon:
                    const Icon(Icons.search, color: Color(0xFF8A8FA3)),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12),
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
                        color: Color(0xFF3E63DD), width: 1.5)),
              ),
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.status == ProductStatus.error
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.redAccent),
                            const SizedBox(height: 12),
                            Text(state.errorMessage ?? 'Error',
                                style: const TextStyle(
                                    color: Color(0xFF8A8FA3))),
                            const SizedBox(height: 16),
                            ElevatedButton(
                                onPressed: () => ref
                                    .read(productProvider.notifier)
                                    .loadAll(),
                                child: const Text('Retry')),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inventory_2_outlined,
                                    size: 48, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text(
                                  _search.isEmpty
                                      ? 'No products found'
                                      : 'No results for "\$_search"',
                                  style: const TextStyle(
                                      color: Color(0xFF8A8FA3)),
                                ),
                              ],
                            ),
                          )
                        : isMobile
                            ? _MobileList(
                                products: filtered,
                                onEdit: (p) => _showForm(product: p),
                                onDelete: _confirmDelete,
                              )
                            : _DesktopTable(
                                products: filtered,
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
  final List<ProductModel> products;
  final Function(ProductModel) onEdit;
  final Function(ProductModel) onDelete;

  const _DesktopTable({
    required this.products,
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
                  border: Border(
                      bottom: BorderSide(color: Color(0xFFE7E9F0))),
                ),
                child: const Row(children: [
                  _TH('image', flex: 2),
                  _TH('Article Name', flex: 4),
                  _TH('Sale Price', flex: 2),
                  _TH('Purchase Price', flex: 2),
                  _TH('Actions', flex: 2),
                ]),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: products.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFE7E9F0)),
                  itemBuilder: (_, i) {
                    final p = products[i];
                    return Padding(
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
                          child: Text(
                              'Rs. ${p.salePrice.toStringAsFixed(0)}',
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
                                  fontSize: 13,
                                  color: Color(0xFF5A5F7A))),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(children: [
                            _IconBtn(
                              icon: Icons.edit_outlined,
                              color: const Color(0xFF3E63DD),
                              tooltip: 'Edit',
                              onTap: () => onEdit(p),
                            ),
                            const SizedBox(width: 8),
                            _IconBtn(
                              icon: Icons.delete_outline,
                              color: Colors.redAccent,
                              tooltip: 'Delete',
                              onTap: () => onDelete(p),
                            ),
                          ]),
                        ),
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
  }

  static Widget _placeholder(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFEAEFFD),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.inventory_2_outlined,
            size: 18, color: Color(0xFF3E63DD)),
      );
}

class _MobileList extends StatelessWidget {
  final List<ProductModel> products;
  final Function(ProductModel) onEdit;
  final Function(ProductModel) onDelete;

  const _MobileList({
    required this.products,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: products.length,
      itemBuilder: (_, i) {
        final p = products[i];
        return Container(
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
                        'Sale: Rs. \${p.salePrice.toStringAsFixed(0)}  |  Purchase: Rs. \${p.purchasePrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF8A8FA3))),
                  ],
                ),
              ),
              Column(
                children: [
                  _IconBtn(
                      icon: Icons.edit_outlined,
                      color: const Color(0xFF3E63DD),
                      tooltip: 'Edit',
                      onTap: () => onEdit(p)),
                  const SizedBox(height: 6),
                  _IconBtn(
                      icon: Icons.delete_outline,
                      color: Colors.redAccent,
                      tooltip: 'Delete',
                      onTap: () => onDelete(p)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _placeholder() => Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFEAEFFD),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.inventory_2_outlined,
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
                letterSpacing: 0.3),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
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
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
