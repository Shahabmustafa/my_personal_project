import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safishoe_app/core/service/realtime/table_changes_provider.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/pagination/pagination.dart';
import '../../../shared/current_branch_provider.dart';
import '../../data/datasource/branch_stock_datasource.dart';
import '../../data/model/branch_stock_model.dart';
import '../../data/repository/branch_stock_repository.dart';

// ── Infrastructure ────────────────────────────────────────────────────────
final branchStockDatasourceProvider = Provider<BranchStockDatasource>(
  (ref) => BranchStockDatasource(Supabase.instance.client),
);

final branchStockRepositoryProvider = Provider<BranchStockRepository>(
  (ref) => BranchStockRepository(ref.read(branchStockDatasourceProvider)),
);

// ── Server-paginated branch stock list ────────────────────────────────────
class BranchStockNotifier extends PaginatedListNotifier<BranchStockModel> {
  final BranchStockRepository _repo;
  final String _branchId;

  BranchStockNotifier(this._repo, this._branchId);

  @override
  Future<PageResult<BranchStockModel>> fetchPage(PageRequest request) =>
      _repo.fetchStockPage(request, branchId: _branchId);
}

final branchStockProvider = StateNotifierProvider<BranchStockNotifier,
    PaginatedListState<BranchStockModel>>(
  (ref) {
    final notifier = BranchStockNotifier(
      ref.read(branchStockRepositoryProvider),
      ref.watch(currentBranchIdProvider),
    );
    // Realtime — sale, return, exchange, claim, transfer ya assign accept se
    // quantity badalte hi list update (bina Refresh).
    ref.listen(tableChangesProvider('branch_stock_inventory'),
        (_, _) => notifier.reloadLoaded());
    return notifier;
  },
);

// ── Aggregate stats (server-side RPC) ─────────────────────────────────────
class BranchStockStats {
  final int totalProducts;
  final int totalQuantity;
  final double totalSalePrice;
  final int lowStockCount;

  /// Poore branch stock mein 1–4 pairs / 0 pairs wale SKUs (filter se aazad).
  final int lowCount;
  final int outCount;
  const BranchStockStats(
      {this.totalProducts = 0,
      this.totalQuantity = 0,
      this.totalSalePrice = 0,
      this.lowStockCount = 0,
      this.lowCount = 0,
      this.outCount = 0});
}

final branchStockStatsProvider =
    FutureProvider.autoDispose<BranchStockStats>((ref) async {
  ref.watch(tableChangesProvider('branch_stock_inventory'));
  final bid = ref.watch(currentBranchIdProvider);
  if (bid.isEmpty) return const BranchStockStats();
  // Low / Out of Stock button lage to cards bhi usi filter ke totals.
  final level =
      ref.watch(branchStockProvider.select((s) => s.filters['stock_level']));
  final res = await Supabase.instance.client.rpc('branch_stock_stats',
      params: {'p_branch_id': bid, 'p_level': level});
  final j = (res as Map).cast<String, dynamic>();
  return BranchStockStats(
    totalProducts: (j['total_skus'] as num?)?.toInt() ?? 0,
    totalQuantity: (j['total_qty'] as num?)?.toInt() ?? 0,
    totalSalePrice: (j['total_value'] as num?)?.toDouble() ?? 0,
    lowStockCount: (j['low_stock_count'] as num?)?.toInt() ?? 0,
    lowCount: (j['low_count'] as num?)?.toInt() ?? 0,
    outCount: (j['out_count'] as num?)?.toInt() ?? 0,
  );
});
