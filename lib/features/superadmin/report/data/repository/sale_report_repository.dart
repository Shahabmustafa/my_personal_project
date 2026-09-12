import '../../../../branch/sale_exchange/data/model/sale_exchange_model.dart';
import '../../../../branch/sale_invoice/data/model/sale_invoice_model.dart';
import '../../../../branch/sale_return/data/model/sale_return_model.dart';
import '../datasource/sale_report_datasource.dart';
import '../model/report_page_result.dart';
import '../model/sale_summary_totals.dart';
import '../model/sale_transaction_row.dart';

class SaleReportRepository {
  final SaleReportDatasource _datasource;
  SaleReportRepository(this._datasource);

  Future<PrinterLookupItem?> getBranchPrinter(String branchId) =>
      _datasource.fetchBranchPrinter(branchId);

  Future<ReportPageResult<SaleInvoiceModel>> getInvoiceReport({
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
    required int page,
    required int pageSize,
  }) =>
      _datasource.fetchInvoiceReport(
          startDate: startDate,
          endDate: endDate,
          branchId: branchId,
          page: page,
          pageSize: pageSize);

  Future<ReportPageResult<SaleReturnModel>> getReturnReport({
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
    required int page,
    required int pageSize,
  }) =>
      _datasource.fetchReturnReport(
          startDate: startDate,
          endDate: endDate,
          branchId: branchId,
          page: page,
          pageSize: pageSize);

  Future<ReportPageResult<SaleExchangeModel>> getExchangeReport({
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
    required int page,
    required int pageSize,
  }) =>
      _datasource.fetchExchangeReport(
          startDate: startDate,
          endDate: endDate,
          branchId: branchId,
          page: page,
          pageSize: pageSize);

  Future<SaleInvoiceModel> getInvoiceById(String id) => _datasource.fetchInvoiceById(id);

  Future<SaleReturnModel> getReturnById(String id) => _datasource.fetchReturnById(id);

  Future<SaleExchangeModel> getExchangeById(String id) => _datasource.fetchExchangeById(id);

  Future<SaleSummaryTotals> getSummaryTotals({
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
  }) =>
      _datasource.fetchSummaryTotals(startDate: startDate, endDate: endDate, branchId: branchId);

  Future<List<SaleTransactionRow>> getCombinedTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
  }) =>
      _datasource.fetchCombinedTransactions(
          startDate: startDate, endDate: endDate, branchId: branchId);

  Future<Map<String, double>> getNetSaleByBranch({DateTime? date}) =>
      _datasource.fetchNetSaleByBranch(date: date);
}
