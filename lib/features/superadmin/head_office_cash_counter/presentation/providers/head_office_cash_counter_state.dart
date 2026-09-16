import '../../data/model/head_office_cash_counter_model.dart';

enum HeadOfficeCashCounterStatus { initial, loading, success, error }

class HeadOfficeCashCounterState {
  final HeadOfficeCashCounterStatus status;
  final List<HeadOfficeCashCounterModel> records;
  final String? errorMessage;

  const HeadOfficeCashCounterState({
    this.status = HeadOfficeCashCounterStatus.initial,
    this.records = const [],
    this.errorMessage,
  });

  HeadOfficeCashCounterState copyWith({
    HeadOfficeCashCounterStatus? status,
    List<HeadOfficeCashCounterModel>? records,
    String? errorMessage,
  }) {
    return HeadOfficeCashCounterState(
      status: status ?? this.status,
      records: records ?? this.records,
      errorMessage: errorMessage,
    );
  }

  bool get isLoading => status == HeadOfficeCashCounterStatus.loading;

  double get totalNetAmount =>
      records.fold(0, (sum, r) => sum + r.netAmount);
  double get totalPurchase =>
      records.fold(0, (sum, r) => sum + r.totalPurchase);
  double get totalReturn =>
      records.fold(0, (sum, r) => sum + r.totalReturnPurchase);
  double get totalExpense => records.fold(0, (sum, r) => sum + r.expense);
}
