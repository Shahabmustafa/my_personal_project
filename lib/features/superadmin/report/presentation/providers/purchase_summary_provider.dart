import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasource/purchase_report_datasource.dart';
import '../../data/model/purchase_transaction_row.dart';

final purchaseReportDatasourceProvider = Provider<PurchaseReportDatasource>(
  (_) => PurchaseReportDatasource(Supabase.instance.client),
);

final purchaseReportCompaniesProvider = FutureProvider<List<(String, String)>>(
  (ref) => ref.read(purchaseReportDatasourceProvider).fetchCompanies(),
);

class PurchaseSummaryState {
  final PurchaseSummaryTotals totals;
  final List<PurchaseTransactionRow> transactions;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? companyId;

  /// 1-based current page — list client-side [pageSize] rows per page.
  final int page;
  final bool isLoading;
  final String? error;

  const PurchaseSummaryState({
    this.totals = const PurchaseSummaryTotals(),
    this.transactions = const [],
    this.startDate,
    this.endDate,
    this.companyId,
    this.page = 1,
    this.isLoading = false,
    this.error,
  });

  static const pageSize = 10;

  bool get hasFilter => startDate != null || endDate != null;

  int get totalPages =>
      transactions.isEmpty ? 1 : ((transactions.length - 1) ~/ pageSize) + 1;

  List<PurchaseTransactionRow> get pageRows =>
      transactions.skip((page - 1) * pageSize).take(pageSize).toList();

  PurchaseSummaryState copyWith({
    PurchaseSummaryTotals? totals,
    List<PurchaseTransactionRow>? transactions,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    String? companyId,
    bool clearCompanyId = false,
    int? page,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) => PurchaseSummaryState(
    totals: totals ?? this.totals,
    transactions: transactions ?? this.transactions,
    startDate: clearStartDate ? null : startDate ?? this.startDate,
    endDate: clearEndDate ? null : endDate ?? this.endDate,
    companyId: clearCompanyId ? null : companyId ?? this.companyId,
    page: page ?? this.page,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : error ?? this.error,
  );
}

/// Purchase Summary screen — Total Purchase / Total Return / Net Purchase /
/// Credit cards aur combined history, date-range + company filter ke sath.
class PurchaseSummaryNotifier extends StateNotifier<PurchaseSummaryState> {
  final PurchaseReportDatasource _datasource;
  PurchaseSummaryNotifier(this._datasource)
    : super(const PurchaseSummaryState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final (totals, rows) = await _datasource.fetchSummary(
        startDate: state.startDate,
        endDate: state.endDate,
        companyId: state.companyId,
      );
      state = state.copyWith(
        totals: totals,
        transactions: rows,
        page: 1,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst(RegExp(r'^Exception: '), ''),
      );
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

  void goToPage(int page) {
    state = state.copyWith(page: page.clamp(1, state.totalPages));
  }

  void clearDateRange() {
    state = state.copyWith(clearStartDate: true, clearEndDate: true);
    load();
  }

  void setCompany(String? companyId) {
    state = state.copyWith(
      companyId: companyId,
      clearCompanyId: companyId == null || companyId.isEmpty,
    );
    load();
  }
}

final purchaseSummaryProvider =
    StateNotifierProvider<PurchaseSummaryNotifier, PurchaseSummaryState>(
      (ref) =>
          PurchaseSummaryNotifier(ref.read(purchaseReportDatasourceProvider)),
    );
