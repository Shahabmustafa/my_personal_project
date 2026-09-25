import 'package:flutter_riverpod/legacy.dart';
import '../../../branch/data/repository/branch_repository.dart';
import '../../../branch/presentation/providers/branch_provider.dart';
import '../../../branch_target/data/branch_target_datasource.dart';
import '../../data/model/branch_target_row.dart';
import '../../data/repository/sale_report_repository.dart';
import 'sale_report_providers.dart' show saleReportRepositoryProvider;

class BranchTargetReportState {
  final List<BranchTargetRow> rows;
  final bool isLoading;
  final String? error;

  /// Jab data aakhri baar load hua — har row ke sath "Date & Time" ke taur
  /// par dikhaya jata hai.
  final DateTime? asOf;

  const BranchTargetReportState({
    this.rows = const [],
    this.isLoading = false,
    this.error,
    this.asOf,
  });

  BranchTargetReportState copyWith({
    List<BranchTargetRow>? rows,
    bool? isLoading,
    String? error,
    bool clearError = false,
    DateTime? asOf,
  }) =>
      BranchTargetReportState(
        rows: rows ?? this.rows,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        asOf: asOf ?? this.asOf,
      );
}

/// Har active branch ka aaj ka target aur aaj ki net sale — "Branch Target"
/// report.
class BranchTargetReportNotifier extends StateNotifier<BranchTargetReportState> {
  final SaleReportRepository _saleRepo;
  final BranchRepository _branchRepo;
  final BranchTargetDatasource _targetDs;
  BranchTargetReportNotifier(this._saleRepo, this._branchRepo, this._targetDs)
      : super(const BranchTargetReportState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final today = DateTime.now();
      final results = await Future.wait([
        _branchRepo.getAllBranches(),
        _saleRepo.getNetSaleByBranch(),
        _targetDs.fetchForDate(today),
      ]);
      final branches = results[0] as List<dynamic>;
      final netByBranch = results[1] as Map<String, double>;
      final targetByBranch = results[2] as Map<String, double>;

      final rows = branches
          .where((b) => b.isActive as bool)
          .map((b) => BranchTargetRow(
                branchId: b.id as String,
                branchName: b.branchName as String,
                todayTarget: targetByBranch[b.id as String] ?? 0,
                netSaleToday: netByBranch[b.id as String] ?? 0,
              ))
          .toList()
        ..sort((a, b) => a.branchName.compareTo(b.branchName));

      state = state.copyWith(rows: rows, isLoading: false, asOf: DateTime.now());
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final branchTargetReportProvider =
    StateNotifierProvider<BranchTargetReportNotifier, BranchTargetReportState>((ref) {
  return BranchTargetReportNotifier(
    ref.read(saleReportRepositoryProvider),
    ref.read(branchRepositoryProvider),
    ref.read(branchTargetDatasourceProvider),
  );
});
