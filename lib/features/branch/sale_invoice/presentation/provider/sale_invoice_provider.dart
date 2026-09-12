import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../superadmin/branch/presentation/providers/branch_provider.dart';
import '../../../../superadmin/discount/data/model/sale_discount_tier_model.dart';
import '../../../../superadmin/discount/presentation/providers/sale_discount_tier_provider.dart';
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
  (ref) =>
      BranchStockRepository(BranchStockDatasource(Supabase.instance.client)),
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

/// Current branch ka (ek hi) manager — role='manager', employee_salary se.
/// Null = branch ko koi manager assign nahi → sale block ho jati hai.
final branchManagerProvider = FutureProvider<EmployeeLookupItem?>(
  (ref) => ref
      .read(saleInvoiceRepositoryProvider)
      .getBranchManager(ref.watch(currentBranchIdProvider)),
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

/// Superadmin ki "Discount → Branch Invoice Discount" screen se set hota hai —
/// is branch ka cashier sale invoice par max kitne % tak extra (invoice-wise)
/// discount laga sakta hai. 0 hone par discount field dikhta hi nahi.
final currentBranchMaxInvoiceDiscountPctProvider = FutureProvider<double>((
  ref,
) async {
  final branchId = ref.watch(currentBranchIdProvider);
  if (branchId.isEmpty) return 0;
  final branch = await ref
      .read(branchRepositoryProvider)
      .getBranchById(branchId);
  return branch.maxInvoiceDiscountPct;
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
  }) => SaleInvoiceListState(
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
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
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
  final EmployeeLookupItem? manager;
  final BankEntryLookupItem? bankEntry;
  final PrinterLookupItem? printer;
  final String note;
  final List<SaleCartItem> cartItems;

  /// Invoice-wise extra discount as a percentage of [itemsTotal]. Branch ke
  /// max % (superadmin set) tak clamp hota hai. Rupees amount [invoiceDiscount]
  /// getter se nikalta hai taaki cart badalne par apne aap recalculate ho.
  final double invoiceDiscountPct;

  /// Head office ki "Sale Discount Tiers" screen se — sab tiers, highest
  /// min_sale_amount pehle. Load hote hi ek dafa fetch ho jate hain.
  final List<SaleDiscountTierModel> discountTiers;
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
    this.manager,
    this.bankEntry,
    this.printer,
    this.note = '',
    this.cartItems = const [],
    this.invoiceDiscountPct = 0,
    this.discountTiers = const [],
    this.isSaving = false,
    this.error,
    this.lastSavedInvoice,
  });

  /// Invoice-wise extra discount, rupees mein — % of items total.
  double get invoiceDiscount => itemsTotal * invoiceDiscountPct / 100;

  /// Head office ki tier jo [itemsTotal] par qualify karti hai — sab se
  /// zyada min_sale_amount wali jeet ti hai (stacking nahi hoti).
  SaleDiscountTierModel? get matchedDiscountTier {
    final eligible = discountTiers.where((t) => itemsTotal >= t.minSaleAmount);
    if (eligible.isEmpty) return null;
    return eligible.reduce((a, b) => a.minSaleAmount >= b.minSaleAmount ? a : b);
  }

  /// Matched tier ka discount, rupees mein — cashier isko badal nahi sakta,
  /// items total qualify hote hi automatically lagta hai.
  double get autoDiscount => matchedDiscountTier?.discountFor(itemsTotal) ?? 0;

  /// 'cash_card' ke liye card portion = total - cash (0 se kam nahi ho sakta).
  double get cardAmount => (totalAmount - cashAmount).clamp(0, double.infinity);

  double get subtotal =>
      cartItems.fold(0, (sum, i) => sum + (i.salePrice * i.quantity));
  double get totalDiscount =>
      cartItems.fold(0, (sum, i) => sum + (i.discountAmount * i.quantity));

  /// Items ka net total, invoice-wise extra discount lagne se pehle.
  double get itemsTotal => cartItems.fold(0, (sum, i) => sum + i.lineTotal);
  double get totalAmount =>
      (itemsTotal - invoiceDiscount - autoDiscount).clamp(0, double.infinity);
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
    EmployeeLookupItem? manager,
    bool clearManager = false,
    BankEntryLookupItem? bankEntry,
    bool clearBankEntry = false,
    PrinterLookupItem? printer,
    bool clearPrinter = false,
    String? note,
    List<SaleCartItem>? cartItems,
    double? invoiceDiscountPct,
    List<SaleDiscountTierModel>? discountTiers,
    bool? isSaving,
    String? error,
    bool clearError = false,
    SaleInvoiceModel? lastSavedInvoice,
  }) => SaleInvoiceState(
    invoiceNumber: invoiceNumber ?? this.invoiceNumber,
    invoiceLoading: invoiceLoading ?? this.invoiceLoading,
    paymentType: paymentType ?? this.paymentType,
    cashAmount: cashAmount ?? this.cashAmount,
    customer: clearCustomer ? null : customer ?? this.customer,
    salesman: clearSalesman ? null : salesman ?? this.salesman,
    manager: clearManager ? null : manager ?? this.manager,
    bankEntry: clearBankEntry ? null : bankEntry ?? this.bankEntry,
    printer: clearPrinter ? null : printer ?? this.printer,
    note: note ?? this.note,
    cartItems: cartItems ?? this.cartItems,
    invoiceDiscountPct: invoiceDiscountPct ?? this.invoiceDiscountPct,
    discountTiers: discountTiers ?? this.discountTiers,
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
    _loadDefaultEmployees();
    _loadDiscountTiers();
  }

  /// Head office ki "Sale Discount Tiers" — ek dafa load karke rakh lete
  /// hain taake cart badalne par [SaleInvoiceState.autoDiscount] turant
  /// recalculate ho sake, koi extra network call ki zaroorat nahi.
  Future<void> _loadDiscountTiers() async {
    try {
      final tiers = await _ref.read(saleDiscountTiersProvider.future);
      if (mounted) state = state.copyWith(discountTiers: tiers);
    } catch (_) {
      // Tiers load na hon to bhi invoice normal (bina auto discount) ban sakti hai.
    }
  }

  /// Manager branch se auto-resolve hota hai (koi dropdown nahi — cashier
  /// khud manager select nahi karta). Manager na milne par state.manager
  /// null rehta hai → UI banner dikhata hai aur Save disable.
  Future<void> _loadDefaultEmployees() async {
    try {
      final manager = await _ref.read(branchManagerProvider.future);
      if (mounted) {
        state = state.copyWith(manager: manager, clearManager: manager == null);
      }
    } catch (_) {}
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
        state = state.copyWith(
          invoiceNumber: 'SAL-000001',
          invoiceLoading: false,
        );
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

  void setCashAmount(double amount) =>
      state = state.copyWith(cashAmount: amount);

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
    final existing = state.cartItems.indexWhere(
      (c) => c.branchStockId == stock.id,
    );
    if (existing != -1) {
      final updated = List<SaleCartItem>.from(state.cartItems);
      final current = updated[existing];
      final maxAllowed = current.availableStock;
      final newQty = (current.quantity + quantity).clamp(
        1,
        maxAllowed <= 0 ? current.quantity : maxAllowed,
      );
      updated[existing] = current.copyWith(quantity: newQty);
      state = state.copyWith(cartItems: updated, clearError: true);
      return newQty - current.quantity;
    }

    final cappedQty = stock.quantity <= 0
        ? 0
        : quantity.clamp(1, stock.quantity);
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
      // Per-article branch stock discount is disabled — only the invoice-wise
      // Branch Invoice Discount is allowed now.
      discountPct: 0,
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
      cartItems: state.cartItems
          .where((c) => c.branchStockId != branchStockId)
          .toList(),
    );
  }

  void clearCart() =>
      state = state.copyWith(cartItems: [], invoiceDiscountPct: 0);

  /// Invoice-wise extra discount %, 0..[maxPct] tak clamp. [maxPct] superadmin
  /// ki "Branch Invoice Discount" screen se aata hai (0 = allowed nahi).
  void setInvoiceDiscountPct(double pct, {required double maxPct}) {
    final capped = pct.clamp(0, maxPct <= 0 ? 0 : maxPct);
    state = state.copyWith(invoiceDiscountPct: capped.toDouble());
  }

  /// Current state se payment legs banata hai — cash/card ek row, cash_card do rows.
  List<PaymentInput> _buildPayments() {
    switch (state.paymentType) {
      case 'card':
        return [
          PaymentInput(
            type: 'card',
            amount: state.totalAmount,
            bankEntryId: state.bankEntry?.id,
          ),
        ];
      case 'cash_card':
        return [
          PaymentInput(type: 'cash', amount: state.cashAmount),
          PaymentInput(
            type: 'card',
            amount: state.cardAmount,
            bankEntryId: state.bankEntry?.id,
          ),
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
      if (state.bankEntry == null)
        return 'Select a bank account for the card portion';
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

    // Har invoice ka commission/accountability kisi na kisi manager ke
    // against jana chahiye — branch me manager assign na ho (ya select na
    // kiya ho) to sale hi create nahi hone dete. UI upfront check + banner
    // dikhata hai; ye last-line guard hai.
    final manager = state.manager;
    if (manager == null) {
      return 'Select a manager for this invoice. If none is listed, add a manager for this branch under Employees.';
    }

    state = state.copyWith(isSaving: true, clearError: true);

    // Cashier hamesha logged-in user hi hota hai — koi dropdown/selection nahi.
    final cashierId = _ref.read(authProvider).user?.id;
    final managerCommissionPercent = manager.commissionPercent;
    final managerCommissionAmount =
        state.totalAmount * managerCommissionPercent / 100;
    final salesmanCommissionPercent = state.salesman?.commissionPercent ?? 0;
    final salesmanCommissionAmount =
        state.totalAmount * salesmanCommissionPercent / 100;

    Future<SaleInvoiceModel> attemptSave(String number) =>
        _repo.saveSaleInvoice(
          invoiceNumber: number,
          branchId: _branchId,
          printerId: state.printer?.id,
          cashierId: cashierId,
          customerId: state.customer!.id,
          salesmanId: state.salesman?.id,
          managerId: manager.id,
          subtotal: state.subtotal,
          totalDiscount: state.totalDiscount,
          // Manual invoice discount + head office ka automatic sale-tier
          // discount — dono ek hi column mein combine ho kar save hote hain.
          invoiceDiscount: state.invoiceDiscount + state.autoDiscount,
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
        state = state.copyWith(
          isSaving: false,
          lastSavedInvoice: _withReceiptDetails(saved),
        );
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
          if (mounted)
            state = state.copyWith(isSaving: false, error: e2.toString());
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
        .map(
          (c) => SaleInvoiceItemModel(
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
          ),
        )
        .toList();

    final payments = _buildPayments()
        .map(
          (p) => SaleInvoicePaymentModel(
            id: '',
            saleInvoiceId: saved.id,
            branchId: _branchId,
            bankEntryId: p.bankEntryId,
            paymentType: p.type,
            amount: p.amount,
            createdAt: saved.createdAt,
          ),
        )
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
    await _loadDefaultEmployees();
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
