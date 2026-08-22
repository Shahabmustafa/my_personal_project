import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/warehouse_stock_model.dart';

class StockDatasource {
  final SupabaseClient _client;

  StockDatasource(this._client);

  static const _table = 'warehouse_stock_inventory';
  static const _joinSelect = '''
    *,
    products(article_name),
    sizes(number),
    brands(name),
    companies(name),
    colors(name),
    categories(name),
    types(name),
    warehouses(warehouse_name)
  ''';

  // ── Fetch all stock for a given warehouse ─────────────────────────────────
  Future<List<WarehouseStockModel>> fetchByWarehouse(String warehouseId) async {
    final response = await _client
        .from(_table)
        .select(_joinSelect)
        .eq('warehouse_id', warehouseId);

    final list = (response as List)
        .map((e) => WarehouseStockModel.fromJson(e as Map<String, dynamic>))
        .toList();

    list.sort((a, b) {
      final nameCompare = (a.productName ?? '').toLowerCase()
          .compareTo((b.productName ?? '').toLowerCase());
      if (nameCompare != 0) return nameCompare;
      return b.quantity.compareTo(a.quantity);
    });

    return list;
  }

  // ── Check barcode exists globally ─────────────────────────────────────────
  Future<bool> barcodeExists(String barcode) async {
    final res = await _client
        .from(_table)
        .select('id')
        .eq('barcode', barcode)
        .maybeSingle();
    return res != null;
  }

  // ── Check duplicate SKU ───────────────────────────────────────────────────
  Future<bool> skuExists({
    required String warehouseId,
    required String productId,
    required String sizeId,
    required String brandId,
    String? companyId,
    required String colorId,
    required String categoryId,
    required String typeId,
  }) async {
    var query = _client
        .from(_table)
        .select('id')
        .eq('warehouse_id', warehouseId)
        .eq('product_id', productId)
        .eq('size_id', sizeId)
        .eq('brand_id', brandId)
        .eq('color_id', colorId)
        .eq('category_id', categoryId)
        .eq('type_id', typeId);

    if (companyId != null) {
      query = query.eq('company_id', companyId);
    }

    final res = await query.maybeSingle();
    return res != null;
  }

  // ── Insert multiple stock entries ─────────────────────────────────────────
  Future<List<WarehouseStockModel>> insertBatch(
      List<WarehouseStockModel> stocks) async {
    final payload = stocks.map((s) => s.toInsertJson()).toList();
    final response = await _client
        .from(_table)
        .insert(payload)
        .select(_joinSelect);

    return (response as List)
        .map((e) => WarehouseStockModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Update quantity ───────────────────────────────────────────────────────
  Future<WarehouseStockModel> updateQuantity(
      String stockId, int quantity) async {
    final response = await _client
        .from(_table)
        .update({'quantity': quantity})
        .eq('id', stockId)
        .select(_joinSelect)
        .single();
    return WarehouseStockModel.fromJson(response as Map<String, dynamic>);
  }

  // ── Update sale price and discount ────────────────────────────────────────
  Future<WarehouseStockModel> updatePriceAndDiscount(
      String stockId, double salePrice, double discountPct) async {
    final response = await _client
        .from(_table)
        .update({
          'sale_price': salePrice,
          'discount': discountPct,
        })
        .eq('id', stockId)
        .select(_joinSelect)
        .single();
    return WarehouseStockModel.fromJson(response as Map<String, dynamic>);
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  Future<void> deleteStock(String stockId) async {
    await _client.from(_table).delete().eq('id', stockId);
  }

  // ── Lookup helpers ────────────────────────────────────────────────────────
  Future<List<StockLookupItem>> fetchProducts() async {
    final res = await _client
        .from('products')
        .select('id, article_name')
        .order('article_name');
    return (res as List)
        .map((e) => StockLookupItem(
            id: e['id'] as String, label: e['article_name'] as String))
        .toList();
  }

  Future<List<StockLookupItem>> fetchSizes() async {
    final res = await _client
        .from('sizes')
        .select('id, number')
        .order('number');
    return (res as List)
        .map((e) => StockLookupItem(
            id: e['id'] as String, label: e['number'] as String))
        .toList();
  }

  Future<List<StockLookupItem>> fetchBrands() async {
    final res = await _client
        .from('brands')
        .select('id, name')
        .order('name');
    return (res as List)
        .map((e) => StockLookupItem(
            id: e['id'] as String, label: e['name'] as String))
        .toList();
  }

  Future<List<StockLookupItem>> fetchCompanies() async {
    final res = await _client
        .from('companies')
        .select('id, name')
        .order('name');
    return (res as List)
        .map((e) => StockLookupItem(
            id: e['id'] as String, label: e['name'] as String))
        .toList();
  }

  Future<List<StockLookupItem>> fetchColors() async {
    final res = await _client
        .from('colors')
        .select('id, name')
        .order('name');
    return (res as List)
        .map((e) => StockLookupItem(
            id: e['id'] as String, label: e['name'] as String))
        .toList();
  }

  Future<List<StockLookupItem>> fetchCategories() async {
    final res = await _client
        .from('categories')
        .select('id, name')
        .order('name');
    return (res as List)
        .map((e) => StockLookupItem(
            id: e['id'] as String, label: e['name'] as String))
        .toList();
  }

  Future<List<StockLookupItem>> fetchTypes() async {
    final res = await _client
        .from('types')
        .select('id, name')
        .order('name');
    return (res as List)
        .map((e) => StockLookupItem(
            id: e['id'] as String, label: e['name'] as String))
        .toList();
  }
}
