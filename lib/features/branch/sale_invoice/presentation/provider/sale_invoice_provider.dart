import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../superadmin/branch/presentation/providers/branch_provider.dart';
import '../../../shared/current_branch_provider.dart';
import '../../../branch_stock_inventory/data/datasource/branch_stock_datasource.dart';
import '../../../branch_stock_inventory/data/model/branch_stock_model.dart';
import '../../../branch_stock_inventory/data/repository/branch_stock_repository.dart';
import '../../../customer/data/model/customer_model.dart';
import '../../../customer/presentation/providers/customer_provider.dart';
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

final customersForSaleProvider = FutureProvider<List<CustomerModel>>(
  (ref) => ref
      .read(customerRepositoryProvider)
      .getCustomersByBranch(ref.watch(currentBranchIdProvider)),
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

/// Superadmin ki "Invoice Discount Access" screen se decide hota hai —
/// false hone par Sale Invoice screen par discount field dikhta hi nahi.
final currentBranchAllowsInvoiceDiscountProvider = FutureProvider<bool>((ref) async {
  final branchId = ref.watch(currentBranchIdProvider);
  if (branchId.isEmpty) return false;
  final branch = await ref.read(branchRepositoryProvider).getBranchById(branchId);
  return branch.canApplyInvoiceDiscount;
});

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
  final String paymentType; // cash | card | cash_card
  final double cashAmount; // only used when paymentType == 'cash_card'
  final CustomerModel? customer;
  final EmployeeLookupItem? salesman;
  final BankEntryLookupItem? bankEntry;
  final PrinterLookupItem? printer;
  final String note;
  final List<SaleCartItem> cartItems;
  final double invoiceDiscount;
  final bool isSaving;
  final String? error;
  final SaleInvoiceModel? lastSavedInvoice;

  const SaleInvoiceState({
    this.invoiceNumber = '',
    this.invoiceLoading = false,
    this.paymentType = 'cash',
    this.cashAmount = 0,
    this.customer,
    this.salesman,
    this.bankEntry,
    this.printer,
    this.note = '',
    this.cartItems = const [],
    this.invoiceDiscount = 0,
    this.isSaving = false,
    this.error,
    this.lastSavedInvoice,
  });

  /// 'cash_card' ke liye card portion = total - cash (0 se kam nahi ho sakta).
  double get cardAmount => (totalAmount - cashAmount).clamp(0, double.infinity);

  double get subtotal =>
      cartItems.fold(0, (sum, i) => sum + (i.salePrice * i.quantity));
  double get totalDiscount =>
      cartItems.fold(0, (sum, i) => sum + (i.discountAmount * i.quantity));
  /// Items ka net total, invoice-wise extra discount lagne se pehle.
  double get itemsTotal => cartItems.fold(0, (sum, i) => sum + i.lineTotal);
  double get totalAmount => (itemsTotal - invoiceDiscount).clamp(0, double.infinity);
  int get totalQuantity => cartItems.fold(0, (sum, i) => sum + i.quantity);

  SaleInvoiceState copyWith({
    String? invoiceNumber,
    bool? invoiceLoading,
    String? paymentType,
    double? cashAmount,
    CustomerModel? customer,
    bool clearCustomer = false,
    EmployeeLookupItem? salesman,
    bool clearSalesman = false,
    BankEntryLookupItem? bankEntry,
    bool clearBankEntry = false,
    PrinterLookupItem? printer,
    bool clearPrinter = false,
    String? note,
    List<SaleCartItem>? cartItems,
    double? invoiceDiscount,
    bool? isSaving,
    String? error,
    bool clearError = false,
    SaleInvoiceModel? lastSavedInvoice,
  }) =>
      SaleInvoiceState(
        invoiceNumber: invoiceNumber ?? this.invoiceNumber,
        invoiceLoading: invoiceLoading ?? this.invoiceLoading,
        paymentType: paymentType ?? this.paymentType,
        cashAmount: cashAmount ?? this.cashAmount,
        customer: clearCustomer ? null : customer ?? this.customer,
        salesman: clearSalesman ? null : salesman ?? this.salesman,
        bankEntry: clearBankEntry ? null : bankEntry ?? this.bankEntry,
        printer: clearPrinter ? null : printer ?? this.printer,
        note: note ?? this.note,
        cartItems: cartItems ?? this.cartItems,
        invoiceDiscount: invoiceDiscount ?? this.invoiceDiscount,
        isSaving: isSaving ?? this.isSaving,
        error: clearError ? null : error ?? this.error,
        lastSavedInvoice: lastSavedInvoice ?? this.lastSavedInvoice,
      );
}

class SaleInvoiceNotifier extends StateNotifier<SaleInvoiceState> {
  final Ref _ref;
  final SaleInvoiceRepository _repo;
  final String _branchId;

  SaleInvoiceNotifier(this._ref, this._repo, this._branchId)
      : super(const SaleInvoiceState()) {
    _loadInvoiceNumber();
    _loadDefaultCustomer();
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

  /// Har naye invoice pe by default "Walk-in Customer" (branches ke darmiyan
  /// shared record) select kar deta hai — cashier chahe to dropdown se kisi
  /// aur customer par badal sakta hai.
  Future<void> _loadDefaultCustomer() async {
    try {
      final customers = await _ref.read(customersForSaleProvider.future);
      if (!mounted || state.customer != null) return;
      final walkIn = customers.where((c) => c.isWalkIn);
      if (walkIn.isNotEmpty) {
        state = state.copyWith(customer: walkIn.first);
      }
    } catch (_) {
      // Customer dropdown apna error khud dikha dega — default select
      // fail hone par bhi cashier manually customer chun sakta hai.
    }
  }

  void selectPaymentType(String type) => state = state.copyWith(
        paymentType: type,
        cashAmount: type == 'cash_card' ? state.cashAmount : 0,
      );

  void setCashAmount(double amount) => state = state.copyWith(cashAmount: amount);

  void selectCustomer(CustomerModel? customer) {
    if (customer == null) {
      state = state.copyWith(clearCustomer: true);
    } else {
      state = state.copyWith(customer: customer);
    }
  }

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

  void clearCart() => state = state.copyWith(cartItems: [], invoiceDiscount: 0);

  /// 0..itemsTotal tak clamp — branch ki permission check UI (footer field
  /// ki visibility) mein hoti hai, yahan sirf value sanity clamp hai.
  void setInvoiceDiscount(double amount) {
    final capped = amount.clamp(0, state.itemsTotal);
    state = state.copyWith(invoiceDiscount: capped.toDouble());
  }

  /// Current state se payment legs banata hai — cash/card ek row, cash_card do rows.
  List<PaymentInput> _buildPayments() {
    switch (state.paymentType) {
      case 'card':
        return [PaymentInput(type: 'card', amount: state.totalAmount, bankEntryId: state.bankEntry?.id)];
      case 'cash_card':
        return [
          PaymentInput(type: 'cash', amount: state.cashAmount),
          PaymentInput(type: 'card', amount: state.cardAmount, bankEntryId: state.bankEntry?.id),
        ];
      default:
        return [PaymentInput(type: 'cash', amount: state.totalAmount)];
    }
  }

  Future<String?> saveInvoice() async {
    if (state.cartItems.isEmpty) return 'Cart is empty';
    if (state.customer == null) return 'Select a customer';
    if (state.salesman == null) return 'Select a salesman';
    if (state.printer == null) return 'Select a printer';
    if (state.paymentType == 'card' && state.bankEntry == null) {
      return 'Select a bank account for card sale';
    }
    if (state.paymentType == 'cash_card') {
      if (state.bankEntry == null) return 'Select a bank account for the card portion';
      if (state.cashAmount <= 0 || state.cashAmount >= state.totalAmount) {
        return 'Enter a cash amount between 0 and the net amount';
      }
    }
    for (final item in state.cartItems) {
      if (item.availableStock > 0 && item.quantity > item.availableStock) {
        return '${item.productName} — only ${item.availableStock} in stock';
      }
    }
    if (state.invoiceDiscount > state.itemsTotal) {
      return 'Discount cannot exceed the items total';
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
          customerId: state.customer!.id,
          salesmanId: state.salesman?.id,
          managerId: manager?.id,
          subtotal: state.subtotal,
          totalDiscount: state.totalDiscount,
          invoiceDiscount: state.invoiceDiscount,
          totalAmount: state.totalAmount,
          salesmanCommissionPercent: salesmanCommissionPercent,
          salesmanCommissionAmount: salesmanCommissionAmount,
          managerCommissionPercent: managerCommissionPercent,
          managerCommissionAmount: managerCommissionAmount,
          note: state.note.trim().isEmpty ? null : state.note.trim(),
          cartItems: state.cartItems,
          payments: _buildPayments(),
        );

    try {
      final saved = await attemptSave(state.invoiceNumber);
      if (mounted) {
        state = state.copyWith(isSaving: false, lastSavedInvoice: _withReceiptDetails(saved));
      }
      return null;
    } catch (e) {
      final errMsg = e.toString();
      if (errMsg.contains('duplicate') || errMsg.contains('23505')) {
        try {
          final retryNumber = await _repo.generateInvoiceNumber();
          final saved = await attemptSave(retryNumber);
          if (mounted) {
            state = state.copyWith(
              isSaving: false,
              invoiceNumber: retryNumber,
              lastSavedInvoice: _withReceiptDetails(saved),
            );
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

  /// [saved] header ko (items ke bagair) cart items + payment se enrich
  /// karta hai — print receipt ke liye extra DB round-trip nahi chahiye.
  SaleInvoiceModel _withReceiptDetails(SaleInvoiceModel saved) {
    final items = state.cartItems
        .map((c) => SaleInvoiceItemModel(
              id: '',
              saleInvoiceId: saved.id,
              branchStockId: c.branchStockId,
              productId: c.productId,
              sizeId: c.sizeId,
              colorId: c.colorId,
              brandId: c.brandId,
              categoryId: c.categoryId,
              typeId: c.typeId,
              barcode: c.barcode,
              quantity: c.quantity,
              salePrice: c.salePrice,
              purchasePrice: c.purchasePrice,
              discountPct: c.discountPct,
              discount: c.discountAmount * c.quantity,
              totalPrice: c.lineTotal,
              productName: c.productName,
              sizeName: c.sizeName,
              colorName: c.colorName,
              brandName: c.brandName,
              categoryName: c.categoryName,
              typeName: c.typeName,
            ))
        .toList();

    final payments = _buildPayments()
        .map((p) => SaleInvoicePaymentModel(
              id: '',
              saleInvoiceId: saved.id,
              branchId: _branchId,
              bankEntryId: p.bankEntryId,
              paymentType: p.type,
              amount: p.amount,
              createdAt: saved.createdAt,
            ))
        .toList();

    return SaleInvoiceModel(
      id: saved.id,
      invoiceNumber: saved.invoiceNumber,
      branchId: saved.branchId,
      printerId: saved.printerId,
      cashierId: saved.cashierId,
      customerId: saved.customerId,
      customerName: state.customer?.name,
      salesmanId: saved.salesmanId,
      salesmanName: state.salesman?.name,
      managerId: saved.managerId,
      managerName: saved.managerName,
      subtotal: saved.subtotal,
      totalDiscount: saved.totalDiscount,
      invoiceDiscount: saved.invoiceDiscount,
      totalAmount: saved.totalAmount,
      salesmanCommissionPercent: saved.salesmanCommissionPercent,
      salesmanCommissionAmount: saved.salesmanCommissionAmount,
      managerCommissionPercent: saved.managerCommissionPercent,
      managerCommissionAmount: saved.managerCommissionAmount,
      note: saved.note,
      createdAt: saved.createdAt,
      items: items,
      payments: payments,
    );
  }

  Future<void> resetInvoice() async {
    if (!mounted) return;
    state = const SaleInvoiceState(invoiceLoading: true);
    await _loadInvoiceNumber();
    await _loadDefaultCustomer();
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
