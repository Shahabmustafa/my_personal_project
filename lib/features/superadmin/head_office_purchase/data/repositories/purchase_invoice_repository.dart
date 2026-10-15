import '../datasources/purchase_invoice_datasource.dart';
import '../models/purchase_invoice_model.dart';
import '../models/purchase_return_model.dart';
import '../models/warehouse_stock_model.dart';

class PurchaseInvoiceRepository {
  final PurchaseInvoiceDatasource _datasource;

  PurchaseInvoiceRepository(this._datasource);

  Future<String> generateInvoiceNumber() =>
      _datasource.generateInvoiceNumber();

  Future<List<WarehouseStockModel>> getWarehouseStock() =>
      _datasource.fetchWarehouseStock();

  Future<WarehouseStockModel?> getStockByBarcode(String barcode) =>
      _datasource.fetchStockByBarcode(barcode);

  Future<List<StockLookupItem>> getCompanies() =>
      _datasource.fetchCompanies();

  Future<WarehouseCashCounter> getOrCreateCounter() =>
      _datasource.getOrCreateCounter();

  Future<CompanyWithBalance?> getCompanyWithBalance(String companyId) =>
      _datasource.fetchCompanyWithBalance(companyId);

  Future<void> updateCompanyOpeningBalance(String companyId, double balance) =>
      _datasource.updateCompanyOpeningBalance(companyId, balance);

  Future<PurchaseInvoiceModel> savePurchaseInvoice({
    required String invoiceNumber,
    required String headOfficeId,
    String? companyId,
    required double totalAmount,
    required double totalDiscount,
    required double netAmount,
    required double paidAmount,
    required double creditAmount,
    required String paymentMode,
    required List<PurchaseCartItem> cartItems,
    String? notes,
  }) =>
      _datasource.savePurchaseInvoice(
        invoiceNumber: invoiceNumber,
        headOfficeId: headOfficeId,
        companyId: companyId,
        totalAmount: totalAmount,
        totalDiscount: totalDiscount,
        netAmount: netAmount,
        paidAmount: paidAmount,
        creditAmount: creditAmount,
        paymentMode: paymentMode,
        cartItems: cartItems,
        notes: notes,
      );

  Future<List<PurchaseInvoiceModel>> getInvoices(String headOfficeId) =>
      _datasource.fetchInvoices(headOfficeId);

  Future<PurchaseInvoiceModel> getInvoiceDetail(String invoiceId) =>
      _datasource.fetchInvoiceDetail(invoiceId);
}
