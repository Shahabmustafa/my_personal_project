import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../../core/pagination/pagination.dart';
import '../../../../../core/service/realtime/table_changes_provider.dart';
import '../../../shared/current_branch_provider.dart';
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

/// Summary cards ke totals (poori table, server-side SUM). List ke saath
/// nahi, alag RPC call se aate hain — list ki pehli page / refresh / search
/// badalne par [BranchCashCounterNotifier] isay naye sire se laata hai.
final branchCashCounterStatsProvider =
    StateProvider<BranchCashCounterStats?>((_) => null);

// ── Server-paginated cash counter list ────────────────────────────────────
class BranchCashCounterNotifier extends PaginatedListNotifier<BranchCashCounterModel> {
  final BranchCashCounterRepository _repo;
  final String _branchId;
  final void Function(BranchCashCounterStats?) _onStats;

  /// Tez search / refresh mein purana jawab naye ko overwrite na kare.
  int _statsSeq = 0;

  BranchCashCounterNotifier(this._repo, this._branchId, this._onStats)
      : super(pageSize: 30);

  @override
  Future<PageResult<BranchCashCounterModel>> fetchPage(PageRequest request) {
    // withCount sirf pehli page / refresh / search badalne par true hota hai —
    // scroll (loadMore) par totals dobara nahi mangte.
    if (request.withCount) _loadStats(request.search);
    return _repo.fetchPage(request, branchId: _branchId);
  }

  /// Realtime change par: loaded rows aur totals dono chupchaap dobara —
  /// spinner ya scroll reset ke baghair.
  Future<void> reloadLive() async {
    await Future.wait([reloadLoaded(), _loadStats(state.search)]);
  }

  Future<void> _loadStats(String search) async {
    final seq = ++_statsSeq;
    try {
      final stats = await _repo.getStats(_branchId, search: search);
      if (mounted && seq == _statsSeq) _onStats(stats);
    } catch (_) {
      // Cards chhup jate hain; list apni jagah chalti rahti hai.
      if (mounted && seq == _statsSeq) _onStats(null);
    }
  }
}

final branchCashCounterProvider = StateNotifierProvider<
    BranchCashCounterNotifier, PaginatedListState<BranchCashCounterModel>>(
  (ref) {
    final notifier = BranchCashCounterNotifier(
      ref.read(branchCashCounterRepositoryProvider),
      ref.watch(currentBranchIdProvider),
      (stats) => ref.read(branchCashCounterStatsProvider.notifier).state = stats,
    );
    // Realtime — sale, return, exchange ya expense se counter row badalte hi
    // list aur summary cards update (bina Refresh).
    ref.listen(tableChangesProvider('branch_cash_counter'),
        (_, _) => notifier.reloadLive());
    return notifier;
  },
);
