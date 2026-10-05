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
  final bool isLoading;
  final String? error;

  const PurchaseSummaryState({
    this.totals = const PurchaseSummaryTotals(),
    this.transactions = const [],
    this.startDate,
    this.endDate,
    this.companyId,
    this.isLoading = false,
    this.error,
  });

  bool get hasFilter => startDate != null || endDate != null;

  PurchaseSummaryState copyWith({
    PurchaseSummaryTotals? totals,
    List<PurchaseTransactionRow>? transactions,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    String? companyId,
    bool clearCompanyId = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      PurchaseSummaryState(
        totals: totals ?? this.totals,
        transactions: transactions ?? this.transactions,
        startDate: clearStartDate ? null : startDate ?? this.startDate,
        endDate: clearEndDate ? null : endDate ?? this.endDate,
        companyId: clearCompanyId ? null : companyId ?? this.companyId,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

/// Purchase Summary screen — Total Purchase / Total Return / Net Purchase /
/// Credit cards aur combined history, date-range + company filter ke sath.
class PurchaseSummaryNotifier extends StateNotifier<PurchaseSummaryState> {
  final PurchaseReportDatasource _datasource;
  PurchaseSummaryNotifier(this._datasource) : super(const PurchaseSummaryState()) {
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
      state = state.copyWith(totals: totals, transactions: rows, isLoading: false);
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
  (ref) => PurchaseSummaryNotifier(ref.read(purchaseReportDatasourceProvider)),
);
