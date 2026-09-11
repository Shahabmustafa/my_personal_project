import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../branch/sale_invoice/data/model/sale_invoice_model.dart';
import '../../data/datasource/sale_report_datasource.dart';
import '../../data/repository/sale_report_repository.dart';
import 'report_state.dart';

final saleReportDatasourceProvider = Provider<SaleReportDatasource>(
  (_) => SaleReportDatasource(Supabase.instance.client),
);

final saleReportRepositoryProvider = Provider<SaleReportRepository>(
  (ref) => SaleReportRepository(ref.read(saleReportDatasourceProvider)),
);

class SaleInvoiceReportNotifier extends StateNotifier<ReportState<SaleInvoiceModel>> {
  final SaleReportRepository _repo;
  SaleInvoiceReportNotifier(this._repo) : super(const ReportState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.getInvoiceReport(
        startDate: state.startDate,
        endDate: state.endDate,
        branchId: state.branchId,
        page: state.page,
        pageSize: state.pageSize,
      );
      state = state.copyWith(
        rows: result.rows,
        totalCount: result.totalCount,
        totalQuantity: result.totalQuantity,
        totalAmount: result.totalAmount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  void goToPage(int page) {
    if (page < 1 || page > state.totalPages || page == state.page) return;
    state = state.copyWith(page: page);
    load();
  }

  void applyDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(
      startDate: start,
      clearStartDate: start == null,
      endDate: end,
      clearEndDate: end == null,
      page: 1,
    );
    load();
  }

  void clearDateRange() {
    state = state.copyWith(clearStartDate: true, clearEndDate: true, page: 1);
    load();
  }

  void setBranch(String? branchId) {
    state = state.copyWith(
      branchId: branchId,
      clearBranchId: branchId == null || branchId.isEmpty,
      page: 1,
    );
    load();
  }
}

final saleInvoiceReportProvider =
    StateNotifierProvider<SaleInvoiceReportNotifier, ReportState<SaleInvoiceModel>>(
  (ref) => SaleInvoiceReportNotifier(ref.read(saleReportRepositoryProvider)),
);
