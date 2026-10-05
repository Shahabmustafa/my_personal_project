import 'package:flutter_riverpod/legacy.dart';
import '../../../branch/data/repository/branch_repository.dart';
import '../../../branch/presentation/providers/branch_provider.dart';
import '../../../branch_target/data/branch_target_datasource.dart';
import '../../data/model/branch_target_row.dart';
import '../../data/repository/sale_report_repository.dart';
import 'sale_report_providers.dart' show saleReportRepositoryProvider;

enum TargetPeriod { today, monthly, yearly }

class BranchTargetReportState {
  final List<BranchTargetRow> rows;
  final bool isLoading;
  final String? error;

  /// Jab data aakhri baar load hua — har row ke sath "Date & Time" ke taur
  /// par dikhaya jata hai.
  final DateTime? asOf;

  final TargetPeriod period;

  /// Chuna hua mahina/saal — is din ka mahina (monthly) ya saal (yearly).
  final DateTime anchor;

  BranchTargetReportState({
    this.rows = const [],
    this.isLoading = false,
    this.error,
    this.asOf,
    this.period = TargetPeriod.today,
    DateTime? anchor,
  }) : anchor = anchor ?? DateTime.now();

  /// Period ka pehla din.
  DateTime get from => switch (period) {
        TargetPeriod.today => DateTime(anchor.year, anchor.month, anchor.day),
        TargetPeriod.monthly => DateTime(anchor.year, anchor.month, 1),
        TargetPeriod.yearly => DateTime(anchor.year, 1, 1),
      };

  /// Period ka aakhri din (us din samet).
  DateTime get to => switch (period) {
        TargetPeriod.today => from,
        TargetPeriod.monthly => DateTime(anchor.year, anchor.month + 1, 0),
        TargetPeriod.yearly => DateTime(anchor.year, 12, 31),
      };

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// "Today", "Oct 2026" ya "2026".
  String get periodLabel => switch (period) {
        TargetPeriod.today => 'Today',
        TargetPeriod.monthly => '${_months[anchor.month - 1]} ${anchor.year}',
        TargetPeriod.yearly => '${anchor.year}',
      };

  /// Aage wala mahina/saal abhi shuru nahi hua — wahan jane ka faida nahi.
  bool get canGoNext {
    final now = DateTime.now();
    return switch (period) {
      TargetPeriod.today => false,
      TargetPeriod.monthly =>
        anchor.year < now.year || (anchor.year == now.year && anchor.month < now.month),
      TargetPeriod.yearly => anchor.year < now.year,
    };
  }

  BranchTargetReportState copyWith({
    List<BranchTargetRow>? rows,
    bool? isLoading,
    String? error,
    bool clearError = false,
    DateTime? asOf,
    TargetPeriod? period,
    DateTime? anchor,
  }) =>
      BranchTargetReportState(
        rows: rows ?? this.rows,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        asOf: asOf ?? this.asOf,
        period: period ?? this.period,
        anchor: anchor ?? this.anchor,
      );
}

/// Har active branch ka chune hue period (aaj / mahina / saal) ka total
/// target aur net sale — "Branch Target" report.
class BranchTargetReportNotifier extends StateNotifier<BranchTargetReportState> {
  final SaleReportRepository _saleRepo;
  final BranchRepository _branchRepo;
  final BranchTargetDatasource _targetDs;
  BranchTargetReportNotifier(this._saleRepo, this._branchRepo, this._targetDs)
      : super(BranchTargetReportState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final from = state.from;
      final to = state.to;
      final results = await Future.wait([
        _branchRepo.getAllBranches(),
        _saleRepo.getNetSaleByBranch(date: from, to: to),
        _targetDs.fetchTotalsForRange(from, to),
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

  void setPeriod(TargetPeriod period) {
    if (period == state.period) return;
    state = state.copyWith(period: period, anchor: DateTime.now());
    load();
  }

  /// Pichla (-1) ya agla (+1) mahina/saal.
  void shift(int delta) {
    final a = state.anchor;
    final next = switch (state.period) {
      TargetPeriod.today => a,
      TargetPeriod.monthly => DateTime(a.year, a.month + delta, 1),
      TargetPeriod.yearly => DateTime(a.year + delta, 1, 1),
    };
    state = state.copyWith(anchor: next);
    load();
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
