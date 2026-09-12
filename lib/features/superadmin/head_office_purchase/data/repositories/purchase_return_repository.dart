import '../datasources/purchase_return_datasource.dart';
import '../models/purchase_return_model.dart';
import '../models/warehouse_stock_model.dart';

class PurchaseReturnRepository {
  final PurchaseReturnDatasource _datasource;

  PurchaseReturnRepository(this._datasource);

  Future<WarehouseCashCounter> getOrCreateCounter() =>
      _datasource.getOrCreateCounter();

  Future<String> generateReturnNumber() =>
      _datasource.generateReturnNumber();

  Future<List<WarehouseStockModel>> getWarehouseStock() =>
      _datasource.fetchWarehouseStock();

  Future<WarehouseStockModel?> getStockByBarcode(String barcode) =>
      _datasource.fetchStockByBarcode(barcode);

  Future<List<StockLookupItem>> getCompanies() =>
      _datasource.fetchCompanies();

  Future<List<Map<String, String>>> getInvoiceNumbers(String headOfficeId) =>
      _datasource.fetchInvoiceNumbers(headOfficeId);

  Future<PurchaseReturnModel> savePurchaseReturn({
    required String returnNumber,
    required String headOfficeId,
    String? companyId,
    String? originalInvoiceId,
    required double totalAmount,
    required double totalDiscount,
    required double netAmount,
    required List<ReturnCartItem> cartItems,
    String? notes,
  }) =>
      _datasource.savePurchaseReturn(
        returnNumber: returnNumber,
        headOfficeId: headOfficeId,
        companyId: companyId,
        originalInvoiceId: originalInvoiceId,
        totalAmount: totalAmount,
        totalDiscount: totalDiscount,
        netAmount: netAmount,
        cartItems: cartItems,
        notes: notes,
      );

  Future<List<PurchaseReturnModel>> getReturns(String headOfficeId) =>
      _datasource.fetchReturns(headOfficeId);

  Future<PurchaseReturnModel> getReturnDetail(String returnId) =>
      _datasource.fetchReturnDetail(returnId);
}
