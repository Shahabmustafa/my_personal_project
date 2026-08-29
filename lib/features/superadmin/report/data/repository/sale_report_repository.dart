import '../../../../branch/sale_exchange/data/model/sale_exchange_model.dart';
import '../../../../branch/sale_invoice/data/model/sale_invoice_model.dart';
import '../../../../branch/sale_return/data/model/sale_return_model.dart';
import '../datasource/sale_report_datasource.dart';
import '../model/report_page_result.dart';

class SaleReportRepository {
  final SaleReportDatasource _datasource;
  SaleReportRepository(this._datasource);

  Future<PrinterLookupItem?> getBranchPrinter(String branchId) =>
      _datasource.fetchBranchPrinter(branchId);

  Future<ReportPageResult<SaleInvoiceModel>> getInvoiceReport({
    DateTime? startDate,
    DateTime? endDate,
    required int page,
    required int pageSize,
  }) =>
      _datasource.fetchInvoiceReport(
          startDate: startDate, endDate: endDate, page: page, pageSize: pageSize);

  Future<ReportPageResult<SaleReturnModel>> getReturnReport({
    DateTime? startDate,
    DateTime? endDate,
    required int page,
    required int pageSize,
  }) =>
      _datasource.fetchReturnReport(
          startDate: startDate, endDate: endDate, page: page, pageSize: pageSize);

  Future<ReportPageResult<SaleExchangeModel>> getExchangeReport({
    DateTime? startDate,
    DateTime? endDate,
    required int page,
    required int pageSize,
  }) =>
      _datasource.fetchExchangeReport(
          startDate: startDate, endDate: endDate, page: page, pageSize: pageSize);
}
