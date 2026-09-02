import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/purchase_return_datasource.dart';
import '../../data/models/purchase_return_model.dart';
import '../../data/models/warehouse_stock_model.dart';
import '../../data/repositories/purchase_return_repository.dart';

// ── Infrastructure ────────────────────────────────────────────────────────
final purchaseReturnDatasourceProvider = Provider<PurchaseReturnDatasource>(
  (ref) => PurchaseReturnDatasource(Supabase.instance.client),
);

final purchaseReturnRepositoryProvider = Provider<PurchaseReturnRepository>(
  (ref) =>
      PurchaseReturnRepository(ref.read(purchaseReturnDatasourceProvider)),
);

// ── Cash counter provider ─────────────────────────────────────────────────
final cashCounterProvider =
    StateNotifierProvider<CashCounterNotifier, WarehouseCashCounter?>(
  (ref) => CashCounterNotifier(ref.read(purchaseReturnRepositoryProvider)),
);

class CashCounterNotifier extends StateNotifier<WarehouseCashCounter?> {
  final PurchaseReturnRepository _repo;

  CashCounterNotifier(this._repo) : super(null) {
    load();
  }

  Future<void> load() async {
    final counter = await _repo.getOrCreateCounter();
    if (mounted) state = counter;
  }
}

// ── Return list state ─────────────────────────────────────────────────────
class ReturnListState {
  final List<PurchaseReturnModel> returns;
  final bool isLoading;
  final String? error;

  const ReturnListState({
    this.returns = const [],
    this.isLoading = false,
    this.error,
  });

  ReturnListState copyWith({
    List<PurchaseReturnModel>? returns,
    bool? isLoading,
    String? error,
  }) =>
      ReturnListState(
        returns: returns ?? this.returns,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class ReturnListNotifier extends StateNotifier<ReturnListState> {
  final PurchaseReturnRepository _repo;

  ReturnListNotifier(this._repo) : super(const ReturnListState());

  Future<void> loadReturns() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _repo.getReturns();
      state = state.copyWith(returns: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final returnListProvider =
    StateNotifierProvider<ReturnListNotifier, ReturnListState>((ref) {
  return ReturnListNotifier(ref.read(purchaseReturnRepositoryProvider));
});

// ── Lookup providers ──────────────────────────────────────────────────────
final returnCompaniesProvider = FutureProvider<List<StockLookupItem>>(
  (ref) => ref.read(purchaseReturnRepositoryProvider).getCompanies(),
);

final returnInvoiceNumbersProvider =
    FutureProvider<List<Map<String, String>>>(
  (ref) => ref.read(purchaseReturnRepositoryProvider).getInvoiceNumbers(),
);

final returnWarehouseStockProvider =
    FutureProvider<List<WarehouseStockModel>>(
  (ref) => ref.read(purchaseReturnRepositoryProvider).getWarehouseStock(),
);

// ── Active return / cart state ────────────────────────────────────────────
class PurchaseReturnState {
  final String returnNumber;
  final bool returnLoading;
  final StockLookupItem? selectedCompany;
  final String? selectedInvoiceId;
  final String? selectedInvoiceNumber;
  final List<ReturnCartItem> cartItems;
  final bool isSaving;
  final String? error;

  const PurchaseReturnState({
    this.returnNumber = '',
    this.returnLoading = false,
    this.selectedCompany,
    this.selectedInvoiceId,
    this.selectedInvoiceNumber,
    this.cartItems = const [],
    this.isSaving = false,
    this.error,
  });

  double get totalAmount =>
      cartItems.fold(0, (s, i) => s + (i.purchasePrice * i.quantity));
  double get totalDiscount =>
      cartItems.fold(0, (s, i) => s + (i.purchaseDiscountAmount * i.quantity));
  double get netAmount => cartItems.fold(0, (s, i) => s + i.purchaseLineTotal);
  int get totalQuantity => cartItems.fold(0, (s, i) => s + i.quantity);

  PurchaseReturnState copyWith({
    String? returnNumber,
    bool? returnLoading,
    StockLookupItem? selectedCompany,
    bool clearCompany = false,
    String? selectedInvoiceId,
    bool clearInvoice = false,
    String? selectedInvoiceNumber,
    List<ReturnCartItem>? cartItems,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) =>
      PurchaseReturnState(
        returnNumber: returnNumber ?? this.returnNumber,
        returnLoading: returnLoading ?? this.returnLoading,
        selectedCompany:
            clearCompany ? null : selectedCompany ?? this.selectedCompany,
        selectedInvoiceId:
            clearInvoice ? null : selectedInvoiceId ?? this.selectedInvoiceId,
        selectedInvoiceNumber: clearInvoice
            ? null
            : selectedInvoiceNumber ?? this.selectedInvoiceNumber,
        cartItems: cartItems ?? this.cartItems,
        isSaving: isSaving ?? this.isSaving,
        error: clearError ? null : error ?? this.error,
      );
}

class PurchaseReturnNotifier extends StateNotifier<PurchaseReturnState> {
  final PurchaseReturnRepository _repo;

  PurchaseReturnNotifier(this._repo)
      : super(const PurchaseReturnState()) {
    _loadReturnNumber();
  }

  Future<void> _loadReturnNumber() async {
    if (!mounted) return;
    state = state.copyWith(returnLoading: true);
    try {
      final number = await _repo.generateReturnNumber();
      if (mounted) {
        state = state.copyWith(returnNumber: number, returnLoading: false);
      }
    } catch (_) {
      if (mounted) {
        state = state.copyWith(returnNumber: 'PR-000001', returnLoading: false);
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

  void selectInvoice(String? invoiceId, String? invoiceNumber) {
    if (invoiceId == null) {
      state = state.copyWith(clearInvoice: true);
    } else {
      state = state.copyWith(
        selectedInvoiceId: invoiceId,
        selectedInvoiceNumber: invoiceNumber,
      );
    }
  }

  void addCartItem(WarehouseStockModel stock, {int quantity = 1}) {
    final existing =
        state.cartItems.indexWhere((c) => c.stockId == stock.id);
    if (existing != -1) {
      final updated = List<ReturnCartItem>.from(state.cartItems);
      updated[existing] = updated[existing]
          .copyWith(quantity: updated[existing].quantity + quantity);
      state = state.copyWith(cartItems: updated);
      return;
    }

    final item = ReturnCartItem(
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
        .map((i) => i.stockId == stockId ? i.copyWith(salePrice: price) : i)
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

  Future<String?> saveReturn() async {
    if (state.cartItems.isEmpty) return 'Cart is empty';
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final freshNumber = await _repo.generateReturnNumber();

      await _repo.savePurchaseReturn(
        returnNumber: freshNumber,
        companyId: state.selectedCompany?.id,
        originalInvoiceId: state.selectedInvoiceId,
        totalAmount: state.totalAmount,
        totalDiscount: state.totalDiscount,
        netAmount: state.netAmount,
        cartItems: state.cartItems,
      );

      if (mounted) {
        state = state.copyWith(isSaving: false, returnNumber: freshNumber);
      }
      return null;
    } catch (e) {
      final errMsg = e.toString();

      if (errMsg.contains('duplicate') || errMsg.contains('23505')) {
        try {
          await Future.delayed(const Duration(milliseconds: 50));
          final retryNumber = await _repo.generateReturnNumber();

          await _repo.savePurchaseReturn(
            returnNumber: retryNumber,
            companyId: state.selectedCompany?.id,
            originalInvoiceId: state.selectedInvoiceId,
            totalAmount: state.totalAmount,
            totalDiscount: state.totalDiscount,
            netAmount: state.netAmount,
            cartItems: state.cartItems,
          );

          if (mounted) {
            state = state.copyWith(isSaving: false, returnNumber: retryNumber);
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

  Future<void> resetReturn() async {
    if (!mounted) return;
    state = const PurchaseReturnState(returnLoading: true);
    await _loadReturnNumber();
  }
}

final purchaseReturnProvider =
    StateNotifierProvider<PurchaseReturnNotifier, PurchaseReturnState>((ref) {
  return PurchaseReturnNotifier(ref.read(purchaseReturnRepositoryProvider));
});
