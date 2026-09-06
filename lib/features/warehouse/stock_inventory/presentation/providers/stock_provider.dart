import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/pagination/pagination.dart';
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

// ── Lookup providers (small reference tables — unchanged) ──────────────────
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

// ── Aggregate stats (server-side RPC — no full-table download) ─────────────
class StockStats {
  final int totalSkus;
  final int totalQty;
  final double totalValue;
  final int lowStockCount;
  const StockStats(
      {this.totalSkus = 0,
      this.totalQty = 0,
      this.totalValue = 0,
      this.lowStockCount = 0});

  factory StockStats.fromJson(Map<String, dynamic> j) => StockStats(
        totalSkus: (j['total_skus'] as num?)?.toInt() ?? 0,
        totalQty: (j['total_qty'] as num?)?.toInt() ?? 0,
        totalValue: (j['total_value'] as num?)?.toDouble() ?? 0,
        lowStockCount: (j['low_stock_count'] as num?)?.toInt() ?? 0,
      );
}

/// Own-warehouse stats. Invalidate after stock mutations to refresh.
final warehouseStockStatsProvider =
    FutureProvider.autoDispose<StockStats>((ref) async {
  final wid = ref.watch(currentWarehouseIdProvider);
  if (wid.isEmpty) return const StockStats();
  final res = await Supabase.instance.client
      .rpc('warehouse_stock_stats', params: {'p_warehouse_id': wid});
  return StockStats.fromJson((res as Map).cast<String, dynamic>());
});

// ── Own-warehouse paginated stock list ────────────────────────────────────
class StockNotifier extends PaginatedListNotifier<WarehouseStockModel> {
  final StockRepository _repository;
  final String _warehouseId;

  StockNotifier(this._repository, this._warehouseId);

  @override
  Future<PageResult<WarehouseStockModel>> fetchPage(PageRequest request) =>
      _repository.fetchStockPage(request, warehouseId: _warehouseId);

  void toggleLowStock(bool value) =>
      setFilters({'low_stock': value ? true : null});

  /// Returns: list of skipped (duplicate) barcode/sku labels.
  Future<({String? error, List<String> skipped})> addBatchStock(
      List<WarehouseStockModel> stocks) async {
    try {
      final toInsert = <WarehouseStockModel>[];
      final skipped = <String>[];
      for (final s in stocks) {
        if (await _repository.barcodeExists(s.barcode)) {
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
        await refresh();
      }
      return (error: null, skipped: skipped);
    } catch (e) {
      return (error: e.toString(), skipped: <String>[]);
    }
  }

  Future<String?> updateQuantity(String stockId, int qty) async {
    try {
      final updated = await _repository.updateQuantity(stockId, qty);
      replaceRow((s) => s.id == stockId, updated);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateDiscount(String stockId, double discount) async {
    try {
      final updated = await _repository.updateDiscount(stockId, discount);
      replaceRow((s) => s.id == stockId, updated);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteStock(String stockId) async {
    try {
      await _repository.deleteStock(stockId);
      removeRow((s) => s.id == stockId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final stockProvider = StateNotifierProvider<StockNotifier,
    PaginatedListState<WarehouseStockModel>>((ref) {
  return StockNotifier(
    ref.read(stockRepositoryProvider),
    ref.watch(currentWarehouseIdProvider),
  );
});

// ── Admin: paginated stock across ALL warehouses (read-only) ───────────────
class AdminStockNotifier extends PaginatedListNotifier<WarehouseStockModel> {
  final StockRepository _repository;
  AdminStockNotifier(this._repository);

  @override
  Future<PageResult<WarehouseStockModel>> fetchPage(PageRequest request) =>
      _repository.fetchStockPage(request);
}

final adminStockProvider = StateNotifierProvider<AdminStockNotifier,
    PaginatedListState<WarehouseStockModel>>(
  (ref) => AdminStockNotifier(ref.read(stockRepositoryProvider)),
);
