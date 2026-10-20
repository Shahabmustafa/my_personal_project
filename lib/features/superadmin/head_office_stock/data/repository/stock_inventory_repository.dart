import '../../../../../core/pagination/pagination.dart';
import '../datasource/stock_inventory_datasource.dart';
import '../model/stock_inventory_model.dart';

class StockInventoryRepository {
  final StockInventoryDatasource _datasource;

  StockInventoryRepository(this._datasource);

  Future<List<StockInventoryModel>> getAllStock() => _datasource.fetchAll();

  Future<PageResult<StockInventoryModel>> fetchStockPage(PageRequest request) =>
      _datasource.fetchPage(request);

  /// Har page ko loop kar ke filter/search ke saare rows (print ke liye).
  Future<List<StockInventoryModel>> fetchAllStock({
    String search = '',
    Map<String, Object?> filters = const {},
  }) async {
    const size = 1000;
    final all = <StockInventoryModel>[];
    for (var page = 1;; page++) {
      final res = await _datasource.fetchPage(PageRequest(
          page: page,
          pageSize: size,
          search: sanitizeSearch(search),
          filters: filters,
          withCount: false));
      all.addAll(res.rows);
      if (res.rows.length < size) return all;
    }
  }

  Future<bool> barcodeExists(String barcode) =>
      _datasource.barcodeExists(barcode);

  Future<bool> skuExists({
    required String productId,
    required String sizeId,
    required String brandId,
    String? companyId,
    required String colorId,
    required String categoryId,
    required String typeId,
  }) =>
      _datasource.skuExists(
        productId: productId,
        sizeId: sizeId,
        brandId: brandId,
        companyId: companyId,
        colorId: colorId,
        categoryId: categoryId,
        typeId: typeId,
      );

  Future<List<StockInventoryModel>> addBatchStock(
          List<StockInventoryModel> stocks) =>
      _datasource.insertBatch(stocks);

  Future<StockInventoryModel> updateQuantity(String stockId, int quantity) =>
      _datasource.updateQuantity(stockId, quantity);

  Future<StockInventoryModel> updateDiscount(String stockId, double discount) =>
      _datasource.updateDiscount(stockId, discount);

  Future<void> deleteStock(String stockId) => _datasource.deleteStock(stockId);
}
