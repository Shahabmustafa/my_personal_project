import '../datasource/sale_invoice_datasource.dart';
import '../model/sale_invoice_model.dart';

class SaleInvoiceRepository {
  final SaleInvoiceDatasource _datasource;
  SaleInvoiceRepository(this._datasource);

  Future<String> generateInvoiceNumber() => _datasource.generateInvoiceNumber();

  Future<List<EmployeeLookupItem>> getSalesmen(String branchId) =>
      _datasource.fetchEmployees(branchId, 'salesman');

  Future<EmployeeLookupItem?> getBranchManager(String branchId) =>
      _datasource.fetchBranchManager(branchId);

  Future<List<BankEntryLookupItem>> getBankEntries(String branchId) =>
      _datasource.fetchBankEntries(branchId);

  Future<List<PrinterLookupItem>> getPrinters(String branchId) =>
      _datasource.fetchPrinters(branchId);

  Future<SaleInvoiceModel> saveSaleInvoice({
    required String invoiceNumber,
    required String branchId,
    String? printerId,
    String? cashierId,
    required String customerId,
    String? salesmanId,
    String? managerId,
    required double subtotal,
    required double totalDiscount,
    double invoiceDiscount = 0,
    required double totalAmount,
    required double salesmanCommissionPercent,
    required double salesmanCommissionAmount,
    required double managerCommissionPercent,
    required double managerCommissionAmount,
    String? note,
    required List<SaleCartItem> cartItems,
    required List<PaymentInput> payments,
  }) => _datasource.saveSaleInvoice(
    invoiceNumber: invoiceNumber,
    branchId: branchId,
    printerId: printerId,
    cashierId: cashierId,
    customerId: customerId,
    salesmanId: salesmanId,
    managerId: managerId,
    subtotal: subtotal,
    totalDiscount: totalDiscount,
    invoiceDiscount: invoiceDiscount,
    totalAmount: totalAmount,
    salesmanCommissionPercent: salesmanCommissionPercent,
    salesmanCommissionAmount: salesmanCommissionAmount,
    managerCommissionPercent: managerCommissionPercent,
    managerCommissionAmount: managerCommissionAmount,
    note: note,
    cartItems: cartItems,
    payments: payments,
  );

  Future<List<SaleInvoiceModel>> getInvoices(String branchId) =>
      _datasource.fetchInvoices(branchId);

  Future<SaleInvoiceModel> getInvoiceDetail(String invoiceId) =>
      _datasource.fetchInvoiceDetail(invoiceId);
}
