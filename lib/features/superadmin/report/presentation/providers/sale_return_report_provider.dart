import 'package:flutter_riverpod/legacy.dart';
import '../../../../branch/sale_return/data/model/sale_return_model.dart';
import '../../data/repository/sale_report_repository.dart';
import 'report_state.dart';
import 'sale_invoice_report_provider.dart' show saleReportRepositoryProvider;

class SaleReturnReportNotifier extends StateNotifier<ReportState<SaleReturnModel>> {
  final SaleReportRepository _repo;
  SaleReturnReportNotifier(this._repo) : super(const ReportState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.getReturnReport(
        startDate: state.startDate,
        endDate: state.endDate,
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
}

final saleReturnReportProvider =
    StateNotifierProvider<SaleReturnReportNotifier, ReportState<SaleReturnModel>>(
  (ref) => SaleReturnReportNotifier(ref.read(saleReportRepositoryProvider)),
);
