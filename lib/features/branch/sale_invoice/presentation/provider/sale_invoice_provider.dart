import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safishoe_app/core/service/realtime/table_changes_provider.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../superadmin/branch/presentation/providers/branch_provider.dart';
import '../../../../superadmin/discount/data/model/b1g1_offer_model.dart';
import '../../../../superadmin/discount/data/model/sale_discount_tier_model.dart';
import '../../../../superadmin/discount/presentation/providers/b1g1_offer_provider.dart';
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
  (ref) {
    // Realtime — sale, return, exchange, accept ya doosre counter ki sale se
    // stock badalte hi list reload (page refresh ki zaroorat nahi).
    ref.watch(tableChangesProvider('branch_stock_inventory'));
    return ref
        .read(_branchStockRepoForSaleProvider)
        .getBranchStock(ref.watch(currentBranchIdProvider));
  },
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

  /// Returns/exchanges ke baad net total.
  double get totalAmount => invoices.fold(0, (s, i) => s + i.netAmount);

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

  /// Aaj chalne wale Buy 1 Get 1 offers (admin ki "Discount → Buy 1 Get 1").
  final List<B1g1OfferModel> b1g1Offers;
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
    this.b1g1Offers = const [],
    this.isSaving = false,
    this.error,
    this.lastSavedInvoice,
  });

  /// Cart mein koi item B1G1 mein free gaya — phir koi aur discount nahi.
  bool get b1g1Applied => cartItems.any((i) => i.b1g1FreeQty > 0);

  /// B1G1 mein free gaye units ki qeemat.
  double get b1g1Discount =>
      cartItems.fold(0, (sum, i) => sum + i.b1g1Discount);

  /// Invoice-wise extra discount, rupees mein — % of items total.
  double get invoiceDiscount =>
      b1g1Applied ? 0 : itemsTotal * invoiceDiscountPct / 100;

  /// Head office ki tier jo [itemsTotal] par qualify karti hai — sab se
  /// zyada min_sale_amount wali jeet ti hai (stacking nahi hoti).
  SaleDiscountTierModel? get matchedDiscountTier {
    final eligible = discountTiers.where((t) => itemsTotal >= t.minSaleAmount);
    if (eligible.isEmpty) return null;
    return eligible.reduce((a, b) => a.minSaleAmount >= b.minSaleAmount ? a : b);
  }

  /// Matched tier ka discount, rupees mein — cashier isko badal nahi sakta,
  /// items total qualify hote hi automatically lagta hai.
  double get autoDiscount =>
      b1g1Applied ? 0 : matchedDiscountTier?.discountFor(itemsTotal) ?? 0;

  /// 'cash_card' ke liye card portion = total - cash (0 se kam nahi ho sakta).
  double get cardAmount => (totalAmount - cashAmount).clamp(0, double.infinity);

  double get subtotal =>
      cartItems.fold(0, (sum, i) => sum + (i.salePrice * i.quantity));
  /// Item-wise discount (B1G1 ke ilawa).
  double get itemDiscount =>
      cartItems.fold(0, (sum, i) => sum + (i.discountAmount * i.quantity));

  /// Item-wise + B1G1 free — invoice ke total_discount mein yahi jata hai.
  double get totalDiscount => itemDiscount + b1g1Discount;

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
    List<B1g1OfferModel>? b1g1Offers,
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
    b1g1Offers: b1g1Offers ?? this.b1g1Offers,
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

  /// Admin ke offers badle (ya pehli dafa load hon) to cart dobara nikalo.
  void setB1g1Offers(List<B1g1OfferModel> offers) {
    if (!mounted) return;
    state = state.copyWith(b1g1Offers: offers);
    _setCart(state.cartItems);
  }

  /// Har cart change isi se — B1G1 free units har dafa naye sire se.
  void _setCart(List<SaleCartItem> items, {double? invoiceDiscountPct}) {
    final results = computeB1g1([
      for (final i in items)
        (
          price: i.salePrice,
          quantity: i.quantity,
          productId: i.productId,
          variantKey: b1g1VariantKey(
            productId: i.productId,
            sizeId: i.sizeId,
            colorId: i.colorId,
            brandId: i.brandId,
            categoryId: i.categoryId,
            typeId: i.typeId,
          ),
          brandId: i.brandId,
          categoryId: i.categoryId,
        ),
    ], state.b1g1Offers);
    state = state.copyWith(
      cartItems: [
        for (var k = 0; k < items.length; k++)
          results[k].offerId == null
              ? items[k].copyWith(clearB1g1: true)
              : items[k].copyWith(
                  b1g1OfferId: results[k].offerId,
                  b1g1FreeQty: results[k].freeQty,
                ),
      ],
      invoiceDiscountPct: invoiceDiscountPct,
      clearError: true,
    );
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
  /// tak clamp karta hai — return value actual quantity jo add hui. Offer
  /// wala article ho to us ka free partner bhi khud cart mein aa jata hai.
  int addCartItem(BranchStockModel stock, {int quantity = 1}) {
    final added = _addStock(stock, quantity);
    if (added > 0) _addB1g1FreeUnit(stock.id);
    return added;
  }

  int _addStock(BranchStockModel stock, int quantity) {
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
      _setCart(updated);
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

    _setCart([...state.cartItems, item]);
    return cappedQty;
  }

  /// Variant kis chalte B1G1 offer mein hai — [computeB1g1] jaisa pehla match.
  B1g1OfferModel? _b1g1OfferForIds({
    required String productId,
    required String sizeId,
    required String colorId,
    required String brandId,
    required String categoryId,
    required String typeId,
  }) {
    final key = b1g1VariantKey(
      productId: productId,
      sizeId: sizeId,
      colorId: colorId,
      brandId: brandId,
      categoryId: categoryId,
      typeId: typeId,
    );
    for (final o in state.b1g1Offers) {
      if (o.matches(
        productId: productId,
        variantKey: key,
        brandId: brandId,
        categoryId: categoryId,
      )) {
        return o;
      }
    }
    return null;
  }

  B1g1OfferModel? _b1g1OfferFor(SaleCartItem i) => _b1g1OfferForIds(
    productId: i.productId,
    sizeId: i.sizeId,
    colorId: i.colorId,
    brandId: i.brandId,
    categoryId: i.categoryId,
    typeId: i.typeId,
  );

  /// [offer] ke cart mein kitne units hain.
  int _b1g1Units(B1g1OfferModel offer) => state.cartItems
      .where((c) => _b1g1OfferFor(c)?.id == offer.id)
      .fold(0, (sum, c) => sum + c.quantity);

  /// Offer wala article add hua aur us offer ke units taaq (odd) hain — jodi
  /// poori karne ke liye admin ke usi offer ka doosra, kam (ya barabar) qeemat
  /// wala article (stock mein ho to) free mein cart mein. Aisa koi na mile to
  /// usi variant ka ek aur unit. Cart mein is offer ka koi article pehle se
  /// free ho to usi ka ek aur unit — paid 2 to wahi free article bhi 2.
  void _addB1g1FreeUnit(String branchStockId) {
    final idx = state.cartItems.indexWhere(
      (c) => c.branchStockId == branchStockId,
    );
    if (idx == -1) return;
    final item = state.cartItems[idx];
    final offer = _b1g1OfferFor(item);
    if (offer == null || _b1g1Units(offer).isEven) return;

    SaleCartItem? freeLine;
    for (final c in state.cartItems) {
      if (c.b1g1FreeQty <= 0 || c.salePrice > item.salePrice) continue;
      if (c.availableStock > 0 && c.quantity >= c.availableStock) continue;
      if (_b1g1OfferFor(c)?.id != offer.id) continue;
      if (freeLine == null || c.salePrice < freeLine.salePrice) freeLine = c;
    }
    if (freeLine != null) {
      _setQty(freeLine.branchStockId, freeLine.quantity + 1);
      return;
    }

    final inCart = {
      for (final c in state.cartItems) c.branchStockId: c.quantity,
    };
    BranchStockModel? partner;
    for (final s in _ref.read(branchStockCacheProvider).value ?? const []) {
      if (s.id == item.branchStockId || s.salePrice > item.salePrice) continue;
      if (s.quantity - (inCart[s.id] ?? 0) <= 0) continue;
      final o = _b1g1OfferForIds(
        productId: s.productId,
        sizeId: s.sizeId,
        colorId: s.colorId,
        brandId: s.brandId,
        categoryId: s.categoryId,
        typeId: s.typeId,
      );
      if (o?.id != offer.id) continue;
      if (partner == null || s.salePrice < partner.salePrice) partner = s;
    }
    if (partner != null) {
      _addStock(partner, 1);
      return;
    }

    if (item.availableStock > 0 && item.quantity >= item.availableStock) return;
    final updated = List<SaleCartItem>.from(state.cartItems);
    updated[idx] = item.copyWith(quantity: item.quantity + 1);
    _setCart(updated);
  }

  /// Offer wala unit kam hua aur jodi toot gayi — jo unit pehle free tha wo
  /// bhi cart se nikal do (warna wo paid ban kar bill mein reh jata).
  /// Sab se sasta free article pehle kam hota hai.
  void _dropB1g1FreeUnit(B1g1OfferModel? offer, List<SaleCartItem> before) {
    if (offer == null || _b1g1Units(offer).isEven) return;
    final sorted = [...before]
      ..sort((a, b) => a.salePrice.compareTo(b.salePrice));
    for (final b in sorted) {
      if (b.b1g1FreeQty <= 0 || _b1g1OfferFor(b)?.id != offer.id) continue;
      final now = state.cartItems.where(
        (c) => c.branchStockId == b.branchStockId,
      );
      if (now.isEmpty) continue;
      _setQty(b.branchStockId, now.first.quantity - 1);
      return;
    }
  }

  /// Seedha quantity set — koi B1G1 auto add/remove nahi.
  void _setQty(String branchStockId, int quantity) {
    if (quantity <= 0) {
      _setCart(state.cartItems
          .where((c) => c.branchStockId != branchStockId)
          .toList());
      return;
    }
    _setCart(state.cartItems.map((i) {
      if (i.branchStockId != branchStockId) return i;
      final capped = i.availableStock > 0
          ? quantity.clamp(1, i.availableStock)
          : quantity;
      return i.copyWith(quantity: capped);
    }).toList());
  }

  void updateItemQuantity(String branchStockId, int quantity) {
    final before = state.cartItems;
    final current = before.where((c) => c.branchStockId == branchStockId);
    if (current.isEmpty) return;
    final item = current.first;
    _setQty(branchStockId, quantity);
    if (quantity > item.quantity) {
      _addB1g1FreeUnit(branchStockId);
    } else if (quantity < item.quantity) {
      _dropB1g1FreeUnit(_b1g1OfferFor(item), before);
    }
  }

  void removeItem(String branchStockId) =>
      updateItemQuantity(branchStockId, 0);

  /// Cart ki FREE row delete — sirf us line ke free units nikalte hain.
  void removeB1g1FreeUnits(String branchStockId) {
    final item = state.cartItems.where((c) => c.branchStockId == branchStockId);
    if (item.isEmpty) return;
    _setQty(branchStockId, item.first.quantity - item.first.b1g1FreeQty);
  }

  void clearCart() => _setCart(const [], invoiceDiscountPct: 0);

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
      _ref.invalidate(branchStockCacheProvider);
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
          _ref.invalidate(branchStockCacheProvider);
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
            discount: c.discountAmount * c.quantity + c.b1g1Discount,
            totalPrice: c.lineTotal,
            isB1g1: c.isB1g1,
            b1g1FreeQty: c.b1g1FreeQty,
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
    // Tiers aur B1G1 offers naye invoice par bhi wahi rehte hain.
    state = SaleInvoiceState(
      invoiceLoading: true,
      discountTiers: state.discountTiers,
      b1g1Offers: state.b1g1Offers,
    );
    await _loadInvoiceNumber();
    await _loadDefaultCustomer();
    await _loadDefaultEmployees();
  }
}

final saleInvoiceProvider =
    StateNotifierProvider<SaleInvoiceNotifier, SaleInvoiceState>(
      (ref) {
        final notifier = SaleInvoiceNotifier(
          ref,
          ref.read(saleInvoiceRepositoryProvider),
          ref.watch(currentBranchIdProvider),
        );
        // Admin ke B1G1 offers — load hote hi aur realtime badalne par.
        ref.listen(
          runningB1g1OffersProvider,
          (_, next) => notifier.setB1g1Offers(next.value ?? const []),
          fireImmediately: true,
        );
        return notifier;
      },
    );
