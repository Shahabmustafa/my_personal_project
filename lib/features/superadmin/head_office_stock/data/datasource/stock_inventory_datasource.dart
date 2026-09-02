import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/stock_inventory_model.dart';

class StockInventoryDatasource {
  final SupabaseClient _client;

  StockInventoryDatasource(this._client);

  static const _table = 'stock_inventory';
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
