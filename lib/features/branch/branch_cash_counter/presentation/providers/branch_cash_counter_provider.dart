import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/datasource/branch_cash_counter_remote_datasource.dart';
import '../../data/model/branch_cash_counter_model.dart';
import '../../data/repository/branch_cash_counter_repository.dart';

final branchCashCounterDatasourceProvider =
    Provider<BranchCashCounterRemoteDatasource>(
  (_) => BranchCashCounterRemoteDatasource(),
);

final branchCashCounterRepositoryProvider =
    Provider<BranchCashCounterRepository>(
  (ref) => BranchCashCounterRepository(
      remoteDatasource: ref.read(branchCashCounterDatasourceProvider)),
);

enum BranchCashCounterStatus { initial, loading, success, error }

class BranchCashCounterState {
  final BranchCashCounterStatus status;
  final List<BranchCashCounterModel> records;
  final String? errorMessage;

  const BranchCashCounterState({
    this.status = BranchCashCounterStatus.initial,
    this.records = const [],
    this.errorMessage,
  });

  bool get isLoading => status == BranchCashCounterStatus.loading;

  double get totalSale => records.fold(0, (s, r) => s + r.totalSale);
  double get totalNetSale => records.fold(0, (s, r) => s + r.netSale);
  double get totalExpense => records.fold(0, (s, r) => s + r.expense);
  double get totalGross => records.fold(0, (s, r) => s + r.gross);
  double get totalAmount => records.fold(0, (s, r) => s + r.totalAmount);

  BranchCashCounterState copyWith({
    BranchCashCounterStatus? status,
    List<BranchCashCounterModel>? records,
    String? errorMessage,
    bool clearError = false,
  }) =>
      BranchCashCounterState(
        status: status ?? this.status,
        records: records ?? this.records,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      );
}

class BranchCashCounterNotifier extends StateNotifier<BranchCashCounterState> {
  final BranchCashCounterRepository _repo;
  BranchCashCounterNotifier(this._repo) : super(const BranchCashCounterState());

  Future<void> loadByBranch(String branchId) async {
    state = state.copyWith(
        status: BranchCashCounterStatus.loading, clearError: true);
    try {
      final records = await _repo.getByBranch(branchId);
      state = state.copyWith(
          status: BranchCashCounterStatus.success, records: records);
    } catch (e) {
      state = state.copyWith(
        status: BranchCashCounterStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

final branchCashCounterProvider =
    StateNotifierProvider<BranchCashCounterNotifier, BranchCashCounterState>(
  (ref) =>
      BranchCashCounterNotifier(ref.read(branchCashCounterRepositoryProvider)),
);
