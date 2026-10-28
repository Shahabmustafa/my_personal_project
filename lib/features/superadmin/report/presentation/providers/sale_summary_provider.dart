import 'package:flutter_riverpod/legacy.dart';
import '../../data/model/sale_summary_totals.dart';
import '../../data/model/sale_transaction_row.dart';
import '../../data/repository/sale_report_repository.dart';
import 'sale_report_providers.dart' show saleReportRepositoryProvider;

class SaleSummaryState {
  final SaleSummaryTotals totals;
  final List<SaleTransactionRow> transactions;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? branchId;
  final int page;
  final bool isLoading;
  final String? error;

  const SaleSummaryState({
    this.totals = const SaleSummaryTotals(),
    this.transactions = const [],
    this.startDate,
    this.endDate,
    this.branchId,
    this.page = 1,
    this.isLoading = false,
    this.error,
  });

  static const pageSize = 50;

  bool get hasFilter => startDate != null || endDate != null;

  int get totalCount => totals.invoiceCount + totals.returnCount + totals.exchangeCount;
  int get totalPages => totalCount == 0 ? 1 : ((totalCount - 1) ~/ pageSize) + 1;

  SaleSummaryState copyWith({
    SaleSummaryTotals? totals,
    List<SaleTransactionRow>? transactions,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    String? branchId,
    bool clearBranchId = false,
    int? page,
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
        page: page ?? this.page,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

/// Sale Summary screen ke top cards drive karta hai — Total Sale, Total
/// Return, Exchange Change, Net Total Sale — optional date-range + branch
/// filter ke sath.
class SaleSummaryNotifier extends StateNotifier<SaleSummaryState> {
  final SaleReportRepository _repo;
  /// Default aaj ka din — pehli load par sirf aaj ke invoices dikhte hain;
  /// filter clear karne par poora data.
  SaleSummaryNotifier(this._repo)
      : super(SaleSummaryState(startDate: _today(), endDate: _today())) {
    load();
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Filter badalne ya refresh par: totals + pehla page.
  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final totals = await _repo.getSummaryTotals(
        startDate: state.startDate,
        endDate: state.endDate,
        branchId: state.branchId,
      );
      state = state.copyWith(totals: totals);
      final page = state.page.clamp(1, state.totalPages);
      final rows = await _fetchPage(page);
      state = state.copyWith(transactions: rows, page: page, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceFirst(RegExp(r'^Exception: '), ''));
    }
  }

  Future<List<SaleTransactionRow>> _fetchPage(int page) => _repo.getTransactionsPage(
        startDate: state.startDate,
        endDate: state.endDate,
        branchId: state.branchId,
        page: page,
        pageSize: SaleSummaryState.pageSize,
      );

  /// Sirf list ka page badalta hai — totals dobara nahi mangta.
  Future<void> goToPage(int page) async {
    final target = page.clamp(1, state.totalPages);
    state = state.copyWith(page: target, isLoading: true, clearError: true);
    try {
      final rows = await _fetchPage(target);
      state = state.copyWith(transactions: rows, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceFirst(RegExp(r'^Exception: '), ''));
    }
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

final saleSummaryProvider = StateNotifierProvider<SaleSummaryNotifier, SaleSummaryState>(
  (ref) => SaleSummaryNotifier(ref.read(saleReportRepositoryProvider)),
);
