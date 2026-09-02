import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

// ── Read-only stock list (head office) ────────────────────────────────────
final headOfficeStockProvider = FutureProvider<List<StockInventoryModel>>(
    (ref) => ref.read(stockInventoryRepositoryProvider).getAllStock());

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
