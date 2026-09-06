import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  HeadOfficeStockNotifier(this._repo);

  @override
  Future<PageResult<StockInventoryModel>> fetchPage(PageRequest request) =>
      _repo.fetchStockPage(request);
}

final headOfficeStockProvider = StateNotifierProvider<HeadOfficeStockNotifier,
    PaginatedListState<StockInventoryModel>>(
  (ref) => HeadOfficeStockNotifier(ref.read(stockInventoryRepositoryProvider)),
);

class HeadOfficeStockStats {
  final int totalSkus;
  final int totalQty;
  final double totalValue;
  final int lowStockCount;
  const HeadOfficeStockStats(
      {this.totalSkus = 0,
      this.totalQty = 0,
      this.totalValue = 0,
      this.lowStockCount = 0});
}

final headOfficeStockStatsProvider =
    FutureProvider.autoDispose<HeadOfficeStockStats>((ref) async {
  final res =
      await Supabase.instance.client.rpc('head_office_stock_stats');
  final j = (res as Map).cast<String, dynamic>();
  return HeadOfficeStockStats(
    totalSkus: (j['total_skus'] as num?)?.toInt() ?? 0,
    totalQty: (j['total_qty'] as num?)?.toInt() ?? 0,
    totalValue: (j['total_value'] as num?)?.toDouble() ?? 0,
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
