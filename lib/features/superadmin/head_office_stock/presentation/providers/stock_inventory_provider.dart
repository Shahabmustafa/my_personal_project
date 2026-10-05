import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safishoe_app/core/service/realtime/table_changes_provider.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/pagination/pagination.dart';
import '../../data/datasource/stock_inventory_datasource.dart';
import '../../data/model/stock_inventory_model.dart';
import '../../data/repository/stock_inventory_repository.dart';

// ── Infrastructure ────────────────────────────────────────────────────────
final stockInventoryDatasourceProvider = Provider<StockInventoryDatasource>(
  (ref) => StockInventoryDatasource(Supabase.instance.client),
);

final stockInventoryRepositoryProvider = Provider<StockInventoryRepository>(
  (ref) => StockInventoryRepository(ref.read(stockInventoryDatasourceProvider)),
);

// ── Server-paginated stock list (head office) ─────────────────────────────
class HeadOfficeStockNotifier
    extends PaginatedListNotifier<StockInventoryModel> {
  final StockInventoryRepository _repo;
  HeadOfficeStockNotifier(this._repo) : super(pageSize: pageSize);

  /// Screen page-by-page dikhata hai (infinite scroll nahi) — 100 per page.
  static const pageSize = 100;

  int get totalPages => state.totalCount <= 0
      ? 1
      : ((state.totalCount - 1) ~/ state.pageSize) + 1;

  @override
  Future<PageResult<StockInventoryModel>> fetchPage(PageRequest request) =>
      _repo.fetchStockPage(request);

  /// Usi page ko chupchaap dobara laata hai (spinner/page reset ke baghair) —
  /// realtime change aane par.
  Future<void> reloadCurrentPage() async {
    if (state.isFirstLoad) return;
    try {
      final result =
          await fetchPage(state.requestFor(state.page, withCount: true));
      state = state.copyWith(
        rows: result.rows,
        totalCount:
            result.totalCount < 0 ? state.totalCount : result.totalCount,
      );
    } catch (_) {
      // Agli change ya manual Refresh par phir try hoga.
    }
  }

  /// [page] ki rows load kar ke purani rows replace karta hai.
  Future<void> goToPage(int page) async {
    final target = page.clamp(1, totalPages);
    if (target == state.page && !state.isFirstLoad) return;
    state = state.copyWith(isFirstLoad: true, clearError: true);
    try {
      final result =
          await fetchPage(state.requestFor(target, withCount: false));
      state = state.copyWith(
          rows: result.rows, page: target, isFirstLoad: false);
    } catch (e) {
      state = state.copyWith(
          isFirstLoad: false,
          error: e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final headOfficeStockProvider = StateNotifierProvider<HeadOfficeStockNotifier,
    PaginatedListState<StockInventoryModel>>(
  (ref) {
    final notifier =
        HeadOfficeStockNotifier(ref.read(stockInventoryRepositoryProvider));
    // Realtime — assign stock / purchase / return se quantity badalte hi
    // list update. Ek assignment kai rows badalta hai, is liye thoda ruk kar
    // ek hi baar reload.
    Timer? debounce;
    ref.listen(tableChangesProvider('stock_inventory'), (_, _) {
      debounce?.cancel();
      debounce = Timer(
          const Duration(milliseconds: 400), notifier.reloadCurrentPage);
    });
    ref.onDispose(() => debounce?.cancel());
    return notifier;
  },
);

class HeadOfficeStockStats {
  final int totalSkus;

  /// Alag products (articles) ki ginti.
  final int totalArticles;
  final int totalQty;

  /// Sale price × quantity.
  final double totalValue;

  /// Purchase price × quantity.
  final double totalPurchaseValue;
  final int lowStockCount;
  const HeadOfficeStockStats(
      {this.totalSkus = 0,
      this.totalArticles = 0,
      this.totalQty = 0,
      this.totalValue = 0,
      this.totalPurchaseValue = 0,
      this.lowStockCount = 0});
}

final headOfficeStockStatsProvider =
    FutureProvider.autoDispose<HeadOfficeStockStats>((ref) async {
  // Realtime — stock badalte hi cards ke totals bhi dobara.
  ref.watch(tableChangesProvider('stock_inventory'));
  final res =
      await Supabase.instance.client.rpc('head_office_stock_stats');
  final j = (res as Map).cast<String, dynamic>();
  return HeadOfficeStockStats(
    totalSkus: (j['total_skus'] as num?)?.toInt() ?? 0,
    totalArticles: (j['total_articles'] as num?)?.toInt() ?? 0,
    totalQty: (j['total_qty'] as num?)?.toInt() ?? 0,
    totalValue: (j['total_value'] as num?)?.toDouble() ?? 0,
    totalPurchaseValue:
        (j['total_purchase_value'] as num?)?.toDouble() ?? 0,
    lowStockCount: (j['low_stock_count'] as num?)?.toInt() ?? 0,
  );
});

// ── Add action helper ────────────────────────────────────────────────────
final headOfficeStockActionsProvider = Provider<HeadOfficeStockActions>(
  (ref) => HeadOfficeStockActions(ref.read(stockInventoryRepositoryProvider)),
);

class HeadOfficeStockActions {
  final StockInventoryRepository _repo;
  HeadOfficeStockActions(this._repo);

  /// Returns (error message or null, list of skipped duplicate labels).
  Future<({String? error, List<String> skipped})> addBatchStock(
      List<StockInventoryModel> stocks) async {
    try {
      final toInsert = <StockInventoryModel>[];
      final skipped = <String>[];

      for (final s in stocks) {
        if (await _repo.barcodeExists(s.barcode)) {
          skipped.add('Barcode ${s.barcode} already exists');
          continue;
        }
        final skuEx = await _repo.skuExists(
          productId: s.productId,
          sizeId: s.sizeId,
          brandId: s.brandId,
          companyId: s.companyId,
          colorId: s.colorId,
          categoryId: s.categoryId,
          typeId: s.typeId,
        );
        if (skuEx) {
          skipped.add('SKU combination already exists');
          continue;
        }
        toInsert.add(s);
      }

      if (toInsert.isNotEmpty) {
        await _repo.addBatchStock(toInsert);
      }
      return (error: null, skipped: skipped);
    } catch (e) {
      return (error: e.toString(), skipped: <String>[]);
    }
  }

  Future<String?> updateQuantity(String stockId, int qty) async {
    try {
      await _repo.updateQuantity(stockId, qty);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateDiscount(String stockId, double discount) async {
    try {
      await _repo.updateDiscount(stockId, discount);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteStock(String stockId) async {
    try {
      await _repo.deleteStock(stockId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
