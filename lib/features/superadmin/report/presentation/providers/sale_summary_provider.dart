import 'package:flutter_riverpod/legacy.dart';
import '../../data/model/sale_summary_totals.dart';
import '../../data/model/sale_transaction_row.dart';
import '../../data/repository/sale_report_repository.dart';
import 'sale_invoice_report_provider.dart' show saleReportRepositoryProvider;

class SaleSummaryState {
  final SaleSummaryTotals totals;
  final List<SaleTransactionRow> transactions;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? branchId;
  final bool isLoading;
  final String? error;

  const SaleSummaryState({
    this.totals = const SaleSummaryTotals(),
    this.transactions = const [],
    this.startDate,
    this.endDate,
    this.branchId,
    this.isLoading = false,
    this.error,
  });

  bool get hasFilter => startDate != null || endDate != null;

  SaleSummaryState copyWith({
    SaleSummaryTotals? totals,
    List<SaleTransactionRow>? transactions,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    String? branchId,
    bool clearBranchId = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      SaleSummaryState(
        totals: totals ?? this.totals,
        transactions: transactions ?? this.transactions,
        startDate: clearStartDate ? null : startDate ?? this.startDate,
        endDate: clearEndDate ? null : endDate ?? this.endDate,
        branchId: clearBranchId ? null : branchId ?? this.branchId,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

/// Sale Summary screen ke top cards drive karta hai — Total Sale, Total
/// Return, Exchange Change, Net Total Sale — optional date-range + branch
/// filter ke sath.
class SaleSummaryNotifier extends StateNotifier<SaleSummaryState> {
  final SaleReportRepository _repo;
  SaleSummaryNotifier(this._repo) : super(const SaleSummaryState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _repo.getSummaryTotals(
          startDate: state.startDate,
          endDate: state.endDate,
          branchId: state.branchId,
        ),
        _repo.getCombinedTransactions(
          startDate: state.startDate,
          endDate: state.endDate,
          branchId: state.branchId,
        ),
      ]);
      state = state.copyWith(
        totals: results[0] as SaleSummaryTotals,
        transactions: results[1] as List<SaleTransactionRow>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  void applyDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(
      startDate: start,
      clearStartDate: start == null,
      endDate: end,
      clearEndDate: end == null,
    );
    load();
  }

  void clearDateRange() {
    state = state.copyWith(clearStartDate: true, clearEndDate: true);
    load();
  }

  void setBranch(String? branchId) {
    state = state.copyWith(
      branchId: branchId,
      clearBranchId: branchId == null || branchId.isEmpty,
    );
    load();
  }
}

final saleSummaryProvider = StateNotifierProvider<SaleSummaryNotifier, SaleSummaryState>(
  (ref) => SaleSummaryNotifier(ref.read(saleReportRepositoryProvider)),
);
