import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/purchase_invoice_datasource.dart';
import '../../data/models/purchase_invoice_model.dart';
import '../../data/models/purchase_return_model.dart';
import '../../data/models/warehouse_stock_model.dart';
import '../../data/repositories/purchase_invoice_repository.dart';
import '../../../shared/current_head_office_provider.dart';

// ── Infrastructure ────────────────────────────────────────────────────────
final purchaseInvoiceDatasourceProvider = Provider<PurchaseInvoiceDatasource>(
  (ref) => PurchaseInvoiceDatasource(Supabase.instance.client),
);

final purchaseInvoiceRepositoryProvider = Provider<PurchaseInvoiceRepository>(
  (ref) => PurchaseInvoiceRepository(ref.read(purchaseInvoiceDatasourceProvider)),
);

// ── Lookup: companies ─────────────────────────────────────────────────────
final purchaseCompaniesProvider = FutureProvider<List<StockLookupItem>>(
  (ref) => ref.read(purchaseInvoiceRepositoryProvider).getCompanies(),
);

// ── Cash Counter ─────────────────────────────────────────────────────────
final purchaseCashCounterProvider =
    StateNotifierProvider<PurchaseCashCounterNotifier, WarehouseCashCounter?>(
  (ref) => PurchaseCashCounterNotifier(
    ref.read(purchaseInvoiceRepositoryProvider),
  ),
);

class PurchaseCashCounterNotifier
    extends StateNotifier<WarehouseCashCounter?> {
  final PurchaseInvoiceRepository _repo;

  PurchaseCashCounterNotifier(this._repo) : super(null) {
    load();
  }

  Future<void> load() async {
    final counter = await _repo.getOrCreateCounter();
    if (mounted) state = counter;
  }
}

// ── Company balance ───────────────────────────────────────────────────────
final companyBalanceProvider = StateNotifierProvider.family<
    CompanyBalanceNotifier, CompanyWithBalance?, String>(
  (ref, companyId) => CompanyBalanceNotifier(
      ref.read(purchaseInvoiceRepositoryProvider), companyId),
);

class CompanyBalanceNotifier extends StateNotifier<CompanyWithBalance?> {
  final PurchaseInvoiceRepository _repo;
  final String companyId;

  CompanyBalanceNotifier(this._repo, this.companyId) : super(null) {
    load();
  }

  Future<void> load() async {
    final company = await _repo.getCompanyWithBalance(companyId);
    if (mounted) state = company;
  }
}

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
  final String _headOfficeId;

  InvoiceListNotifier(this._repo, this._headOfficeId)
      : super(const InvoiceListState());

  Future<void> loadInvoices() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _repo.getInvoices(_headOfficeId);
      state = state.copyWith(invoices: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final invoiceListProvider =
    StateNotifierProvider<InvoiceListNotifier, InvoiceListState>((ref) {
  return InvoiceListNotifier(
    ref.read(purchaseInvoiceRepositoryProvider),
    ref.watch(currentHeadOfficeIdProvider),
  );
});

// ── Head office stock cache ──────────────────────────────────────────────
final warehouseStockCacheProvider = FutureProvider<List<WarehouseStockModel>>(
  (ref) => ref.read(purchaseInvoiceRepositoryProvider).getWarehouseStock(),
);

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
      cartItems.fold(0, (sum, i) => sum + (i.purchasePrice * i.quantity));
  double get totalDiscount =>
      cartItems.fold(0, (sum, i) => sum + (i.purchaseDiscountAmount * i.quantity));
  double get netAmount => cartItems.fold(0, (sum, i) => sum + i.purchaseLineTotal);
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
  final String _headOfficeId;

  PurchaseInvoiceNotifier(this._repo, this._headOfficeId)
      : super(const PurchaseInvoiceState()) {
    _loadInvoiceNumber();
  }

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
      // Purchase invoice mein discount concept use nahi hota — sirf
      // purchase price par based totals.
      discountPct: 0,
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


  void removeItem(String stockId) {
    state = state.copyWith(
      cartItems: state.cartItems.where((c) => c.stockId != stockId).toList(),
    );
  }

  void clearCart() {
    state = state.copyWith(cartItems: []);
  }

  Future<String?> saveInvoice({
    required double paidAmount,
    required double creditAmount,
    required String paymentMode,
    required PurchaseInvoiceRepository repo,
  }) async {
    if (state.cartItems.isEmpty) return 'Cart is empty';
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final freshNumber = await _generateNextNumber();

      await repo.savePurchaseInvoice(
        invoiceNumber: freshNumber,
        headOfficeId: _headOfficeId,
        companyId: state.selectedCompany?.id,
        totalAmount: state.totalAmount,
        totalDiscount: state.totalDiscount,
        netAmount: state.netAmount,
        paidAmount: paidAmount,
        creditAmount: creditAmount,
        paymentMode: paymentMode,
        cartItems: state.cartItems,
      );

      if (mounted) {
        state = state.copyWith(isSaving: false, invoiceNumber: freshNumber);
      }
      return null;
    } catch (e) {
      final errMsg = e.toString();

      if (errMsg.contains('duplicate') || errMsg.contains('23505')) {
        try {
          await Future.delayed(const Duration(milliseconds: 50));
          final retryNumber = await _generateNextNumber();

          await repo.savePurchaseInvoice(
            invoiceNumber: retryNumber,
            headOfficeId: _headOfficeId,
            companyId: state.selectedCompany?.id,
            totalAmount: state.totalAmount,
            totalDiscount: state.totalDiscount,
            netAmount: state.netAmount,
            paidAmount: paidAmount,
            creditAmount: creditAmount,
            paymentMode: paymentMode,
            cartItems: state.cartItems,
          );

          if (mounted) {
            state =
                state.copyWith(isSaving: false, invoiceNumber: retryNumber);
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
  (ref) => PurchaseInvoiceNotifier(
    ref.read(purchaseInvoiceRepositoryProvider),
    ref.watch(currentHeadOfficeIdProvider),
  ),
);
