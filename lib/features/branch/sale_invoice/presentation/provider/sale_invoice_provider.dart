import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/current_branch_provider.dart';
import '../../../branch_stock_inventory/data/datasource/branch_stock_datasource.dart';
import '../../../branch_stock_inventory/data/model/branch_stock_model.dart';
import '../../../branch_stock_inventory/data/repository/branch_stock_repository.dart';
import '../../data/datasource/sale_invoice_datasource.dart';
import '../../data/model/sale_invoice_model.dart';
import '../../data/repository/sale_invoice_repository.dart';

// ── Infrastructure ────────────────────────────────────────────────────────

final saleInvoiceDatasourceProvider = Provider<SaleInvoiceDatasource>(
  (ref) => SaleInvoiceDatasource(Supabase.instance.client),
);

final saleInvoiceRepositoryProvider = Provider<SaleInvoiceRepository>(
  (ref) => SaleInvoiceRepository(ref.read(saleInvoiceDatasourceProvider)),
);

final _branchStockRepoForSaleProvider = Provider<BranchStockRepository>(
  (ref) => BranchStockRepository(BranchStockDatasource(Supabase.instance.client)),
);

// ── Branch stock cache (product selector ke liye) ─────────────────────────
final branchStockCacheProvider = FutureProvider<List<BranchStockModel>>(
  (ref) => ref
      .read(_branchStockRepoForSaleProvider)
      .getBranchStock(ref.watch(currentBranchIdProvider)),
);

// ── Lookups ───────────────────────────────────────────────────────────────

final salesmenProvider = FutureProvider<List<EmployeeLookupItem>>(
  (ref) => ref
      .read(saleInvoiceRepositoryProvider)
      .getSalesmen(ref.watch(currentBranchIdProvider)),
);

final bankEntriesForSaleProvider = FutureProvider<List<BankEntryLookupItem>>(
  (ref) => ref
      .read(saleInvoiceRepositoryProvider)
      .getBankEntries(ref.watch(currentBranchIdProvider)),
);

final printersForSaleProvider = FutureProvider<List<PrinterLookupItem>>(
  (ref) => ref
      .read(saleInvoiceRepositoryProvider)
      .getPrinters(ref.watch(currentBranchIdProvider)),
);

// ── Invoice list ──────────────────────────────────────────────────────────

class SaleInvoiceListState {
  final List<SaleInvoiceModel> invoices;
  final bool isLoading;
  final String? error;

  const SaleInvoiceListState({
    this.invoices = const [],
    this.isLoading = false,
    this.error,
  });

  double get totalAmount => invoices.fold(0, (s, i) => s + i.totalAmount);

  SaleInvoiceListState copyWith({
    List<SaleInvoiceModel>? invoices,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      SaleInvoiceListState(
        invoices: invoices ?? this.invoices,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

class SaleInvoiceListNotifier extends StateNotifier<SaleInvoiceListState> {
  final SaleInvoiceRepository _repo;
  final String _branchId;

  SaleInvoiceListNotifier(this._repo, this._branchId)
      : super(const SaleInvoiceListState());

  Future<void> loadInvoices() async {
    if (_branchId.isEmpty) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repo.getInvoices(_branchId);
      state = state.copyWith(invoices: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final saleInvoiceListProvider =
    StateNotifierProvider<SaleInvoiceListNotifier, SaleInvoiceListState>(
  (ref) => SaleInvoiceListNotifier(
    ref.read(saleInvoiceRepositoryProvider),
    ref.watch(currentBranchIdProvider),
  ),
);

// ── Cart / active invoice state ───────────────────────────────────────────

class SaleInvoiceState {
  final String invoiceNumber;
  final bool invoiceLoading;
  final String paymentType; // cash | card
  final EmployeeLookupItem? salesman;
  final BankEntryLookupItem? bankEntry;
  final PrinterLookupItem? printer;
  final String note;
  final List<SaleCartItem> cartItems;
  final bool isSaving;
  final String? error;

  const SaleInvoiceState({
    this.invoiceNumber = '',
    this.invoiceLoading = false,
    this.paymentType = 'cash',
    this.salesman,
    this.bankEntry,
    this.printer,
    this.note = '',
    this.cartItems = const [],
    this.isSaving = false,
    this.error,
  });

  double get subtotal =>
      cartItems.fold(0, (sum, i) => sum + (i.salePrice * i.quantity));
  double get totalDiscount =>
      cartItems.fold(0, (sum, i) => sum + (i.discountAmount * i.quantity));
  double get totalAmount => cartItems.fold(0, (sum, i) => sum + i.lineTotal);
  int get totalQuantity => cartItems.fold(0, (sum, i) => sum + i.quantity);

  SaleInvoiceState copyWith({
    String? invoiceNumber,
    bool? invoiceLoading,
    String? paymentType,
    EmployeeLookupItem? salesman,
    bool clearSalesman = false,
    BankEntryLookupItem? bankEntry,
    bool clearBankEntry = false,
    PrinterLookupItem? printer,
    bool clearPrinter = false,
    String? note,
    List<SaleCartItem>? cartItems,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) =>
      SaleInvoiceState(
        invoiceNumber: invoiceNumber ?? this.invoiceNumber,
        invoiceLoading: invoiceLoading ?? this.invoiceLoading,
        paymentType: paymentType ?? this.paymentType,
        salesman: clearSalesman ? null : salesman ?? this.salesman,
        bankEntry: clearBankEntry ? null : bankEntry ?? this.bankEntry,
        printer: clearPrinter ? null : printer ?? this.printer,
        note: note ?? this.note,
        cartItems: cartItems ?? this.cartItems,
        isSaving: isSaving ?? this.isSaving,
        error: clearError ? null : error ?? this.error,
      );
}

class SaleInvoiceNotifier extends StateNotifier<SaleInvoiceState> {
  final Ref _ref;
  final SaleInvoiceRepository _repo;
  final String _branchId;

  SaleInvoiceNotifier(this._ref, this._repo, this._branchId)
      : super(const SaleInvoiceState()) {
    _loadInvoiceNumber();
  }

  Future<void> _loadInvoiceNumber() async {
    if (!mounted) return;
    state = state.copyWith(invoiceLoading: true);
    try {
      final number = await _repo.generateInvoiceNumber();
      if (mounted) {
        state = state.copyWith(invoiceNumber: number, invoiceLoading: false);
      }
    } catch (_) {
      if (mounted) {
        state = state.copyWith(invoiceNumber: 'SAL-000001', invoiceLoading: false);
      }
    }
  }

  void selectPaymentType(String type) => state = state.copyWith(paymentType: type);

  void selectSalesman(EmployeeLookupItem? emp) {
    if (emp == null) {
      state = state.copyWith(clearSalesman: true);
    } else {
      state = state.copyWith(salesman: emp);
    }
  }

  void selectBankEntry(BankEntryLookupItem? entry) {
    if (entry == null) {
      state = state.copyWith(clearBankEntry: true);
    } else {
      state = state.copyWith(bankEntry: entry);
    }
  }

  void selectPrinter(PrinterLookupItem? printer) {
    if (printer == null) {
      state = state.copyWith(clearPrinter: true);
    } else {
      state = state.copyWith(printer: printer);
    }
  }

  void setNote(String note) => state = state.copyWith(note: note);

  /// Requested quantity ko available stock (minus jo already cart mein hai)
  /// tak clamp karta hai — return value actual quantity jo add hui.
  int addCartItem(BranchStockModel stock, {int quantity = 1}) {
    final existing =
        state.cartItems.indexWhere((c) => c.branchStockId == stock.id);
    if (existing != -1) {
      final updated = List<SaleCartItem>.from(state.cartItems);
      final current = updated[existing];
      final maxAllowed = current.availableStock;
      final newQty = (current.quantity + quantity).clamp(1, maxAllowed <= 0 ? current.quantity : maxAllowed);
      updated[existing] = current.copyWith(quantity: newQty);
      state = state.copyWith(cartItems: updated, clearError: true);
      return newQty - current.quantity;
    }

    final cappedQty = stock.quantity <= 0 ? 0 : quantity.clamp(1, stock.quantity);
    if (cappedQty <= 0) return 0;

    final item = SaleCartItem(
      branchStockId: stock.id,
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
      availableStock: stock.quantity,
      quantity: cappedQty,
      salePrice: stock.salePrice,
      purchasePrice: stock.purchasePrice,
      discountPct: stock.discount,
    );

    state = state.copyWith(
      cartItems: [...state.cartItems, item],
      clearError: true,
    );
    return cappedQty;
  }

  void updateItemQuantity(String branchStockId, int quantity) {
    if (quantity <= 0) {
      removeItem(branchStockId);
      return;
    }
    final updated = state.cartItems.map((i) {
      if (i.branchStockId != branchStockId) return i;
      final capped = i.availableStock > 0
          ? quantity.clamp(1, i.availableStock)
          : quantity;
      return i.copyWith(quantity: capped);
    }).toList();
    state = state.copyWith(cartItems: updated);
  }

  void removeItem(String branchStockId) {
    state = state.copyWith(
      cartItems:
          state.cartItems.where((c) => c.branchStockId != branchStockId).toList(),
    );
  }

  void clearCart() => state = state.copyWith(cartItems: []);

  Future<String?> saveInvoice() async {
    if (state.cartItems.isEmpty) return 'Cart is empty';
    if (state.paymentType == 'card' && state.bankEntry == null) {
      return 'Select a bank account for card sale';
    }
    for (final item in state.cartItems) {
      if (item.availableStock > 0 && item.quantity > item.availableStock) {
        return '${item.productName} — only ${item.availableStock} in stock';
      }
    }

    state = state.copyWith(isSaving: true, clearError: true);

    final cashierId = _ref.read(authProvider).user?.id;
    final manager = await _repo.getBranchManager(_branchId);
    final managerCommissionPercent = manager?.commissionPercent ?? 0;
    final managerCommissionAmount = state.totalAmount * managerCommissionPercent / 100;
    final salesmanCommissionPercent = state.salesman?.commissionPercent ?? 0;
    final salesmanCommissionAmount = state.totalAmount * salesmanCommissionPercent / 100;

    Future<SaleInvoiceModel> attemptSave(String number) => _repo.saveSaleInvoice(
          invoiceNumber: number,
          branchId: _branchId,
          printerId: state.printer?.id,
          cashierId: cashierId,
          salesmanId: state.salesman?.id,
          managerId: manager?.id,
          subtotal: state.subtotal,
          totalDiscount: state.totalDiscount,
          totalAmount: state.totalAmount,
          salesmanCommissionPercent: salesmanCommissionPercent,
          salesmanCommissionAmount: salesmanCommissionAmount,
          managerCommissionPercent: managerCommissionPercent,
          managerCommissionAmount: managerCommissionAmount,
          note: state.note.trim().isEmpty ? null : state.note.trim(),
          cartItems: state.cartItems,
          paymentType: state.paymentType,
          bankEntryId: state.bankEntry?.id,
        );

    try {
      await attemptSave(state.invoiceNumber);
      if (mounted) state = state.copyWith(isSaving: false);
      return null;
    } catch (e) {
      final errMsg = e.toString();
      if (errMsg.contains('duplicate') || errMsg.contains('23505')) {
        try {
          final retryNumber = await _repo.generateInvoiceNumber();
          await attemptSave(retryNumber);
          if (mounted) {
            state = state.copyWith(isSaving: false, invoiceNumber: retryNumber);
          }
          return null;
        } catch (e2) {
          if (mounted) state = state.copyWith(isSaving: false, error: e2.toString());
          return e2.toString();
        }
      }
      if (mounted) state = state.copyWith(isSaving: false, error: errMsg);
      return errMsg;
    }
  }

  Future<void> resetInvoice() async {
    if (!mounted) return;
    state = const SaleInvoiceState(invoiceLoading: true);
    await _loadInvoiceNumber();
  }
}

final saleInvoiceProvider =
    StateNotifierProvider<SaleInvoiceNotifier, SaleInvoiceState>(
  (ref) => SaleInvoiceNotifier(
    ref,
    ref.read(saleInvoiceRepositoryProvider),
    ref.watch(currentBranchIdProvider),
  ),
);
