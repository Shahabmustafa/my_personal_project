import '../../data/model/warehouse_cash_counter_model.dart';

enum CashCounterStatus { initial, loading, success, error }

class WarehouseCashCounterState {
  final CashCounterStatus status;
  final List<WarehouseCashCounterModel> records;
  final String? errorMessage;

  const WarehouseCashCounterState({
    this.status = CashCounterStatus.initial,
    this.records = const [],
    this.errorMessage,
  });

  WarehouseCashCounterState copyWith({
    CashCounterStatus? status,
    List<WarehouseCashCounterModel>? records,
    String? errorMessage,
  }) {
    return WarehouseCashCounterState(
      status: status ?? this.status,
      records: records ?? this.records,
      errorMessage: errorMessage,
    );
  }

  bool get isLoading => status == CashCounterStatus.loading;

  // Summary totals across all records
  double get totalNetAmount =>
      records.fold(0, (sum, r) => sum + r.netAmount);
  double get totalPurchase =>
      records.fold(0, (sum, r) => sum + r.totalPurchase);
  double get totalReturn =>
      records.fold(0, (sum, r) => sum + r.totalReturnPurchase);
  double get totalExpense =>
      records.fold(0, (sum, r) => sum + r.expense);
}
