import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/pagination/pagination.dart';
import '../model/branch_stock_model.dart';

/// Branch stock ke alag alag screens: poora stock, sirf chalte Buy 1 Get 1
/// offer wala stock, ya sirf discount wala stock.
enum BranchStockView {
  all('Branch Stock Inventory'),
  b1g1('Buy 1 Get 1 Stock'),
  discount('Discount Stock');

  final String title;
  const BranchStockView(this.title);

  /// Is view ka data kis table/view se aata hai.
  String get source =>
      this == b1g1 ? 'v_branch_stock_b1g1' : 'v_branch_stock';
}

class BranchStockDatasource {
  final SupabaseClient _client;

  BranchStockDatasource(this._client);

  Future<List<BranchStockModel>> fetchBranchStock(String branchId) async {
    // Supabase ek request mein max 1000 rows deta hai — page-by-page saari
    // rows lao, warna dropdowns mein purane articles gayab ho jate hain.
    const size = 1000;
    final out = <BranchStockModel>[];
    for (var from = 0; ; from += size) {
      final page = await _client
          .from('branch_stock_inventory')
          .select('''
          *,
          products   ( article_name ),
          sizes      ( number ),
          colors     ( name ),
          brands     ( name ),
          categories ( name ),
          types      ( name )
        ''')
          .eq('branch_id', branchId)
          .order('created_at', ascending: false)
          .order('id', ascending: true)
          .range(from, from + size - 1);
      out.addAll((page as List)
          .map((e) => BranchStockModel.fromJson(e as Map<String, dynamic>)));
      if (page.length < size) return out;
    }
  }

  static BranchStockModel _fromViewRow(Map<String, dynamic> r) =>
      BranchStockModel.fromJson({
        ...r,
        'products': {'article_name': r['product_name']},
        'sizes': {'number': r['size_name']},
        'colors': {'name': r['color_name']},
        'brands': {'name': r['brand_name']},
        'categories': {'name': r['category_name']},
        'types': {'name': r['type_name']},
      });

  /// Server-paginated + searched page of this branch's stock (via
  /// `v_branch_stock`). `filters['low_stock'] == true` -> `quantity <= 5`;
  /// `filters['stock_level']` 'low' -> 1..4, 'out' -> 0.
  Future<PageResult<BranchStockModel>> fetchPage(
    PageRequest request, {
    required String branchId,
    BranchStockView view = BranchStockView.all,
  }) async {
    if (branchId.isEmpty) {
      return const PageResult(rows: [], totalCount: 0);
    }
    var query = _client
        .from(view.source)
        .select()
        .eq('branch_id', branchId);
    if (view == BranchStockView.discount) query = query.gt('discount', 0);
    if (request.search.isNotEmpty) {
      query = query.ilike('search_text', '%${request.search.toLowerCase()}%');
    }
    if (request.filters['low_stock'] == true) {
      query = query.lte('quantity', 5);
    }
    for (final key in const ['category_id', 'type_id', 'brand_id', 'size_id']) {
      final v = request.filters[key];
      if (v is String && v.isNotEmpty) query = query.eq(key, v);
    }
    switch (request.filters['stock_level']) {
      case 'low':
        query = query.gte('quantity', 1).lt('quantity', 5);
      case 'out':
        query = query.lte('quantity', 0);
    }
    // Same article (product + color + brand + category + type) sits together
    // so its sizes group into one row.
    final result = await runSupabasePage(
      query
          .order('product_name', ascending: true)
          .order('color_name', ascending: true)
          .order('brand_name', ascending: true)
          .order('category_name', ascending: true)
          .order('type_name', ascending: true)
          .order('id', ascending: true),
      request: request,
    );
    return result.map(_fromViewRow);
  }

  /// [view] ke saare rows ki sirf quantity + qeemat — cards ke totals ke liye.
  Future<List<({int quantity, double salePrice})>> fetchQtyPrice(
    String branchId,
    BranchStockView view,
  ) async {
    const size = 1000;
    final out = <({int quantity, double salePrice})>[];
    for (var from = 0; ; from += size) {
      var q = _client
          .from(view.source)
          .select('quantity, sale_price')
          .eq('branch_id', branchId);
      if (view == BranchStockView.discount) q = q.gt('discount', 0);
      final page = await q.order('id').range(from, from + size - 1);
      for (final r in page) {
        out.add((
          quantity: (r['quantity'] as num?)?.toInt() ?? 0,
          salePrice: (r['sale_price'] as num?)?.toDouble() ?? 0,
        ));
      }
      if (page.length < size) return out;
    }
  }

  /// Every size of one article in this branch's stock (for the sizes panel).
  Future<List<BranchStockModel>> fetchVariants({
    required String branchId,
    required String productId,
    required String colorId,
    required String brandId,
    required String categoryId,
    required String typeId,
  }) async {
    final res = await _client
        .from('v_branch_stock')
        .select()
        .eq('branch_id', branchId)
        .eq('product_id', productId)
        .eq('color_id', colorId)
        .eq('brand_id', brandId)
        .eq('category_id', categoryId)
        .eq('type_id', typeId);
    return (res as List)
        .map((e) => _fromViewRow(e as Map<String, dynamic>))
        .toList();
  }
}
