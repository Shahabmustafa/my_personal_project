import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/purchase_invoice_datasource.dart';
import '../../data/models/purchase_invoice_model.dart';
import '../../data/models/warehouse_stock_model.dart';
import '../../data/repositories/purchase_invoice_repository.dart';

const kWarehouseId = '1d6646fe-d2ce-43a6-a9b3-705f23c199ee';

// ── Infrastructure ────────────────────────────────────────────────────────
final purchaseInvoiceDatasourceProvider = Provider<PurchaseInvoiceDatasource>(
      (ref) => PurchaseInvoiceDatasource(Supabase.instance.client),
);

final purchaseInvoiceRepositoryProvider = Provider<PurchaseInvoiceRepository>(
      (ref) => PurchaseInvoiceRepository(
      ref.read(purchaseInvoiceDatasourceProvider)),
);

// ── Lookup: companies ─────────────────────────────────────────────────────
final purchaseCompaniesProvider = FutureProvider<List<StockLookupItem>>(
      (ref) => ref.read(purchaseInvoiceRepositoryProvider).getCompanies(),
);

// ── Warehouse stock cache ─────────────────────────────────────────────────
final warehouseStockCacheProvider = FutureProvider<List<WarehouseStockModel>>(
      (ref) => ref
      .read(purchaseInvoiceRepositoryProvider)
      .getWarehouseStock(kWarehouseId),
);

// ── Invoice list ──────────────────────────────────────────────────────────
class InvoiceListState {
  final List<PurchaseInvoiceModel> invoices;
  final bool isLoading;
  final String? error;

  const InvoiceListState({
    this.invoices = const [],
    this.isLoading = false,
    this.error,
  });

  InvoiceListState copyWith({
    List<PurchaseInvoiceModel>? invoices,
    bool? isLoading,
    String? error,
  }) =>
      InvoiceListState(
        invoices: invoices ?? this.invoices,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class InvoiceListNotifier extends StateNotifier<InvoiceListState> {
  final PurchaseInvoiceRepository _repo;
  InvoiceListNotifier(this._repo) : super(const InvoiceListState());

  Future<void> loadInvoices() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _repo.getInvoices(kWarehouseId);
      state = state.copyWith(invoices: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final invoiceListProvider =
StateNotifierProvider<InvoiceListNotifier, InvoiceListState>((ref) {
  return InvoiceListNotifier(ref.read(purchaseInvoiceRepositoryProvider));
});

// ── Cart / active invoice state ───────────────────────────────────────────
class PurchaseInvoiceState {
  final String invoiceNumber;
  final bool invoiceLoading;
  final StockLookupItem? selectedCompany;
  final List<PurchaseCartItem> cartItems;
  final bool isSaving;
  final String? error;

  const PurchaseInvoiceState({
    this.invoiceNumber = '',
    this.invoiceLoading = false,
    this.selectedCompany,
    this.cartItems = const [],
    this.isSaving = false,
    this.error,
  });

  double get totalAmount =>
      cartItems.fold(0, (sum, i) => sum + (i.salePrice * i.quantity));
  double get totalDiscount =>
      cartItems.fold(0, (sum, i) => sum + (i.discountAmount * i.quantity));
  double get netAmount => cartItems.fold(0, (sum, i) => sum + i.lineTotal);
  int get totalQuantity => cartItems.fold(0, (sum, i) => sum + i.quantity);

  PurchaseInvoiceState copyWith({
    String? invoiceNumber,
    bool? invoiceLoading,
    StockLookupItem? selectedCompany,
    bool clearCompany = false,
    List<PurchaseCartItem>? cartItems,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) =>
      PurchaseInvoiceState(
        invoiceNumber: invoiceNumber ?? this.invoiceNumber,
        invoiceLoading: invoiceLoading ?? this.invoiceLoading,
        selectedCompany:
        clearCompany ? null : selectedCompany ?? this.selectedCompany,
        cartItems: cartItems ?? this.cartItems,
        isSaving: isSaving ?? this.isSaving,
        error: clearError ? null : error ?? this.error,
      );
}

class PurchaseInvoiceNotifier extends StateNotifier<PurchaseInvoiceState> {
  final PurchaseInvoiceRepository _repo;

  PurchaseInvoiceNotifier(this._repo) : super(const PurchaseInvoiceState()) {
    _loadInvoiceNumber();
  }

  // ── Generate next number: MAX of all existing + 1 ────────────────────────
  static Future<String> _generateNextNumber() async {
    final client = Supabase.instance.client;
    final res = await client
        .from('purchase_invoices')
        .select('invoice_number')
        .like('invoice_number', 'Pur-%');

    int maxNumber = 0;
    for (final row in res as List) {
      final inv = row['invoice_number'] as String? ?? '';
      final dashIndex = inv.lastIndexOf('-');
      if (dashIndex != -1) {
        final n = int.tryParse(inv.substring(dashIndex + 1)) ?? 0;
        if (n > maxNumber) maxNumber = n;
      }
    }
    return 'Pur-${(maxNumber + 1).toString().padLeft(6, '0')}';
  }

  Future<void> _loadInvoiceNumber() async {
    if (!mounted) return;
    state = state.copyWith(invoiceLoading: true);
    try {
      final number = await _generateNextNumber();
      if (mounted) {
        state = state.copyWith(invoiceNumber: number, invoiceLoading: false);
      }
    } catch (_) {
      if (mounted) {
        state = state.copyWith(
            invoiceNumber: 'Pur-000001', invoiceLoading: false);
      }
    }
  }

  void selectCompany(StockLookupItem? company) {
    if (company == null) {
      state = state.copyWith(clearCompany: true);
    } else {
      state = state.copyWith(selectedCompany: company);
    }
  }

  void addCartItem(WarehouseStockModel stock, {int quantity = 1}) {
    final existing =
    state.cartItems.indexWhere((c) => c.stockId == stock.id);
    if (existing != -1) {
      final updated = List<PurchaseCartItem>.from(state.cartItems);
      updated[existing] = updated[existing]
          .copyWith(quantity: updated[existing].quantity + quantity);
      state = state.copyWith(cartItems: updated);
      return;
    }

    final item = PurchaseCartItem(
      stockId: stock.id,
      barcode: stock.barcode,
      productId: stock.productId,
      productName: stock.productName ?? '',
      sizeId: stock.sizeId,
      sizeName: stock.sizeName ?? '',
      colorId: stock.colorId,
      colorName: stock.colorName ?? '',
      brandId: stock.brandId,
      brandName: stock.brandName ?? '',
      categoryId: stock.categoryId,
      categoryName: stock.categoryName ?? '',
      typeId: stock.typeId,
      typeName: stock.typeName ?? '',
      totalStock: stock.quantity,
      quantity: quantity,
      salePrice: stock.salePrice,
      purchasePrice: stock.purchasePrice,
      discountPct: stock.discountPct,
    );

    state = state.copyWith(
      cartItems: [...state.cartItems, item],
      clearError: true,
    );
  }

  void updateItemQuantity(String stockId, int quantity) {
    if (quantity <= 0) {
      removeItem(stockId);
      return;
    }
    final updated = state.cartItems
        .map((i) => i.stockId == stockId ? i.copyWith(quantity: quantity) : i)
        .toList();
    state = state.copyWith(cartItems: updated);
  }

  void updateItemDiscount(String stockId, double discountPct) {
    final updated = state.cartItems
        .map((i) =>
    i.stockId == stockId ? i.copyWith(discountPct: discountPct) : i)
        .toList();
    state = state.copyWith(cartItems: updated);
  }

  void updateItemSalePrice(String stockId, double price) {
    final updated = state.cartItems
        .map((i) =>
    i.stockId == stockId ? i.copyWith(salePrice: price) : i)
        .toList();
    state = state.copyWith(cartItems: updated);
  }

  void updateItemPurchasePrice(String stockId, double price) {
    final updated = state.cartItems
        .map((i) =>
    i.stockId == stockId ? i.copyWith(purchasePrice: price) : i)
        .toList();
    state = state.copyWith(cartItems: updated);
  }

  void removeItem(String stockId) {
    state = state.copyWith(
      cartItems: state.cartItems.where((c) => c.stockId != stockId).toList(),
    );
  }

  void clearCart() {
    state = state.copyWith(cartItems: []);
  }

  /// Save invoice: generate a FRESH number at save time to avoid duplicates,
  /// then retry once if still duplicate (race condition safety net).
  Future<String?> saveInvoice() async {
    if (state.cartItems.isEmpty) return 'Cart is empty';
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      // Generate fresh number RIGHT before inserting
      final freshNumber = await _generateNextNumber();

      await _repo.savePurchaseInvoice(
        invoiceNumber: freshNumber,
        warehouseId: kWarehouseId,
        companyId: state.selectedCompany?.id,
        totalAmount: state.totalAmount,
        totalDiscount: state.totalDiscount,
        netAmount: state.netAmount,
        cartItems: state.cartItems,
      );

      // Update displayed number to match what was actually saved
      if (mounted) {
        state = state.copyWith(isSaving: false, invoiceNumber: freshNumber);
      }
      return null;
    } catch (e) {
      final errMsg = e.toString();

      // If duplicate key → retry once with a new number
      if (errMsg.contains('duplicate') || errMsg.contains('23505')) {
        try {
          await Future.delayed(const Duration(milliseconds: 50));
          final retryNumber = await _generateNextNumber();

          await _repo.savePurchaseInvoice(
            invoiceNumber: retryNumber,
            warehouseId: kWarehouseId,
            companyId: state.selectedCompany?.id,
            totalAmount: state.totalAmount,
            totalDiscount: state.totalDiscount,
            netAmount: state.netAmount,
            cartItems: state.cartItems,
          );

          if (mounted) {
            state = state.copyWith(isSaving: false, invoiceNumber: retryNumber);
          }
          return null;
        } catch (e2) {
          if (mounted) {
            state = state.copyWith(isSaving: false, error: e2.toString());
          }
          return e2.toString();
        }
      }

      if (mounted) {
        state = state.copyWith(isSaving: false, error: errMsg);
      }
      return errMsg;
    }
  }

  Future<void> resetInvoice() async {
    if (!mounted) return;
    state = const PurchaseInvoiceState(invoiceLoading: true);
    await _loadInvoiceNumber();
  }
}

final purchaseInvoiceProvider =
StateNotifierProvider<PurchaseInvoiceNotifier, PurchaseInvoiceState>(
        (ref) {
      return PurchaseInvoiceNotifier(
          ref.read(purchaseInvoiceRepositoryProvider));
    });