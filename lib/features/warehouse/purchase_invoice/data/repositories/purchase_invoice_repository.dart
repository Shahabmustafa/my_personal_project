import '../datasources/purchase_invoice_datasource.dart';
import '../models/purchase_invoice_model.dart';
import '../models/warehouse_stock_model.dart';

class PurchaseInvoiceRepository {
  final PurchaseInvoiceDatasource _datasource;

  PurchaseInvoiceRepository(this._datasource);

  Future<String> generateInvoiceNumber() =>
      _datasource.generateInvoiceNumber();

  Future<List<WarehouseStockModel>> getWarehouseStock(String warehouseId) =>
      _datasource.fetchWarehouseStock(warehouseId);

  Future<WarehouseStockModel?> getStockByBarcode(String barcode) =>
      _datasource.fetchStockByBarcode(barcode);

  Future<List<StockLookupItem>> getCompanies() =>
      _datasource.fetchCompanies();

  Future<PurchaseInvoiceModel> savePurchaseInvoice({
    required String invoiceNumber,
    required String warehouseId,
    String? companyId,
    required double totalAmount,
    required double totalDiscount,
    required double netAmount,
    required List<PurchaseCartItem> cartItems,
    String? notes,
  }) =>
      _datasource.savePurchaseInvoice(
        invoiceNumber: invoiceNumber,
        warehouseId: warehouseId,
        companyId: companyId,
        totalAmount: totalAmount,
        totalDiscount: totalDiscount,
        netAmount: netAmount,
        cartItems: cartItems,
        notes: notes,
      );

  Future<List<PurchaseInvoiceModel>> getInvoices(String warehouseId) =>
      _datasource.fetchInvoices(warehouseId);

  Future<PurchaseInvoiceModel> getInvoiceDetail(String invoiceId) =>
      _datasource.fetchInvoiceDetail(invoiceId);
}
