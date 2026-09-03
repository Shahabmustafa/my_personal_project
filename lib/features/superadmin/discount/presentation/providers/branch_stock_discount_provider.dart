import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../branch/branch_stock_inventory/data/model/branch_stock_model.dart';
import '../../data/branch_stock_discount_datasource.dart';
import '../../data/branch_stock_discount_repository.dart';

// ── Infrastructure ────────────────────────────────────────────────────────
final _datasourceProvider = Provider<BranchStockDiscountDatasource>(
  (ref) => BranchStockDiscountDatasource(Supabase.instance.client),
);

final branchStockDiscountRepositoryProvider =
    Provider<BranchStockDiscountRepository>(
  (ref) => BranchStockDiscountRepository(ref.read(_datasourceProvider)),
);

// ── State ─────────────────────────────────────────────────────────────────
class BranchStockDiscountState {
  final String? branchId;
  final List<BranchStockModel> items;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  /// Jin rows par abhi discount save ho raha hai unke ids.
  final Set<String> savingIds;

  const BranchStockDiscountState({
    this.branchId,
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.savingIds = const {},
  });

  List<BranchStockModel> get filtered {
    if (searchQuery.trim().isEmpty) return items;
    final q = searchQuery.toLowerCase();
    return items
        .where((i) =>
            (i.productName ?? '').toLowerCase().contains(q) ||
            i.barcode.toLowerCase().contains(q) ||
            (i.sizeName ?? '').toLowerCase().contains(q) ||
            (i.colorName ?? '').toLowerCase().contains(q) ||
            (i.brandName ?? '').toLowerCase().contains(q) ||
            (i.categoryName ?? '').toLowerCase().contains(q) ||
            (i.typeName ?? '').toLowerCase().contains(q))
        .toList();
  }

  int get discountedCount => items.where((i) => i.discount > 0).length;

  BranchStockDiscountState copyWith({
    String? branchId,
    List<BranchStockModel>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? searchQuery,
    Set<String>? savingIds,
  }) =>
      BranchStockDiscountState(
        branchId: branchId ?? this.branchId,
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        searchQuery: searchQuery ?? this.searchQuery,
        savingIds: savingIds ?? this.savingIds,
      );
}

class BranchStockDiscountNotifier
    extends StateNotifier<BranchStockDiscountState> {
  final BranchStockDiscountRepository _repo;

  BranchStockDiscountNotifier(this._repo)
      : super(const BranchStockDiscountState());

  Future<void> selectBranch(String branchId) async {
    if (branchId.isEmpty) return;
    state = state.copyWith(
      branchId: branchId,
      isLoading: true,
      clearError: true,
      items: [],
      searchQuery: '',
    );
    try {
      final list = await _repo.getStock(branchId);
      state = state.copyWith(items: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> refresh() async {
    final id = state.branchId;
    if (id != null) await selectBranch(id);
  }

  void search(String query) => state = state.copyWith(searchQuery: query);

  Future<void> updateDiscount(String branchStockId, double rawPct) async {
    final pct = rawPct.clamp(0, 100).toDouble();
    state = state.copyWith(savingIds: {...state.savingIds, branchStockId});
    try {
      await _repo.updateDiscount(branchStockId, pct);
      final updated = state.items
          .map((i) => i.id == branchStockId
              ? i.copyWith(discount: pct, updatedAt: DateTime.now())
              : i)
          .toList();
      state = state.copyWith(
        items: updated,
        savingIds: {...state.savingIds}..remove(branchStockId),
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
        savingIds: {...state.savingIds}..remove(branchStockId),
      );
    }
  }
}

final branchStockDiscountProvider = StateNotifierProvider<
    BranchStockDiscountNotifier, BranchStockDiscountState>(
  (ref) => BranchStockDiscountNotifier(
      ref.read(branchStockDiscountRepositoryProvider)),
);
