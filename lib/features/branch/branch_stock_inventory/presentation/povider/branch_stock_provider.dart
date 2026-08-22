import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

// ── Branch Stock State ────────────────────────────────────────────────────
class BranchStockState {
  final List<BranchStockModel> items;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const BranchStockState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  // Search filter
  List<BranchStockModel> get filtered {
    if (searchQuery.isEmpty) return items;
    final q = searchQuery.toLowerCase();
    return items.where((i) =>
        (i.productName ?? '').toLowerCase().contains(q) ||
        i.barcode.toLowerCase().contains(q) ||
        (i.sizeName ?? '').toLowerCase().contains(q) ||
        (i.colorName ?? '').toLowerCase().contains(q) ||
        (i.brandName ?? '').toLowerCase().contains(q) ||
        (i.categoryName ?? '').toLowerCase().contains(q) ||
        (i.typeName ?? '').toLowerCase().contains(q)).toList();
  }

  int get totalQuantity => items.fold(0, (s, i) => s + i.quantity);
  int get totalProducts => items.length;
  int get lowStockCount => items.where((i) => i.quantity <= 5).length;
  double get totalSalePrice =>
      items.fold(0, (s, i) => s + (i.salePrice * i.quantity));

  BranchStockState copyWith({
    List<BranchStockModel>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? searchQuery,
  }) =>
      BranchStockState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
        searchQuery: searchQuery ?? this.searchQuery,
      );
}

class BranchStockNotifier extends StateNotifier<BranchStockState> {
  final BranchStockRepository _repo;
  final String _branchId;

  BranchStockNotifier(this._repo, this._branchId)
      : super(const BranchStockState()) {
    loadStock();
  }

  Future<void> loadStock() async {
    if (_branchId.isEmpty) {
      state = state.copyWith(
          isLoading: false, error: 'Branch ID not found');
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repo.getBranchStock(_branchId);
      state = state.copyWith(items: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

final branchStockProvider =
    StateNotifierProvider<BranchStockNotifier, BranchStockState>(
  (ref) => BranchStockNotifier(
    ref.read(branchStockRepositoryProvider),
    ref.watch(currentBranchIdProvider),
  ),
);
