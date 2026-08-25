import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/stock_datasource.dart';
import '../../data/models/warehouse_stock_model.dart';
import '../../data/repositories/stock_repository.dart';
import '../../../shared/current_warehouse_provider.dart';

// ── Infrastructure ────────────────────────────────────────────────────────
final stockDatasourceProvider = Provider<StockDatasource>(
  (ref) => StockDatasource(Supabase.instance.client),
);

final stockRepositoryProvider = Provider<StockRepository>(
  (ref) => StockRepository(ref.read(stockDatasourceProvider)),
);

// ── Lookup providers ──────────────────────────────────────────────────────
final stockProductsProvider = FutureProvider<List<StockLookupItem>>(
    (ref) => ref.read(stockRepositoryProvider).getProducts());

final stockSizesProvider = FutureProvider<List<StockLookupItem>>(
    (ref) => ref.read(stockRepositoryProvider).getSizes());

final stockBrandsProvider = FutureProvider<List<StockLookupItem>>(
    (ref) => ref.read(stockRepositoryProvider).getBrands());

final stockCompaniesProvider = FutureProvider<List<StockLookupItem>>(
    (ref) => ref.read(stockRepositoryProvider).getCompanies());

final stockColorsProvider = FutureProvider<List<StockLookupItem>>(
    (ref) => ref.read(stockRepositoryProvider).getColors());

final stockCategoriesProvider = FutureProvider<List<StockLookupItem>>(
    (ref) => ref.read(stockRepositoryProvider).getCategories());

final stockTypesProvider = FutureProvider<List<StockLookupItem>>(
    (ref) => ref.read(stockRepositoryProvider).getTypes());

// ── Admin: read-only stock across ALL warehouses ────────────────────────────
final adminStockProvider = FutureProvider<List<WarehouseStockModel>>(
    (ref) => ref.read(stockRepositoryProvider).getAllStock());

// ── Stock list state ──────────────────────────────────────────────────────
class StockState {
  final List<WarehouseStockModel> items;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const StockState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  StockState copyWith({
    List<WarehouseStockModel>? items,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) =>
      StockState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        searchQuery: searchQuery ?? this.searchQuery,
      );

  List<WarehouseStockModel> get filtered {
    if (searchQuery.isEmpty) return items;
    final q = searchQuery.toLowerCase();
    return items.where((s) =>
        (s.productName ?? '').toLowerCase().contains(q) ||
        s.barcode.toLowerCase().contains(q) ||
        (s.brandName ?? '').toLowerCase().contains(q) ||
        (s.colorName ?? '').toLowerCase().contains(q) ||
        (s.sizeName ?? '').toLowerCase().contains(q) ||
        (s.categoryName ?? '').toLowerCase().contains(q) ||
        (s.typeName ?? '').toLowerCase().contains(q)).toList();
  }
}

class StockNotifier extends StateNotifier<StockState> {
  final StockRepository _repository;
  final String _warehouseId;

  StockNotifier(this._repository, this._warehouseId)
      : super(const StockState());

  Future<void> loadStock() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _repository.getStockByWarehouse(_warehouseId);
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Returns: list of skipped (duplicate) barcode/sku labels, or empty if all saved
  Future<({String? error, List<String> skipped})> addBatchStock(
      List<WarehouseStockModel> stocks) async {
    try {
      // Check each entry for barcode + SKU duplicates before inserting
      final toInsert = <WarehouseStockModel>[];
      final skipped = <String>[];

      for (final s in stocks) {
        final bcExists = await _repository.barcodeExists(s.barcode);
        if (bcExists) {
          skipped.add('Barcode ${s.barcode} already exists');
          continue;
        }
        final skuEx = await _repository.skuExists(
          warehouseId: s.warehouseId,
          productId: s.productId,
          sizeId: s.sizeId,
          brandId: s.brandId,
          companyId: s.companyId,
          colorId: s.colorId,
          categoryId: s.categoryId,
          typeId: s.typeId,
        );
        if (skuEx) {
          skipped.add('SKU combination already exists in warehouse');
          continue;
        }
        toInsert.add(s);
      }

      if (toInsert.isNotEmpty) {
        await _repository.addBatchStock(toInsert);
        await loadStock();
      }

      return (error: null, skipped: skipped);
    } catch (e) {
      return (error: e.toString(), skipped: <String>[]);
    }
  }

  Future<String?> updateQuantity(String stockId, int qty) async {
    try {
      final updated = await _repository.updateQuantity(stockId, qty);
      state = state.copyWith(
        items: state.items.map((s) => s.id == stockId ? updated : s).toList(),
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateDiscount(String stockId, double discount) async {
    try {
      final updated = await _repository.updateDiscount(stockId, discount);
      state = state.copyWith(
        items: state.items.map((s) => s.id == stockId ? updated : s).toList(),
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteStock(String stockId) async {
    try {
      await _repository.deleteStock(stockId);
      state = state.copyWith(
          items: state.items.where((s) => s.id != stockId).toList());
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  void search(String query) => state = state.copyWith(searchQuery: query);
}

final stockProvider =
    StateNotifierProvider<StockNotifier, StockState>((ref) {
  return StockNotifier(
    ref.read(stockRepositoryProvider),
    ref.watch(currentWarehouseIdProvider),
  );
});
