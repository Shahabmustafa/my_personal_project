import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/pagination/pagination.dart';
import '../model/stock_inventory_model.dart';

class StockInventoryDatasource {
  final SupabaseClient _client;

  StockInventoryDatasource(this._client);

  static const _table = 'stock_inventory';

  static StockInventoryModel _fromViewRow(Map<String, dynamic> r) =>
      StockInventoryModel.fromJson({
        ...r,
        'products': {'article_name': r['product_name']},
        'sizes': {'number': r['size_name']},
        'colors': {'name': r['color_name']},
        'brands': {'name': r['brand_name']},
        'categories': {'name': r['category_name']},
        'types': {'name': r['type_name']},
        'companies': {'name': r['company_name']},
      });

  /// Server-paginated + searched page of head-office stock (via
  /// `v_head_office_stock`).
  Future<PageResult<StockInventoryModel>> fetchPage(PageRequest request) async {
    var query = _client.from('v_head_office_stock').select();
    if (request.search.isNotEmpty) {
      query = query.ilike('search_text', '%${request.search.toLowerCase()}%');
    }
    if (request.filters['low_stock'] == true) {
      query = query.lte('quantity', 5);
    }
    final result = await runSupabasePage(
      query
          .order('product_name', ascending: true)
          .order('quantity', ascending: false),
      request: request,
    );
    return result.map(_fromViewRow);
  }
  static const _joins = '''
    *,
    products(article_name),
    sizes(number),
    brands(name),
    companies(name),
    colors(name),
    categories(name),
    types(name)
  ''';

  Future<List<StockInventoryModel>> fetchAll() async {
    final response = await _client.from(_table).select(_joins);
    final list = (response as List)
        .map((e) => StockInventoryModel.fromJson(e as Map<String, dynamic>))
        .toList();

    list.sort((a, b) {
      final nameCompare = (a.productName ?? '')
          .toLowerCase()
          .compareTo((b.productName ?? '').toLowerCase());
      if (nameCompare != 0) return nameCompare;
      return b.quantity.compareTo(a.quantity);
    });

    return list;
  }

  Future<bool> barcodeExists(String barcode) async {
    final res = await _client
        .from(_table)
        .select('id')
        .eq('barcode', barcode)
        .maybeSingle();
    return res != null;
  }

  Future<bool> skuExists({
    required String productId,
    required String sizeId,
    required String brandId,
    String? companyId,
    required String colorId,
    required String categoryId,
    required String typeId,
  }) async {
    final res = await _client
        .from(_table)
        .select('id')
        .eq('product_id', productId)
        .eq('size_id', sizeId)
        .eq('brand_id', brandId)
        .eq('color_id', colorId)
        .eq('category_id', categoryId)
        .eq('type_id', typeId)
        .maybeSingle();
    return res != null;
  }

  Future<List<StockInventoryModel>> insertBatch(
      List<StockInventoryModel> stocks) async {
    final payload = stocks.map((s) => s.toInsertJson()).toList();
    final response = await _client.from(_table).insert(payload).select(_joins);
    return (response as List)
        .map((e) => StockInventoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StockInventoryModel> updateQuantity(
      String stockId, int quantity) async {
    final response = await _client
        .from(_table)
        .update({'quantity': quantity})
        .eq('id', stockId)
        .select(_joins)
        .single();
    return StockInventoryModel.fromJson(response);
  }

  Future<StockInventoryModel> updateDiscount(
      String stockId, double discount) async {
    final response = await _client
        .from(_table)
        .update({'discount': discount})
        .eq('id', stockId)
        .select(_joins)
        .single();
    return StockInventoryModel.fromJson(response);
  }

  Future<void> deleteStock(String stockId) async {
    await _client.from(_table).delete().eq('id', stockId);
  }
}
