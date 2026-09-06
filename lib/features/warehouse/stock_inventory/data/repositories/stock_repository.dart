import '../../../../../core/pagination/pagination.dart';
import '../datasources/stock_datasource.dart';
import '../models/warehouse_stock_model.dart';

class StockRepository {
  final StockDatasource _datasource;

  StockRepository(this._datasource);

  Future<List<WarehouseStockModel>> getStockByWarehouse(String warehouseId) =>
      _datasource.fetchByWarehouse(warehouseId);

  Future<List<WarehouseStockModel>> getAllStock() => _datasource.fetchAll();

  Future<PageResult<WarehouseStockModel>> fetchStockPage(
    PageRequest request, {
    String? warehouseId,
  }) =>
      _datasource.fetchPage(request, warehouseId: warehouseId);

  Future<bool> barcodeExists(String barcode) =>
      _datasource.barcodeExists(barcode);

  Future<bool> skuExists({
    required String warehouseId,
    required String productId,
    required String sizeId,
    required String brandId,
    String? companyId,
    required String colorId,
    required String categoryId,
    required String typeId,
  }) =>
      _datasource.skuExists(
        warehouseId: warehouseId,
        productId: productId,
        sizeId: sizeId,
        brandId: brandId,
        companyId: companyId,
        colorId: colorId,
        categoryId: categoryId,
        typeId: typeId,
      );

  Future<List<WarehouseStockModel>> addBatchStock(
          List<WarehouseStockModel> stocks) =>
      _datasource.insertBatch(stocks);

  Future<WarehouseStockModel> updateQuantity(String stockId, int quantity) =>
      _datasource.updateQuantity(stockId, quantity);

  Future<WarehouseStockModel> updateDiscount(String stockId, double discount) =>
      _datasource.updateDiscount(stockId, discount);

  Future<void> deleteStock(String stockId) =>
      _datasource.deleteStock(stockId);

  Future<List<StockLookupItem>> getProducts() => _datasource.fetchProducts();
  Future<List<StockLookupItem>> getSizes() => _datasource.fetchSizes();
  Future<List<StockLookupItem>> getBrands() => _datasource.fetchBrands();
  Future<List<StockLookupItem>> getCompanies() => _datasource.fetchCompanies();
  Future<List<StockLookupItem>> getColors() => _datasource.fetchColors();
  Future<List<StockLookupItem>> getCategories() => _datasource.fetchCategories();
  Future<List<StockLookupItem>> getTypes() => _datasource.fetchTypes();
}
