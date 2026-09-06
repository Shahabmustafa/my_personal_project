import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/current_branch_provider.dart';
import '../../../branch_stock_inventory/data/model/branch_stock_model.dart';
import '../../../customer/data/model/customer_model.dart';
import '../../../sale_exchange/data/model/sale_exchange_model.dart' show ReturnCartItem;
import '../../../sale_invoice/data/model/sale_invoice_model.dart' show SaleInvoiceModel;
import '../../../sale_invoice/presentation/provider/sale_invoice_provider.dart'
    show customersForSaleProvider, salesmenProvider, saleInvoiceRepositoryProvider;
import '../../data/datasource/sale_return_datasource.dart';
import '../../data/model/sale_return_model.dart';
import '../../data/repository/sale_return_repository.dart';

// ── Infrastructure ────────────────────────────────────────────────────────

final saleReturnDatasourceProvider = Provider<SaleReturnDatasource>(
  (ref) => SaleReturnDatasource(Supabase.instance.client),
);

final saleReturnRepositoryProvider = Provider<SaleReturnRepository>(
  (ref) => SaleReturnRepository(ref.read(saleReturnDatasourceProvider)),
);

// ── Return list ───────────────────────────────────────────────────────────

class SaleReturnListState {
  final List<SaleReturnModel> returns;
  final bool isLoading;
  final String? error;

  const SaleReturnListState({
    this.returns = const [],
    this.isLoading = false,
    this.error,
  });

  double get totalAmount => returns.fold(0, (s, r) => s + r.totalAmount);

  SaleReturnListState copyWith({
    List<SaleReturnModel>? returns,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      SaleReturnListState(
        returns: returns ?? this.returns,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

class SaleReturnListNotifier extends StateNotifier<SaleReturnListState> {
  final SaleReturnRepository _repo;
  final String _branchId;

  SaleReturnListNotifier(this._repo, this._branchId)
      : super(const SaleReturnListState());

  Future<void> loadReturns() async {
    if (_branchId.isEmpty) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repo.getReturns(_branchId);
      state = state.copyWith(returns: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final saleReturnListProvider =
    StateNotifierProvider<SaleReturnListNotifier, SaleReturnListState>(
  (ref) => SaleReturnListNotifier(
    ref.read(saleReturnRepositoryProvider),
    ref.watch(currentBranchIdProvider),
  ),
);

// ── Cart / active return state ───────────────────────────────────────────

class SaleReturnState {
  final String returnNumber;
  final bool numberLoading;
  final String paymentType; // cash | card | cash_card
  final double cashAmount; // only used when paymentType == 'cash_card'
  final CustomerModel? customer;
  final EmployeeLookupItem? salesman;
  final BankEntryLookupItem? bankEntry;
  final PrinterLookupItem? printer;
  final String note;
  final List<SaleCartItem> cartItems;
  final SaleInvoiceModel? originalInvoice;
  final bool originalInvoiceLoading;
  final List<ReturnCartItem> invoiceReturnItems;
  final bool isSaving;
  final String? error;
  final SaleReturnModel? lastSavedReturn;

  const SaleReturnState({
    this.returnNumber = '',
    this.numberLoading = false,
    this.paymentType = 'cash',
    this.cashAmount = 0,
    this.customer,
    this.salesman,
    this.bankEntry,
    this.printer,
    this.note = '',
    this.cartItems = const [],
    this.originalInvoice,
    this.originalInvoiceLoading = false,
    this.invoiceReturnItems = const [],
    this.isSaving = false,
    this.error,
    this.lastSavedReturn,
  });

  /// Invoice se link hui return mein items `invoiceReturnItems` (checkbox se
  /// opt-in) se aate hain, warna free-form `cartItems` se (invoice ke bina
  /// wala purana flow).
  bool get isInvoiceLinked => originalInvoice != null;

  double get subtotal => isInvoiceLinked
      ? invoiceReturnItems.where((i) => i.quantity > 0).fold(0.0, (s, i) => s + (i.salePrice * i.quantity))
      : cartItems.fold(0, (sum, i) => sum + (i.salePrice * i.quantity));
  double get totalDiscount => isInvoiceLinked
      ? invoiceReturnItems.where((i) => i.quantity > 0).fold(0.0, (s, i) => s + (i.discountAmount * i.quantity))
      : cartItems.fold(0, (sum, i) => sum + (i.discountAmount * i.quantity));
  double get totalAmount => isInvoiceLinked
      ? invoiceReturnItems.where((i) => i.quantity > 0).fold(0.0, (s, i) => s + i.lineTotal)
      : cartItems.fold(0, (sum, i) => sum + i.lineTotal);
  int get totalQuantity => isInvoiceLinked
      ? invoiceReturnItems.fold(0, (s, i) => s + i.quantity)
      : cartItems.fold(0, (sum, i) => sum + i.quantity);

  /// 'cash_card' ke liye card portion = total - cash.
  double get cardAmount => (totalAmount - cashAmount).clamp(0, double.infinity);

  SaleReturnState copyWith({
    String? returnNumber,
    bool? numberLoading,
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
    SaleInvoiceModel? originalInvoice,
    bool clearOriginalInvoice = false,
    bool? originalInvoiceLoading,
    List<ReturnCartItem>? invoiceReturnItems,
    bool? isSaving,
    String? error,
    bool clearError = false,
    SaleReturnModel? lastSavedReturn,
  }) =>
      SaleReturnState(
        returnNumber: returnNumber ?? this.returnNumber,
        numberLoading: numberLoading ?? this.numberLoading,
        paymentType: paymentType ?? this.paymentType,
        cashAmount: cashAmount ?? this.cashAmount,
        customer: clearCustomer ? null : customer ?? this.customer,
        salesman: clearSalesman ? null : salesman ?? this.salesman,
        bankEntry: clearBankEntry ? null : bankEntry ?? this.bankEntry,
        printer: clearPrinter ? null : printer ?? this.printer,
        note: note ?? this.note,
        cartItems: cartItems ?? this.cartItems,
        originalInvoice: clearOriginalInvoice ? null : originalInvoice ?? this.originalInvoice,
        originalInvoiceLoading: originalInvoiceLoading ?? this.originalInvoiceLoading,
        invoiceReturnItems: invoiceReturnItems ?? this.invoiceReturnItems,
        isSaving: isSaving ?? this.isSaving,
        error: clearError ? null : error ?? this.error,
        lastSavedReturn: lastSavedReturn ?? this.lastSavedReturn,
      );
}

class SaleReturnNotifier extends StateNotifier<SaleReturnState> {
  final Ref _ref;
  final SaleReturnRepository _repo;
  final String _branchId;

  SaleReturnNotifier(this._ref, this._repo, this._branchId)
      : super(const SaleReturnState()) {
    _loadReturnNumber();
    _loadDefaultCustomer();
  }

  /// Har naye return pe by default "Walk-in Customer" (branches ke darmiyan
  /// shared record) select kar deta hai — screen mein abhi customer dropdown
  /// nahi hai, is default ke bina saveReturn() hamesha "Select a customer"
  /// error deta rehta.
  Future<void> _loadDefaultCustomer() async {
    try {
      final customers = await _ref.read(customersForSaleProvider.future);
      if (!mounted || state.customer != null) return;
      final walkIn = customers.where((c) => c.isWalkIn);
      if (walkIn.isNotEmpty) {
        state = state.copyWith(customer: walkIn.first);
      }
    } catch (_) {
      // Fail hone par bhi return flow chalta rahega; agar future mein
      // customer dropdown add hua to cashier manually chun sakega.
    }
  }

  Future<void> _loadReturnNumber() async {
    if (!mounted) return;
    state = state.copyWith(numberLoading: true);
    try {
      final number = await _repo.generateReturnNumber();
      if (mounted) {
        state = state.copyWith(returnNumber: number, numberLoading: false);
      }
    } catch (_) {
      if (mounted) {
        state = state.copyWith(returnNumber: 'RET-000001', numberLoading: false);
      }
    }
  }

  /// Invoice list se select hone par uski poori detail (items sahit) load
  /// karta hai aur return items ko us invoice ki lines se seed karta hai
  /// (sab quantity 0 se shuru — cashier explicitly line opt-in karega,
  /// bilkul SaleExchangeNotifier.selectOriginalInvoice jaisa). Customer aur
  /// salesman bhi original invoice se resolve ho jate hain.
  Future<void> selectOriginalInvoice(SaleInvoiceModel summary) async {
    if (!mounted) return;
    state = state.copyWith(originalInvoiceLoading: true, clearError: true);
    try {
      final detail =
          await _ref.read(saleInvoiceRepositoryProvider).getInvoiceDetail(summary.id);

      final returnItems = detail.items
          .map((i) => ReturnCartItem(
                originalItemId: i.id,
                branchStockId: i.branchStockId,
                barcode: i.barcode ?? '',
                productId: i.productId,
                productName: i.productName ?? '',
                sizeId: i.sizeId ?? '',
                sizeName: i.sizeName ?? '',
                colorId: i.colorId ?? '',
                colorName: i.colorName ?? '',
                brandId: i.brandId ?? '',
                brandName: i.brandName ?? '',
                categoryId: i.categoryId ?? '',
                categoryName: i.categoryName ?? '',
                typeId: i.typeId ?? '',
                typeName: i.typeName ?? '',
                maxQuantity: i.quantity,
                quantity: 0,
                salePrice: i.salePrice,
                purchasePrice: i.purchasePrice,
                discountPct: i.discountPct,
              ))
          .toList();

      CustomerModel? resolvedCustomer;
      if (detail.customerId != null) {
        try {
          final customers = await _ref.read(customersForSaleProvider.future);
          final matches = customers.where((c) => c.id == detail.customerId);
          resolvedCustomer = matches.isEmpty ? null : matches.first;
        } catch (_) {
          // customer list load na ho to bhi return continue ho sakta hai
        }
      }

      EmployeeLookupItem? resolvedSalesman;
      if (detail.salesmanId != null) {
        try {
          final salesmen = await _ref.read(salesmenProvider.future);
          final matches = salesmen.where((s) => s.id == detail.salesmanId);
          resolvedSalesman = matches.isEmpty ? null : matches.first;
        } catch (_) {
          // salesmen list load na ho to bhi return continue ho sakta hai
        }
      }

      if (!mounted) return;
      state = state.copyWith(
        originalInvoice: detail,
        originalInvoiceLoading: false,
        invoiceReturnItems: returnItems,
        cartItems: const [],
        customer: resolvedCustomer,
        clearCustomer: resolvedCustomer == null,
        salesman: resolvedSalesman,
        clearSalesman: resolvedSalesman == null,
      );
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          originalInvoiceLoading: false,
          error: e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  /// Dropdown se invoice selection clear karke wapas free-form (invoice ke
  /// bina) return mode par le jata hai.
  void clearOriginalInvoice() {
    state = state.copyWith(
      clearOriginalInvoice: true,
      invoiceReturnItems: const [],
      clearError: true,
    );
  }

  void toggleReturnItem(String originalItemId, bool selected) {
    setReturnQuantity(originalItemId, selected ? 1 : 0);
  }

  void setReturnQuantity(String originalItemId, int quantity) {
    final updated = state.invoiceReturnItems.map((i) {
      if (i.originalItemId != originalItemId) return i;
      final capped = quantity.clamp(0, i.maxQuantity);
      return i.copyWith(quantity: capped);
    }).toList();
    state = state.copyWith(invoiceReturnItems: updated, clearError: true);
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

  void selectSalesman(EmployeeLookupItem? salesman) {
    if (salesman == null) {
      state = state.copyWith(clearSalesman: true);
    } else {
      state = state.copyWith(salesman: salesman);
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

  /// Return ke liye stock limit nahi lagta — jitni bhi qty return karni ho
  /// utni add ho sakti hai (sale ka bilkul vice versa).
  void addCartItem(BranchStockModel stock, {int quantity = 1}) {
    final existing =
        state.cartItems.indexWhere((c) => c.branchStockId == stock.id);
    final qty = quantity > 0 ? quantity : 1;
    if (existing != -1) {
      final updated = List<SaleCartItem>.from(state.cartItems);
      final current = updated[existing];
      updated[existing] = current.copyWith(quantity: current.quantity + qty);
      state = state.copyWith(cartItems: updated, clearError: true);
      return;
    }

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
      availableStock: 0, // return: koi upper cap nahi
      quantity: qty,
      salePrice: stock.salePrice,
      purchasePrice: stock.purchasePrice,
      // Per-article branch stock discount is disabled — only the invoice-wise
      // Branch Invoice Discount is allowed now.
      discountPct: 0,
    );

    state = state.copyWith(
      cartItems: [...state.cartItems, item],
      clearError: true,
    );
  }

  void updateItemQuantity(String branchStockId, int quantity) {
    if (quantity <= 0) {
      removeItem(branchStockId);
      return;
    }
    final updated = state.cartItems
        .map((i) => i.branchStockId == branchStockId ? i.copyWith(quantity: quantity) : i)
        .toList();
    state = state.copyWith(cartItems: updated);
  }

  void removeItem(String branchStockId) {
    state = state.copyWith(
      cartItems:
          state.cartItems.where((c) => c.branchStockId != branchStockId).toList(),
    );
  }

  void clearCart() => state = state.copyWith(cartItems: []);

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

  /// Invoice-linked mode mein selected `ReturnCartItem`s ko `SaleCartItem`
  /// mein convert karta hai (datasource ka insert shape yahi expect karta
  /// hai) — free-form mode mein `state.cartItems` seedha use ho jata hai.
  List<SaleCartItem> _buildCartItemsPayload() {
    if (!state.isInvoiceLinked) return state.cartItems;
    return state.invoiceReturnItems.where((i) => i.quantity > 0).map((i) {
      return SaleCartItem(
        branchStockId: i.branchStockId,
        barcode: i.barcode,
        productId: i.productId,
        productName: i.productName,
        sizeId: i.sizeId,
        sizeName: i.sizeName,
        colorId: i.colorId,
        colorName: i.colorName,
        brandId: i.brandId,
        brandName: i.brandName,
        categoryId: i.categoryId,
        categoryName: i.categoryName,
        typeId: i.typeId,
        typeName: i.typeName,
        availableStock: 0,
        quantity: i.quantity,
        salePrice: i.salePrice,
        purchasePrice: i.purchasePrice,
        discountPct: i.discountPct,
      );
    }).toList();
  }

  Future<String?> saveReturn() async {
    if (state.isInvoiceLinked) {
      if (!state.invoiceReturnItems.any((i) => i.quantity > 0)) {
        return 'Select at least one item the customer is returning';
      }
    } else if (state.cartItems.isEmpty) {
      return 'Cart is empty';
    }
    if (state.customer == null) return 'Select a customer';
    if (state.salesman == null) return 'Select a salesman';
    if (state.printer == null) return 'Select a printer';
    if (state.paymentType == 'card' && state.bankEntry == null) {
      return 'Select a bank account for card refund';
    }
    if (state.paymentType == 'cash_card') {
      if (state.bankEntry == null) return 'Select a bank account for the card portion';
      if (state.cashAmount <= 0 || state.cashAmount >= state.totalAmount) {
        return 'Enter a cash amount between 0 and the net amount';
      }
    }

    state = state.copyWith(isSaving: true, clearError: true);

    final cashierId = _ref.read(authProvider).user?.id;
    final cartItemsPayload = _buildCartItemsPayload();

    Future<SaleReturnModel> attemptSave(String number) => _repo.saveSaleReturn(
          returnNumber: number,
          branchId: _branchId,
          originalInvoiceId: state.originalInvoice?.id,
          printerId: state.printer?.id,
          cashierId: cashierId,
          customerId: state.customer!.id,
          salesmanId: state.salesman?.id,
          subtotal: state.subtotal,
          totalDiscount: state.totalDiscount,
          totalAmount: state.totalAmount,
          note: state.note.trim().isEmpty ? null : state.note.trim(),
          cartItems: cartItemsPayload,
          payments: _buildPayments(),
        );

    try {
      final saved = await attemptSave(state.returnNumber);
      if (mounted) {
        state = state.copyWith(isSaving: false, lastSavedReturn: _withReceiptDetails(saved));
      }
      return null;
    } catch (e) {
      final errMsg = e.toString();
      if (errMsg.contains('duplicate') || errMsg.contains('23505')) {
        try {
          final retryNumber = await _repo.generateReturnNumber();
          final saved = await attemptSave(retryNumber);
          if (mounted) {
            state = state.copyWith(
              isSaving: false,
              returnNumber: retryNumber,
              lastSavedReturn: _withReceiptDetails(saved),
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

  SaleReturnModel _withReceiptDetails(SaleReturnModel saved) {
    final items = _buildCartItemsPayload()
        .map((c) => SaleReturnItemModel(
              id: '',
              saleReturnId: saved.id,
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
        .map((p) => SaleReturnPaymentModel(
              id: '',
              saleReturnId: saved.id,
              branchId: _branchId,
              bankEntryId: p.bankEntryId,
              paymentType: p.type,
              amount: p.amount,
              createdAt: saved.createdAt,
            ))
        .toList();

    return SaleReturnModel(
      id: saved.id,
      returnNumber: saved.returnNumber,
      branchId: saved.branchId,
      originalInvoiceId: state.originalInvoice?.id,
      originalInvoiceNumber: state.originalInvoice?.invoiceNumber,
      printerId: saved.printerId,
      cashierId: saved.cashierId,
      customerId: saved.customerId,
      customerName: state.customer?.name,
      salesmanId: saved.salesmanId,
      salesmanName: state.salesman?.name,
      subtotal: saved.subtotal,
      totalDiscount: saved.totalDiscount,
      totalAmount: saved.totalAmount,
      note: saved.note,
      createdAt: saved.createdAt,
      items: items,
      payments: payments,
    );
  }

  Future<void> resetReturn() async {
    if (!mounted) return;
    state = const SaleReturnState(numberLoading: true);
    await _loadReturnNumber();
    await _loadDefaultCustomer();
  }
}

final saleReturnProvider =
    StateNotifierProvider<SaleReturnNotifier, SaleReturnState>(
  (ref) => SaleReturnNotifier(
    ref,
    ref.read(saleReturnRepositoryProvider),
    ref.watch(currentBranchIdProvider),
  ),
);
