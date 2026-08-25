import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/current_branch_provider.dart';
import '../../../branch_stock_inventory/data/model/branch_stock_model.dart';
import '../../../sale_invoice/data/model/sale_invoice_model.dart';
import '../../../sale_invoice/presentation/provider/sale_invoice_provider.dart'
    show salesmenProvider, saleInvoiceRepositoryProvider;
import '../../data/datasource/sale_exchange_datasource.dart';
import '../../data/model/sale_exchange_model.dart';
import '../../data/repository/sale_exchange_repository.dart';

// ── Infrastructure ────────────────────────────────────────────────────────

final saleExchangeDatasourceProvider = Provider<SaleExchangeDatasource>(
  (ref) => SaleExchangeDatasource(Supabase.instance.client),
);

final saleExchangeRepositoryProvider = Provider<SaleExchangeRepository>(
  (ref) => SaleExchangeRepository(ref.read(saleExchangeDatasourceProvider)),
);

// ── State ─────────────────────────────────────────────────────────────────

class SaleExchangeState {
  final String exchangeNumber;
  final bool numberLoading;
  final SaleInvoiceModel? originalInvoice;
  final bool originalInvoiceLoading;
  final List<ReturnCartItem> returnCartItems;
  final List<SaleCartItem> newCartItems;
  final EmployeeLookupItem? salesman;
  final PrinterLookupItem? printer;
  final BankEntryLookupItem? bankEntry;
  final String paymentType; // cash | card | cash_card
  final double cashAmount; // only used when paymentType == 'cash_card'
  final String note;
  final bool isSaving;
  final String? error;
  final SaleExchangeModel? lastSavedExchange;

  const SaleExchangeState({
    this.exchangeNumber = '',
    this.numberLoading = false,
    this.originalInvoice,
    this.originalInvoiceLoading = false,
    this.returnCartItems = const [],
    this.newCartItems = const [],
    this.salesman,
    this.printer,
    this.bankEntry,
    this.paymentType = 'cash',
    this.cashAmount = 0,
    this.note = '',
    this.isSaving = false,
    this.error,
    this.lastSavedExchange,
  });

  double get returnSubtotal =>
      returnCartItems.where((i) => i.quantity > 0).fold(0, (s, i) => s + (i.salePrice * i.quantity));
  double get returnDiscount => returnCartItems
      .where((i) => i.quantity > 0)
      .fold(0, (s, i) => s + (i.discountAmount * i.quantity));
  double get returnTotal =>
      returnCartItems.where((i) => i.quantity > 0).fold(0, (s, i) => s + i.lineTotal);

  double get newSubtotal => newCartItems.fold(0, (s, i) => s + (i.salePrice * i.quantity));
  double get newDiscount =>
      newCartItems.fold(0, (s, i) => s + (i.discountAmount * i.quantity));
  double get newTotal => newCartItems.fold(0, (s, i) => s + i.lineTotal);

  double get differenceAmount => newTotal - returnTotal;
  bool get isCollect => differenceAmount > 0;
  bool get isRefund => differenceAmount < 0;
  double get absDifference => differenceAmount.abs();

  /// 'cash_card' ke liye card portion = |difference| - cash (0 se kam nahi).
  double get cardAmount => (absDifference - cashAmount).clamp(0, double.infinity);

  SaleExchangeState copyWith({
    String? exchangeNumber,
    bool? numberLoading,
    SaleInvoiceModel? originalInvoice,
    bool clearOriginalInvoice = false,
    bool? originalInvoiceLoading,
    List<ReturnCartItem>? returnCartItems,
    List<SaleCartItem>? newCartItems,
    EmployeeLookupItem? salesman,
    bool clearSalesman = false,
    PrinterLookupItem? printer,
    bool clearPrinter = false,
    BankEntryLookupItem? bankEntry,
    bool clearBankEntry = false,
    String? paymentType,
    double? cashAmount,
    String? note,
    bool? isSaving,
    String? error,
    bool clearError = false,
    SaleExchangeModel? lastSavedExchange,
  }) =>
      SaleExchangeState(
        exchangeNumber: exchangeNumber ?? this.exchangeNumber,
        numberLoading: numberLoading ?? this.numberLoading,
        originalInvoice: clearOriginalInvoice ? null : originalInvoice ?? this.originalInvoice,
        originalInvoiceLoading: originalInvoiceLoading ?? this.originalInvoiceLoading,
        returnCartItems: returnCartItems ?? this.returnCartItems,
        newCartItems: newCartItems ?? this.newCartItems,
        salesman: clearSalesman ? null : salesman ?? this.salesman,
        printer: clearPrinter ? null : printer ?? this.printer,
        bankEntry: clearBankEntry ? null : bankEntry ?? this.bankEntry,
        paymentType: paymentType ?? this.paymentType,
        cashAmount: cashAmount ?? this.cashAmount,
        note: note ?? this.note,
        isSaving: isSaving ?? this.isSaving,
        error: clearError ? null : error ?? this.error,
        lastSavedExchange: lastSavedExchange ?? this.lastSavedExchange,
      );
}

class SaleExchangeNotifier extends StateNotifier<SaleExchangeState> {
  final Ref _ref;
  final SaleExchangeRepository _repo;
  final String _branchId;

  SaleExchangeNotifier(this._ref, this._repo, this._branchId)
      : super(const SaleExchangeState()) {
    _loadExchangeNumber();
  }

  Future<void> _loadExchangeNumber() async {
    if (!mounted) return;
    state = state.copyWith(numberLoading: true);
    try {
      final number = await _repo.generateExchangeNumber();
      if (mounted) state = state.copyWith(exchangeNumber: number, numberLoading: false);
    } catch (_) {
      if (mounted) {
        state = state.copyWith(exchangeNumber: 'EXC-000001', numberLoading: false);
      }
    }
  }

  /// Invoice list se select hone par uski poori detail (items sahit) load
  /// karta hai aur return-side cart seed karta hai (sab quantity 0 se shuru,
  /// cashier explicitly line opt-in karega). Salesman bhi original invoice
  /// se default ho jata hai (commissionPercent ke liye salesmenProvider se
  /// resolve karna padta hai, kyunke invoice model sirf naam rakhta hai).
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

      EmployeeLookupItem? resolvedSalesman;
      if (detail.salesmanId != null) {
        try {
          final salesmen = await _ref.read(salesmenProvider.future);
          final matches = salesmen.where((s) => s.id == detail.salesmanId);
          resolvedSalesman = matches.isEmpty ? null : matches.first;
        } catch (_) {
          // salesmen list load na ho to bhi exchange continue ho sakta hai — cashier manually select karega
        }
      }

      if (!mounted) return;
      state = state.copyWith(
        originalInvoice: detail,
        originalInvoiceLoading: false,
        returnCartItems: returnItems,
        newCartItems: const [],
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

  void toggleReturnItem(String originalItemId, bool selected) {
    setReturnQuantity(originalItemId, selected ? 1 : 0);
  }

  void setReturnQuantity(String originalItemId, int quantity) {
    final updated = state.returnCartItems.map((i) {
      if (i.originalItemId != originalItemId) return i;
      final capped = quantity.clamp(0, i.maxQuantity);
      return i.copyWith(quantity: capped);
    }).toList();
    state = state.copyWith(returnCartItems: updated, clearError: true);
  }

  /// Requested quantity ko available stock tak clamp karta hai — bilkul
  /// SaleInvoiceNotifier.addCartItem jaisa.
  int addNewCartItem(BranchStockModel stock, {int quantity = 1}) {
    final existing =
        state.newCartItems.indexWhere((c) => c.branchStockId == stock.id);
    if (existing != -1) {
      final updated = List<SaleCartItem>.from(state.newCartItems);
      final current = updated[existing];
      final maxAllowed = current.availableStock;
      final newQty =
          (current.quantity + quantity).clamp(1, maxAllowed <= 0 ? current.quantity : maxAllowed);
      updated[existing] = current.copyWith(quantity: newQty);
      state = state.copyWith(newCartItems: updated, clearError: true);
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

    state = state.copyWith(newCartItems: [...state.newCartItems, item], clearError: true);
    return cappedQty;
  }

  void updateNewItemQuantity(String branchStockId, int quantity) {
    if (quantity <= 0) {
      removeNewItem(branchStockId);
      return;
    }
    final updated = state.newCartItems.map((i) {
      if (i.branchStockId != branchStockId) return i;
      final capped = i.availableStock > 0 ? quantity.clamp(1, i.availableStock) : quantity;
      return i.copyWith(quantity: capped);
    }).toList();
    state = state.copyWith(newCartItems: updated);
  }

  void removeNewItem(String branchStockId) {
    state = state.copyWith(
      newCartItems: state.newCartItems.where((c) => c.branchStockId != branchStockId).toList(),
    );
  }

  void selectSalesman(EmployeeLookupItem? emp) {
    if (emp == null) {
      state = state.copyWith(clearSalesman: true);
    } else {
      state = state.copyWith(salesman: emp);
    }
  }

  void selectPrinter(PrinterLookupItem? printer) {
    if (printer == null) {
      state = state.copyWith(clearPrinter: true);
    } else {
      state = state.copyWith(printer: printer);
    }
  }

  void selectBankEntry(BankEntryLookupItem? entry) {
    if (entry == null) {
      state = state.copyWith(clearBankEntry: true);
    } else {
      state = state.copyWith(bankEntry: entry);
    }
  }

  void selectPaymentType(String type) => state = state.copyWith(
        paymentType: type,
        cashAmount: type == 'cash_card' ? state.cashAmount : 0,
      );

  void setCashAmount(double amount) => state = state.copyWith(cashAmount: amount);

  void setNote(String note) => state = state.copyWith(note: note);

  /// difference == 0 par koi payment row nahi banti (even swap).
  List<ExchangePaymentInput> _buildPayments() {
    if (state.differenceAmount == 0) return [];
    final direction = state.isCollect ? 'collect' : 'refund';
    switch (state.paymentType) {
      case 'card':
        return [
          ExchangePaymentInput(
              direction: direction, type: 'card', amount: state.absDifference, bankEntryId: state.bankEntry?.id)
        ];
      case 'cash_card':
        return [
          ExchangePaymentInput(direction: direction, type: 'cash', amount: state.cashAmount),
          ExchangePaymentInput(
              direction: direction, type: 'card', amount: state.cardAmount, bankEntryId: state.bankEntry?.id),
        ];
      default:
        return [ExchangePaymentInput(direction: direction, type: 'cash', amount: state.absDifference)];
    }
  }

  Future<String?> saveExchange() async {
    if (state.originalInvoice == null) return 'Select an invoice to exchange from';
    if (!state.returnCartItems.any((i) => i.quantity > 0)) {
      return 'Select at least one item the customer is returning';
    }
    if (state.newCartItems.isEmpty) return 'Add at least one new item';
    if (state.salesman == null) return 'Select a salesman';
    if (state.printer == null) return 'Select a printer';
    if (state.differenceAmount != 0) {
      if (state.paymentType == 'card' && state.bankEntry == null) {
        return 'Select a bank account';
      }
      if (state.paymentType == 'cash_card') {
        if (state.bankEntry == null) return 'Select a bank account for the card portion';
        if (state.cashAmount <= 0 || state.cashAmount >= state.absDifference) {
          return 'Enter a cash amount between 0 and the difference amount';
        }
      }
    }
    for (final item in state.newCartItems) {
      if (item.availableStock > 0 && item.quantity > item.availableStock) {
        return '${item.productName} — only ${item.availableStock} in stock';
      }
    }

    state = state.copyWith(isSaving: true, clearError: true);

    final cashierId = _ref.read(authProvider).user?.id;
    final salesmanCommissionPercent = state.salesman?.commissionPercent ?? 0;
    final salesmanCommissionAmount = state.differenceAmount * salesmanCommissionPercent / 100;
    final returnItems = state.returnCartItems.where((i) => i.quantity > 0).toList();

    Future<SaleExchangeModel> attemptSave(String number) => _repo.saveExchange(
          exchangeNumber: number,
          branchId: _branchId,
          originalInvoiceId: state.originalInvoice!.id,
          printerId: state.printer?.id,
          cashierId: cashierId,
          customerId: state.originalInvoice!.customerId,
          salesmanId: state.salesman?.id,
          returnSubtotal: state.returnSubtotal,
          returnDiscount: state.returnDiscount,
          returnTotal: state.returnTotal,
          newSubtotal: state.newSubtotal,
          newDiscount: state.newDiscount,
          newTotal: state.newTotal,
          differenceAmount: state.differenceAmount,
          salesmanCommissionPercent: salesmanCommissionPercent,
          salesmanCommissionAmount: salesmanCommissionAmount,
          note: state.note.trim().isEmpty ? null : state.note.trim(),
          returnItems: returnItems,
          newItems: state.newCartItems,
          payments: _buildPayments(),
        );

    try {
      final saved = await attemptSave(state.exchangeNumber);
      if (mounted) state = state.copyWith(isSaving: false, lastSavedExchange: saved);
      return null;
    } catch (e) {
      final errMsg = e.toString();
      if (errMsg.contains('duplicate') || errMsg.contains('23505')) {
        try {
          final retryNumber = await _repo.generateExchangeNumber();
          final saved = await attemptSave(retryNumber);
          if (mounted) {
            state = state.copyWith(
              isSaving: false,
              exchangeNumber: retryNumber,
              lastSavedExchange: saved,
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

  Future<void> resetExchange() async {
    if (!mounted) return;
    state = const SaleExchangeState(numberLoading: true);
    await _loadExchangeNumber();
  }
}

final saleExchangeProvider =
    StateNotifierProvider<SaleExchangeNotifier, SaleExchangeState>(
  (ref) => SaleExchangeNotifier(
    ref,
    ref.read(saleExchangeRepositoryProvider),
    ref.watch(currentBranchIdProvider),
  ),
);
